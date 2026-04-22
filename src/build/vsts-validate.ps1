# Guide for available variables and working with secrets:
# https://docs.microsoft.com/en-us/vsts/build-release/concepts/definitions/build/variables?tabs=powershell

# Needs to ensure things are Done Right and only legal commits to master get built

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$licenseCatalogPath = Join-Path -Path $PSScriptRoot -ChildPath '../PSMicrosoftEntraID/internal/identifiers/LicenseIdentifiers.json'
$generatedCatalogPath = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.json')

try {
	& "$PSScriptRoot/Update-LicenseIdentifiers.ps1" -OutputPath $generatedCatalogPath

	$expectedCatalog = Get-Content -Path $generatedCatalogPath -Raw
	$currentCatalog = Get-Content -Path $licenseCatalogPath -Raw

	if ($expectedCatalog -cne $currentCatalog) {
		throw "LicenseIdentifiers.json is outdated. Run src/build/Update-LicenseIdentifiers.ps1 and commit the regenerated catalog."
	}
}
finally {
	if (Test-Path -Path $generatedCatalogPath) {
		Remove-Item -Path $generatedCatalogPath -Force
	}
}

# Run internal pester tests
& "$PSScriptRoot\..\tests\pester.ps1"