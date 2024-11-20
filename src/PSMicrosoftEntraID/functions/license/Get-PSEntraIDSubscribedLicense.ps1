function Get-PSEntraIDSubscribedLicense {
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

    )
    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $query = @{
            '$select' = ((Get-PSFConfig -Module $sript:ModuleName -Name Settings.GraphApiQuery.Select.SubscribedSku).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }
    process {
        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.List' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            ConvertFrom-RestSubscribedSku -InputObject (Invoke-EntraRequest -Service $service -Path subscribedSkus -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end
    {}
}