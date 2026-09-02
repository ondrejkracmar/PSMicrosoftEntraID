# Selects the compiled library for the running .NET runtime.
# PowerShell 7.4/7.5 run on .NET 8/9 -> net8.0; PowerShell 7.6+ runs on .NET 10 -> net10.0.
$script:PSMicrosoftEntraIDFramework = if ([System.Environment]::Version.Major -ge 10) { 'net10.0' } else { 'net8.0' }

try {
    Add-Type -Path "$script:ModuleRoot\bin\$script:PSMicrosoftEntraIDFramework\PSMicrosoftEntraID.dll" -ErrorAction Stop
}
catch {
    Write-Warning "Failed to load PSMicrosoftEntraID Assembly for '$script:PSMicrosoftEntraIDFramework'! Unable to import module."
    throw
}
try {
    Update-TypeData -AppendPath "$script:ModuleRoot\types\PSMicrosoftEntraID.Types.ps1xml" -ErrorAction Stop
}
catch {
    Write-Warning "Failed to load PSMicrosoftEntraID type extensions! Unable to import module."
    throw
}
