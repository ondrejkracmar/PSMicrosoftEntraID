function Get-PSEntraIDGroupLicenseDetail {
    <#
        .SYNOPSIS
            Return details for licenses that are assigned to a group.

        .DESCRIPTION
            Return details for licenses that are assigned to a group.

        .PARAMETER InputObject
            PSMicrosoftEntraID.Groups.Group object in tenant/directory.

        .PARAMETER Identity
            MailNickname, Mail or Id of the group attribute populated in tenant/directory.

        .PARAMETER AdvancedFilter
            Returns the full assigned-license detail including expanded service plan
            information instead of the simplified default projection.

        .PARAMETER EnableException
            This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
            but allows catching exceptions in calling scripts.

        .EXAMPLE
            PS C:\> Get-PSEntraIDGroupLicenseDetail -Identity licensing-group

            Get Office 365 subscriptions with their service plans of specific group
    #>
    [OutputType('PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
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
                    [string] $groupTarget = if (-not [string]::IsNullOrWhiteSpace($itemInputObject.DisplayName)) { $itemInputObject.DisplayName } else { $itemInputObject.Id }
                    $result = Invoke-PSFProtectedCommand -ActionString 'Group.LicenseDetail.List' -ActionStringValues $groupTarget -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestGroupLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('groups/{0}/licenseDetails' -f $itemInputObject.Id) -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'Identity' {
                foreach ($group in $Identity) {
                    [PSMicrosoftEntraID.Groups.Group] $aADGroup = Get-PSEntraIDGroup -Identity $group
                    if ([object]::Equals($aADGroup, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $group)
                        }
                    }
                    else {
                        $result = Invoke-PSFProtectedCommand -ActionString 'Group.LicenseDetail.List' -ActionStringValues $group -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestGroupLicenseDetail -InputObject (Invoke-EntraRequest -Service $service -Path ('groups/{0}/licenseDetails' -f $aADGroup.Id) -Query $query -Method Get)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                        $result
                    }
                }
            }
        }
    }

    end {}
}