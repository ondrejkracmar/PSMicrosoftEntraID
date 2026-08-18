<#
Add all things you want to run before importing the main function code.

WARNING: ONLY provide paths to files!

After building the module, this file will be completely ignored, adding anything but paths to files ...
- Will not work after publishing
- Could break the build process
#>

$moduleRoot = Split-Path (Split-Path $PSScriptRoot)

# Load Assembly
"$($moduleRoot)\bin\assembly.ps1"

# Load all internal classes
"$moduleRoot\internal\classes\attributes\ValidateGroupIdentityAttribute.ps1"
"$moduleRoot\internal\classes\attributes\ValidateMailAddressAttribute.ps1"
"$moduleRoot\internal\classes\attributes\ValidateUserIdentityAttribute.ps1"
"$moduleRoot\internal\classes\attributes\ValidateGuidAttribute.ps1"

#"$moduleRoot\internal\classes\other\FederationProvider.ps1"
"$moduleRoot\internal\classes\token\EntraToken.ps1"
"$moduleRoot\internal\classes\other\FilterBuilder.ps1"
"$moduleRoot\internal\classes\other\ServiceSelector.ps1"

# Load the strings used in messages
"$moduleRoot\internal\scripts\strings.ps1"