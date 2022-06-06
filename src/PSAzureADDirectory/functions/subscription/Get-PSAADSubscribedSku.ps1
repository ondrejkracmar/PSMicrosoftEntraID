function Get-PSAADSubscribedSku {
    <#
	.SYNOPSIS
		Get the list of commercial subscriptions that an organization has acquired
	
	.DESCRIPTION
		Get the list of commercial subscriptions that an organization has acquired. For the mapping of license names as displayed on the Azure portal or the Microsoft 365 admin center against their Microsoft Graph skuId and skuPartNumber properties
	
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