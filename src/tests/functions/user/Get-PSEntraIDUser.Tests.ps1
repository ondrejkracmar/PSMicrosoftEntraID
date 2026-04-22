BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDUser' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'userPrincipalName', 'mail') }
        }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id                = 'user-id-001'
                displayName       = 'John Doe'
                userPrincipalName = 'john.doe@contoso.com'
                mail              = 'john.doe@contoso.com'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Name parameter' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['Name']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory CompanyName parameter' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['CompanyName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Filter parameter' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory All parameter' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['All']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for Identity' {
            $param = (Get-Command Get-PSEntraIDUser).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have OutputType PSMicrosoftEntraID.Users.User' {
            (Get-Command Get-PSEntraIDUser).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.User'
        }
    }

    Context 'Get user by Identity' {
        It 'Should call API with correct path' {
            Get-PSEntraIDUser -Identity 'john.doe@contoso.com'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -like 'users/*'
            }
        }

        It 'Should return user object' {
            $result = Get-PSEntraIDUser -Identity 'john.doe@contoso.com'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDUser -Identity @('user1@contoso.com', 'user2@contoso.com')
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 2 -Exactly
        }

        It 'Should first try mail query to resolve user' {
            Get-PSEntraIDUser -Identity 'john.doe@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq "mail eq 'john.doe@contoso.com'"
            }
        }

        It 'Should process pipeline input' {
            @('user1@contoso.com', 'user2@contoso.com') | Get-PSEntraIDUser
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 2 -Exactly
        }
    }

    Context 'Get user by Name' {
        It 'Should call API with displayName/givenName/surname filter' {
            Get-PSEntraIDUser -Name 'John'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -like "startswith(displayName,'John'*"
            }
        }

        It 'Should handle multiple names' {
            Get-PSEntraIDUser -Name @('John', 'Jane')
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 2 -Exactly
        }
    }

    Context 'Get user by Filter' {
        It 'Should pass custom filter to API' {
            Get-PSEntraIDUser -Filter "department eq 'IT'"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq "department eq 'IT'"
            }
        }

        It 'Should use ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDUser -Filter "startswith(displayName,'J')" -AdvancedFilter
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }

        It 'Should not set ConsistencyLevel without AdvancedFilter' {
            Get-PSEntraIDUser -Filter "department eq 'IT'"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $null -eq $Header -or $null -eq $Header.ConsistencyLevel
            }
        }
    }

    Context 'Get user by CompanyName' {
        It 'Should build companyName in filter' {
            Get-PSEntraIDUser -CompanyName 'Contoso'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -like "companyName in*'Contoso'*"
            }
        }

        It 'Should add disabled filter when Disabled switch is present' {
            Get-PSEntraIDUser -CompanyName 'Contoso' -Disabled
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -like '*accountEnabled eq false*'
            }
        }

        It 'Should use ConsistencyLevel header' {
            Get-PSEntraIDUser -CompanyName 'Contoso'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }
    }

    Context 'Get all users' {
        It 'Should call API with users path' {
            Get-PSEntraIDUser -All
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'users'
            }
        }

        It 'Should include count and top query parameters' {
            Get-PSEntraIDUser -All
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true' -and $Query.'$top' -eq 999
            }
        }

        It 'Should add disabled filter with Disabled switch' {
            Get-PSEntraIDUser -All -Disabled
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq 'accountEnabled eq false'
            }
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDUser -Identity 'test@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand for retries' {
            Get-PSEntraIDUser -Identity 'test@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should convert response using ConvertFrom-RestUser' {
            Get-PSEntraIDUser -Identity 'test@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestUser
        }
    }
}
