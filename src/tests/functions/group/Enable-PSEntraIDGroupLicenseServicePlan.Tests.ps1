BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Enable-PSEntraIDGroupLicenseServicePlan' -Tag 'Unit' {
    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        $script:TestSkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:DisabledPlan = '33333333-3333-3333-3333-333333333333'
        $script:EnabledPlan = '22222222-2222-2222-2222-222222222222'
        $script:Group = [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = '12345678-1234-1234-1234-123456789012'; DisplayName = 'Test Group'; AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:DisabledPlan, $script:EnabledPlan) }) }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { [PSCustomObject]@{ SkuId = $script:TestSkuId; SkuPartNumber = 'ENTERPRISEPACK'; ServicePlans = @([PSCustomObject]@{ ServicePlanId = $script:EnabledPlan; ServicePlanName = 'EXCHANGE_S_ENTERPRISE' }, [PSCustomObject]@{ ServicePlanId = $script:DisabledPlan; ServicePlanName = 'SHAREPOINTWAC' }) } }
    }

    It 'Should remove plan from disabled list' {
        Enable-PSEntraIDGroupLicenseServicePlan -InputObject $script:Group -SkuId $script:TestSkuId -ServicePlanId $script:EnabledPlan -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Body.addLicenses[0].disabledPlans -contains $script:DisabledPlan -and $Body.addLicenses[0].disabledPlans -notcontains $script:EnabledPlan }
    }
}