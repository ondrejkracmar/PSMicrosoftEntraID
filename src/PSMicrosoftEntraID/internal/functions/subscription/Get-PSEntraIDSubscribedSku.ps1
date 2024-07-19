function Get-PSEntraIDSubscribedSku {
    <#
	.SYNOPSIS
		Get the list of commercial subscriptions that an organization has acquired.

	.DESCRIPTION
		Get the list of commercial subscriptions that an organization has acquired.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDSubscribedSku

		Get the list of commercial subscriptions

	#>
    [OutputType('PSMicrosoftEntraID.License')]
    [CmdletBinding()]
    param (

    )
    begin {

    }
    process {
        Get-PSFResultCache
    }
    end
    {}
}