function ConvertFrom-RestUserLicenseDetail {
    <#
	.SYNOPSIS
		Converts User Office 365 License Detail objects to look nice.

	.DESCRIPTION
		Converts User Office 365 License Detail objects to look nice.

	.PARAMETER InputObject
		The rest response representing a User Office 365 License Detail

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicenseDetail -InputObject (Invoke-RestRequest -Service 'graph' -Path pstnCalls -Method Get -ErrorAction Stop)
		Retrieves the specified User Office 365 License Detail and converts it into something userfriendly
	#>
    param (
        $InputObject
    )
    if (-not $InputObject) { return }

    ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku])
}