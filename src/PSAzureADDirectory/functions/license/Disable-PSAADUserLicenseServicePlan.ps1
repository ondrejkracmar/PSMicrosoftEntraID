function Disable-PSAADUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Disable serivce plan of users's sku subscription

	.DESCRIPTION
		Disable serivce plan of users's sku subscription

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

	.EXAMPLE
		PS C:\> Disable-PSAADUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Disable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentitySkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateIdentity()]
        [string[]]
        [Alias("Id","UserPrincipalName","Mail")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [ValidateGuid()]
        [string]
        $SkuId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SkuPartNumber,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [ValidateGuid()]
        [string[]]
        $ServicePlanId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServicePlanName,
        [switch]
        $EnableException
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        Get-PSAADSubscribedSku | Set-PSFResultCache
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }
    process {
        foreach ($user in  $Identity) {
            $aADUser = Get-PSAADUserLicenseServicePlan -Identity $user
            if (-not ([object]::Equals($aADUser, $null))) {
                $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                switch -Regex ($PSCmdlet.ParameterSetName) {
                    '\wSkuId\w' {
                        $bodySkuId = $SkuId
                        $skuTarget = $SkuId
                    }
                    '\wSkuPartNumber\w' {
                        $bodySkuId = (Get-PSFResultCache | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
                        $skuTarget = $SkuPartNumber
                    }
                    '\wPlanId' {
                        [string[]]$enabledServicePlans = (($aADUser.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).EnabledServicePlans | Where-Object { $_.ServicePlanId -in $ServicePlanId }).ServicePlanId
                        [string[]]$bodyDisabledServicePlans = (($aADUser.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanId -notin $ServicePlanId }).ServicePlanId
                        if (-not [object]::Equals($enabledServicePlans, $null)) {
                            $bodyDisabledServicePlans += $enabledServicePlans
                        }
                        if (Test-PSFPowerShell -PSMinVersion 7.0) {
                            $servicePlanTarget = ($ServicePlanId | Join-String -SingleQuote -Separator ',')
                        }
                        else {
                            $servicePlanTarget = ($ServicePlanId | ForEach-Object { "'{0}'" -f $_ }) -join ','
                        }
                    }
                    '\wPlanName' {
                        [string[]]$enabledServicePlans = (($aADUser.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).EnabledServicePlans | Where-Object { $_.ServicePlanName -in $ServicePlanName }).ServicePlanId
                        [string[]]$bodyDisabledServicePlans = (($aADUser.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanName -notin $ServicePlanName }).ServicePlanId
                        if (-not [object]::Equals($enabledServicePlans, $null)) {
                            $bodyDisabledServicePlans += $enabledServicePlans
                        }
                        if (Test-PSFPowerShell -PSMinVersion 7.0) {
                            $servicePlanTarget = ($ServicePlanName | Join-String -SingleQuote -Separator ',')
                        }
                        else {
                            $servicePlanTarget = ($ServicePlanName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                        }
                    }
                }

                $body = @{

                    addLicenses    = @(
                        @{
                            disabledPlans = $bodyDisabledServicePlans
                            skuId         = $bodySkuId
                        }
                    )
                    removeLicenses = @()
                }
                Invoke-PSFProtectedCommand -ActionString 'LicenseServicePLan.Disable' -ActionStringValues $servicePlanTarget, $skuTarget -Target $aADUser.UserPrincipalName -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {}
        }
    }
    end
    {}
}