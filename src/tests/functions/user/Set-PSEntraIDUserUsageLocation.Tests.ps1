BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Set-PSEntraIDUserUsageLocation' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUsageLocation {
            @{
                'Czech Republic' = 'CZ'
                'Germany'        = 'DE'
                'United States'  = 'US'
                'United Kingdom' = 'GB'
            }
        }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser {
            [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
                DisplayName       = 'Test User'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }
    }

    Context 'Parameter Validation' {
        It 'Should have four parameter sets' {
            $command = Get-Command Set-PSEntraIDUserUsageLocation
            $command.ParameterSets.Name | Should -Contain 'InputObjectUsageLocationCode'
            $command.ParameterSets.Name | Should -Contain 'InputObjectUsageLocationCountry'
            $command.ParameterSets.Name | Should -Contain 'IdentityUsageLocationCode'
            $command.ParameterSets.Name | Should -Contain 'IdentityUsageLocationCountry'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Set-PSEntraIDUserUsageLocation
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have mandatory UsageLocationCode in code parameter sets' {
            $param = (Get-Command Set-PSEntraIDUserUsageLocation).Parameters['UsageLocationCode']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory UsageLocationCountry in country parameter sets' {
            $param = (Get-Command Set-PSEntraIDUserUsageLocation).Parameters['UsageLocationCountry']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }
    }

    Context 'Set usage location by code with InputObject' {
        It 'Should call API with PATCH and usageLocation body' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and
                $Path -eq 'users/00000000-0000-0000-0000-000000000001' -and
                $Body.usageLocation -eq 'CZ'
            }
        }

        It 'Should include Content-Type header' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'DE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }
    }

    Context 'Set usage location by country name with InputObject' {
        It 'Should resolve country name to code via hashtable' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCountry 'Czech Republic' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.usageLocation -eq 'CZ'
            }
        }
    }

    Context 'Set usage location by Identity' {
        It 'Should resolve user and call PATCH with code' {
            Set-PSEntraIDUserUsageLocation -Identity 'user@contoso.com' -UsageLocationCode 'GB' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and $Body.usageLocation -eq 'GB'
            }
        }

        It 'Should resolve user and call PATCH with country name' {
            Set-PSEntraIDUserUsageLocation -Identity 'user@contoso.com' -UsageLocationCountry 'Germany' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.usageLocation -eq 'DE'
            }
        }

        It 'Should handle user not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Set-PSEntraIDUserUsageLocation -Identity 'notfound@contoso.com' -UsageLocationCode 'US' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with PATCH method via InputObject' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'PATCH'
            $result.Url | Should -Be '/users/00000000-0000-0000-0000-000000000001'
        }

        It 'Should return batch request via Identity' {
            $result = Set-PSEntraIDUserUsageLocation -Identity 'user@contoso.com' -UsageLocationCode 'US' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'PATCH'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDUsageLocation for lookup table' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUsageLocation -Times 1 -Exactly
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                $userObj = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = '00000000-0000-0000-0000-000000000001'
                    UserPrincipalName = 'user@contoso.com'
                }

                Set-PSEntraIDUserUsageLocation -InputObject $userObj -UsageLocationCode 'CZ' -WhatIf

                Should -Invoke -CommandName Invoke-EntraRequest -Times 0
            }
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input and call Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $userObj = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = '00000000-0000-0000-0000-000000000001'
                    UserPrincipalName = 'user@contoso.com'
                }

                $userObj | Set-PSEntraIDUserUsageLocation -UsageLocationCode 'CZ' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }
}
