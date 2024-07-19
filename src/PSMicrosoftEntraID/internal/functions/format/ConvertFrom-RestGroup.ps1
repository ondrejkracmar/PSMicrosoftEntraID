function ConvertFrom-RestGroup {
    <#
	.SYNOPSIS
		Converts group objects to look nice.

	.DESCRIPTION
		Converts group objects to look nice.

	.PARAMETER InputObject
		The rest response representing a group

	.EXAMPLE
		PS C:\> Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroup

		Retrieves the specified group and converts it into something userfriendly

	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )
    begin {

    }
    process {
        if ((-not $InputObject) -or ([string]::IsNullOrEmpty($InputObject.id)) ) { return }


        [PSCustomObject]@{
            PSTypeName      = 'PSMicrosoftEntraID.Group'
            Id              = $InputObject.id
            CreatedDateTime = $InputObject.createdDateTime
            MailNickname    = $InputObject.mailNickname
            Mail            = $InputObject.mail
            ProxyAddresses  = $InputObject.proxyAddresses
            MailEnabled     = $InputObject.mailEnabled
            Visibility      = $InputObject.visibility
            DisplayName     = $InputObject.displayName
            Description     = $InputObject.description
            GropupTypes     = $InputObject.groupTypes
            CreatedByAppId  = $InputObject.createdByAppId

        }

    }
}