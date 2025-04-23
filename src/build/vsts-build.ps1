<#
.SYNOPSIS
    Publishes a PowerShell module to a NuGet repository or PSGallery.

.DESCRIPTION
    This script creates a clean `publish` folder with only relevant module files
    (.psd1, .psm1, .ps1, .dll, .pdb, .json, .xml, .md), updates the module manifest
    version, and optionally publishes it.

.PARAMETER WorkingDirectory
    The working root directory containing the module folder.

.PARAMETER Repository
    Repository to publish to (default: PSGallery).

.PARAMETER ApiKey
    API key for publishing to the repository.

.PARAMETER LocalRepo
    Switch to create a NuGet package locally instead of publishing.

.PARAMETER SkipPublish
    If set, the script will skip the actual publishing step.

.PARAMETER ModuleName
    Name of the module to publish.

.PARAMETER ModuleVersion
    Version number for the module.

.PARAMETER PreRelease
    Optional prerelease label.

.PARAMETER CommitsSinceVersion
    Optional build metadata (commits since last version).

.PARAMETER AutoVersion
    If set, version will be auto-incremented based on the repository.
#>

param (
    $WorkingDirectory,
    $Repository = 'PSGallery',
    $ApiKey,
    [switch]$LocalRepo,
    [switch]$SkipPublish,
    [string]$ModuleName,
    [string]$ModuleVersion,
    [string]$PreRelease,
    [string]$CommitsSinceVersion,
    [switch]$AutoVersion
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory) {
    if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
        $WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
    } else {
        $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    }
}
if (-not $WorkingDirectory) {
    $WorkingDirectory = Split-Path $PSScriptRoot
}
#endregion

# Paths
$modulePath = Join-Path $WorkingDirectory $ModuleName
$publishDir = Join-Path $WorkingDirectory 'publish'
$publishModulePath = Join-Path $publishDir $ModuleName

# Clean publish folder
if (Test-Path $publishModulePath) {
    Remove-Item -Path $publishModulePath -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -Path $publishModulePath -ItemType Directory -Force | Out-Null

Write-PSFMessage -Level Important -Message "📁 Creating filtered publish folder: $publishModulePath"

# Define allowed file extensions
$allowedExtensions = @('.psd1', '.psm1', '.ps1', '.dll', '.pdb', '.json', '.xml', '.md')

# Copy filtered files only
Get-ChildItem -Path $modulePath -Recurse -File | Where-Object {
    $allowedExtensions -contains $_.Extension.ToLower()
} | ForEach-Object {
    $relativePath = $_.FullName.Substring($modulePath.Length).TrimStart('\','/')
    $targetPath = Join-Path $publishModulePath $relativePath
    $targetDir = Split-Path $targetPath -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    Copy-Item -Path $_.FullName -Destination $targetPath -Force
}

#region Update module version
$manifestPath = Join-Path $publishModulePath "$ModuleName.psd1"

if ($AutoVersion) {
    Write-PSFMessage -Level Important -Message "Updating module version automatically"
    try {
        [version]$remoteVersion = (Find-Module "$ModuleName" -Repository $Repository -ErrorAction Stop).Version
    } catch {
        Stop-PSFFunction -Message "Failed to access $Repository" -EnableException $true -ErrorRecord $_
    }
    if (-not $remoteVersion) {
        Stop-PSFFunction -Message "Couldn't find $ModuleName on repository $Repository" -EnableException $true
    }
    $newBuildNumber = $remoteVersion.Build + 1
    [version]$localVersion = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
    Update-ModuleManifest -Path $manifestPath -ModuleVersion "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
}

if (-not ([string]::IsNullOrEmpty($ModuleVersion))) {
    if (-not ([string]::IsNullOrEmpty($PreRelease))) {
        $prereleaseSanitized = ("$PreRelease$CommitsSinceVersion") -replace '[^a-zA-Z0-9]', ''
        Update-ModuleManifest -Path $manifestPath -ModuleVersion $ModuleVersion -Prerelease $prereleaseSanitized
    } else {
        Update-ModuleManifest -Path $manifestPath -ModuleVersion $ModuleVersion
    }
}
#endregion

#region Publish
if ($SkipPublish) { return }

if ($LocalRepo) {
    Write-PSFMessage -Level Important -Message "📦 Creating NuGet package locally for: $ModuleName"
    New-PSMDModuleNugetPackage -ModulePath $publishModulePath -PackagePath .
} else {
    Write-PSFMessage -Level Important -Message "🚀 Publishing module to: $Repository"
    Publish-Module -Path $publishModulePath -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion
