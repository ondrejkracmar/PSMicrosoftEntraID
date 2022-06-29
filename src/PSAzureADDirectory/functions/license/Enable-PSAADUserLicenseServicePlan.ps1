function Enable-PSAADUserLicenseServicePlan {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'UPNSkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                If ($_ -match '@') {
                    $True
                }
                else {
                    $false
                }
            })]
        [string]
        $UserPrincipalName,    
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } 
                catch {
                    $false
                }
            })]
        [string]
        $UserId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } 
                catch {
                    $false
                }
            })]
        [string]
        $SkuId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SkuPartNumber,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanId')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServicePlanId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UPNSkuPartNumberPlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuIdServicePlanName')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdSkuPartNumberPlanName')]
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
                
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'UPN\w' {
                $userLicenseDetail = Get-PSAADUserLicenseServicePlan -UserPrincipalName $UserPrinciplaName
                $path = ("{0}/{1}" -f $UserPrinciplaName, 'assignLicense')
            }
            'UserId\w' {
                $userLicenseDetail = Get-PSAADUserLicenseServicePlan -UserPrincipalName $UserId
                $path = ("{0}/{1}" -f $UserId, 'assignLicense')
            }
            '\wSkuId\w' {
                $bodySkuId = $SkuId
            }
            '\wSkuPartNumber\w' {
                $bodySkuId = (Get-PSFResultCache | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
            }
            'w\PlanId' {
                [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuPartNumber -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanId -notin $ServicePlanId }).ServicePlanId
            }
            'w\PlanName' {
                [string[]]$bodyDisabledServicePlans = (($userLicenseDetail.AssignedLicenses | Where-Object -Property SkuPartNumber -EQ -Value $bodySkuId).DisabledServicePlans | Where-Object { $_.ServicePlanName -notin $ServicePlanName }).ServicePlanId
            }
        }

        $body = @{
                            
            addLicenses      = @(
                @{
                    'disabledPlans' = $bodyServicePlanList
                    "skuId"         = $bodySkuId
                }
            )
            "removeLicenses" = @()
        }
        
        Invoke-PSFProtectedCommand -ActionString 'New-MdcaSubnet.Create' -ActionStringValues $Name -Target $Name -ScriptBlock {
            #Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post
            $body
        } -EnableException $EnableException -PSCmdlet $PSCmdlet

        
        
    }
    end
    {}
}
