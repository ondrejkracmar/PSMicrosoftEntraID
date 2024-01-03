

#region Handle Working Directory Defaults
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

#define module for documentation

$ModuleName = 'PSMicrosoftEntraID'
if (Test-Path -Path "$($WorkingDirectory)/src/docs") {
	$MarkdownPath = "$($WorkingDirectory)/src/docs"
}
else {
	$MarkdownPath = New-Item -Path "$($WorkingDirectory)/src/" -Name 'docs' -ItemType Directory -Force
}
Import-Module "$($WorkingDirectory)/src/$($ModuleName)/$($ModuleName).psd1"
if (Test-Path -Path "$($WorkingDirectory)/src/PSMicrosoftEntraID/en-us") {
	$MamlPath = "$($WorkingDirectory)/src/PSMicrosoftEntraID/en-us"
}else {
	$MamlPath = New-Item -Path "$($WorkingDirectory)/src/" -Name 'en-us' -ItemType Directory -Force
}

$MdHelpParams = @{
	Module                = $ModuleName
	OutputFolder          = $MarkdownPath
	AlphabeticParamsOrder = $true
	UseFullTypeName       = $true
	WithModulePage        = $true
	ExcludeDontShow       = $false
	Encoding              = [System.Text.Encoding]::UTF8
}

$ExtHelpParams = @{
	Path       = $MarkdownPath
	OutputPath = $MamlPath
}

$ExtHelpCabParams = @{
	CabFilesFolder  = $MamlPath
	LandingPagePath = "$($MarkdownPath)/$($ModuleName).md"
	OutputFolder    = "$($MamlPath)/cab"
}

# Generate documentation
$MDFiles = Get-ChildItem -Path "$($MarkdownPath)/*" -Filter *.md
if ($MDFiles.Count -eq 0) {
	Write-PSFMessage -Level Important -Message "Generate initial Markdown help"
	New-MarkdownHelp @MdHelpParams
}
else {
	Write-PSFMessage -Level Important -Message "Updating Markdown files"
	Remove-Item -Path "$($MarkdownPath)/*" -Include *.md -Force
	New-MarkdownHelp @MdHelpParams
}


Write-PSFMessage -Level Important -Message "Creating about help topics"
New-MarkdownAboutHelp -OutputFolder $MarkdownPath -AboutName $ModuleName

Write-PSFMessage -Level Important -Message "Creating external help"
New-ExternalHelp @ExtHelpParams -force

#New-ExternalHelpCab is only supported on Windows because it relies on makecab.exe to create CAB files.
#New-ExternalHelpCab @extHelpCabParams