BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'
    $commandName = 'Get-PSEntraIDSubscribedLicense'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe "Get-PSEntraIDSubscribedLicense" -Tag 'Unit' {
    BeforeAll {
        Mock Get-PSFConfigValue -ModuleName PSMicrosoftEntraID {
            param($FullName)
            switch ($FullName) {
                'PSMicrosoftEntraID.Settings.DefaultService' { return 'PSMicrosoftEntraID.Graph' }
                'PSMicrosoftEntraID.Settings.Command.RetryCount' { return 3 }
                'PSMicrosoftEntraID.Settings.Command.RetryWaitInSeconds' { return 5 }
            }
        }

        Mock Get-PSFConfig -ModuleName PSMicrosoftEntraID {
            param($Module, $Name)
            if ($Name -eq 'Settings.GraphApiQuery.Select.SubscribedSku') {
                return @{
                    Value = @('id', 'skuId', 'skuPartNumber', 'servicePlans')
                }
            }
        }

        Mock Assert-EntraConnection -ModuleName PSMicrosoftEntraID { }

        Mock Invoke-EntraRequest -ModuleName PSMicrosoftEntraID {
            return @{
                value = @(
                    @{
                        id = 'subscription1-guid'
                        skuId = 'sku1-guid'
                        skuPartNumber = 'ENTERPRISEPACK'
                        consumedUnits = 10
                        prepaidUnits = @{
                            enabled = 25
                            suspended = 0
                            warning = 0
                        }
                        servicePlans = @(
                            @{
                                servicePlanId = 'plan1-guid'
                                servicePlanName = 'EXCHANGE_S_ENTERPRISE'
                            }
                        )
                    },
                    @{
                        id = 'subscription2-guid'
                        skuId = 'sku2-guid'
                        skuPartNumber = 'EMSPREMIUM'
                        consumedUnits = 5
                        prepaidUnits = @{
                            enabled = 15
                            suspended = 0
                            warning = 0
                        }
                        servicePlans = @(
                            @{
                                servicePlanId = 'plan2-guid'
                                servicePlanName = 'INTUNE_A'
                            }
                        )
                    }
                )
            }
        }

        Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
            param($ScriptBlock)
            & $ScriptBlock
        }

        Mock ConvertFrom-RestSubscribedSku -ModuleName PSMicrosoftEntraID {
            param($InputObject)
            foreach ($item in $InputObject.value) {
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
                    Id = $item.id
                    SkuId = $item.skuId
                    SkuPartNumber = $item.skuPartNumber
                    ConsumedUnits = $item.consumedUnits
                    PrepaidUnits = $item.prepaidUnits
                    ServicePlans = $item.servicePlans
                }
            }
        }

        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { return $true } -ParameterFilter { $EnableException -eq $false }
        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { throw [System.Management.Automation.PipelineStoppedException]::new() } -ParameterFilter { $EnableException -eq $true }

        Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $false }
    }

    Context 'Parameter Validation' {
        It 'Should have EnableException as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDSubscribedLicense).Parameters['EnableException']
            $parameter.SwitchParameter | Should -Be $true
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDSubscribedLicense
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
        }

        It 'Should not require any mandatory parameters' {
            $command = Get-Command Get-PSEntraIDSubscribedLicense
            $mandatoryParams = $command.Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $mandatoryParams | Should -BeNullOrEmpty
        }
    }

    Context 'Basic Functionality' {
        It 'Should retrieve all subscribed licenses' {
            $result = Get-PSEntraIDSubscribedLicense

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should return licenses with correct properties' {
            $result = Get-PSEntraIDSubscribedLicense

            $result[0].SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            $result[0].ConsumedUnits | Should -Be 10
            $result[1].SkuPartNumber | Should -Be 'EMSPREMIUM'
            $result[1].ConsumedUnits | Should -Be 5
        }

        It 'Should use subscribedSkus API endpoint' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -eq 'subscribedSkus'
            } -Times 1 -Scope It
        }

        It 'Should pass correct query parameters with select' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$select'] -eq 'id,skuId,skuPartNumber,servicePlans'
            } -Times 1 -Scope It
        }

        It 'Should use GET method' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Method -eq 'Get'
            } -Times 1 -Scope It
        }
    }

    Context 'Connection and Configuration' {
        It 'Should assert connection to Entra' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use Graph service' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            } -Times 1 -Scope It
        }

        It 'Should retrieve configuration values' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Get-PSFConfigValue -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $FullName -eq 'PSMicrosoftEntraID.Settings.DefaultService'
            } -Times 1 -Scope It

            Should -Invoke Get-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.GraphApiQuery.Select.SubscribedSku'
            } -Times 1 -Scope It
        }
    }

    Context 'Error Handling' {
        It 'Should respect EnableException parameter' {
            Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
                param($ScriptBlock, $EnableException)
                $EnableException | Should -Be $true
            }

            Get-PSEntraIDSubscribedLicense -EnableException

            Should -Invoke Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle API errors gracefully without EnableException' {
            Mock Invoke-EntraRequest -ModuleName PSMicrosoftEntraID {
                return $null
            }

            $result = Get-PSEntraIDSubscribedLicense -EnableException:$false
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle function interrupt' {
            Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $true }

            $result = Get-PSEntraIDSubscribedLicense

            $result | Should -BeNullOrEmpty
        }

        It 'Should use ErrorAction Stop in API call' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $ErrorAction -eq 'Stop'
            } -Times 1 -Scope It
        }
    }

    Context 'Return Values' {
        It 'Should return correct object type' {
            Mock ConvertFrom-RestSubscribedSku -ModuleName PSMicrosoftEntraID {
                param($InputObject)
                foreach ($item in $InputObject.value) {
                    $obj = [PSCustomObject]@{
                        Id = $item.id
                        SkuId = $item.skuId
                        SkuPartNumber = $item.skuPartNumber
                        ConsumedUnits = $item.consumedUnits
                        PrepaidUnits = $item.prepaidUnits
                        ServicePlans = $item.servicePlans
                    }
                    $obj.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.License.SubscriptionSkuLicense')
                    $obj
                }
            }
            
            $result = Get-PSEntraIDSubscribedLicense

            $result[0].PSObject.TypeNames[0] | Should -Be 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
        }

        It 'Should include service plans in results' {
            $result = Get-PSEntraIDSubscribedLicense

            $result[0].ServicePlans | Should -Not -BeNullOrEmpty
            $result[0].ServicePlans[0].servicePlanName | Should -Be 'EXCHANGE_S_ENTERPRISE'
        }

        It 'Should include prepaid units information' {
            $result = Get-PSEntraIDSubscribedLicense

            $result[0].PrepaidUnits | Should -Not -BeNullOrEmpty
            $result[0].PrepaidUnits.enabled | Should -Be 25
        }
    }

    Context 'Retry Configuration' {
        It 'Should configure retry count from configuration' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Get-PSFConfigValue -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $FullName -like '*RetryCount'
            } -Times 1 -Scope It
        }

        It 'Should configure retry wait time from configuration' {
            Get-PSEntraIDSubscribedLicense

            Should -Invoke Get-PSFConfigValue -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $FullName -like '*RetryWaitInSeconds'
            } -Times 1 -Scope It
        }
    }
}
