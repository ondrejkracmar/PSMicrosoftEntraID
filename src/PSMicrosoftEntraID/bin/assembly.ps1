try {
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        Add-Type -Path "$script:ModuleRoot\bin\PSMicrosoftEntraID.dll" -ErrorAction Stop
    }
    else {
        Add-Type -Path "$script:ModuleRoot\bin\PS4\PSMicrosoftEntraID.dll" -ErrorAction Stop
    }
}
catch {
    Write-Warning "Failed to load PSMicrosoftEntraID Assembly! Unable to import module."
    throw
}
try {
    Update-TypeData -AppendPath "$script:ModuleRoot\types\PSMicrosoftEntraID.Types.ps1xml" -ErrorAction Stop
}
catch {
    Write-Warning "Failed to load PSMicrosoftEntraID type extensions! Unable to import module."
    throw
}