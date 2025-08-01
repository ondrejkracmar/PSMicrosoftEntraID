﻿function Get-PSEntraIDSubscribedLicense {
    <#
	.SYNOPSIS
		Register the list of commercial subscriptions that an organization has acquired.

	.DESCRIPTION
		Register the list of commercial subscriptions that an organization has acquired.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDSubscribedLicense

		Register the list of commercial subscriptions

	#>
    [OutputType('PSMicrosoftEntraID.License.SubscriptionSkuLicense')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $EnableException
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$select' = ((Get-PSFConfig -Module $sript:ModuleName -Name Settings.GraphApiQuery.Select.SubscribedSku).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.List' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            ConvertFrom-RestSubscribedSku -InputObject (Invoke-EntraRequest -Service $service -Path subscribedSkus -Query $query -Method Get -ErrorAction Stop)
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
        if (Test-PSFFunctionInterrupt) { return }
    }
    end
    {}
}