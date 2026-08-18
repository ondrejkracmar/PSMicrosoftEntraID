BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe 'Get-PSEntraIDGroupLicenseDetail' -Tag 'Unit' {
    BeforeAll {
        Mock Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID {
            @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
                    SkuId = 'sku-guid'
                    SkuPartNumber = 'ENTERPRISEPACK'
                    SkuFriendlyName = 'Office 365 E3'
                    ServicePlans = @(
                        [PSCustomObject]@{
                            ServicePlanId = 'plan-enabled'
                            ServicePlanName = 'EXCHANGE_S_ENTERPRISE'
                            ServicePlanFriendlyName = 'Exchange Online Plan 2'
                            AppliesTo = 'User'
                        },
                        [PSCustomObject]@{
                            ServicePlanId = 'plan-disabled'
                            ServicePlanName = 'SHAREPOINTWAC'
                            ServicePlanFriendlyName = 'Office for the Web'
                            AppliesTo = 'User'
                        }
                    )
                }
            )
        }

        Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID {
            param($Identity)

            [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = $Identity
                AssignedLicenses = @(
                    [PSCustomObject]@{
                        PSTypeName = 'PSMicrosoftEntraID.Groups.AssignedLicense'
                        SkuId = 'sku-guid'
                        DisabledPlans = @('plan-disabled')
                    }
                )
            }
        }

    }

    Context 'Parameter Validation' {
        It 'Should have correct parameter sets' {
            $command = Get-Command Get-PSEntraIDGroupLicenseDetail
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have correct aliases for Identity parameter' {
            $parameter = (Get-Command Get-PSEntraIDGroupLicenseDetail).Parameters['Identity']
            $parameter.Aliases | Should -Contain 'Id'
            $parameter.Aliases | Should -Contain 'GroupId'
            $parameter.Aliases | Should -Contain 'TeamId'
            $parameter.Aliases | Should -Contain 'MailNickName'
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDGroupLicenseDetail
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku'
        }

        It 'Should have InputObject parameter accept pipeline input' {
            $parameter = (Get-Command Get-PSEntraIDGroupLicenseDetail).Parameters['InputObject']
            @($parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipeline }).Count | Should -BeGreaterThan 0
        }

        It 'Should have Identity parameter accept pipeline input' {
            $parameter = (Get-Command Get-PSEntraIDGroupLicenseDetail).Parameters['Identity']
            @($parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.ValueFromPipeline }).Count | Should -BeGreaterThan 0
        }

        It 'Should have EnableException as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDGroupLicenseDetail).Parameters['EnableException']
            $parameter.SwitchParameter | Should -Be $true
        }
    }

    Context 'When using InputObject parameter set' {
        It 'Should retrieve license details for group object' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = 'Licensing Group'
            }

            $result = Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject

            $result | Should -Not -BeNullOrEmpty
            $result.SkuId | Should -Be 'sku-guid'
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            $result.SkuFriendlyName | Should -Be 'Office 365 E3'
            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku'
            $result.ServicePlans | Should -HaveCount 2
            ($result.ServicePlans | Where-Object ServicePlanId -EQ 'plan-enabled').ProvisioningStatus | Should -Be 'Success'
            ($result.ServicePlans | Where-Object ServicePlanId -EQ 'plan-disabled').ProvisioningStatus | Should -Be 'Disabled'
            $result.ServicePlans[0].ServicePlanFriendlyName | Should -Be 'Exchange Online Plan 2'
            $result.ServicePlans[0].ServicePlanId | Should -Be 'plan-enabled'
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle multiple group objects' {
            $groupObjects = @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                    Id = 'group1-guid'
                    DisplayName = 'Licensing Group 1'
                },
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                    Id = 'group2-guid'
                    DisplayName = 'Licensing Group 2'
                }
            )

            $result = Get-PSEntraIDGroupLicenseDetail -InputObject $groupObjects

            $result | Should -HaveCount 2
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }
    }

    Context 'When using Identity parameter set' {
        It 'Should retrieve license details by group identity' {
            $result = Get-PSEntraIDGroupLicenseDetail -Identity 'licensing-group'

            $result | Should -Not -BeNullOrEmpty
            $result.SkuId | Should -Be 'sku-guid'
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            $result.SkuFriendlyName | Should -Be 'Office 365 E3'
            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku'
            $result.ServicePlans | Should -HaveCount 2
            ($result.ServicePlans | Where-Object ServicePlanId -EQ 'plan-enabled').ProvisioningStatus | Should -Be 'Success'
            ($result.ServicePlans | Where-Object ServicePlanId -EQ 'plan-disabled').ProvisioningStatus | Should -Be 'Disabled'
            $result.ServicePlans[0].ServicePlanId | Should -Be 'plan-enabled'
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle multiple identities' {
            $identities = @('group1', 'group2')

            $result = Get-PSEntraIDGroupLicenseDetail -Identity $identities

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }
    }

    Context 'Pass-through behavior' {
        It 'Should pass EnableException to the underlying cmdlet' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = 'Licensing Group'
            }

            Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject -EnableException

            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $EnableException.IsPresent
            } -Times 1 -Scope It
        }
    }
}