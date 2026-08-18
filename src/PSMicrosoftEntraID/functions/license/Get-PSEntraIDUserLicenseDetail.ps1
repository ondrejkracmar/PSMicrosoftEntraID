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

    .PARAMETER AdvancedFilter
        Returns the full assigned-license detail including expanded service plan
        information instead of the simplified default projection.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicenseDetail -Identity user@domain.com

		Get Office 365 subscriptions with their service plans of specific user
	    .NOTES
        Piping into Select-Object -First N logs a warning that is not a failure:

            WARNING: [<cmdlet>] Failed to: ... | The pipeline has been stopped

        The results are correct and complete. Select-Object stops the pipeline once it
        has what it asked for, and the next write throws PipelineStoppedException -
        normal termination, reported as an error only because the write happens inside a
        protected block. Materialise first if the warning is in the way:

            $items = @(<cmdlet> ...)
            $items | Select-Object -First 3

        or filter server-side with -Filter instead of trimming client-side. Not silenced
        on purpose: the only fix that works is to collect the whole result before
        emitting any of it, which would cost streaming on every read.

#>
    [OutputType('PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
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
                    $result = Invoke-PSFProtectedCommand -ActionString 'User.LicenseDetail.List' -ActionStringValues $itemInputObject.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/licenseDetails' -f $itemInputObject.Id) -Query $query -Method Get -ErrorAction Stop)
                                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'Identity' {
                foreach ($user in $Identity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                    else {
                        $result = Invoke-PSFProtectedCommand -ActionString 'User.LicenseDetail.List' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/licenseDetails' -f $aADUser.Id) -Query $query -Method Get -ErrorAction Stop)
                                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                    }
                }
            }
        }
    }
    end
    {}
}
