function Get-PSEntraIDGroupLicense {
    <#
        .SYNOPSIS
            Get assigned licenses of a group with service plan status details.

        .DESCRIPTION
            Get assigned licenses of a group with resolved SKU names and service plan status details.

        .PARAMETER InputObject
            PSMicrosoftEntraID.Groups.Group object in tenant/directory.

        .PARAMETER Identity
            MailNickname, Mail or Id of the group attribute populated in tenant/directory.

        .PARAMETER EnableException
            This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
            but allows catching exceptions in calling scripts.

        .EXAMPLE
            PS C:\> Get-PSEntraIDGroupLicense -Identity licensing-group

            Get assigned group licenses with enabled and disabled service plans.
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
    [OutputType('PSMicrosoftEntraID.Groups.AssignedLicenseDetail')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))

        [object[]] $subscribedLicenses = @(Get-PSEntraIDSubscribedLicense -EnableException:$EnableException)
        [object[]] $licenseIdentifiers = @(Get-PSEntraIDLicenseIdentifier -EnableException:$EnableException)

        [hashtable] $subscribedSkuById = @{}
        foreach ($subscribedLicense in $subscribedLicenses) {
            [string] $subscribedSkuId = $subscribedLicense.SkuId
            if (-not [string]::IsNullOrWhiteSpace($subscribedSkuId)) {
                $subscribedSkuById[$subscribedSkuId.ToLowerInvariant()] = $subscribedLicense
            }
        }

        [hashtable] $licenseIdentifiersBySkuId = @{}
        foreach ($licenseIdentifier in $licenseIdentifiers) {
            [string] $identifierSkuId = $licenseIdentifier.SkuId
            if (-not [string]::IsNullOrWhiteSpace($identifierSkuId)) {
                $licenseIdentifiersBySkuId[$identifierSkuId.ToLowerInvariant()] = $licenseIdentifier
            }
        }

        function ConvertTo-GroupAssignedLicenseDetail {
            param (
                [Parameter(Mandatory = $true)]
                $GroupObject
            )

            if ([object]::Equals($GroupObject.AssignedLicenses, $null) -or $GroupObject.AssignedLicenses.Count -eq 0) {
                return
            }

            foreach ($assignedLicense in @($GroupObject.AssignedLicenses)) {
                if ([object]::Equals($assignedLicense, $null)) {
                    continue
                }

                [string] $skuId = $assignedLicense.SkuId
                [string] $skuKey = $null
                if (-not [string]::IsNullOrWhiteSpace($skuId)) {
                    $skuKey = $skuId.ToLowerInvariant()
                }

                $subscribedLicense = $null
                if ($skuKey -and $subscribedSkuById.ContainsKey($skuKey)) {
                    $subscribedLicense = $subscribedSkuById[$skuKey]
                }

                $licenseIdentifier = $null
                if ($skuKey -and $licenseIdentifiersBySkuId.ContainsKey($skuKey)) {
                    $licenseIdentifier = $licenseIdentifiersBySkuId[$skuKey]
                }

                [hashtable] $servicePlanIdentifierById = @{}
                if ($licenseIdentifier -and -not [object]::Equals($licenseIdentifier.ServicePlans, $null)) {
                    foreach ($servicePlanIdentifier in @($licenseIdentifier.ServicePlans)) {
                        [string] $servicePlanIdentifierId = $servicePlanIdentifier.ServicePlanId
                        if (-not [string]::IsNullOrWhiteSpace($servicePlanIdentifierId)) {
                            $servicePlanIdentifierById[$servicePlanIdentifierId.ToLowerInvariant()] = $servicePlanIdentifier
                        }
                    }
                }

                [string[]] $disabledPlanIds = @()
                [hashtable] $disabledPlanLookup = @{}
                if (-not [object]::Equals($assignedLicense.DisabledPlans, $null)) {
                    foreach ($disabledPlanId in @($assignedLicense.DisabledPlans)) {
                        [string] $disabledPlanIdString = [string] $disabledPlanId
                        if (-not [string]::IsNullOrWhiteSpace($disabledPlanIdString)) {
                            $disabledPlanIds += $disabledPlanIdString
                            $disabledPlanLookup[$disabledPlanIdString.ToLowerInvariant()] = $true
                        }
                    }
                }

                [System.Collections.Generic.List[object]] $servicePlanDetails = [System.Collections.Generic.List[object]]::new()
                [hashtable] $servicePlanSeen = @{}
                [object[]] $servicePlanSources = @()

                if ($subscribedLicense -and -not [object]::Equals($subscribedLicense.ServicePlans, $null)) {
                    $servicePlanSources = @($subscribedLicense.ServicePlans)
                }
                elseif ($licenseIdentifier -and -not [object]::Equals($licenseIdentifier.ServicePlans, $null)) {
                    $servicePlanSources = @($licenseIdentifier.ServicePlans)
                }

                foreach ($servicePlan in $servicePlanSources) {
                    [string] $servicePlanId = [string] $servicePlan.ServicePlanId
                    [string] $servicePlanKey = $null
                    if (-not [string]::IsNullOrWhiteSpace($servicePlanId)) {
                        $servicePlanKey = $servicePlanId.ToLowerInvariant()
                        $servicePlanSeen[$servicePlanKey] = $true
                    }

                    $servicePlanIdentifier = $null
                    if ($servicePlanKey -and $servicePlanIdentifierById.ContainsKey($servicePlanKey)) {
                        $servicePlanIdentifier = $servicePlanIdentifierById[$servicePlanKey]
                    }

                    [bool] $isDisabled = $false
                    if ($servicePlanKey -and $disabledPlanLookup.ContainsKey($servicePlanKey)) {
                        $isDisabled = $true
                    }

                    $provisioningStatus = $null
                    if ($servicePlan.PSObject.Properties['ProvisioningStatus']) {
                        $provisioningStatus = $servicePlan.PSObject.Properties['ProvisioningStatus'].Value
                    }

                    $appliesTo = $null
                    if ($servicePlan.PSObject.Properties['AppliesTo']) {
                        $appliesTo = $servicePlan.PSObject.Properties['AppliesTo'].Value
                    }

                    [string] $servicePlanFriendlyName = $null
                    if ($servicePlanIdentifier) {
                        $servicePlanFriendlyName = $servicePlanIdentifier.ServicePlanFriendlyName
                    }

                    [string] $servicePlanStatus = 'Enabled'
                    if ($isDisabled) {
                        $servicePlanStatus = 'Disabled'
                    }

                        $servicePlanDetail = [PSCustomObject]@{
                            ServicePlanId = $servicePlanId
                            ServicePlanName = $servicePlan.ServicePlanName
                            ServicePlanFriendlyName = $servicePlanFriendlyName
                            AppliesTo = $appliesTo
                            ProvisioningStatus = $provisioningStatus
                            Status = $servicePlanStatus
                            IsDisabled = $isDisabled
                        }
                        $servicePlanDetail.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Groups.AssignedLicenseServicePlanDetail')
                        [void]$servicePlanDetails.Add($servicePlanDetail)
                }

                foreach ($disabledPlanId in $disabledPlanIds) {
                    [string] $disabledPlanKey = $disabledPlanId.ToLowerInvariant()
                    if ($servicePlanSeen.ContainsKey($disabledPlanKey)) {
                        continue
                    }

                    $servicePlanIdentifier = $null
                    if ($servicePlanIdentifierById.ContainsKey($disabledPlanKey)) {
                        $servicePlanIdentifier = $servicePlanIdentifierById[$disabledPlanKey]
                    }

                    [string] $disabledServicePlanName = $null
                    if ($servicePlanIdentifier) {
                        $disabledServicePlanName = $servicePlanIdentifier.ServicePlanName
                    }

                    [string] $disabledServicePlanFriendlyName = $null
                    if ($servicePlanIdentifier) {
                        $disabledServicePlanFriendlyName = $servicePlanIdentifier.ServicePlanFriendlyName
                    }

                    $servicePlanDetail = [PSCustomObject]@{
                        ServicePlanId = $disabledPlanId
                        ServicePlanName = $disabledServicePlanName
                        ServicePlanFriendlyName = $disabledServicePlanFriendlyName
                        AppliesTo = $null
                        ProvisioningStatus = $null
                        Status = 'Disabled'
                        IsDisabled = $true
                    }
                    $servicePlanDetail.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Groups.AssignedLicenseServicePlanDetail')
                    [void]$servicePlanDetails.Add($servicePlanDetail)
                }

                [object[]] $servicePlanDetailArray = @($servicePlanDetails)

                [string] $skuPartNumber = $null
                if ($subscribedLicense) {
                    $skuPartNumber = $subscribedLicense.SkuPartNumber
                }
                elseif ($licenseIdentifier) {
                    $skuPartNumber = $licenseIdentifier.SkuPartNumber
                }

                [string] $skuFriendlyName = $null
                if ($licenseIdentifier) {
                    $skuFriendlyName = $licenseIdentifier.SkuFriendlyName
                }

                $licenseDetail = [PSCustomObject]@{
                    GroupId = $GroupObject.Id
                    GroupDisplayName = $GroupObject.DisplayName
                    GroupMail = $GroupObject.Mail
                    GroupMailNickname = $GroupObject.MailNickname
                    SkuId = $skuId
                    SkuPartNumber = $skuPartNumber
                    SkuFriendlyName = $skuFriendlyName
                    DisabledPlanIds = $disabledPlanIds
                    DisabledPlanCount = @($servicePlanDetailArray | Where-Object -Property IsDisabled -EQ -Value $true).Count
                    EnabledPlanCount = @($servicePlanDetailArray | Where-Object -Property IsDisabled -EQ -Value $false).Count
                    TotalPlanCount = $servicePlanDetailArray.Count
                    ServicePlans = $servicePlanDetailArray
                }
                $licenseDetail.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Groups.AssignedLicenseDetail')
                $licenseDetail
            }
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    $groupObject = $itemInputObject
                    if ((-not $itemInputObject.PSObject.Properties['AssignedLicenses'] -or [object]::Equals($itemInputObject.AssignedLicenses, $null)) -and -not [string]::IsNullOrWhiteSpace($itemInputObject.Id)) {
                        $groupObject = Get-PSEntraIDGroup -Identity $itemInputObject.Id -EnableException:$EnableException
                    }

                    if ([object]::Equals($groupObject, $null)) {
                        continue
                    }

                    [string] $groupTarget = if (-not [string]::IsNullOrWhiteSpace($groupObject.DisplayName)) { $groupObject.DisplayName } else { $groupObject.Id }
                    $result = Invoke-PSFProtectedCommand -ActionString 'Group.License.List' -ActionStringValues $groupTarget -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertTo-GroupAssignedLicenseDetail -GroupObject $groupObject
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
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

                    [string] $groupTarget = if (-not [string]::IsNullOrWhiteSpace($groupObject.DisplayName)) { $groupObject.DisplayName } else { $groupObject.Id }
                    $result = Invoke-PSFProtectedCommand -ActionString 'Group.License.List' -ActionStringValues $groupTarget -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertTo-GroupAssignedLicenseDetail -GroupObject $groupObject
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
        }
    }

    end {}
}