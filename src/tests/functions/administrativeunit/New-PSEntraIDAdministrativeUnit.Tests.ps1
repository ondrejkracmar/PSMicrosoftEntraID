BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'New-PSEntraIDAdministrativeUnit' -Tag 'Unit' {

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
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory DisplayName parameter' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for DisplayName' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipelineByPropertyName | Should -Contain $true
        }

        It 'Should have optional Description parameter' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['Description']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Not -Contain $true
        }

        It 'Should validate Visibility parameter values' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['Visibility']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet.ValidValues | Should -Contain 'HiddenMembership'
            $validateSet.ValidValues | Should -Contain 'Public'
        }

        It 'Should have bool IsMemberManagementRestricted parameter with default false' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['IsMemberManagementRestricted']
            $param.ParameterType.Name | Should -Be 'Boolean'
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command New-PSEntraIDAdministrativeUnit).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Create administrative unit with required parameters' {
        It 'Should call API with correct path' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits'
            }
        }

        It 'Should use POST method' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Post'
            }
        }

        It 'Should call API with correct body structure' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'Test AU' -and
                $Body.isMemberManagementRestricted -eq $false -and
                -not $Body.ContainsKey('description') -and
                -not $Body.ContainsKey('visibility')
            }
        }

        It 'Should include Content-Type header' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }

        It 'Should execute the create operation' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'Create administrative unit with all parameters' {
        It 'Should include description in body when specified' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Description 'Test Description' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.description -eq 'Test Description'
            }
        }

        It 'Should include visibility in body when specified' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Visibility 'HiddenMembership' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.visibility -eq 'HiddenMembership'
            }
        }

        It 'Should set IsMemberManagementRestricted to true when specified' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -IsMemberManagementRestricted $true -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.isMemberManagementRestricted -eq $true
            }
        }

        It 'Should create AU with all parameters' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Description 'Description' -Visibility 'Public' -IsMemberManagementRestricted $true -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'Test AU' -and
                $Body.description -eq 'Description' -and
                $Body.visibility -eq 'Public' -and
                $Body.isMemberManagementRestricted -eq $true
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified' {
            $result = New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'administrativeUnits'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should include body in batch request' {
            $result = New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Description 'Test' -PassThru

            $result.Body.displayName | Should -Be 'Test AU'
            $result.Body.description | Should -Be 'Test'
        }
    }

    Context 'WhatIf and Confirm support' {
        It 'Should support WhatIf' {
            $command = Get-Command New-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
        }

        It 'Should support Confirm' {
            $command = Get-Command New-PSEntraIDAdministrativeUnit
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should use Invoke-PSFProtectedCommand for confirmation' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'Pipeline input' {
        It 'Should process pipeline input from DisplayName property' {
            $input = [PSCustomObject]@{ DisplayName = 'AU1'; Description = 'Desc1' }
            $input | New-PSEntraIDAdministrativeUnit -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should process multiple objects from pipeline' {
            $input1 = [PSCustomObject]@{ DisplayName = 'AU1' }
            $input2 = [PSCustomObject]@{ DisplayName = 'AU2' }
            @($input1, $input2) | New-PSEntraIDAdministrativeUnit -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use retry configuration' {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                param($ScriptBlock)
                & $ScriptBlock
            }

            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryCount'
            } -Times 1 -Scope It

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*RetryWaitInSeconds'
            } -Times 1 -Scope It
        }

        It 'Should use Force switch correctly' {
            New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -Force

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
                New-PSEntraIDAdministrativeUnit -DisplayName 'Test AU' -WhatIf
            }
            Should -Invoke -CommandName Invoke-EntraRequest -ModuleName $script:ModuleName -Times 0
        }
    }

    Context 'Pipeline input with typed object' {
        It 'Should accept pipeline input and invoke Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $pipelineObj = [PSCustomObject]@{
                    PSTypeName  = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
                    DisplayName = 'Pipeline AU'
                }
                $pipelineObj | New-PSEntraIDAdministrativeUnit -Force -Confirm:$false
            }
            Should -Invoke -CommandName Invoke-PSFProtectedCommand -ModuleName $script:ModuleName -Times 1
        }
    }
}
