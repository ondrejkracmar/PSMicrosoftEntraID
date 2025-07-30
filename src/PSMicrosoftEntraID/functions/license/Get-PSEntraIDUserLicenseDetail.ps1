function Get-PSEntraIDUserLicenseDetail {
    <#
	.SYNOPSIS
		Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

	.DESCRIPTION
		Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

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
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $Identity,
        [switch] $AdvancedFilter,
        [Parameter()]
        [switch] $EnableException
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count' = 'true'
            '$top'   = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'User.LicenseDetai.List' -ActionStringValues $itemInputObject.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/licenseDetails' -f $itemInputObject.Id) -Query $query -Method Get)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity' {
                foreach ($user in $Identity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if (-not([object]::Equals($aADUser, $null))) {
                        Invoke-PSFProtectedCommand -ActionString 'User.LicenseDetai.List' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUserLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/licenseDetails' -f $aADUser.Id) -Query $query -Method Get)
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
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
