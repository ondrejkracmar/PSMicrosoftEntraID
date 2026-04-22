function Register-PSEntraIDLicenseIdentifier {
    <#
	.SYNOPSIS
		Register the list of product names and service plan identifiers for licensing.

	.DESCRIPTION
		Register the list of product names and service plan identifiers for licensing.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Register-PSEntraIDLicenseIdentifier

		Register the list of product names and service plan identifiers for licensing

	#>
    [OutputType('PSMicrosoftEntraID.License')]
    [CmdletBinding()]
    param (

    )
    begin {

    }
    process {
        [bool] $autoUpdateOnImport = Get-PSFConfigValue -FullName ('{0}.LicenseIdentifiers.AutoUpdateOnImport' -f $script:ModuleName) -Fallback $false
        if ($autoUpdateOnImport) {
            Update-PSEntraIDLicenseIdentifierCache | Out-Null
        }

        [string] $licenseIdentifiers = Resolve-PSEntraIDLicenseIdentifierPath
        Get-Content -Path $licenseIdentifiers -Raw | ConvertFrom-Json | Set-PSFResultCache
    }
    end
    {}
}