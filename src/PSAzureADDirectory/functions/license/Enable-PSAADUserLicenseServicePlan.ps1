function Enable-PSAADUserLicenseServicePlan {
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
                    [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanId -notin $ServicePlanId }).ServicePlanId
                    if ([object]::Equals($bodyDisabledServicePlans, $null)) {
                        [string[]]$bodyDisabledServicePlans = ((Get-PSFResultCache | Where-Object -Property SkuId -EQ -Value $bodySkuId).ServicePlans | Where-Object { $_.ServicePlanId -notin $ServicePlanId }).ServicePlanId
                    }
                }
                '\wPlanName' {
                    [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuId -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanName -notin $ServicePlanName }).ServicePlanId
                    if ([object]::Equals($bodyDisabledServicePlans, $null)) {
                        [string[]]$bodyDisabledServicePlans = ((Get-PSFResultCache | Where-Object -Property SkuId -EQ -Value $bodySkuId).ServicePlans | Where-Object { $_.ServicePlanName -notin $ServicePlanName }).ServicePlanId
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
            
            Invoke-PSFProtectedCommand -ActionString 'LicenseServicePLan.Enable' -ActionStringValues $Identity -Target $Identity -ScriptBlock {
                $enableicenseServicePlan = Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post
            } -EnableException $EnableException -PSCmdlet $PSCmdlet
            $enableicenseServicePlan | ConvertFrom-RestUser
        }
    }
    end
    {}
}