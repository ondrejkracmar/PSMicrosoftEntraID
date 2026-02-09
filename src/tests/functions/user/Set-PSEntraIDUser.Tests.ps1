BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Set-PSEntraIDUser' -Tag 'Unit' {

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
        It 'Should have InputObjectUpdateUser and IdentityUpdateUser parameter sets' {
            $command = Get-Command Set-PSEntraIDUser
            $command.ParameterSets.Name | Should -Contain 'InputObjectUpdateUser'
            $command.ParameterSets.Name | Should -Contain 'IdentityUpdateUser'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Set-PSEntraIDUser
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have all expected user property parameters' {
            $command = Get-Command Set-PSEntraIDUser
            $expectedParams = @('DisplayName', 'GivenName', 'Surname', 'JobTitle', 'Department',
                'CompanyName', 'OfficeLocation', 'City', 'PostalCode', 'State', 'Country',
                'MobilePhone', 'BusinessPhones', 'Mail', 'ProxyAddresses', 'UserPrincipalName',
                'MailNickname', 'FaxNumber', 'EmployeeId', 'OtherMails', 'UsageLocation',
                'PreferredLanguage', 'AccountEnabled', 'Password')
            foreach ($param in $expectedParams) {
                $command.Parameters.ContainsKey($param) | Should -Be $true
            }
        }

        It 'Should have PassThru parameter' {
            (Get-Command Set-PSEntraIDUser).Parameters.ContainsKey('PassThru') | Should -Be $true
        }
    }

    Context 'Update user by InputObject' {
        It 'Should call API with PATCH method' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUser -InputObject $userObj -JobTitle 'Manager' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and $Path -eq 'users/00000000-0000-0000-0000-000000000001'
            }
        }

        It 'Should include only specified properties in body' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUser -InputObject $userObj -JobTitle 'Manager' -Department 'IT' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.jobTitle -eq 'Manager' -and $Body.department -eq 'IT'
            }
        }

        It 'Should include Content-Type header' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUser -InputObject $userObj -City 'Prague' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }
    }

    Context 'Update user by Identity' {
        It 'Should resolve user and call PATCH' {
            Set-PSEntraIDUser -Identity 'user@contoso.com' -Department 'HR' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and $Body.department -eq 'HR'
            }
        }

        It 'Should handle user not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Set-PSEntraIDUser -Identity 'notfound@contoso.com' -Department 'HR' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }

        It 'Should not call API when user not found without EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Set-PSEntraIDUser -Identity 'notfound@contoso.com' -Department 'HR' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Password with passwordProfile' {
        It 'Should build passwordProfile body when Password specified' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }
            $securePass = ConvertTo-SecureString 'TestP@ss123!' -AsPlainText -Force

            Set-PSEntraIDUser -InputObject $userObj -Password $securePass -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.passwordProfile -ne $null -and $Body.passwordProfile.password -eq 'TestP@ss123!'
            }
        }

        It 'Should include ForceChangePasswordNextSignIn in passwordProfile' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }
            $securePass = ConvertTo-SecureString 'TestP@ss123!' -AsPlainText -Force

            Set-PSEntraIDUser -InputObject $userObj -Password $securePass -ForceChangePasswordNextSignIn $true -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.passwordProfile.forceChangePasswordNextSignIn -eq $true
            }
        }
    }

    Context 'Multiple property updates' {
        It 'Should include multiple properties in body' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUser -InputObject $userObj -DisplayName 'New Name' -City 'Berlin' -Country 'DE' -UsageLocation 'DE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'New Name' -and
                $Body.city -eq 'Berlin' -and
                $Body.country -eq 'DE' -and
                $Body.usageLocation -eq 'DE'
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with PATCH method' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Set-PSEntraIDUser -InputObject $userObj -JobTitle 'Director' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'PATCH'
            $result.Url | Should -Be '/users/00000000-0000-0000-0000-000000000001'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Set-PSEntraIDUser -InputObject $userObj -JobTitle 'Director' -PassThru

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

            Set-PSEntraIDUser -InputObject $userObj -Department 'Sales' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
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

                Set-PSEntraIDUser -InputObject $userObj -JobTitle 'Manager' -WhatIf

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

                $userObj | Set-PSEntraIDUser -JobTitle 'Manager' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }
}
