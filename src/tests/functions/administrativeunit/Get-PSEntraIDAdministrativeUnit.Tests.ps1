BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDAdministrativeUnit' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { 
            [PSCustomObject]@{ Value = @('id', 'displayName', 'description') }
        } -ParameterFilter { $Name -eq 'Settings.GraphApiQuery.Select.AdministrativeUnit' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { 
            [PSCustomObject]@{
                value = @($script:MockAU)
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestAdministrativeUnit { $InputObject.value }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }

        # Mock administrative unit data
        $script:MockAU = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
            Id = '12345678-1234-1234-1234-123456789012'
            DisplayName = 'Marketing AU'
            Description = 'Marketing Department Administrative Unit'
            Visibility = 'Public'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory DisplayName parameter for DisplayName parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Filter parameter for Filter parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory All parameter for All parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['All']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept pipeline input for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'Get administrative unit by Identity' {
        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits/12345678-1234-1234-1234-123456789012'
            }
        }

        It 'Should return administrative unit object' {
            $result = Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be $script:MockAU.Id
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDAdministrativeUnit -Identity @('id1', 'id2')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should process pipeline input' {
            @('id1', 'id2') | Get-PSEntraIDAdministrativeUnit

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Get administrative unit by DisplayName' {
        It 'Should call API with filter query' {
            Get-PSEntraIDAdministrativeUnit -DisplayName 'Marketing'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "startswith(displayName,'Marketing')"
            }
        }

        It 'Should handle multiple display names' {
            Get-PSEntraIDAdministrativeUnit -DisplayName @('Marketing', 'Finance')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Get administrative unit with Filter' {
        It 'Should call API with custom filter' {
            Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "displayName eq 'Marketing AU'"
            }
        }

        It 'Should use ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnit -Filter "startswith(displayName,'M')" -AdvancedFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }

        It 'Should not use ConsistencyLevel header without AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $null -eq $Header -or $null -eq $Header.ConsistencyLevel
            }
        }
    }

    Context 'Get all administrative units' {
        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnit -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits'
            }
        }

        It 'Should include count and top parameters' {
            Get-PSEntraIDAdministrativeUnit -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true' -and $Query.'$top' -eq 999
            }
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDAdministrativeUnit -Identity 'test-id'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand for retries' {
            Get-PSEntraIDAdministrativeUnit -Identity 'test-id'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should convert response using ConvertFrom-RestAdministrativeUnit' {
            Get-PSEntraIDAdministrativeUnit -Identity 'test-id'

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestAdministrativeUnit -Times 1 -Exactly
        }
    }
}
