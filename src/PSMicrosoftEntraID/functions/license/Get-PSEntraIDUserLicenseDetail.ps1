function Get-PSEntraIDUserLicenseDetail {
    <#
	.SYNOPSIS
		Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

	.DESCRIPTION
		Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicenseDetail -Identity user@domain.com

		Get Office 365 subscriptions with their service plansPlans of specific user
	#>
    [OutputType('PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$Identity,
        [switch]$AdvancedFilter,
        [switch]$EnableException
    )
    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $aADUser = Get-PSEntraIDUser -Identity $user
                    if (-not([object]::Equals($aADUser, $null))) {
                        $userId = $aADUser.Id
                        Invoke-PSFProtectedCommand -ActionString 'User.LicenseDetai.List' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUserLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/licenseDetails' -f $userId) -Query $query -Method Get)
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                }
            }
        }
    }
    end
    {}
}
