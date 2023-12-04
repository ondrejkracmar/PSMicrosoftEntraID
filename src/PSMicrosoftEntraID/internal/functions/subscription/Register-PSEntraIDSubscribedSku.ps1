function Register-PSEntraIDSubscribedSku {
    <#
	.SYNOPSIS
		Register the list of commercial subscriptions that an organization has acquired.

	.DESCRIPTION
		Register the list of commercial subscriptions that an organization has acquired.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Register-PSEntraIDSubscribedSku

		Register the list of commercial subscriptions

	#>
    [OutputType('PSMicrosoftEntraID.License')]
    [CmdletBinding()]
    param (

    )
    begin {
        Assert-RestConnection -Service graph -Cmdlet $PSCmdlet
        $query = @{
            '$select' = ((Get-PSFConfig -Module $sript:ModuleName -Name Settings.GraphApiQuery.Select.SubscribedSku).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.List' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            Invoke-RestRequest -Service 'graph' -Path subscribedSkus -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestSubscribedSku
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait | Set-PSFResultCache
        if (Test-PSFFunctionInterrupt) { return }
    }
    end
    {}
}