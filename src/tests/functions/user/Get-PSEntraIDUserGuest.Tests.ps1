BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDUserGuest' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'userPrincipalName', 'mail', 'userType') }
        }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id                = 'guest-id-001'
                displayName       = 'Guest User'
                userPrincipalName = 'guest_contoso.com#EXT#@tenant.onmicrosoft.com'
                mail              = 'guest@contoso.com'
                userType          = 'Guest'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUserGuest { $InputObject }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject }
        Mock -ModuleName $script:ModuleName Add-GuestFilter { "$args and userType eq 'Guest'" }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Name parameter' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['Name']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory CompanyName parameter' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['CompanyName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Filter parameter' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory All parameter' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['All']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for Identity' {
            $param = (Get-Command Get-PSEntraIDUserGuest).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have OutputType PSMicrosoftEntraID.Users.UserGuest' {
            (Get-Command Get-PSEntraIDUserGuest).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.UserGuest'
        }
    }

    Context 'Get guest user by Identity' {
        It 'Should call API with users path' {
            Get-PSEntraIDUserGuest -Identity 'guest@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -like 'users*'
            }
        }

        It 'Should return guest user object' {
            $result = Get-PSEntraIDUserGuest -Identity 'guest@contoso.com'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDUserGuest -Identity @('guest1@contoso.com', 'guest2@contoso.com')
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 2 -Exactly
        }

        It 'Should use ConvertFrom-RestUserGuest for response' {
            Get-PSEntraIDUserGuest -Identity 'guest@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestUserGuest
        }
    }

    Context 'Get guest users by Filter' {
        It 'Should combine filter with guest type filter' {
            Get-PSEntraIDUserGuest -Filter "companyName eq 'Partner'"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Add-GuestFilter -Times 1
        }

        It 'Should use ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDUserGuest -Filter "startswith(displayName,'G')" -AdvancedFilter
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }
    }

    Context 'Get guest users by CompanyName' {
        It 'Should build companyName filter with guest filter' {
            Get-PSEntraIDUserGuest -CompanyName 'Partner'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }

        It 'Should add disabled filter when Disabled is present' {
            Get-PSEntraIDUserGuest -CompanyName 'Partner' -Disabled
            Should -Invoke -ModuleName $script:ModuleName -CommandName Add-GuestFilter -ParameterFilter {
                $CurrentFilter -like '*accountEnabled eq false*'
            }
        }
    }

    Context 'Get all guest users' {
        It 'Should add guest userType filter' {
            Get-PSEntraIDUserGuest -All
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq "userType eq 'Guest'"
            }
        }

        It 'Should add disabled filter with Disabled switch' {
            Get-PSEntraIDUserGuest -All -Disabled
            Should -Invoke -ModuleName $script:ModuleName -CommandName Add-GuestFilter
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDUserGuest -Identity 'guest@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand' {
            Get-PSEntraIDUserGuest -Identity 'guest@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }
}
