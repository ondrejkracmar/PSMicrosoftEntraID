function Disable-PSEntraIDUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Disable serivce plan of users's sku subscription.

	.DESCRIPTION
		Disable serivce plan of users's sku subscription.

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
        Friendly servcie plan name of subscribedSku.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the disable license action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

	.EXAMPLE
		PS C:\> Disable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Disable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'InputObjectSkuPartNumberPlanName')]
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
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else {
            [boolean] $cmdLetVerbose = $false
        }
    }
    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            '\wSkuId\w' {
                [string] $bodySkuId = $SkuId
                [string] $skuTarget = $SkuId
            }
            '\wSkuPartNumber\w' {
                [string] $bodySkuId = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
                [string] $skuTarget = $SkuPartNumber
            }
            '\wPlanId' {
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    [string] $servicePlanTarget = ($ServicePlanId | Join-String -SingleQuote -Separator ',')
                }
                else {
                    [string] $servicePlanTarget = ($ServicePlanId | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                [string[]] $bodyServicePlanId = $ServicePlanId
            }
            '\wPlanName' {
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    [string] $servicePlanTarget = ($ServicePlanName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    [string] $servicePlanTarget = ($ServicePlanName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                [string[]] $bodyServicePlanId = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuId -EQ -Value $bodySkuId |
                    Select-Object -ExpandProperty ServicePlans |
                    Where-Object { $ServicePlanName -Contains $PSItem.ServicePlanName }).ServicePlanId
            }
        }
        [System.Collections.ArrayList] $bodyDisabledServicePlanList = [System.Collections.ArrayList]::new()
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in  $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'LicenseServicePLan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {
                        [string] $path = ("users/{0}/{1}" -f $InputObject.Id, 'assignLicense')
                        [PSMicrosoftEntraID.Users.LicenseManagement.ServicePlan[]] $userLicenseDetail = $itemInputObject |
                        Get-PSEntraIDUserLicenseDetail |
                        Where-Object -Property SkuId -EQ -Value $bodySkuId |
                        Select-Object -ExpandProperty ServicePlans
                        if (-not([object]::Equals($userLicenseDetail, $null))) {
                            [string[]] $existingDisabledServicePlanList = ($userLicenseDetail |
                                Where-Object -Property ProvisioningStatus -Value 'Disabled' -EQ).ServicePlanId
                            if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                                [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId |
                                Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                                $bodyDisabledServicePlanList = $existingDisabledServicePlanList + $bodyNewDisabledServicePlanList
                            }
                            else {
                                [string[]] $bodyDisabledServicePlanList = @()
                            }
                        }
                        else {
                            [string[]] $bodyDisabledServicePlanList = @()
                        }
                        [hashtable] $body = @{
                            addLicenses    = @(
                                @{
                                    disabledPlans = $bodyDisabledServicePlanList
                                    skuId         = $bodySkuId
                                }
                            )
                            removeLicenses = @()
                        }
                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}'.$path); Body = $body; Headers = $header }
                        }
                        else {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                    }
                } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            'Identity\w' {
                foreach ($user in  $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'LicenseServicePLan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $user -ScriptBlock {
                        [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                        if (-not ([object]::Equals($aADUser, $null))) {
                            [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                            [PSMicrosoftEntraID.Users.LicenseManagement.ServicePlan[]] $userLicenseDetail = $aADUser |
                            Get-PSEntraIDUserLicenseDetail |
                            Where-Object -Property SkuId -EQ -Value $bodySkuId |
                            Select-Object -ExpandProperty ServicePlans
                            if (-not([object]::Equals($userLicenseDetail, $null))) {
                                [string[]] $existingDisabledServicePlanList = ($userLicenseDetail |
                                    Where-Object -Property ProvisioningStatus -Value 'Disabled' -EQ).ServicePlanId
                                if (-not [object]::Equals($existingDisabledServicePlanList, $null)) {
                                    [string[]] $bodyNewDisabledServicePlanList = $bodyServicePlanId |
                                    Where-Object { $PSItem -notin $existingDisabledServicePlanList }
                                    [string[]] $bodyDisabledServicePlanList = $existingDisabledServicePlanList + $bodyNewDisabledServicePlanList
                                }
                                else {
                                    $bodyDisabledServicePlanList = @()
                                }
                            }
                            else {
                                [string[]] $bodyDisabledServicePlanList = @()
                            }
                            [hashtable] $body = @{
                                addLicenses    = @(
                                    @{
                                        disabledPlans = $bodyDisabledServicePlanList
                                        skuId         = $bodySkuId
                                    }
                                )
                                removeLicenses = @()
                            }
                            if ($PassThru.IsPresent) {
                                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}'.$path); Body = $body; Headers = $header }
                            }
                            else {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                            }
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                            }
                        }
                    } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end
    {}
}