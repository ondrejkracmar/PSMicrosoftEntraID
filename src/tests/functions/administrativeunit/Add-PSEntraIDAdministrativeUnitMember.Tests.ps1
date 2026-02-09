BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Add-PSEntraIDAdministrativeUnitMember' -Tag 'Unit' {

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
            UserPrincipalName = 'testuser@contoso.com'
        }

        # Mock group
        $script:MockGroup = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Groups.Group'
            Id = 'group-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test Group'
        }

        # Mock device
        $script:MockDevice = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Devices.Device'
            Id = 'device-12345678-1234-1234-1234-123456789012'
            DisplayName = 'Test Device'
        }

        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $script:MockAU }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:MockUser }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $script:MockGroup }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory User parameter for IdentityUser parameter set' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['User']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Group parameter for IdentityGroup parameter set' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['Group']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Device parameter for IdentityDevice parameter set' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['Device']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory InputObject parameter for IdentityInputObject parameter set' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Add-PSEntraIDAdministrativeUnitMember).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Add user member by Identity' {
        It 'Should call Get-PSEntraIDAdministrativeUnit to resolve AU' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'testuser@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDUser to resolve user' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'testuser@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should call API with correct path' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'testuser@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)/members/`$ref"
            }
        }

        It 'Should use POST method' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'testuser@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Post'
            }
        }

        It 'Should call API with correct body structure' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'testuser@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/$($script:MockUser.Id)"
            }
        }

        It 'Should handle multiple users' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User @('user1@contoso.com', 'user2@contoso.com') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should throw error when AU not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $null }

            Add-PSEntraIDAdministrativeUnitMember -Identity 'NonExistent' -User 'test@contoso.com' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }

        It 'Should throw error when user not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'notfound@contoso.com' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'Add group member by Identity' {
        It 'Should call Get-PSEntraIDGroup to resolve group' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Group 'Test Group' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1 -Exactly
        }

        It 'Should call API with correct body for group' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Group 'Test Group' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/$($script:MockGroup.Id)"
            }
        }

        It 'Should handle multiple groups' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Group @('Group1', 'Group2') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Add device member by Identity' {
        It 'Should call API with correct body for device' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Device 'device-id' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/device-id"
            }
        }

        It 'Should handle multiple devices' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Device @('device1', 'device2') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Add user member with InputObject' {
        It 'Should accept user object from pipeline' {
            $script:MockUser | Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call API with correct body using InputObject' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObject $script:MockUser -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/$($script:MockUser.Id)"
            }
        }

        It 'Should handle multiple user objects from pipeline' {
            @($script:MockUser, $script:MockUser) | Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should not call Get-PSEntraIDUser when using InputObject' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObject $script:MockUser -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 0 -Exactly
        }
    }

    Context 'Add group member with InputObject' {
        It 'Should accept group object' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObjectGroup $script:MockGroup -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/$($script:MockGroup.Id)"
            }
        }

        It 'Should not call Get-PSEntraIDGroup when using InputObjectGroup' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObjectGroup $script:MockGroup -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 0 -Exactly
        }
    }

    Context 'Add device member with InputObject' {
        It 'Should accept device object' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -InputObjectDevice $script:MockDevice -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.'@odata.id' -eq "https://graph.microsoft.com/v1.0/directoryObjects/$($script:MockDevice.Id)"
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified' {
            $result = Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'members/\$ref'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should include body in batch request' {
            $result = Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -PassThru

            $result.Body.'@odata.id' | Should -Match 'directoryObjects/'
        }
    }

    Context 'WhatIf and Confirm support' {
        It 'Should support WhatIf' {
            $command = Get-Command Add-PSEntraIDAdministrativeUnitMember
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It 'Should support Confirm' {
            $command = Get-Command Add-PSEntraIDAdministrativeUnitMember
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should use Invoke-PSFProtectedCommand for confirmation' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use retry configuration' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryCount'
            } -Times 1 -Scope It

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryWaitInSeconds'
            } -Times 1 -Scope It
        }

        It 'Should use Force switch correctly' {
            Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -Force

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
                Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -User 'test@contoso.com' -WhatIf
            }
            Should -Invoke -CommandName Invoke-EntraRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Pipeline input with typed object' {
        It 'Should accept pipeline input and invoke Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $pipelineUser = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'user-pipeline-1234'
                    DisplayName       = 'Pipeline User'
                    UserPrincipalName = 'pipeline@contoso.com'
                }
                $pipelineUser | Add-PSEntraIDAdministrativeUnitMember -Identity 'Test AU' -Force -Confirm:$false
            }
            Should -Invoke -CommandName Invoke-PSFProtectedCommand -ModuleName $script:ModuleName -Times 1
        }
    }
}
