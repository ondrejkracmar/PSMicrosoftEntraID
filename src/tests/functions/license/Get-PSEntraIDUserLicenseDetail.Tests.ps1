BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'
    $commandName = 'Get-PSEntraIDUserLicenseDetail'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe "Get-PSEntraIDUserLicenseDetail" -Tag 'Unit' {
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
            return @{
                value = @(
                    @{
                        id = 'license1-guid'
                        skuId = 'sku-guid'
                        skuPartNumber = 'ENTERPRISEPACK'
                        servicePlans = @(
                            @{
                                servicePlanId = 'plan1-guid'
                                servicePlanName = 'EXCHANGE_S_ENTERPRISE'
                                provisioningStatus = 'Success'
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

        Mock ConvertFrom-RestUserLicenseDetail -ModuleName PSMicrosoftEntraID {
            param($InputObject)
            foreach ($item in $InputObject.value) {
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku'
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
            $command = Get-Command Get-PSEntraIDUserLicenseDetail
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have correct aliases for Identity parameter' {
            $parameter = (Get-Command Get-PSEntraIDUserLicenseDetail).Parameters['Identity']
            $parameter.Aliases | Should -Contain 'Id'
            $parameter.Aliases | Should -Contain 'UserPrincipalName'
            $parameter.Aliases | Should -Contain 'Mail'
        }

        It 'Should have EnableException as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDUserLicenseDetail).Parameters['EnableException']
            $parameter.SwitchParameter | Should -Be $true
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDUserLicenseDetail
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku'
        }

        It 'Should have InputObject parameter accept pipeline input' {
            $parameter = (Get-Command Get-PSEntraIDUserLicenseDetail).Parameters['InputObject']
            $parameter.Attributes.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have Identity parameter accept pipeline input' {
            $parameter = (Get-Command Get-PSEntraIDUserLicenseDetail).Parameters['Identity']
            $parameter.Attributes.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'When using InputObject parameter set' {
        It 'Should retrieve license details for user object' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'user-guid'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            $result | Should -Not -BeNullOrEmpty
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle multiple user objects' {
            $userObjects = @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.User'
                    Id = 'user1-guid'
                    UserPrincipalName = 'user1@contoso.com'
                },
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.User'
                    Id = 'user2-guid'
                    UserPrincipalName = 'user2@contoso.com'
                }
            )

            $result = Get-PSEntraIDUserLicenseDetail -InputObject $userObjects

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }

        It 'Should use correct API path with user ID' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'test-user-guid'
                UserPrincipalName = 'test@contoso.com'
            }

            Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -like 'users/test-user-guid/licenseDetails'
            } -Times 1 -Scope It
        }

        It 'Should pass correct query parameters' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'user-guid'
                UserPrincipalName = 'user@contoso.com'
            }

            Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$count'] -eq 'true' -and
                $Query['$top'] -eq 100
            } -Times 1 -Scope It
        }
    }

    Context 'When using Identity parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID {
                param($Identity)
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.User'
                    Id = 'resolved-user-guid'
                    UserPrincipalName = $Identity
                }
            }
        }

        It 'Should retrieve license details by user identity' {
            $result = Get-PSEntraIDUserLicenseDetail -Identity 'user@contoso.com'

            $result | Should -Not -BeNullOrEmpty
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            Should -Invoke Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle multiple identities' {
            $identities = @('user1@contoso.com', 'user2@contoso.com')

            $result = Get-PSEntraIDUserLicenseDetail -Identity $identities

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }

        It 'Should use resolved user ID in API path' {
            Get-PSEntraIDUserLicenseDetail -Identity 'user@contoso.com'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -like 'users/resolved-user-guid/licenseDetails'
            } -Times 1 -Scope It
        }

        It 'Should handle when user is not found with EnableException' {
            Mock Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID { return $null }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { }

            { Get-PSEntraIDUserLicenseDetail -Identity 'notfound@contoso.com' -EnableException } | Should -Not -Throw
            Should -Invoke Invoke-TerminatingException -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should not call API when user is not found' {
            Mock Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID { return $null }

            Get-PSEntraIDUserLicenseDetail -Identity 'notfound@contoso.com'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 0 -Scope It
        }
    }

    Context 'Connection and Configuration' {
        It 'Should assert connection to Entra' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'user-guid'
                UserPrincipalName = 'user@contoso.com'
            }

            Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use Graph service' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'user-guid'
                UserPrincipalName = 'user@contoso.com'
            }

            Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            } -Times 1 -Scope It
        }
    }

    Context 'Error Handling' {
        It 'Should respect EnableException parameter' {
            Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
                $EnableException | Should -Be $true
            }

            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = 'user-guid'
                UserPrincipalName = 'user@contoso.com'
            }

            Get-PSEntraIDUserLicenseDetail -InputObject $userObject -EnableException

            Should -Invoke Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle function interrupt' {
            Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $true }

            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Get-PSEntraIDUserLicenseDetail -InputObject $userObject

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Pipeline Support' {
        It 'Should accept user object from pipeline' {
            $userObject = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = $userObject | Get-PSEntraIDUserLicenseDetail

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should accept identity from pipeline' {
            Mock Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.User'
                    Id = 'resolved-user-guid'
                    UserPrincipalName = 'user@contoso.com'
                }
            }

            $result = 'user@contoso.com' | Get-PSEntraIDUserLicenseDetail

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Get-PSEntraIDUser -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }
    }
}
