BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'New-PSEntraIDUser' -Tag 'Unit' {

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

        $script:TestPassword = ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory DisplayName parameter' {
            $param = (Get-Command New-PSEntraIDUser).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory UserPrincipalName parameter' {
            $param = (Get-Command New-PSEntraIDUser).Parameters['UserPrincipalName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory MailNickname parameter' {
            $param = (Get-Command New-PSEntraIDUser).Parameters['MailNickname']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Password as SecureString' {
            $param = (Get-Command New-PSEntraIDUser).Parameters['Password']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
            $param.ParameterType.Name | Should -Be 'SecureString'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-PSEntraIDUser
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should accept pipeline input by property name' {
            $param = (Get-Command New-PSEntraIDUser).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipelineByPropertyName | Should -Contain $true
        }
    }

    Context 'Create user with required parameters' {
        It 'Should call API with POST method' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Post' -and $Path -eq 'users'
            }
        }

        It 'Should build body with required properties' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'John Doe' -and
                $Body.userPrincipalName -eq 'john.doe@contoso.com' -and
                $Body.mailNickname -eq 'jdoe' -and
                $Body.accountEnabled -eq $true -and
                $null -ne $Body.passwordProfile
            }
        }

        It 'Should include Content-Type header' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }
    }

    Context 'Create user with optional parameters' {
        It 'Should include GivenName and Surname in body' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -GivenName 'John' -Surname 'Doe' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.givenName -eq 'John' -and $Body.surname -eq 'Doe'
            }
        }

        It 'Should include UsageLocation in body' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -UsageLocation 'CZ' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.usageLocation -eq 'CZ'
            }
        }

        It 'Should include job details in body' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -JobTitle 'Engineer' -Department 'IT' -CompanyName 'Contoso' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.jobTitle -eq 'Engineer' -and $Body.department -eq 'IT' -and $Body.companyName -eq 'Contoso'
            }
        }

        It 'Should include AccountEnabled as false' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -AccountEnabled $false -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.accountEnabled -eq $false
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified' {
            $result = New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Be '/users'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should include body in batch request' {
            $result = New-PSEntraIDUser -DisplayName 'John Doe' -UserPrincipalName 'john.doe@contoso.com' -MailNickname 'jdoe' -Password $script:TestPassword -PassThru

            $result.Body.displayName | Should -Be 'John Doe'
            $result.Body.userPrincipalName | Should -Be 'john.doe@contoso.com'
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            New-PSEntraIDUser -DisplayName 'Test' -UserPrincipalName 'test@contoso.com' -MailNickname 'test' -Password $script:TestPassword -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand' {
            New-PSEntraIDUser -DisplayName 'Test' -UserPrincipalName 'test@contoso.com' -MailNickname 'test' -Password $script:TestPassword -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }
}
