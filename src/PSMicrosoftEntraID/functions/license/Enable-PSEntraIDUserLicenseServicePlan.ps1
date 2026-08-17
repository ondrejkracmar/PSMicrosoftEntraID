function Enable-PSEntraIDUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Enable service plan of user's sku subscription.

	.DESCRIPTION
		Enable service plan of user's sku subscription.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

    .PARAMETER ServicePlanId
		Service plan Id of subscribedSku.

    .PARAMETER ServicePlanName
        Friendly service plan name of subscribedSku.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

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
		PS C:\> Enable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Enable service plan Office Pro Plus, Exchange Online of subscription ENTERPRISEPACK for user username@contoso.com

	.NOTES
		Graph's assignLicense REPLACES the disabledPlans list on every call - there is no
		server-side merge and no ETag. This cmdlet reads the user's current disabled
		plans and removes the requested ones from that list. With -Identity that read
		happens inside the call, and a read seconds after a previous write can hit a
		directory replica the write has not reached yet - in which case the merge starts
		from stale state and the earlier change is lost. Name every plan in one call, or
		pass -InputObject with a user object whose AssignedLicenses reflect the state you
		mean to merge into; either pattern is deterministic.

	#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'InputObjectSkuPartNumberPlanName')]
    param ([Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [ValidateGuid()]
        [string] $SkuId,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string] $SkuPartNumber,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [ValidateGuid()]
        [string[]] $ServicePlanId,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuPartNumberPlanName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $ServicePlanName,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch]$PassThru
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        # Branched on $PSBoundParameters, NOT on $PSCmdlet.ParameterSetName. With
        # pipeline input the set is not resolved until the first object arrives in
        # process, so the switch that lived here matched nothing and $bodySkuId stayed
        # empty for every piped user - see Disable-PSEntraIDUserLicenseServicePlan for
        # the full account. These four parameters are never pipeline-bound, so
        # $PSBoundParameters answers in begin what ParameterSetName cannot.
        if ($PSBoundParameters.ContainsKey('SkuId')) {
            [string] $bodySkuId = $SkuId
            [string] $skuTarget = $SkuId
        }
        else {
            # Materialised, NOT piped into Select-Object -First 1: that stops the
            # pipeline and the protected read reports a failure, leaving $matchedSku
            # empty and every lookup that depends on $bodySkuId finding nothing.
            [PSMicrosoftEntraID.License.SubscriptionSku[]] $subscribedSkus = @(Get-PSEntraIDSubscribedSku)
            [PSMicrosoftEntraID.License.SubscriptionSku] $matchedSku = @($subscribedSkus | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber })[0]
            [string] $bodySkuId = $matchedSku.SkuId
            [string] $skuTarget = $SkuPartNumber
        }
        if ($PSBoundParameters.ContainsKey('ServicePlanId')) {
            [string] $servicePlanTarget = ($ServicePlanId | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            [string[]] $bodyServicePlanId = $ServicePlanId
        }
        else {
            [string] $servicePlanTarget = ($ServicePlanName | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            [string[]] $bodyServicePlanId = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuId -EQ -Value $bodySkuId |
                Select-Object -ExpandProperty ServicePlans |
                Where-Object { $ServicePlanName -Contains $PSItem.ServicePlanName }).ServicePlanId
        }
    }
    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in  $InputObject) {
                    # Reset PER ITERATION. The old shape only replaced this when the
                    # current user had a value and only defaulted it when it was null -
                    # so on pipeline input, a user with nothing to disable inherited the
                    # PREVIOUS user's disabled plans and had them re-applied.
                    [string[]] $bodyDisabledServicePlanList = @()

                    # Both facts - "does the user hold the SKU" and "what is disabled" -
                    # come from assignedLicenses, which this cmdlet's own write sets and
                    # which is visible immediately. They used to come from licenseDetails,
                    # whose provisioningStatus trails the assignment by seconds to
                    # minutes. That lag cut both ways here: a plan disabled a moment ago
                    # read as enabled and got silently re-enabled, and a SKU assigned a
                    # moment ago read as ABSENT - which sent this cmdlet down the
                    # fresh-assignment branch below and disabled every plan except the
                    # ones asked for. Verified against a live tenant.
                    $assignedLicense = @($itemInputObject.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId })[0]
                    if (-not ([object]::Equals($assignedLicense, $null))) {
                        [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                    }
                    else {
                        # The user does not hold the SKU: enabling a plan implies
                        # assigning the licence with everything ELSE disabled, so the
                        # starting list is every plan the subscription has.
                        [string[]] $existingDisabledServicePlanList = (Get-PSEntraIDSubscribedLicense |
                            Where-Object -Property SkuId -Value $bodySkuId -EQ |
                            Select-Object -ExpandProperty ServicePlans).ServicePlanId
                    }
                    if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                        # @() around the PIPELINE, not around the variable later. A pipe
                        # that yields nothing makes a typed assignment $null, and
                        # @($null) is a one-element array whose element is null - which
                        # serialized as "disabledPlans":[null] and Graph has no idea what
                        # plan null is. Wrapped here, an empty result is an empty array.
                        [string[]] $bodyDisabledServicePlanList = @($existingDisabledServicePlanList |
                            Where-Object { $PSItem -notin $bodyServicePlanId })
                    }

                    [hashtable] $body = @{
                        addLicenses    = @(
                            @{
                                # @(), the same as Disable-PSEntraIDUserLicenseServicePlan
                                # after the single-plan fix. The bare variable happened to
                                # survive because of its [string[]] constraint, which is a
                                # line-of-sight away and one refactor from breaking; Graph
                                # rejects a scalar here with "a StartArray node was
                                # expected".
                                disabledPlans = @($bodyDisabledServicePlanList)
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }
                    [string] $path = ("users/{0}/{1}" -f $itemInputObject.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Enable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {

                            [void](Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'Identity\w' {
                foreach ($user in  $Identity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                    else {
                    # Reset PER ITERATION - same reasoning as the InputObject branch: a
                    # user with nothing to disable must not inherit the previous user's
                    # list off this loop variable.
                    [string[]] $bodyDisabledServicePlanList = @()

                    # assignedLicenses, not provisioningStatus - see the InputObject
                    # branch for why. $aADUser was just read, so the field is as fresh
                    # as Graph will give.
                    $assignedLicense = @($aADUser.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId })[0]
                    if (-not ([object]::Equals($assignedLicense, $null))) {
                        [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                    }
                    else {
                        [string[]] $existingDisabledServicePlanList = (Get-PSEntraIDSubscribedLicense |
                            Where-Object -Property SkuId -Value $bodySkuId -EQ |
                            Select-Object -ExpandProperty ServicePlans).ServicePlanId
                    }
                    if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                        # @() around the PIPELINE, not around the variable later. A pipe
                        # that yields nothing makes a typed assignment $null, and
                        # @($null) is a one-element array whose element is null - which
                        # serialized as "disabledPlans":[null] and Graph has no idea what
                        # plan null is. Wrapped here, an empty result is an empty array.
                        [string[]] $bodyDisabledServicePlanList = @($existingDisabledServicePlanList |
                            Where-Object { $PSItem -notin $bodyServicePlanId })
                    }

                    [hashtable] $body = @{
                        addLicenses    = @(
                            @{
                                # @() for the same reason as the InputObject branch.
                                disabledPlans = @($bodyDisabledServicePlanList)
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }
                    [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Enable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $user -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                    }
                }
            }
        }
    }
    end
    {}
}
