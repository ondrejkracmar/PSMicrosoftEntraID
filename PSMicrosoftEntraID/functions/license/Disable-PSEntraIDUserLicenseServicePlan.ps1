function Disable-PSEntraIDUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Disable service plan of users's sku subscription.

	.DESCRIPTION
		Disable service plan of users's sku subscription.

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
		PS C:\> Disable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Disable service plan Office Pro Plus, Exchange Online of subscription ENTERPRISEPACK for user username@contoso.com

	.NOTES
		Graph's assignLicense REPLACES the disabledPlans list on every call - there is no
		server-side merge and no ETag. This cmdlet therefore reads the user's current
		disabled plans and merges the request into them. With -Identity that read happens
		inside the call, and a read seconds after a previous write can hit a directory
		replica the write has not reached yet - in which case the merge starts from stale
		state and the earlier change is lost. Two deterministic patterns avoid it:
		name every plan in ONE call (see the example above), or pass -InputObject with a
		user object you hold, whose AssignedLicenses reflect the state you mean to merge
		into. Verified against a live tenant: back-to-back -Identity calls occasionally
		lose the first change; either pattern above never does.

	#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'InputObjectSkuPartNumberPlanName')]
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
        # Branched on $PSBoundParameters, NOT on $PSCmdlet.ParameterSetName.
        #
        # With pipeline input the parameter set is not resolved until the first object
        # arrives in process - InputObject and Identity both bind from the pipeline, so
        # in begin the ambiguity is still open and ParameterSetName names neither. The
        # switch that used to live here matched nothing, $bodySkuId stayed empty, every
        # piped user failed the SKU match, and the cmdlet reported 'not assigned' for a
        # licence the user held. Piped input never worked, and the test that covered it
        # only counted an intermediate call, so nothing noticed.
        #
        # SkuId/SkuPartNumber/ServicePlanId/ServicePlanName are never pipeline-bound, so
        # $PSBoundParameters answers in begin what ParameterSetName cannot.
        if ($PSBoundParameters.ContainsKey('SkuId')) {
            [string] $bodySkuId = $SkuId
            [string] $skuTarget = $SkuId
        }
        else {
            # Materialised, NOT piped into Select-Object -First 1: that stops the
            # pipeline, the protected read inside reports a failed action, and
            # $matchedSku comes back empty. The same hazard is documented in this
            # module's own help.
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
                    [System.Collections.Generic.List[object]] $bodyDisabledServicePlanList = [System.Collections.Generic.List[object]]::new()

                    # Existing disabled plans come from assignedLicenses.disabledPlans -
                    # the field this very cmdlet writes - NOT from licenseDetails'
                    # provisioningStatus. The two answer different questions:
                    # disabledPlans is the assignment and is visible the moment it is
                    # written; provisioningStatus is what has been PROVISIONED and trails
                    # the write by seconds to minutes. Reading the laggy one meant a plan
                    # disabled a moment ago was not seen as disabled, so the next call
                    # rebuilt the list without it and silently RE-ENABLED it - verified
                    # against a live tenant, where two disables in a row kept only the
                    # second. The group cmdlets have always read disabledPlans, which is
                    # why they never had this defect.
                    $assignedLicense = @($itemInputObject.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId })[0]
                    if (-not ([object]::Equals($assignedLicense, $null))) {
                        [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                        [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId |
                        Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                        $existingDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                        $bodyNewDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                    }
                    else {
                        # Not an error: the SKU simply is not on this user. Say so, though -
                        # silence here reads as success and it is not.
                        Write-PSFMessage -Level Warning -String 'License.Sku.NotAssigned' -StringValues $skuTarget, $(if ($itemInputObject.UserPrincipalName) { $itemInputObject.UserPrincipalName } else { $itemInputObject.Id })
                    }

                    [hashtable] $body = @{
                        addLicenses    = @(
                            @{
                                disabledPlans = @($bodyDisabledServicePlanList | Select-Object -Unique)
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }
                    [string] $path = ("users/{0}/{1}" -f $itemInputObject.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        if ($bodyDisabledServicePlanList.Count -gt 0) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                    }
                    else {
                        if ($bodyDisabledServicePlanList.Count -gt 0) {
                            Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
            'Identity\w' {
                foreach ($user in  $Identity) {
                    [System.Collections.Generic.List[object]] $bodyDisabledServicePlanList = [System.Collections.Generic.List[object]]::new()
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                    else {
                    # assignedLicenses.disabledPlans, not provisioningStatus - see the
                    # InputObject branch for why. $aADUser was just read, so the field is
                    # as fresh as Graph will give.
                    $assignedLicense = @($aADUser.AssignedLicenses | Where-Object { ([string]$PSItem.SkuId) -eq $bodySkuId })[0]
                    if (-not ([object]::Equals($assignedLicense, $null))) {
                        [string[]] $existingDisabledServicePlanList = @($assignedLicense.DisabledPlans | ForEach-Object { [string]$_ })
                        [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId |
                        Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                        $existingDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                        $bodyNewDisabledServicePlanList | ForEach-Object { [void] $bodyDisabledServicePlanList.Add($PSItem) }
                    }
                    else {
                        Write-PSFMessage -Level Warning -String 'License.Sku.NotAssigned' -StringValues $skuTarget, $user
                    }

                    [hashtable] $body = @{
                        addLicenses    = @(
                            @{
                                disabledPlans = @($bodyDisabledServicePlanList | Select-Object -Unique)
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }

                    [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        if ($bodyDisabledServicePlanList.Count -gt 0) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                    }
                    else {
                        if (($bodyDisabledServicePlanList.Count -gt 0)) {
                            Invoke-PSFProtectedCommand -ActionString 'LicenseServicePlan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $user -ScriptBlock {
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
    end
    {}
}
