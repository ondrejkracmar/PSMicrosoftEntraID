function Enable-PSAADLicenseServicePlan {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0,
            ParameterSetName = 'Default')]
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
        [string]$UserId,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 1,
            ParameterSetName = 'Default')]
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
        [string]$SkuId,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 2,
            ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ServicePlanId
    )
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users"
            $authorizationToken = Get-PSAADAuthorizationToken
        }
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }
    }
    process {        
        if (Test-PSFFunctionInterrupt) { return }

        $graphApiParameters = @{
            Method             = 'Post'
            AuthorizationToken = "Bearer $authorizationToken"
            Uri                = Join-UriPath -Uri $url -ChildPath ("{0}/{1}" -f $UserId, 'assignLicense')                
        }

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
                } | ConvertTo-Json -Depth 3 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } 
                $graphApiParameters['Body'] = $body
                Invoke-GraphApiQuery @graphApiParameters
            }
        }
    }
    end
    {}
}
