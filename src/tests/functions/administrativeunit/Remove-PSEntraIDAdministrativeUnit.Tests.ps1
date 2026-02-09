BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Remove-PSEntraIDAdministrativeUnit' -Tag 'Unit' {

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

        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $script:MockAU }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter for InputObject parameter set' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnit).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnit).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should accept string array for Identity parameter' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Remove-PSEntraIDAdministrativeUnit).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Remove administrative unit by InputObject' {
        It 'Should call API with correct path' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)"
            }
        }

        It 'Should use DELETE method' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete'
            }
        }

        It 'Should execute the delete operation' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should accept object from pipeline' {
            $script:MockAU | Remove-PSEntraIDAdministrativeUnit -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle multiple objects from pipeline' {
            @($script:MockAU, $script:MockAU) | Remove-PSEntraIDAdministrativeUnit -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should not call Get-PSEntraIDAdministrativeUnit when using InputObject' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 0 -Exactly
        }
    }

    Context 'Remove administrative unit by Identity' {
        It 'Should call Get-PSEntraIDAdministrativeUnit to resolve identity' {
            Remove-PSEntraIDAdministrativeUnit -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 1 -Exactly
        }

        It 'Should call API with correct path' {
            Remove-PSEntraIDAdministrativeUnit -Identity 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)"
            }
        }

        It 'Should handle multiple identities' {
            Remove-PSEntraIDAdministrativeUnit -Identity @('AU1', 'AU2') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should throw error when AU not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $null }

            Remove-PSEntraIDAdministrativeUnit -Identity 'NonExistent' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified with InputObject' {
            $result = Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
            $result.Url | Should -Match 'administrativeUnits'
        }

        It 'Should return batch request when PassThru is specified with Identity' {
            $result = Remove-PSEntraIDAdministrativeUnit -Identity 'Test AU' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'WhatIf and Confirm support' {
        It 'Should support WhatIf' {
            $command = Get-Command Remove-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It 'Should support Confirm' {
            $command = Get-Command Remove-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should use Invoke-PSFProtectedCommand for confirmation' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use retry configuration' {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                param($ScriptBlock)
                & $ScriptBlock
            }

            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryCount'
            } -Times 1 -Scope It

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryWaitInSeconds'
            } -Times 1 -Scope It
        }

        It 'Should use Force switch correctly' {
            Remove-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Force

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
                Remove-PSEntraIDAdministrativeUnit -Identity 'Test AU' -WhatIf
            }
            Should -Invoke -CommandName Invoke-EntraRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Pipeline input with typed object' {
        It 'Should accept pipeline input and invoke Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $pipelineObj = [PSCustomObject]@{
                    PSTypeName  = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
                    Id          = 'au-pipeline-1234'
                    DisplayName = 'Pipeline AU'
                }
                $pipelineObj | Remove-PSEntraIDAdministrativeUnit -Force -Confirm:$false
            }
            Should -Invoke -CommandName Invoke-PSFProtectedCommand -ModuleName $script:ModuleName -Times 1
        }
    }
}
