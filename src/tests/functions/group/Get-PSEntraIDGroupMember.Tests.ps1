BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDGroupMember' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 100 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'userPrincipalName', 'mail') }
        } -ParameterFilter { $Name -like '*Select.User' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            @(
                [PSCustomObject]@{ id = 'user-001'; displayName = 'Member 1'; userPrincipalName = 'member1@contoso.com' },
                [PSCustomObject]@{ id = 'user-002'; displayName = 'Member 2'; userPrincipalName = 'member2@contoso.com' }
            )
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject }
        Mock -ModuleName $script:ModuleName Test-PSFParameterBinding { $false }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup {
            [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }
    }

    Context 'Parameter Validation' {
        It 'Should have InputObject and Identity parameter sets' {
            $command = Get-Command Get-PSEntraIDGroupMember
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have OutputType PSMicrosoftEntraID.Users.User' {
            (Get-Command Get-PSEntraIDGroupMember).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.User'
        }

        It 'Should have Owner switch parameter' {
            (Get-Command Get-PSEntraIDGroupMember).Parameters.ContainsKey('Owner') | Should -Be $true
        }

        It 'Should have Filter and AdvancedFilter parameters' {
            $command = Get-Command Get-PSEntraIDGroupMember
            $command.Parameters.ContainsKey('Filter') | Should -Be $true
            $command.Parameters.ContainsKey('AdvancedFilter') | Should -Be $true
        }
    }

    Context 'Get members by InputObject' {
        It 'Should call API with members path' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupMember -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010/members'
            }
        }

        It 'Should call API with owners path when Owner switch specified' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupMember -InputObject $groupObj -Owner

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010/owners'
            }
        }

        It 'Should convert response using ConvertFrom-RestUser' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupMember -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestUser -Times 1
        }
    }

    Context 'Get members by Identity' {
        It 'Should resolve group and call API for members' {
            Get-PSEntraIDGroupMember -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010/members'
            }
        }

        It 'Should get owners when Owner switch and Identity are used' {
            Get-PSEntraIDGroupMember -Identity 'testgroup' -Owner

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010/owners'
            }
        }
    }

    Context 'Group not found handling' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $null }
        }

        It 'Should not call API when group is not found' {
            Get-PSEntraIDGroupMember -Identity 'notfound' -EnableException

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Scope It
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupMember -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
