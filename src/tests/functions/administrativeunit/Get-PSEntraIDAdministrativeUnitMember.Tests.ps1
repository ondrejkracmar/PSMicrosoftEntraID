BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDAdministrativeUnitMember' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { 
            [PSCustomObject]@{ Value = @('id', 'userPrincipalName', 'displayName') }
        } -ParameterFilter { $Name -eq 'Settings.GraphApiQuery.Select.User' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { 
            [PSCustomObject]@{
                value = @($script:MockUser1, $script:MockUser2)
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject.value }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }

        # Mock administrative unit
        $script:MockAU = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
            Id = 'au-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test AU'
        }

        # Mock users
        $script:MockUser1 = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.User'
            Id = 'user1-12345678-1234-1234-1234-123456789012'
            DisplayName = 'John Doe'
            UserPrincipalName = 'john@contoso.com'
        }

        $script:MockUser2 = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.User'
            Id = 'user2-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Jane Smith'
            UserPrincipalName = 'jane@contoso.com'
        }

        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $script:MockAU }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter for InputObject parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have optional Filter parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Not -Contain $true
        }

        It 'Should have AdvancedFilter switch parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['AdvancedFilter']
            $param.SwitchParameter | Should -Be $true
        }

        It 'Should accept string array for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnitMember).Parameters['Identity']
            $param.ParameterType.Name | Should -Be 'String[]'
        }
    }

    Context 'Get members by InputObject' {
        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members"
            }
        }

        It 'Should return member objects' {
            $result = Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It 'Should accept object from pipeline' {
            $script:MockAU | Get-PSEntraIDAdministrativeUnitMember

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle multiple AUs from pipeline' {
            @($script:MockAU, $script:MockAU) | Get-PSEntraIDAdministrativeUnitMember

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should include count and top parameters' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true' -and $Query.'$top' -eq 999
            }
        }

        It 'Should not call Get-PSEntraIDAdministrativeUnit when using InputObject' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 0 -Exactly
        }
    }

    Context 'Get members by Identity' {
        It 'Should call Get-PSEntraIDAdministrativeUnit to resolve identity' {
            Get-PSEntraIDAdministrativeUnitMember -Identity 'Test AU'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 1 -Exactly
        }

        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnitMember -Identity 'Test AU'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members"
            }
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDAdministrativeUnitMember -Identity @('AU1', 'AU2')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should throw error when AU not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $null }

            Get-PSEntraIDAdministrativeUnitMember -Identity 'NonExistent' -EnableException

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'Filter members' {
        It 'Should apply filter when specified' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU -Filter "displayName startswith 'John'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "displayName startswith 'John'"
            }
        }

        It 'Should use ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU -Filter "startswith(displayName,'J')" -AdvancedFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }

        It 'Should not use ConsistencyLevel header without AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU -Filter "displayName eq 'John'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $null -eq $Header -or $null -eq $Header.ConsistencyLevel
            }
        }

        It 'Should work with filter and Identity parameter' {
            Get-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Filter "userType eq 'Member'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "userType eq 'Member'"
            }
        }
    }

    Context 'Response conversion' {
        It 'Should convert response using ConvertFrom-RestUser' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestUser -Times 1 -Exactly
        }

        It 'Should return user objects with correct properties' {
            $result = Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            $result[0].UserPrincipalName | Should -Be 'john@contoso.com'
            $result[1].UserPrincipalName | Should -Be 'jane@contoso.com'
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand for retries' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should use retry configuration' {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                param($ScriptBlock)
                & $ScriptBlock
            }

            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

                Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                    $FullName -like '*RetryCount'
                } -Times 1 -Scope It

                Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                    $FullName -like '*RetryWaitInSeconds'
                } -Times 1 -Scope It
        }

        It 'Should check for function interrupts' {
            Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            Should -Invoke -ModuleName $script:ModuleName -CommandName Test-PSFFunctionInterrupt -Times 1 -Exactly
        }
    }

    Context 'Integration scenarios' {
        It 'Should handle empty member list' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { 
                [PSCustomObject]@{ value = @() }
            }

            $result = Get-PSEntraIDAdministrativeUnitMember -InputObject $script:MockAU

            $result | Should -BeNullOrEmpty
        }

        It 'Should work in pipeline chain' {
            $script:MockAU | Get-PSEntraIDAdministrativeUnitMember

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }
}
