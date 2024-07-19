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
        $licenseIdentifiers = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'identifiers' -ChildPath 'LicenseIdentifiers.json' )
        Get-Content -Path $licenseIdentifiers | ConvertFrom-Json| Set-PSFResultCache
    }
    end
    {}
}