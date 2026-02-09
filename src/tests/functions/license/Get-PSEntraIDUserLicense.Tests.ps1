BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe "Get-PSEntraIDUserLicense" -Tag 'Unit' {
    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock Get-PSFConfigValue -ModuleName $script:ModuleName {
            param($FullName)
            switch ($FullName) {
                'PSMicrosoftEntraID.Settings.DefaultService' { return 'PSMicrosoftEntraID.Graph' }
                'PSMicrosoftEntraID.Settings.GraphApiQuery.PageSize' { return 100 }
                'PSMicrosoftEntraID.Settings.Command.RetryCount' { return 3 }
                'PSMicrosoftEntraID.Settings.Command.RetryWaitInSeconds' { return 5 }
            }
        }

        Mock Get-PSFConfig -ModuleName PSMicrosoftEntraID {
            param($Module, $Name)
            if ($Name -eq 'Settings.GraphApiQuery.Select.User') {
                return @{
                    Value = @('id', 'userPrincipalName', 'displayName', 'mail', 'assignedLicenses')
                }
            }
        }

        Mock Assert-EntraConnection -ModuleName PSMicrosoftEntraID { }

        Mock Invoke-EntraRequest -ModuleName PSMicrosoftEntraID {
            return @{
                value = @(
                    @{
                        id = 'user1-guid'
                        userPrincipalName = 'user1@contoso.com'
                        displayName = 'User One'
                        assignedLicenses = @(
                            @{
                                skuId = '00000000-0000-0000-0000-000000000005'
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

        Mock ConvertFrom-RestUser -ModuleName PSMicrosoftEntraID {
            param($InputObject)
            foreach ($item in $InputObject.value) {
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Users.User'
                    Id = $item.id
                    UserPrincipalName = $item.userPrincipalName
                    DisplayName = $item.displayName
                    AssignedLicenses = $item.assignedLicenses
                }
            }
        }

        Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $false }
        
        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { return $true } -ParameterFilter { $EnableException -eq $false }
        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { throw [System.Management.Automation.PipelineStoppedException]::new() } -ParameterFilter { $EnableException -eq $true }
    }

    Context 'Parameter Validation' {
        It 'Should have correct parameter sets' {
            $command = Get-Command Get-PSEntraIDUserLicense
            $command.ParameterSets.Name | Should -Contain 'CompanyName'
            $command.ParameterSets.Name | Should -Contain 'SkuId'
            $command.ParameterSets.Name | Should -Contain 'SkuPartNumber'
            $command.ParameterSets.Name | Should -Contain 'ServicePlanId'
            $command.ParameterSets.Name | Should -Contain 'ServicePlanName'
            $command.ParameterSets.Name | Should -Contain 'Filter'
            $command.ParameterSets.Name | Should -Contain 'SkuIdCompanyName'
            $command.ParameterSets.Name | Should -Contain 'SkuPartNumberCompanyName'
            $command.ParameterSets.Name | Should -Contain 'ServicePlanIdCompanyName'
            $command.ParameterSets.Name | Should -Contain 'ServicePlanNameCompanyName'
        }

        It 'Should have CompanyName parameter with Company alias' {
            $parameter = (Get-Command Get-PSEntraIDUserLicense).Parameters['CompanyName']
            $parameter.Aliases | Should -Contain 'Company'
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDUserLicense
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.User'
        }

        It 'Should have EnableException as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDUserLicense).Parameters['EnableException']
            $parameter.SwitchParameter | Should -Be $true
        }

        It 'Should have AdvancedFilter as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDUserLicense).Parameters['AdvancedFilter']
            $parameter.SwitchParameter | Should -Be $true
        }
    }

    Context 'When using SkuId parameter set' {
        It 'Should filter users by SKU ID' {
            $result = Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000002'

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use correct filter expression' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000002'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$filter'] -eq 'assignedLicenses/any(x:x/skuId eq 00000000-0000-0000-0000-000000000002)'
            } -Times 1 -Scope It
        }

        It 'Should handle multiple SKU IDs' {
            $skuIds = @('00000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000007')

            Get-PSEntraIDUserLicense -SkuId $skuIds

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }

        It 'Should query users endpoint' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000002'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Path -eq 'users'
            } -Times 1 -Scope It
        }
    }

    Context 'When using SkuPartNumber parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{
                    SkuId = 'resolved-sku-guid'
                    SkuPartNumber = 'ENTERPRISEPACK'
                }
            }
        }

        It 'Should resolve SKU part number to SKU ID' {
            Get-PSEntraIDUserLicense -SkuPartNumber 'ENTERPRISEPACK'

            Should -Invoke Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use resolved SKU ID in filter' {
            Get-PSEntraIDUserLicense -SkuPartNumber 'ENTERPRISEPACK'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$filter'] -eq 'assignedLicenses/any(x:x/skuId eq resolved-sku-guid)'
            } -Times 1 -Scope It
        }

        It 'Should handle invalid SKU part number with EnableException' {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID { return $null }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('SKU not found') }

            { Get-PSEntraIDUserLicense -SkuPartNumber 'INVALID' -EnableException } | Should -Throw
        }

        It 'Should not call API when SKU part number is not found' {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID { return $null }

            Get-PSEntraIDUserLicense -SkuPartNumber 'INVALID'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 0 -Scope It
        }
    }

    Context 'When using ServicePlanId parameter set' {
        It 'Should filter users by service plan ID' {
            $result = Get-PSEntraIDUserLicense -ServicePlanId '00000000-0000-0000-0000-000000000003'

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use correct filter for service plans' {
            Get-PSEntraIDUserLicense -ServicePlanId '00000000-0000-0000-0000-000000000003'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$filter'] -eq 'assignedPlans/any(x:x/servicePlanId eq 00000000-0000-0000-0000-000000000003)'
            } -Times 1 -Scope It
        }

        It 'Should set ConsistencyLevel header' {
            Get-PSEntraIDUserLicense -ServicePlanId '00000000-0000-0000-0000-000000000003'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Header['ConsistencyLevel'] -eq 'eventual'
            } -Times 1 -Scope It
        }

        It 'Should handle multiple service plan IDs' {
            $planIds = @('00000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000009')

            Get-PSEntraIDUserLicense -ServicePlanId $planIds

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 2 -Scope It
        }
    }

    Context 'When using ServicePlanName parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{
                    ServicePlans = @(
                        [PSCustomObject]@{
                            ServicePlanId = 'resolved-plan-guid'
                            ServicePlanName = 'EXCHANGE_S_ENTERPRISE'
                        }
                    )
                }
            }
        }

        It 'Should resolve service plan name to ID' {
            Get-PSEntraIDUserLicense -ServicePlanName 'EXCHANGE_S_ENTERPRISE'

            Should -Invoke Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use resolved service plan ID in filter' {
            Get-PSEntraIDUserLicense -ServicePlanName 'EXCHANGE_S_ENTERPRISE'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$filter'] -eq 'assignedPlans/any(x:x/servicePlanId eq resolved-plan-guid)'
            } -Times 1 -Scope It
        }

        It 'Should set ConsistencyLevel header for service plan name' {
            Get-PSEntraIDUserLicense -ServicePlanName 'EXCHANGE_S_ENTERPRISE'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Header['ConsistencyLevel'] -eq 'eventual'
            } -Times 1 -Scope It
        }

        It 'Should handle invalid service plan name with EnableException' {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{ ServicePlans = @() }
            }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('Service plan not found') }

            { Get-PSEntraIDUserLicense -ServicePlanName 'INVALID' -EnableException } | Should -Throw
        }
    }

    Context 'When using CompanyName parameter set' {
        It 'Should filter users by company name' {
            $result = Get-PSEntraIDUserLicense -CompanyName 'Contoso'

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use correct filter for company name' {
            # Mock Join-String to return a specific format
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName 'Contoso'

                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                    $Query['$Filter'] -like "companyName in ('Contoso')"
                } -Times 1 -Scope It
            }
        }

        It 'Should set ConsistencyLevel header for company name' {
            Get-PSEntraIDUserLicense -CompanyName 'Contoso'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Header['ConsistencyLevel'] -eq 'eventual'
            } -Times 1 -Scope It
        }

        It 'Should handle multiple company names' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName @('Contoso', 'Fabrikam')

                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                    $Query['$Filter'] -like "*companyName in (*)*"
                } -Times 1 -Scope It
            }
        }
    }

    Context 'When using SkuIdCompanyName parameter set' {
        It 'Should filter by both SKU ID and company name' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuId '00000000-0000-0000-0000-000000000005'

                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                    $Query['$Filter'] -like "*companyName in*" -and
                    $Query['$Filter'] -like "*assignedLicenses/any*"
                } -Times 1 -Scope It
            }
        }

        It 'Should set ConsistencyLevel header' {
            Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuId '00000000-0000-0000-0000-000000000005'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Header['ConsistencyLevel'] -eq 'eventual'
            } -Times 1 -Scope It
        }

        It 'Should check for function interrupt' {
            Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuId '00000000-0000-0000-0000-000000000005'

            Should -Invoke Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }
    }

    Context 'When using SkuPartNumberCompanyName parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{
                    SkuId = 'resolved-sku-guid'
                    SkuPartNumber = 'ENTERPRISEPACK'
                }
            }
        }

        It 'Should resolve SKU part number and combine with company name' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuPartNumber 'ENTERPRISEPACK'

                Should -Invoke Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            }
        }

        It 'Should handle when SKU part number is not found' {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID { return $null }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('SKU not found') }

            { Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuPartNumber 'INVALID' -EnableException } | Should -Throw
        }
    }

    Context 'When using ServicePlanIdCompanyName parameter set' {
        It 'Should filter by service plan ID and company name' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName 'Contoso' -ServicePlanId '00000000-0000-0000-0000-000000000004'

                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                    $Query['$Filter'] -like "*companyName in*" -and
                    $Query['$Filter'] -like "*assignedPlans/any*"
                } -Times 1 -Scope It
            }
        }

        It 'Should check for function interrupt' {
            Get-PSEntraIDUserLicense -CompanyName 'Contoso' -ServicePlanId '00000000-0000-0000-0000-000000000004'

            Should -Invoke Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }
    }

    Context 'When using ServicePlanNameCompanyName parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{
                    ServicePlans = @(
                        [PSCustomObject]@{
                            ServicePlanId = 'resolved-plan-guid'
                            ServicePlanName = 'EXCHANGE_S_ENTERPRISE'
                        }
                    )
                }
            }
        }

        It 'Should resolve service plan name and combine with company name' {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                Get-PSEntraIDUserLicense -CompanyName 'Contoso' -ServicePlanName 'EXCHANGE_S_ENTERPRISE'

                Should -Invoke Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
                Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            }
        }

        It 'Should handle when service plan name is not found' {
            Mock Get-PSEntraIDSubscribedSku -ModuleName PSMicrosoftEntraID {
                [PSCustomObject]@{ ServicePlans = @() }
            }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('Service plan not found') }

            { Get-PSEntraIDUserLicense -CompanyName 'Contoso' -ServicePlanName 'INVALID' -EnableException } | Should -Throw
        }
    }

    Context 'When using Filter parameter set' {
        It 'Should apply custom filter' {
            $filter = "userType eq 'Member'"

            Get-PSEntraIDUserLicense -Filter $filter

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$Filter'] -eq $filter
            } -Times 1 -Scope It
        }

        It 'Should use advanced filter when switch is present' {
            $filter = "endsWith(mail,'@contoso.com')"

            Get-PSEntraIDUserLicense -Filter $filter -AdvancedFilter

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Header['ConsistencyLevel'] -eq 'eventual'
            } -Times 1 -Scope It
        }

        It 'Should not set ConsistencyLevel header without AdvancedFilter' {
            $filter = "userType eq 'Member'"

            Get-PSEntraIDUserLicense -Filter $filter

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $null -eq $Header -or $Header.Count -eq 0
            } -Times 1 -Scope It
        }

        It 'Should check for function interrupt' {
            Get-PSEntraIDUserLicense -Filter "userType eq 'Member'"

            Should -Invoke Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }
    }

    Context 'Connection and Configuration' {
        It 'Should assert connection to Entra' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should use Graph service' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Assert-EntraConnection -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            } -Times 1 -Scope It
        }

        It 'Should retrieve select configuration for users' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Get-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.GraphApiQuery.Select.User'
            } -Times 1 -Scope It
        }

        It 'Should pass select parameter in query' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$select'] -eq 'id,userPrincipalName,displayName,mail,assignedLicenses'
            } -Times 1 -Scope It
        }
    }

    Context 'Error Handling' {
        It 'Should respect EnableException parameter' {
            Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
                param($ScriptBlock, $EnableException)
                $EnableException | Should -Be $true
            }

            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001' -EnableException

            Should -Invoke Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should handle function interrupt and return early' {
            Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $true }

            $result = Get-PSEntraIDUserLicense -CompanyName 'Contoso'

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Query Parameters' {
        It 'Should include count parameter' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$count'] -eq 'true'
            } -Times 1 -Scope It
        }

        It 'Should include top parameter from configuration' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Query['$top'] -eq 100
            } -Times 1 -Scope It
        }

        It 'Should use GET method' {
            Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            Should -Invoke Invoke-EntraRequest -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Method -eq 'Get'
            } -Times 1 -Scope It
        }
    }

    Context 'Return Values' {
        It 'Should return user objects' {
            Mock ConvertFrom-RestUser -ModuleName PSMicrosoftEntraID {
                param($InputObject)
                foreach ($item in $InputObject.value) {
                    $obj = [PSCustomObject]@{
                        Id = $item.id
                        UserPrincipalName = $item.userPrincipalName
                        DisplayName = $item.displayName
                        AssignedLicenses = $item.assignedLicenses
                    }
                    $obj.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Users.User')
                    $obj
                }
            }
            
            $result = Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            $result | Should -Not -BeNullOrEmpty
            $result[0].PSObject.TypeNames[0] | Should -Be 'PSMicrosoftEntraID.Users.User'
        }

        It 'Should return users with assigned licenses' {
            $result = Get-PSEntraIDUserLicense -SkuId '00000000-0000-0000-0000-000000000001'

            $result[0].AssignedLicenses | Should -Not -BeNullOrEmpty
        }
    }
}
