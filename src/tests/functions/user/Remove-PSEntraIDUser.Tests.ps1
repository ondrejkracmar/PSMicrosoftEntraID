BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Remove-PSEntraIDUser' -Tag 'Unit' {

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
        It 'Should have InputObject and Identity parameter sets' {
            $command = Get-Command Remove-PSEntraIDUser
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-PSEntraIDUser
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have Force parameter' {
            (Get-Command Remove-PSEntraIDUser).Parameters.ContainsKey('Force') | Should -Be $true
        }

        It 'Should have PassThru parameter' {
            (Get-Command Remove-PSEntraIDUser).Parameters.ContainsKey('PassThru') | Should -Be $true
        }
    }

    Context 'Delete user by InputObject' {
        It 'Should call API with DELETE method' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Remove-PSEntraIDUser -InputObject $userObj -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and $Path -eq 'users/00000000-0000-0000-0000-000000000001'
            }
        }
    }

    Context 'Delete user by Identity' {
        It 'Should resolve user and call DELETE' {
            Remove-PSEntraIDUser -Identity 'user@contoso.com' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and $Path -eq 'users/00000000-0000-0000-0000-000000000001'
            }
        }

        It 'Should handle user not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Remove-PSEntraIDUser -Identity 'notfound@contoso.com' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }

        It 'Should not throw when user not found without EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            { Remove-PSEntraIDUser -Identity 'notfound@contoso.com' -Force -Confirm:$false } | Should -Not -Throw

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with DELETE method via InputObject' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Remove-PSEntraIDUser -InputObject $userObj -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
            $result.Url | Should -Be '/users/00000000-0000-0000-0000-000000000001'
        }

        It 'Should return batch request via Identity' {
            $result = Remove-PSEntraIDUser -Identity 'user@contoso.com' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Remove-PSEntraIDUser -InputObject $userObj -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Connection and error handling' {
        It 'Should assert Entra connection' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Remove-PSEntraIDUser -InputObject $userObj -Force -Confirm:$false

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
                Remove-PSEntraIDUser -InputObject $userObj -WhatIf
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input for InputObject parameter' {
            InModuleScope $script:ModuleName {
                $userObj = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = '00000000-0000-0000-0000-000000000001'
                    UserPrincipalName = 'user@contoso.com'
                    Mail              = 'user@contoso.com'
                }
                { $userObj | Remove-PSEntraIDUser -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }
}
