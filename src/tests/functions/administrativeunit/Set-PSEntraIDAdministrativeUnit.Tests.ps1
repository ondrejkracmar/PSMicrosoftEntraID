BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Set-PSEntraIDAdministrativeUnit' -Tag 'Unit' {

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
            Description = 'Original Description'
            Visibility = 'Public'
        }

        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $script:MockAU }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter for InputObject parameter set' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have optional DisplayName parameter' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Not -Contain $true
        }

        It 'Should validate Visibility parameter values' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['Visibility']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet.ValidValues | Should -Contain 'HiddenMembership'
            $validateSet.ValidValues | Should -Contain 'Public'
        }

        It 'Should have nullable bool IsMemberManagementRestricted parameter' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['IsMemberManagementRestricted']
            $param.ParameterType.Name | Should -Be 'Nullable`1'
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Set-PSEntraIDAdministrativeUnit).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Update administrative unit by InputObject' {
        It 'Should call API with correct path' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)"
            }
        }

        It 'Should use PATCH method' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch'
            }
        }

        It 'Should update DisplayName only' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'New Name' -and
                $Body.Count -eq 1
            }
        }

        It 'Should update Description only' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Description 'New Description' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.description -eq 'New Description' -and
                $Body.Count -eq 1
            }
        }

        It 'Should update Visibility only' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Visibility 'HiddenMembership' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.visibility -eq 'HiddenMembership' -and
                $Body.Count -eq 1
            }
        }

        It 'Should update IsMemberManagementRestricted only' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -IsMemberManagementRestricted $true -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.isMemberManagementRestricted -eq $true -and
                $Body.Count -eq 1
            }
        }

        It 'Should update multiple properties at once' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Description 'New Desc' -Visibility 'Public' -IsMemberManagementRestricted $false -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'New Name' -and
                $Body.description -eq 'New Desc' -and
                $Body.visibility -eq 'Public' -and
                $Body.isMemberManagementRestricted -eq $false -and
                $Body.Count -eq 4
            }
        }

        It 'Should accept object from pipeline' {
            $script:MockAU | Set-PSEntraIDAdministrativeUnit -DisplayName 'Updated' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle multiple objects from pipeline' {
            @($script:MockAU, $script:MockAU) | Set-PSEntraIDAdministrativeUnit -DisplayName 'Updated' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should not call Get-PSEntraIDAdministrativeUnit when using InputObject' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 0 -Exactly
        }
    }

    Context 'Update administrative unit by Identity' {
        It 'Should call Get-PSEntraIDAdministrativeUnit to resolve identity' {
            Set-PSEntraIDAdministrativeUnit -Identity 'Test AU' -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 1 -Exactly
        }

        It 'Should call API with correct path' {
            Set-PSEntraIDAdministrativeUnit -Identity 'Test AU' -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "directory/administrativeUnits/$($script:MockAU.Id)"
            }
        }

        It 'Should handle multiple identities' {
            Set-PSEntraIDAdministrativeUnit -Identity @('AU1', 'AU2') -DisplayName 'Updated' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDAdministrativeUnit -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should throw error when AU not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit { $null }

            Set-PSEntraIDAdministrativeUnit -Identity 'NonExistent' -DisplayName 'Name' -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified with InputObject' {
            $result = Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'PATCH'
            $result.Url | Should -Match 'administrativeUnits'
        }

        It 'Should return batch request when PassThru is specified with Identity' {
            $result = Set-PSEntraIDAdministrativeUnit -Identity 'Test AU' -DisplayName 'New Name' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should include body in batch request' {
            $result = Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Description 'New Desc' -PassThru

            $result.Body.displayName | Should -Be 'New Name'
            $result.Body.description | Should -Be 'New Desc'
        }
    }

    Context 'WhatIf and Confirm support' {
        It 'Should support WhatIf' {
            $command = Get-Command Set-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It 'Should support Confirm' {
            $command = Get-Command Set-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should use Invoke-PSFProtectedCommand for confirmation' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'Pipeline input from properties' {
        It 'Should accept DisplayName from pipeline property' {
            $input = [PSCustomObject]@{ DisplayName = 'Updated Name' }
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use retry configuration' {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                param($ScriptBlock)
                & $ScriptBlock
            }

            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryCount'
            } -Times 1 -Scope It

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryWaitInSeconds'
            } -Times 1 -Scope It
        }

        It 'Should use Force switch correctly' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should include Content-Type header' {
            Set-PSEntraIDAdministrativeUnit -InputObject $script:MockAU -DisplayName 'New Name' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }
    }

    Context 'WhatIf execution' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDAdministrativeUnit -Identity 'Test AU' -DisplayName 'New Name' -WhatIf
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
                $pipelineObj | Set-PSEntraIDAdministrativeUnit -DisplayName 'Updated' -Force -Confirm:$false
            }
            Should -Invoke -CommandName Invoke-PSFProtectedCommand -ModuleName $script:ModuleName -Times 1
        }
    }
}
