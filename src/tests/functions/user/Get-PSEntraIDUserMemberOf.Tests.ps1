BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDUserMemberOf' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id          = 'group-id-001'
                displayName = 'IT Department'
                mailNickname = 'it-dept'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestGroup { $InputObject }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Test-PSFParameterBinding { $false }

        $script:MockUser = [PSMicrosoftEntraID.Users.User]::new()
        $script:MockUser.Id = 'user-id-001'
        $script:MockUser.UserPrincipalName = 'john.doe@contoso.com'

        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:MockUser }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter' {
            $param = (Get-Command Get-PSEntraIDUserMemberOf).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Get-PSEntraIDUserMemberOf).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Get-PSEntraIDUserMemberOf).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have OutputType PSMicrosoftEntraID.Groups.Group' {
            (Get-Command Get-PSEntraIDUserMemberOf).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Groups.Group'
        }
    }

    Context 'Get memberOf by Identity' {
        It 'Should resolve identity via Get-PSEntraIDUser' {
            Get-PSEntraIDUserMemberOf -Identity 'john.doe@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should call API with memberOf path' {
            Get-PSEntraIDUserMemberOf -Identity 'john.doe@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -like 'users/*/memberOf'
            }
        }

        It 'Should handle multiple identities' {
            Get-PSEntraIDUserMemberOf -Identity @('user1@contoso.com', 'user2@contoso.com')
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 2 -Exactly
        }

        It 'Should convert response using ConvertFrom-RestGroup' {
            Get-PSEntraIDUserMemberOf -Identity 'john.doe@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestGroup
        }
    }

    Context 'Get memberOf by InputObject' {
        It 'Should call API with user Id in path' {
            Get-PSEntraIDUserMemberOf -InputObject $script:MockUser
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "users/$($script:MockUser.Id)/memberOf"
            }
        }

        It 'Should not call Get-PSEntraIDUser for InputObject' {
            Get-PSEntraIDUserMemberOf -InputObject $script:MockUser
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 0 -Exactly
        }

        It 'Should accept pipeline input' {
            $script:MockUser | Get-PSEntraIDUserMemberOf
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'Filter support' {
        It 'Should pass filter query parameter when Filter is specified with Identity' {
            Mock -ModuleName $script:ModuleName Test-PSFParameterBinding { $true } -ParameterFilter { $ParameterName -eq 'Filter' }

            Get-PSEntraIDUserMemberOf -Identity 'john.doe@contoso.com' -Filter "displayName eq 'IT'"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq "displayName eq 'IT'"
            }
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDUserMemberOf -Identity 'test@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand for retries' {
            Get-PSEntraIDUserMemberOf -Identity 'test@contoso.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }
}
