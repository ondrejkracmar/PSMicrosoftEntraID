BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Disable-PSEntraIDGroupLicenseServicePlan' -Tag 'Unit' {
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
        $script:ExistingDisabledPlan = '33333333-3333-3333-3333-333333333333'
        $script:NewDisabledPlan = '22222222-2222-2222-2222-222222222222'
        $script:Group = [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = '12345678-1234-1234-1234-123456789012'; DisplayName = 'Test Group'; AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:ExistingDisabledPlan) }) }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { [PSCustomObject]@{ SkuId = $script:TestSkuId; SkuPartNumber = 'ENTERPRISEPACK'; ServicePlans = @([PSCustomObject]@{ ServicePlanId = $script:NewDisabledPlan; ServicePlanName = 'EXCHANGE_S_ENTERPRISE' }) } }
    }

    It 'Should add plan to disabled list' {
        Disable-PSEntraIDGroupLicenseServicePlan -InputObject $script:Group -SkuId $script:TestSkuId -ServicePlanId $script:NewDisabledPlan -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Body.addLicenses[0].disabledPlans -contains $script:ExistingDisabledPlan -and $Body.addLicenses[0].disabledPlans -contains $script:NewDisabledPlan }
    }

    It 'Should send disabledPlans as an array when only ONE plan ends up disabled' {
        # Graph rejects a scalar here ("An unexpected 'PrimitiveValue' node was found
        # when reading from the JSON reader. A 'StartArray' node was expected"), which
        # makes disabling a single service plan fail every time - the common case.
        #
        # -contains cannot catch it: PowerShell treats a bare string as a one-element
        # collection, so the assertion above passes on a scalar too. Assert the SHAPE.
        $group = [PSCustomObject]@{
            PSTypeName       = 'PSMicrosoftEntraID.Groups.Group'
            Id               = '12345678-1234-1234-1234-123456789012'
            DisplayName      = 'Test Group'
            AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @() })
        }
        Disable-PSEntraIDGroupLicenseServicePlan -InputObject $group -SkuId $script:TestSkuId -ServicePlanId $script:NewDisabledPlan -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
            $plans = $Body.addLicenses[0].disabledPlans
            $plans -isnot [string] -and $plans -is [System.Collections.IEnumerable] -and @($plans).Count -eq 1
        }
    }

    It 'Should serialize a single disabled plan as a JSON array' {
        # The end-to-end statement of the same defect: what Graph actually receives.
        $group = [PSCustomObject]@{
            PSTypeName       = 'PSMicrosoftEntraID.Groups.Group'
            Id               = '12345678-1234-1234-1234-123456789012'
            DisplayName      = 'Test Group'
            AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @() })
        }
        Disable-PSEntraIDGroupLicenseServicePlan -InputObject $group -SkuId $script:TestSkuId -ServicePlanId $script:NewDisabledPlan -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
            ($Body | ConvertTo-Json -Depth 5 -Compress) -match '"disabledPlans":\['
        }
    }
}