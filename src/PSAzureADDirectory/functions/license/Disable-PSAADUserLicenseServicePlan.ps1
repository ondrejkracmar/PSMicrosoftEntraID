function Disable-PSAADUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Disable serivce plan of users's sku subscription
	
	.DESCRIPTION
		Disable serivce plan of users's sku subscription
	
	.PARAMETER Identity
        UserPrincipalName or Id of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.
    
    .PARAMETER ServicePlanId
		Service plan Id of subscribedSku.

    .PARAMETER ServicePlanName
        Friendly servcie plan name of subscribedSku.

	.EXAMPLE
		PS C:\> Disable-PSAADUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Disable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com
        
	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentitySkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateIdentity()]
        [string[]]
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
    }
    process {
        foreach ($user in  $Identity) {
            switch -Regex ($PSCmdlet.ParameterSetName) {
                'Identity\w' {
                    $userLicenseDetail = Get-PSAADUserLicenseServicePlan -Identity $user
                    $path = ("users/{0}/{1}" -f $user, 'assignLicense')
                }
                '\wSkuId\w' {
                    $bodySkuId = $SkuId
                }
                '\wSkuPartNumber\w' {
                    $bodySkuId = (Get-PSFResultCache | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
                }
                '\wPlanId' {
                    [string[]]$enabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).EnabledServicePlans | Where-Object { $_.ServicePlanId -in $ServicePlanId }).ServicePlanId
                    [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanId -notin $ServicePlanId }).ServicePlanId
                    if (-not [object]::Equals($enabledServicePlans, $null)) {
                        $bodyDisabledServicePlans += $enabledServicePlans
                    }
                }
                '\wPlanName' {
                    [string[]]$enabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).EnabledServicePlans | Where-Object { $_.ServicePlanName -in $ServicePlanName }).ServicePlanId
                    [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanName -notin $ServicePlanName }).ServicePlanId
                    if (-not [object]::Equals($enabledServicePlans, $null)) {
                        $bodyDisabledServicePlans += $enabledServicePlans
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
            
            Invoke-PSFProtectedCommand -ActionString 'LicenseServicePLan.Disable' -ActionStringValues $Identity -Target $Identity -ScriptBlock {
                $disableLicenseServicePlan = Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post
            } -EnableException $EnableException -PSCmdlet $PSCmdlet
            $disableLicenseServicePlan | ConvertFrom-RestUser
        }
    }
    end
    {}
}