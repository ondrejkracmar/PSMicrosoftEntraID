BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Remove-PSEntraIDGroupMember' -Tag 'Unit' {

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
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup {
            [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
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
        It 'Should have IdentityInputObject and IdentityUser parameter sets' {
            $command = Get-Command Remove-PSEntraIDGroupMember
            $command.ParameterSets.Name | Should -Contain 'IdentityInputObject'
            $command.ParameterSets.Name | Should -Contain 'IdentityUser'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-PSEntraIDGroupMember
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Remove-PSEntraIDGroupMember).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }
    }

    Context 'Remove member by User string' {
        It 'Should resolve group and user, then call DELETE with members/$ref path' {
            Remove-PSEntraIDGroupMember -Identity 'testgroup' -User 'user@contoso.com' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and $Path -like 'groups/*/members/*/$ref'
            }
        }

        It 'Should handle user not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Remove-PSEntraIDGroupMember -Identity 'testgroup' -User 'notfound@contoso.com' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }
    }

    Context 'Remove member by InputObject' {
        It 'Should call DELETE with members/$ref path using InputObject Id' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            Remove-PSEntraIDGroupMember -Identity 'testgroup' -InputObject $userObj -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010/members/00000000-0000-0000-0000-000000000001/$ref'
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with DELETE method for User' {
            $result = Remove-PSEntraIDGroupMember -Identity 'testgroup' -User 'user@contoso.com' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
            $result.Url | Should -BeLike '*/members/*/$ref'
        }

        It 'Should return batch request for InputObject' {
            $userObj = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '00000000-0000-0000-0000-000000000001'
                UserPrincipalName = 'user@contoso.com'
            }

            $result = Remove-PSEntraIDGroupMember -Identity 'testgroup' -InputObject $userObj -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            Remove-PSEntraIDGroupMember -Identity 'testgroup' -User 'user@contoso.com' -PassThru

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

            Remove-PSEntraIDGroupMember -Identity 'testgroup' -InputObject $userObj -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Remove-PSEntraIDGroupMember -Identity 'testgroup' -User 'user@contoso.com' -WhatIf
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
                { $userObj | Remove-PSEntraIDGroupMember -Identity 'testgroup' -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }
}
