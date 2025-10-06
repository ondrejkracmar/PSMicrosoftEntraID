
<#
This script create markdown documentation for the module.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$WorkingDirectory,
	$ModuleName,
	$MarkdownDirectoryName = 'docs',
	$Location = 'en-us'
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

# Import the new Microsoft.PowerShell.PlatyPS module
if (-not (Get-Module -Name Microsoft.PowerShell.PlatyPS -ListAvailable)) {
	Write-Warning "Microsoft.PowerShell.PlatyPS module not found. Installing..."
	Install-Module Microsoft.PowerShell.PlatyPS -Force -Scope CurrentUser
}
Import-Module Microsoft.PowerShell.PlatyPS -Force

#define module for documentation
$MarkdownFullPath = Join-Path -Path $WorkingDirectory -ChildPath $MarkdownDirectoryName -AdditionalChildPath "cmdlets"
if (Test-Path -Path $MarkdownFullPath) {
	$MarkdownPath = Get-Item -Path $MarkdownFullPath
}
else {
	$MarkdownPath = New-Item -Path $MarkdownFullPath -ItemType Directory -Force
}

$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath $ModuleName -AdditionalChildPath "$($ModuleName).psd1"
if (-not (Test-Path $ModuleManifestPath)) {
	# Try alternative path structure under src folder
	$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath "src" -AdditionalChildPath $ModuleName, "$($ModuleName).psd1"
}
if (-not (Test-Path $ModuleManifestPath)) {
	# Try root level
	$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath "$($ModuleName).psd1"
}
Import-Module $ModuleManifestPath -Force

$MamlFullPath = Join-Path -Path $WorkingDirectory -ChildPath $ModuleName -AdditionalChildPath $Location
if (-not (Test-Path -Path $MamlFullPath)) {
	# Try alternative path structure under src folder
	$MamlFullPath = Join-Path -Path $WorkingDirectory -ChildPath "src" -AdditionalChildPath $ModuleName, $Location
}
if (Test-Path -Path $MamlFullPath) {
	$MamlPath = Get-Item -Path $MamlFullPath
}
else {
	$MamlPath = New-Item -Path $MamlFullPath -ItemType Directory -Force
}

$MdHelpParams = @{
	ModuleInfo            = (Get-Module $ModuleName)
	OutputFolder          = $MarkdownPath.FullName
	WithModulePage        = $false
	Encoding              = [System.Text.Encoding]::UTF8
}

$ExtHelpParams = @{
	OutputFolder = $MamlPath.FullName
	Encoding     = [System.Text.Encoding]::UTF8
}

$ExtHelpCabParams = @{
	CabFilesFolder  = $MamlPath.FullName
	LandingPagePath = Join-Path -Path $MarkdownPath.FullName -ChildPath "$($ModuleName).md"
	OutputFolder    = Join-Path -Path $MamlPath.FullName -ChildPath "cab"
}

# Generate documentation
$MDFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter *.md -ErrorAction SilentlyContinue
if (-not $MDFiles -or $MDFiles.Count -eq 0) {
	Write-PSFMessage -Level Important -Message "Generate initial Markdown help"
	New-MarkdownCommandHelp @MdHelpParams
}
else {
	Write-PSFMessage -Level Important -Message "Updating Markdown files"
	Remove-Item -Path (Join-Path -Path $MarkdownPath.FullName -ChildPath "*.md") -Force
	New-MarkdownCommandHelp @MdHelpParams
}

# Move files from module subfolder to cmdlets folder directly
$ModuleSubfolder = Join-Path -Path $MarkdownPath.FullName -ChildPath $ModuleName
if (Test-Path -Path $ModuleSubfolder) {
	Write-PSFMessage -Level Important -Message "Moving markdown files to cmdlets folder"
	$SubfolderFiles = Get-ChildItem -Path $ModuleSubfolder -Filter "*.md"
	foreach ($File in $SubfolderFiles) {
		$DestinationPath = Join-Path -Path $MarkdownPath.FullName -ChildPath $File.Name
		if (Test-Path -Path $DestinationPath) {
			Remove-Item -Path $DestinationPath -Force
		}
		Move-Item -Path $File.FullName -Destination $DestinationPath
	}
	# Remove empty subfolder
	if ((Get-ChildItem -Path $ModuleSubfolder).Count -eq 0) {
		Remove-Item -Path $ModuleSubfolder -Force
	}
}

Write-PSFMessage -Level Important -Message "Creating about help topics"
# Note: New-MarkdownAboutHelp is not available in Microsoft.PowerShell.PlatyPS
# About topics need to be created manually or using other methods

Write-PSFMessage -Level Important -Message "Creating external help"
# Check if markdown files exist before trying to import them
$MarkdownFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter "*.md" -ErrorAction SilentlyContinue
if ($MarkdownFiles -and $MarkdownFiles.Count -gt 0) {
	# Import the markdown files first, then export as MAML
	$ImportedHelp = Import-MarkdownCommandHelp -Path $MarkdownPath.FullName
	Export-MamlCommandHelp -CommandHelp $ImportedHelp @ExtHelpParams -Force
}
else {
	Write-PSFMessage -Level Warning -Message "No markdown files found to convert to MAML"
}

# Note: New-ExternalHelpCab is only supported on Windows because it relies on makecab.exe to create CAB files.
# Uncomment the following line if you need CAB file generation on Windows:
# New-ExternalHelpCab @ExtHelpCabParams
