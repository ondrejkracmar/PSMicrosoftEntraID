<#
.SYNOPSIS
    Publishes a PowerShell module as a NuGet package to an Azure DevOps artifact feed.

.DESCRIPTION
    This script uploads a .nupkg package to a private Azure DevOps artifact feed using the NuGet CLI.
    It supports both stable and pre-release versions and builds the correct package file name.

.PARAMETER WorkingDirectory
    The working directory, usually set by the pipeline.

.PARAMETER OrganizationName
    The name of the Azure DevOps organization.

.PARAMETER ArtifactRepositoryName
    The name of the Azure DevOps project.

.PARAMETER ArtifactFeedName
    The name of the Azure Artifacts feed.

.PARAMETER FeedUsername
    Typically 'AzureDevOps'.

.PARAMETER PersonalAccessToken
    The PAT with rights to push packages to the feed.

.PARAMETER ModuleName
    The PowerShell module name (used in the filename).

.PARAMETER ModuleVersion
    The module version (used in the filename).

.PARAMETER PreRelease
    Pre-release label (e.g. 'alpha').

.PARAMETER CommitsSinceVersion
    Number of commits since version source (for prerelease suffix).

.EXAMPLE
    .\vsts-publishNuGetPackage.ps1 -WorkingDirectory ... -ModuleName 'MyModule' -ModuleVersion '1.0.0' ...
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param (
    $WorkingDirectory,
    [string]$OrganizationName,
    [string]$ArtifactRepositoryName,
    [string]$ArtifactFeedName,
    [string]$FeedUsername,
    [string]$PersonalAccessToken,
    [string]$ModuleName,
    [string]$ModuleVersion,
    [string]$PreRelease,
    [string]$CommitsSinceVersion
)

# Constants
$nugetPath = 'nuget'
$packageSourceUrl = "https://pkgs.dev.azure.com/$OrganizationName/$ArtifactRepositoryName/_packaging/$ArtifactFeedName/nuget/v2"

Write-Host "📦 Preparing to publish $ModuleName $ModuleVersion..."

# Register NuGet source
Write-Host "🔐 Registering NuGet source..."
& $nugetPath source add `
    -Name $ArtifactFeedName `
    -Source $packageSourceUrl `
    -Username $FeedUsername `
    -Password $PersonalAccessToken `
    | Out-Null

# Determine package file name
if (-not [string]::IsNullOrEmpty($PreRelease)) {
    $sanitizedSuffix = ($PreRelease + $CommitsSinceVersion) -replace '[^a-zA-Z0-9]', ''
    $packageName = "$ModuleName.$ModuleVersion-$sanitizedSuffix.nupkg"
} else {
    $packageName = "$ModuleName.$ModuleVersion.nupkg"
}

$packagePath = Join-Path -Path $WorkingDirectory -ChildPath $packageName

# Validate existence
if (-not (Test-Path -Path $packagePath)) {
    throw "❌ Package file does not exist: $packagePath"
}

# Push package
Write-Host "🚀 Pushing NuGet package: $packageName"
& $nugetPath push `
    $packagePath `
    -Source $ArtifactFeedName `
    -ApiKey ((New-Guid).Guid) `
    -SkipDuplicate `
    | Out-Null

Write-Host "✅ Module published successfully!"
