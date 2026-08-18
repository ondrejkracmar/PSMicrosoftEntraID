function Disable-PSEntraIDGroupLicenseServicePlan {
    <#
    .SYNOPSIS
        Disable service plans of a license on a group.

    .DESCRIPTION
        Disable one or more service plans within a subscribed SKU license assigned to a Microsoft 365 group.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Groups.Group object in tenant/directory.

    .PARAMETER Identity
        MailNickName or Id of the group.

    .PARAMETER SkuId
        Office 365 product GUID of the subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name of the subscribedSku product.

    .PARAMETER ServicePlanId
        GUID of the service plan to disable.

    .PARAMETER ServicePlanName
        Friendly name of the service plan to disable.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        This is less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch suppresses the confirmation prompt before the Shell modifies the object.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> Disable-PSEntraIDGroupLicenseServicePlan -Identity group1 -SkuPartNumber ENTERPRISEPACK -ServicePlanName EXCHANGE_S_ENTERPRISE

        Disable the EXCHANGE_S_ENTERPRISE service plan of the ENTERPRISEPACK SKU on group group1.
    #>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'InputObjectSkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [ValidateGuid()]
        [string] $SkuId,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string] $SkuPartNumber,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [ValidateGuid()]
        [string[]] $ServicePlanId,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $ServicePlanName,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm

        [PSMicrosoftEntraID.License.SubscriptionSkuLicense[]] $subscribedLicenses = @(Get-PSEntraIDSubscribedLicense)
        # $PSBoundParameters, not $PSCmdlet.ParameterSetName: with pipeline input the
        # set is not resolved until the first object arrives in process, so a switch on
        # it here matches nothing and $bodySkuId stays empty for every piped target.
        # None of these four parameters is pipeline-bound, so this is decidable in begin.
        if ($PSBoundParameters.ContainsKey('SkuId')) {
            [string] $bodySkuId = $SkuId
            [string] $skuTarget = $SkuId
        }
        else {
            [PSMicrosoftEntraID.License.SubscriptionSkuLicense] $matchedSku = @($subscribedLicenses | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber })[0]
            [string] $bodySkuId = $matchedSku.SkuId
            [string] $skuTarget = $SkuPartNumber
        }

        [PSMicrosoftEntraID.License.SubscriptionSkuLicense] $targetSubscribedLicense = @($subscribedLicenses | Where-Object { $_.SkuId -eq $bodySkuId })[0]
        if ($PSBoundParameters.ContainsKey('ServicePlanId')) {
            [string] $servicePlanTarget = ($ServicePlanId | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            [string[]] $bodyServicePlanId = $ServicePlanId
        }
        else {
            [string] $servicePlanTarget = ($ServicePlanName | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            [string[]] $bodyServicePlanId = @($targetSubscribedLicense.ServicePlans | Where-Object { $ServicePlanName -contains $PSItem.ServicePlanName } | ForEach-Object { $_.ServicePlanId })
        }
    }

    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in $InputObject) {
                    $groupObject = $itemInputObject
                    if ((-not $itemInputObject.PSObject.Properties['AssignedLicenses'] -or [object]::Equals($itemInputObject.AssignedLicenses, $null)) -and -not [string]::IsNullOrWhiteSpace($itemInputObject.Id)) {
                        $groupObject = Get-PSEntraIDGroup -Identity $itemInputObject.Id -EnableException:$EnableException
                    }
                    if ([object]::Equals($groupObject, $null)) {
                        Write-PSFMessage -Level Warning -String 'License.Target.NotFound' -StringValues $itemInputObject.Id
                        continue
                    }
                    $assignedLicense = @($groupObject.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId }) | Select-Object -First 1
                    if ([object]::Equals($assignedLicense, $null)) {
                        # Not an error: the SKU simply is not on this target. Say so, though -
                        # silence here reads as success and it is not.
                        Write-PSFMessage -Level Warning -String 'License.Sku.NotAssigned' -StringValues $skuTarget, $(if ($groupObject.DisplayName) { $groupObject.DisplayName } else { $groupObject.Id })
                        continue
                    }
                    [System.Collections.ArrayList] $bodyDisabledServicePlanList = [System.Collections.ArrayList]::new()
                    [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                    if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                        [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId | Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                        $existingDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                        $bodyNewDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                    }
                    else {
                        $bodyServicePlanId | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                    }
                    if ($bodyDisabledServicePlanList.Count -gt 0) {
                        [hashtable] $body = @{ addLicenses = @(@{ disabledPlans = @($bodyDisabledServicePlanList | Select-Object -Unique); skuId = $bodySkuId }); removeLicenses = @() }
                        [string] $path = ('groups/{0}/{1}' -f $groupObject.Id, 'assignLicense')
                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                        else {
                            $groupTarget = if (-not [string]::IsNullOrWhiteSpace($groupObject.DisplayName)) { $groupObject.DisplayName } else { $groupObject.Id }
                            Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $groupTarget -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
            'Identity\w' {
                foreach ($group in $Identity) {
                    [PSMicrosoftEntraID.Groups.Group] $aADGroup = Get-PSEntraIDGroup -Identity $group
                    if ([object]::Equals($aADGroup, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $group)
                        }
                    }
                    else {
                        $assignedLicense = @($aADGroup.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId }) | Select-Object -First 1
                        if ([object]::Equals($assignedLicense, $null)) {
                            # Not an error: the SKU simply is not on this target. Say so, though -
                            # silence here reads as success and it is not.
                            Write-PSFMessage -Level Warning -String 'License.Sku.NotAssigned' -StringValues $skuTarget, $group
                            continue
                        }
                        [System.Collections.ArrayList] $bodyDisabledServicePlanList = [System.Collections.ArrayList]::new()
                        [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                        if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                            [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId | Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                            $existingDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                            $bodyNewDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                        }
                        else {
                            $bodyServicePlanId | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                        }
                        if ($bodyDisabledServicePlanList.Count -gt 0) {
                            [hashtable] $body = @{ addLicenses = @(@{ disabledPlans = @($bodyDisabledServicePlanList | Select-Object -Unique); skuId = $bodySkuId }); removeLicenses = @() }
                            [string] $path = ('groups/{0}/{1}' -f $aADGroup.Id, 'assignLicense')
                            if ($PassThru.IsPresent) {
                                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                            }
                            else {
                                Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $group -ScriptBlock {
                                    [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                        }
                    }
                }
            }
        }
    }
}
