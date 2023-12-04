function Get-PSEntraIDLicenseIdentifier {
    <#
	.SYNOPSIS
		Get the list of product names and service plan identifiers for licensing.

	.DESCRIPTION
		Get the list of product names and service plan identifiers for licensing.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDLicenseIdentifier

		Get the list of product names and service plan identifiers for licensing

	#>
    [OutputType('PSMicrosoftEntraID.License')]
    [CmdletBinding()]
    param (

    )
    begin {

    }
    process {
        $licenseIdentifiers = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'identifiers' -ChildPath 'LicenseIdentifiers.json' )
        Get-Content -Path $licenseIdentifiers | ConvertFrom-Json | Select-Object -Property SkuId, SkuPartNumber, SkuFriednlyName
    }
    end
    {}
}