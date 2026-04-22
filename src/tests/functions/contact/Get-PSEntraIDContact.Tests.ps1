BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDContact' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { 
            [PSCustomObject]@{ Value = @('id', 'displayName', 'mail', 'givenName', 'surname', 'companyName') }
        } -ParameterFilter { $Name -eq 'Settings.GraphApiQuery.Select.Contact' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { 
            [PSCustomObject]@{
                value = @($script:MockContact)
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestContact { $InputObject.value }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }

        # Mock contact data
        $script:MockContact = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Contacts.Contact'
            Id = '12345678-1234-1234-1234-123456789012'
            DisplayName = 'John Doe'
            Mail = 'john.doe@contoso.com'
            GivenName = 'John'
            Surname = 'Doe'
            CompanyName = 'Contoso Ltd.'
            JobTitle = 'Sales Manager'
        }

        $script:MockContact2 = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Contacts.Contact'
            Id = '87654321-4321-4321-4321-210987654321'
            DisplayName = 'Jane Smith'
            Mail = 'jane.smith@fabrikam.com'
            GivenName = 'Jane'
            Surname = 'Smith'
            CompanyName = 'Fabrikam Inc.'
            JobTitle = 'Marketing Director'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Name parameter for Name parameter set' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Name']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory CompanyName parameter for CompanyName parameter set' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['CompanyName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Filter parameter for Filter parameter set' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory All parameter for All parameter set' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['All']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Identity']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should have Id and Mail aliases for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Identity']
            $param.Aliases | Should -Contain 'Id'
            $param.Aliases | Should -Contain 'Mail'
        }

        It 'Should accept string array for Name parameter' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['Name']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept string array for CompanyName parameter' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['CompanyName']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should have EnableException switch parameter' {
            $param = (Get-Command Get-PSEntraIDContact).Parameters['EnableException']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Get contact by Identity' {
        It 'Should call API with correct path and filter' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'contacts' -and $Query.'$filter' -eq "mail eq 'john.doe@contoso.com'"
            }
        }

        It 'Should return contact object' {
            $result = Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            $result | Should -Not -BeNullOrEmpty
            $result.Mail | Should -Be $script:MockContact.Mail
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDContact -Identity @('john.doe@contoso.com', 'jane.smith@fabrikam.com')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1
        }

        It 'Should call ConvertFrom-RestContact' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestContact -Times 1
        }
    }

    Context 'Get contact by Name' {
        It 'Should call API with correct filter for name search' {
            Get-PSEntraIDContact -Name 'John'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'contacts' -and $Query.'$filter' -like "*startswith(displayName,'John')*"
            }
        }

        It 'Should search across displayName, givenName, and surname' {
            Get-PSEntraIDContact -Name 'John'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -like "*displayName*" -and 
                $Query.'$filter' -like "*givenName*" -and 
                $Query.'$filter' -like "*surname*"
            }
        }

        It 'Should return contact objects' {
            $result = Get-PSEntraIDContact -Name 'John'

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle multiple names' {
            Get-PSEntraIDContact -Name @('John', 'Jane')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Get contact by CompanyName' {
        It 'Should call API with correct filter for company name' {
            Get-PSEntraIDContact -CompanyName 'Contoso Ltd.'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'contacts' -and $Query.'$filter' -eq "companyName in ('Contoso Ltd.')"
            }
        }

        It 'Should handle multiple company names' {
            Get-PSEntraIDContact -CompanyName @('Contoso Ltd.', 'Fabrikam Inc.')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -like "*'Contoso Ltd.'*" -and $Query.'$filter' -like "*'Fabrikam Inc.'*"
            }
        }

        It 'Should include ConsistencyLevel header' {
            Get-PSEntraIDContact -CompanyName 'Contoso Ltd.'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ContainsKey('ConsistencyLevel') -and $Header['ConsistencyLevel'] -eq 'eventual'
            }
        }

        It 'Should return contact objects' {
            $result = Get-PSEntraIDContact -CompanyName 'Contoso Ltd.'

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Get contact by Filter' {
        It 'Should call API with custom filter' {
            $customFilter = "startswith(mail,'john')"
            Get-PSEntraIDContact -Filter $customFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'contacts' -and $Query.'$filter' -eq $customFilter
            }
        }

        It 'Should include ConsistencyLevel header with Filter' {
            Get-PSEntraIDContact -Filter "startswith(mail,'john')"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ContainsKey('ConsistencyLevel') -and $Header['ConsistencyLevel'] -eq 'eventual'
            }
        }

        It 'Should return contact objects' {
            $result = Get-PSEntraIDContact -Filter "startswith(mail,'john')"

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle complex filter expressions' {
            $complexFilter = "companyName eq 'Contoso' and startswith(mail,'john')"
            Get-PSEntraIDContact -Filter $complexFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq $complexFilter
            }
        }
    }

    Context 'Get all contacts' {
        It 'Should call API without filter when -All is specified' {
            Get-PSEntraIDContact -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'contacts' -and -not $Query.ContainsKey('$filter')
            }
        }

        It 'Should return contact objects' {
            $result = Get-PSEntraIDContact -All

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should call ConvertFrom-RestContact' {
            Get-PSEntraIDContact -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestContact -Times 1
        }
    }

    Context 'Query Parameters' {
        It 'Should include $count parameter' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true'
            }
        }

        It 'Should include $top parameter with page size' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$top' -eq 999
            }
        }

        It 'Should include $select parameter with contact properties' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$select' -like '*id*' -and $Query.'$select' -like '*displayName*'
            }
        }
    }

    Context 'Error Handling' {
        It 'Should call Invoke-PSFProtectedCommand' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }

        It 'Should respect EnableException parameter' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com' -EnableException

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $EnableException -eq $true
            }
        }

        It 'Should handle Test-PSFFunctionInterrupt' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Test-PSFFunctionInterrupt -Times 1 -Exactly
        }

        It 'Should include retry count in protected command' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $RetryCount -eq 5
            }
        }

        It 'Should include retry wait in protected command' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $null -ne $RetryWait
            }
        }
    }

    Context 'Output Type' {
        It 'Should have correct output type attribute' {
            $command = Get-Command Get-PSEntraIDContact
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Contacts.Contact'
        }
    }

    Context 'Integration Scenarios' {
        It 'Should handle contact not found gracefully' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                [PSCustomObject]@{ value = @() }
            }

            $result = Get-PSEntraIDContact -Identity 'nonexistent@contoso.com'
            $result | Should -BeNullOrEmpty
        }

        It 'Should process multiple contacts' {
            Mock -ModuleName $script:ModuleName ConvertFrom-RestContact { 
                $InputObject.value | ForEach-Object { $_ }
            }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                param($Query)
                if ($Query.'$filter' -like "*john*") {
                    [PSCustomObject]@{ value = @($script:MockContact) }
                }
                elseif ($Query.'$filter' -like "*jane*") {
                    [PSCustomObject]@{ value = @($script:MockContact2) }
                }
            }

            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'
            Get-PSEntraIDContact -Identity 'jane.smith@fabrikam.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2
        }

        It 'Should work with different parameter sets sequentially' {
            Get-PSEntraIDContact -Identity 'john.doe@contoso.com'
            Get-PSEntraIDContact -Name 'John'
            Get-PSEntraIDContact -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 3
        }
    }
}
