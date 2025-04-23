<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$WorkingDirectory,

	$Repository = 'PSGallery',

	$ApiKey,

	[switch]
	$LocalRepo,

	[switch]
	$SkipPublish,

	[string]
	$ModuleName,

	[string]
	$ModuleVersion,

	[string]
	$PreRelease,

	[string]
	$CommitsSinceVersion,

	[switch]
	$AutoVersion
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else {
		$WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY
 }
}
if (-not $WorkingDirectory) {
 $WorkingDirectory = Split-Path $PSScriptRoot
}
#endregion Handle Working Directory Defaults

# Prepare publish folder
Write-PSFMessage -Level Important -Message "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory -Force
Copy-Item -Path "$($WorkingDirectory)\$($ModuleName)" -Destination $publishDir.FullName -Recurse -Force

#region Gather text data to compile
$text = @()
$processed = @()

# Gather Stuff to run before
foreach ($filePath in (& "$($PSScriptRoot)\..\$($ModuleName)\internal\scripts\preimport.ps1")) {
	if ([string]::IsNullOrWhiteSpace($filePath)) {
		continue
 }

	$item = Get-Item $filePath
	if ($item.PSIsContainer) {
		continue
 }
	if ($item.FullName -in $processed) {
		continue
 }
	$text += [System.IO.File]::ReadAllText($item.FullName)
	$processed += $item.FullName
}

# Gather commands
Get-ChildItem -Path "$($publishDir.FullName)\$($ModuleName)\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($publishDir.FullName)\$($ModuleName)\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather stuff to run afterwards
foreach ($filePath in (& "$($PSScriptRoot)\..\$($ModuleName)\internal\scripts\postimport.ps1")) {
	if ([string]::IsNullOrWhiteSpace($filePath)) {
		continue
 }

	$item = Get-Item $filePath
	if ($item.PSIsContainer) {
		continue
 }
	if ($item.FullName -in $processed) {
		continue
 }
	$text += [System.IO.File]::ReadAllText($item.FullName)
	$processed += $item.FullName
}
#endregion Gather text data to compile

#region Update the psm1 file
$fileData = Get-Content -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psm1" -Raw
$fileData = $fileData.Replace('"<was not compiled>"', '"<was compiled>"')
$fileData = $fileData.Replace('"<compile code into here>"', ($text -join "`n`n"))
[System.IO.File]::WriteAllText("$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psm1", $fileData, [System.Text.Encoding]::UTF8)
#endregion Update the psm1 file

#region Updating the Module Version
if ($AutoVersion) {
	Write-PSFMessage -Level Important -Message "Updating module version numbers."
	try {
		[version]$remoteVersion = (Find-Module "$($ModuleName)" -Repository $Repository -ErrorAction Stop).Version
	}
	catch {
		Stop-PSFFunction -Message "Failed to access $($Repository)" -EnableException $true -ErrorRecord $_
	}
	if (-not $remoteVersion) {
		Stop-PSFFunction -Message "Couldn't find $($ModuleName) on repository $($Repository)" -EnableException $true
	}
	$newBuildNumber = $remoteVersion.Build + 1
	[version]$localVersion = (Import-PowerShellDataFile -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1").ModuleVersion
	Update-ModuleManifest -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1" -ModuleVersion "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
}

if (-not ([string]::IsNullOrEmpty($ModuleVersion))) {
	if (-not ([string]::IsNullOrEmpty($PreRelease))) {
		Update-ModuleManifest -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1" -ModuleVersion $ModuleVersion -Prerelease (('{0}{1}' -f $PreRelease, $CommitsSinceVersion) -replace '[^a-zA-Z0-9]', '')
	}
	else {
		Update-ModuleManifest -Path "$($publishDir.FullName)\$($ModuleName)\$($ModuleName).psd1" -ModuleVersion $ModuleVersion
	}
}

#endregion Updating the Module Version

#region Publish
if ($SkipPublish) {
 return
}
if ($LocalRepo) {
	# Dependencies must go first
	Write-PSFMessage -Level Important -Message "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name PSFramework).ModuleBase -PackagePath .
	Write-PSFMessage -Level Important -Message "Creating Nuget Package for module: $($ModuleName)"
	New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\$($ModuleName)" -PackagePath .
}
else {
	# Publish to Gallery
	Write-PSFMessage -Level Important -Message "Publishing the $($ModuleName) module to $($Repository)"
	Publish-Module -Path "$($publishDir.FullName)\$($ModuleName)" -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion Publish
