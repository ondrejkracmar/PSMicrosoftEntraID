function Get-PSAADSubscribedSku {
    <#
	.SYNOPSIS
		Get the list of commercial subscriptions that an organization has acquired

	.DESCRIPTION
		Get the list of commercial subscriptions that an organization has acquired

	.EXAMPLE
		PS C:\> Get-PSAADSubscribedSku
        
		Get the list of commercial subscriptions
	#>
    [OutputType('PSAzureADDirectory.License')]
    [CmdletBinding()]
    param (

    )
    begin {
        Assert-RestConnection -Service graph -Cmdlet $PSCmdlet
    }
    process {
        $query = @{
            '$select' = ((Get-PSFConfig -Module $sript:ModuleName -Name Settings.GraphApiQuery.Select.SubscribedSku).Value -join ',')
        }
        Invoke-RestRequest -Service 'graph' -Path subscribedSkus -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestSubscribedSku
    }
    end
    {}
}