BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe 'Get-PSEntraIDGroupLicenseDetail' -Tag 'Unit' {
    BeforeAll {
        Mock Get-PSFConfigValue -ModuleName PSMicrosoftEntraID {
            param($FullName)
            switch ($FullName) {
                'PSMicrosoftEntraID.Settings.DefaultService' { return 'PSMicrosoftEntraID.Graph' }
                'PSMicrosoftEntraID.Settings.GraphApiQuery.PageSize' { return 100 }
                'PSMicrosoftEntraID.Settings.Command.RetryCount' { return 3 }
                'PSMicrosoftEntraID.Settings.Command.RetryWaitInSeconds' { return 5 }
            }
        }

        Mock Assert-EntraConnection -ModuleName PSMicrosoftEntraID { }

        Mock Invoke-EntraRequest -ModuleName PSMicrosoftEntraID {
            return @(
                @{
                    id = 'license1-guid'
                    skuId = 'sku-guid'
                    skuPartNumber = 'ENTERPRISEPACK'
                    servicePlans = @(
                        @{
                            servicePlanId = 'plan1-guid'
                            servicePlanName = 'EXCHANGE_S_ENTERPRISE'
                            provisioningStatus = 'Success'
                            appliesTo = 'User'
                        }
                    )
                }
            )
        }

        Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
            param($ScriptBlock)
            & $ScriptBlock
        }

        Mock ConvertFrom-RestGroupLicenseDetail -ModuleName PSMicrosoftEntraID {
            param($InputObject)
            foreach ($item in $InputObject) {
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku'
                    Id = $item.id
                    SkuId = $item.skuId
                    SkuPartNumber = $item.skuPartNumber
                    ServicePlans = $item.servicePlans
                }
            }
        }

        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { return $true } -ParameterFilter { $EnableException -eq $false }
        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { throw [System.Management.Automation.PipelineStoppedException]::new() } -ParameterFilter { $EnableException -eq $true }

        Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $false }
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
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
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

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }

        It 'Should use correct API path with group ID' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'test-group-guid'
                DisplayName = 'Test Group'
            }

            Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -like 'groups/test-group-guid/licenseDetails'
            } -Times 1 -Scope It
        }

        It 'Should pass correct query parameters' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = 'Licensing Group'
            }

            Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$count'] -eq 'true' -and
                $Query['$top'] -eq 100
            } -Times 1 -Scope It
        }
    }

    Context 'When using Identity parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID {
                param($Identity)
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                    Id = 'resolved-group-guid'
                    DisplayName = $Identity
                }
            }
        }

        It 'Should retrieve license details by group identity' {
            $result = Get-PSEntraIDGroupLicenseDetail -Identity 'licensing-group'

            $result | Should -Not -BeNullOrEmpty
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle multiple identities' {
            $identities = @('group1', 'group2')

            $result = Get-PSEntraIDGroupLicenseDetail -Identity $identities

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }

        It 'Should use resolved group ID in API path' {
            Get-PSEntraIDGroupLicenseDetail -Identity 'licensing-group'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -like 'groups/resolved-group-guid/licenseDetails'
            } -Times 1 -Scope It
        }

        It 'Should handle when group is not found with EnableException' {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID { return $null }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { }

            { Get-PSEntraIDGroupLicenseDetail -Identity 'missing-group' -EnableException } | Should -Not -Throw
            Should -Invoke Invoke-TerminatingException -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should not call API when group is not found' {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID { return $null }

            Get-PSEntraIDGroupLicenseDetail -Identity 'missing-group'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 0 -Scope It
        }
    }

    Context 'Connection and Configuration' {
        It 'Should assert connection to Entra' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = 'Licensing Group'
            }

            Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use Graph service' {
            $groupObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
                Id = 'group-guid'
                DisplayName = 'Licensing Group'
            }

            Get-PSEntraIDGroupLicenseDetail -InputObject $groupObject

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            } -Times 1 -Scope It
        }
    }
}