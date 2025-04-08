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
    [OutputType('PSMicrosoftEntraID.License.LicenseIdentifier')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $EnableException
    )
    begin {

    }
    process {
        [string] $licenseIdentifiers = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'identifiers' -ChildPath 'LicenseIdentifiers.json' )
        [string] $jsonString = Get-Content -Path $licenseIdentifiers
        [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
        [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
        [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.License.LicenseIdentifier[]])
        return $serializer.ReadObject($stream)
    }
    end
    {}
}