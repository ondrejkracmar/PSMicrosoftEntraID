BeforeAll {
    Import-Module PSFramework -Force
    Import-Module "$PSScriptRoot/../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
}

describe 'TEPP Completion Scriptblocks' {
    Context 'Public Functions' {
        BeforeAll {
            Mock Get-PSEntraIDSubscribedLicense {
                [PSCustomObject]@{
                    PSTypeName    = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
                    SkuId         = 'sku1-0000-0000-0000-000000000001'
                    SkuPartNumber = 'ENTERPRISEPACK'
                    SkuFriendlyName = 'Microsoft 365 E3'
                    ServicePlans  = @(
                        [PSCustomObject]@{
                            ServicePlanId          = 'sp1-0000-0000-0000-000000000001'
                            ServicePlanName        = 'EXCHANGE_S_ENTERPRISE'
                            ServicePlanFriendlyName = 'Exchange Online (Plan 2)'
                        }
                    )
                }
            }
        }

        It 'Get-PSEntraIDSubscribedLicense returns data' {
            $result = Get-PSEntraIDSubscribedLicense
            $result | Should -Not -BeNullOrEmpty
        }
        It 'Get-PSEntraIDUsageLocation returns CZ for Czech Republic' {
            $result = Get-PSEntraIDUsageLocation
            $result | Should -Not -BeNullOrEmpty
            $result['Czech Republic'] | Should -Be 'CZ'
        }
    }
    Context 'TEPP Scriptblocks' {
        It 'subscribed.skuid scriptblock is registered' {
            $block = [PSFramework.TabExpansion.TabExpansionHost]::Scripts['subscribed.skuid']
            $block | Should -Not -BeNullOrEmpty
        }
        It 'subscribed.serviceplanid scriptblock is registered' {
            $block = [PSFramework.TabExpansion.TabExpansionHost]::Scripts['subscribed.serviceplanid']
            $block | Should -Not -BeNullOrEmpty
        }
        It 'user.usagelocationcode scriptblock is registered' {
            $block = [PSFramework.TabExpansion.TabExpansionHost]::Scripts['user.usagelocationcode']
            $block | Should -Not -BeNullOrEmpty
        }
        It 'user.usagelocationcountry scriptblock is registered' {
            $block = [PSFramework.TabExpansion.TabExpansionHost]::Scripts['user.usagelocationcountry']
            $block | Should -Not -BeNullOrEmpty
        }
    }
}
