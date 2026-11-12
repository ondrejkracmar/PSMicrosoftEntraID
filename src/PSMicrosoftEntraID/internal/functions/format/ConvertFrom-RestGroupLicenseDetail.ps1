function ConvertFrom-RestGroupLicenseDetail {
    <#
	.SYNOPSIS
		Converts Group Office 365 License Detail objects to look nice.

	.DESCRIPTION
		Converts Group Office 365 License Detail objects to look nice.

	.PARAMETER InputObject
		The rest response representing a Group Office 365 License Detail

	.EXAMPLE
		PS C:\> Get-PSEntraIDGroupLicenseDetail -InputObject (Invoke-RestRequest -Service 'graph' -Path groups -Method Get -ErrorAction Stop)
		Retrieves the specified Group Office 365 License Detail and converts it into something userfriendly
	#>
    param (
        $InputObject
    )
    if (-not $InputObject) { return }

    ConvertFrom-GraphResponse -InputObject $InputObject -Type ([PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku])
}