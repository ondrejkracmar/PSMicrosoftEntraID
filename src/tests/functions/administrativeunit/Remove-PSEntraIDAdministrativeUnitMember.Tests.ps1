BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Remove-PSEntraIDAdministrativeUnitMember' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }

        # Mock administrative unit
        $script:MockAU = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
            Id = 'au-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test AU'
        }

        # Mock user
        $script:MockUser = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.User'
            Id = 'user-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test User'
        }

        # Mock group
        $script:MockGroup = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
            Id = 'group-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test Group'
        }

        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $script:MockAU }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:MockUser }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $script:MockGroup }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnitMember).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObjectUser' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnitMember).Parameters['InputObjectUser']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnitMember).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Remove user member by Identity' {
        It 'Should call API with correct path' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members/$($script:MockUser.Id)/`$ref"
            }
        }

        It 'Should use DELETE method' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete'
            }
        }

        It 'Should call Get-PSEntraIDAdministrativeUnit' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDUser' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should handle multiple users' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User @('user1@contoso.com', 'user2@contoso.com') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Remove group member by Identity' {
        It 'Should call API with correct path for group' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Group 'Test Group' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members/$($script:MockGroup.Id)/`$ref"
            }
        }

        It 'Should call Get-PSEntraIDGroup' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Group 'Test Group' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1 -Exactly
        }
    }

    Context 'Remove device member by Identity' {
        It 'Should call API with correct path for device' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Device 'device-id' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members/device-id/`$ref"
            }
        }
    }

    Context 'Remove member with InputObject' {
        It 'Should accept user object from pipeline' {
            $script:MockUser | Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should not call Get-PSEntraIDUser when using InputObjectUser' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObjectUser $script:MockUser -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 0 -Exactly
        }

        It 'Should handle multiple objects from pipeline' {
            @($script:MockUser, $script:MockUser) | Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified' {
            $result = Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should throw error when AU not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $null }

            Remove-PSEntraIDAdministrativeUnitMember -Identity 'NonExistent' -User 'test@contoso.com' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }

        It 'Should throw error when user not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'notfound@contoso.com' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand' {
            Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'WhatIf execution' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -WhatIf
            }
            Should -Invoke -CommandName Invoke-EntraRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Pipeline input with typed object' {
        It 'Should accept pipeline input and invoke Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $pipelineUser = [PSCustomObject]@{
                    PSTypeName  = 'PSMicrosoftEntraID.Users.User'
                    Id          = 'user-pipeline-1234'
                    DisplayName = 'Pipeline User'
                }
                $pipelineUser | Remove-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Force -Confirm:$false
            }
            Should -Invoke -CommandName Invoke-PSFProtectedCommand -ModuleName $script:ModuleName -Times 1
        }
    }
}
