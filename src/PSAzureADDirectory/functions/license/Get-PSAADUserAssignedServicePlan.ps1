function Get-PSAADUserAssignedServicePlan {
    [CmdletBinding(DefaultParameterSetName = 'SkuId',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0,
            ParameterSetName = 'ServicePlanId')]
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
        [string]$ServicePlanId,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 1,
            ParameterSetName = 'SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber
    )
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users"
            $authorizationToken = Get-PSAADAuthorizationToken
            $property = (Get-PSFConfig -Module PSAzureADDirectory -Name Settings.GraphApiQuery.Select.ServicePlan).Value
        }
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }
    }
    process {        
        if (Test-PSFFunctionInterrupt) { return }
        $graphApiParameters = @{
            Method             = 'Get'
            AuthorizationToken = "Bearer $authorizationToken"
            Uri                = Join-UriPath -Uri $url -ChildPath ("{0}" -f $UserId)
            Select             = $property -join ","
        }
        if (Test-PSFParameterBinding -Parameter SkuId) {
            $graphApiParameters['Filter'] = ('assignedPlans/any(x:x/servicePlanId eq {1})' -f $SkuId)
            $userServicePlanResult = Invoke-GraphApiQuery @graphApiParameters | Where-Object { $_.SkuId -eq $SkuId }
        }
        elseif (Test-PSFParameterBinding -Parameter SkuPartNumber) {
            $userServicePlanResult = Invoke-GraphApiQuery @graphApiParameters | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
        }
        else {
            $userServicePlanResult = Invoke-GraphApiQuery @graphApiParameters
        }
        $userServicePlanResult | Select-PSFObject -Property $property -ExcludeProperty '@odata*' -TypeName "PSAzureADDirectory.User.ServicePlan"
    }  
    end
    {}
}
