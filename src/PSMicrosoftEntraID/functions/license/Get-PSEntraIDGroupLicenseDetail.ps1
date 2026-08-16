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

        .PARAMETER EnableException
            This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
            but allows catching exceptions in calling scripts.

        .EXAMPLE
            PS C:\> Get-PSEntraIDGroupLicenseDetail -Identity licensing-group

            Get Office 365 subscriptions with their service plans of specific group
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
    [OutputType('PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter()]
        [switch] $EnableException
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    $groupObject = $itemInputObject
                    if ((-not $itemInputObject.PSObject.Properties['AssignedLicenses'] -or [object]::Equals($itemInputObject.AssignedLicenses, $null)) -and -not [string]::IsNullOrWhiteSpace($itemInputObject.Id)) {
                        $groupObject = Get-PSEntraIDGroup -Identity $itemInputObject.Id -EnableException:$EnableException
                    }

                    if ([object]::Equals($groupObject, $null) -or [object]::Equals($groupObject.AssignedLicenses, $null) -or $groupObject.AssignedLicenses.Count -eq 0) {
                        continue
                    }

                    [string] $groupTarget = if (-not [string]::IsNullOrWhiteSpace($groupObject.DisplayName)) { $groupObject.DisplayName } else { $groupObject.Id }
                    Invoke-PSFProtectedCommand -ActionString 'Group.LicenseDetail.List' -ActionStringValues $groupTarget -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        foreach ($assignedLicense in @($groupObject.AssignedLicenses)) {
                            if ($null -eq $assignedLicense) {
                                continue
                            }
                            ConvertFrom-GroupLicenseDetailSubscriptionSku -LicenseDetail $assignedLicense
                        }
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount 0 -RetryWait ([TimeSpan]::Zero) -WhatIf:$false
                }
            }
            'Identity' {
                foreach ($group in $Identity) {
                    $groupObject = Get-PSEntraIDGroup -Identity $group -EnableException:$EnableException

                    if ([object]::Equals($groupObject, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $group)
                        }
                        continue
                    }

                    if ([object]::Equals($groupObject.AssignedLicenses, $null) -or $groupObject.AssignedLicenses.Count -eq 0) {
                        continue
                    }

                    [string] $groupTarget = if (-not [string]::IsNullOrWhiteSpace($groupObject.DisplayName)) { $groupObject.DisplayName } else { $groupObject.Id }
                    Invoke-PSFProtectedCommand -ActionString 'Group.LicenseDetail.List' -ActionStringValues $groupTarget -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        foreach ($assignedLicense in @($groupObject.AssignedLicenses)) {
                            if ($null -eq $assignedLicense) {
                                continue
                            }
                            ConvertFrom-GroupLicenseDetailSubscriptionSku -LicenseDetail $assignedLicense
                        }
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount 0 -RetryWait ([TimeSpan]::Zero) -WhatIf:$false
                }
            }
        }
    }

    end {}
}