function Disable-PSAADLicenseServicePlan {
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
        [string]$UserId,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 1,
            ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuId,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            ValueFromRemainingArguments = $false,
            Position = 2,
            ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [Array]$DisabledServicePlan
    )
    begin
    {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users"
            $authorizationToken = Receive-PSAADAuthorizationToken
        }
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }
    }
    process {        
        if (Test-PSFFunctionInterrupt) { return }
        try 
        {
            $graphApiParameters=@{
                Method = 'Post'
                AuthorizationToken = "Bearer $authorizationToken"
                Uri = Join-UriPath -Uri $url -ChildPath ("{0}{1}" -f $UserId,'assignLicense')
            }

            $userServicePlanList = Get-Office365ServicePlan -UserId $UserId -SkuId $SkuId
            [array]$disabledServicePlanList=$DisabledServicePlan
            if (-not [object]::equals($userServicePlanList,$null)) {
                $userServicePlanDisabledList = $userServicePlanList.servicePlans | Where-Object { $_.provisioningStatus -eq 'Disabled' }
                if (-not [object]::equals($userServicePlanDisabledList,$null)) {
                    [array]$disabledServicePlanList += $userServicePlanDisabledList.servicePlanId
                }
                $body = @{
                    "addLicenses"    = @(
                        @{
                            "disabledPlans" = ($disabledServicePlanList | Select-Object -Unique)
                            "skuId"         = $SkuId
                        }
                    )
                    "removeLicenses" = @()
                } | ConvertTo-Json -Depth 3 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
                $graphApiParameters['Body'] = $body
                Invoke-GraphApiQuery @graphApiParameters
            }
        }
        catch {
			Stop-PSFFunction -String 'FailedDisableAssignLicense' -StringValues $graphApiParameters['Uri'] -Target $graphApiParameters['Uri'] -SilentlyContinue -ErrorRecord $_ -Tag GraphApi,Get
		}
        Write-PSFMessage -Level InternalComment -String 'QueryCommandOutput' -StringValues $graphApiParameters['Uri'] -Target $graphApiParameters['Uri'] -Tag GraphApi,Get -Data $graphApiParameters

    }
    end
    {}
}
