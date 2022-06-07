function Enable-PSAADUserLicenseServicePlan {
    [CmdletBinding(DefaultParameterSetName = 'UPNSkuPartNumberPlanName',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
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
        
        Get-PSAADSubscribedSku | Set-PSFResultCache -DisableCache $true
    }
    process {        
        $userServicePlanList = Get-PSAADLicenseServicePlan -UserId $UserId -SkuId $SkuId | Select-Object -ExpandProperty ServicePlans | Where-Object { $_.provisioningStatus -in @('PendingProvisioning', 'Disabled') }
        if (-not [object]::equals($userServicePlanList, $null)) {
            [array]$disabledServicePlanList = $userServicePlanList | Where-Object { $_.ServicePlanId -notin $ServicePlanId } | Select-Object -Property ServicePlanId 
            if (-not [object]::equals($disabledServicePlanList, $null)) {
                [array]$servicePlanList += $disabledServicePlanList.servicePlanId 
                    
                $body = @{
                            
                    addLicenses      = @(
                        @{
                            'disabledPlans' = $servicePlanList
                            "skuId"         = $skuId
                        }
                    )
                    "removeLicenses" = @()
                } 
                
                
            }
        }
        
		Invoke-PSFProtectedCommand -ActionString 'New-MdcaSubnet.Create' -ActionStringValues $Name -Target $Name -ScriptBlock {
			$userLicenseServicePlan = Invoke-RestRequest -Method Post -Path "subnet/create_rule/" -Body $body
            $userLicenseServicePlan = Invoke-RestRequest -Service 'graph' -Path ("{0}/{1}" -f $UserId, 'assignLicense') -Body $body -Method Post
            $userLicenseServicePlan = Invoke-RestRequest -Service 'graph' -Path ("{0}/{1}" -f $UserPrinciplaName, 'assignLicense') -Body $body -Method Post
		} -EnableException $EnableException -PSCmdlet $PSCmdlet

        Invoke-RestRequest -Service 'graph' -Path ("{0}/{1}" -f $UserId, 'assignLicense') -Body $body -Method Post
        Invoke-RestRequest -Service 'graph' -Path ("{0}/{1}" -f $UserPrinciplaName, 'assignLicense') -Body $body -Method Post
    }
    end
    {}
}
