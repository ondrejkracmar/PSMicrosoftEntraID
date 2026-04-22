function Get-PSEntraIDLicenseIdentifier {
    <#
	.SYNOPSIS
		Get the list of product names and service plan identifiers for licensing.

	.DESCRIPTION
		Get the list of product names and service plan identifiers for licensing.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDLicenseIdentifier

		Get the list of product names and service plan identifiers for licensing

	#>
    [OutputType('PSMicrosoftEntraID.License.LicenseIdentifier')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $EnableException
    )
    begin {

    }
    process {
        [string] $licenseIdentifiers = Resolve-PSEntraIDLicenseIdentifierPath
        [string] $jsonString = Get-Content -Path $licenseIdentifiers -Raw
        [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
        [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
        [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.License.LicenseIdentifier[]])
        return $serializer.ReadObject($stream)
    }
    end
    {}
}