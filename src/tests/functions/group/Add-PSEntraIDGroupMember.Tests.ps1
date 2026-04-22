BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Add-PSEntraIDGroupMember Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should have EnableException switch parameter' {
            $command = Get-Command Add-PSEntraIDGroupMember
            $param = $command.Parameters['EnableException']
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType | Should -Be ([switch])
        }

        It 'Should have User parameter' {
            $command = Get-Command Add-PSEntraIDGroupMember
            $param = $command.Parameters['User']
            $param | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling - User Identity' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue { 
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService { 
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should continue processing valid users when one user not found and EnableException is false' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -eq 'nonexistent@test.com') { return $null }
                return [PSCustomObject]@{ 
                    Id = "id-$Identity"
                    UserPrincipalName = $Identity
                    Mail = $Identity
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { }

            $users = @('valid1@test.com', 'nonexistent@test.com', 'valid2@test.com')
            
            { Add-PSEntraIDGroupMember -Identity 'test-group' -User $users -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 3
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 0
        }

        It 'Should throw when user not found and EnableException is true' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { return $null }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { 
                throw "User not found"
            }

            { Add-PSEntraIDGroupMember -Identity 'test-group' -User 'nonexistent@test.com' -EnableException -Confirm:$false } | Should -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 1
        }

        It 'Should process all valid users and skip invalid ones when EnableException is false' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -match 'invalid') { return $null }
                return [PSCustomObject]@{ 
                    Id = "id-$Identity"
                    UserPrincipalName = $Identity
                    Mail = $Identity
                }
            }

            $users = @('valid1@test.com', 'invalid1@test.com', 'valid2@test.com', 'invalid2@test.com', 'valid3@test.com')
            
            { Add-PSEntraIDGroupMember -Identity 'test-group' -User $users -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 5
        }
    }

    Context 'IdentityInputObject single user' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should add a single InputObject user via POST to members/$ref' {
            InModuleScope $script:ModuleName {
                $user = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user1@test.com'
                    Mail              = 'user1@test.com'
                }
                { Add-PSEntraIDGroupMember -Identity 'group-id' -InputObject $user -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'IdentityInputObject multiple users' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Step-Array { param($InputObject) return ,$InputObject }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should add multiple InputObject users via PATCH with members@odata.bind' {
            InModuleScope $script:ModuleName {
                $users = @(
                    [PSCustomObject]@{
                        PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                        Id                = 'user-id-1'
                        UserPrincipalName = 'user1@test.com'
                        Mail              = 'user1@test.com'
                    },
                    [PSCustomObject]@{
                        PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                        Id                = 'user-id-2'
                        UserPrincipalName = 'user2@test.com'
                        Mail              = 'user2@test.com'
                    }
                )
                { Add-PSEntraIDGroupMember -Identity 'group-id' -InputObject $users -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                [PSCustomObject]@{
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user@domain.com'
                    Mail              = 'user@domain.com'
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand { }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user@domain.com' -WhatIf
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 0
        }
    }

    Context 'Connection verification' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                [PSCustomObject]@{
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user@domain.com'
                    Mail              = 'user@domain.com'
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should call Assert-EntraConnection during execution' {
            InModuleScope $script:ModuleName {
                Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user@domain.com' -Force -Confirm:$false
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Assert-EntraConnection -Times 1
        }
    }

    Context 'Pipeline input' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should accept pipeline input for InputObject parameter' {
            InModuleScope $script:ModuleName {
                $user = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user1@test.com'
                    Mail              = 'user1@test.com'
                }
                { $user | Add-PSEntraIDGroupMember -Identity 'group-id' -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }
}
