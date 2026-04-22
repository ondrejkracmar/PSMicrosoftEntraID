BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Remove-PSEntraIDGroup' -Tag 'Unit' {

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
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }
    }

    Context 'Parameter Validation' {
        It 'Should have InputObject and Identity parameter sets' {
            $command = Get-Command Remove-PSEntraIDGroup
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Remove-PSEntraIDGroup
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have Force and PassThru parameters' {
            $command = Get-Command Remove-PSEntraIDGroup
            $command.Parameters.ContainsKey('Force') | Should -Be $true
            $command.Parameters.ContainsKey('PassThru') | Should -Be $true
        }
    }

    Context 'Delete group by InputObject' {
        It 'Should call API with DELETE method' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Remove-PSEntraIDGroup -InputObject $groupObj -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and $Path -eq 'groups/00000000-0000-0000-0000-000000000010'
            }
        }
    }

    Context 'Delete group by Identity' {
        It 'Should resolve group and call DELETE' {
            Remove-PSEntraIDGroup -Identity 'testgroup' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Delete' -and $Path -eq 'groups/00000000-0000-0000-0000-000000000010'
            }
        }

        It 'Should handle group not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $null }

            Remove-PSEntraIDGroup -Identity 'notfound' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }

        It 'Should not call API when group not found without EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $null }

            { Remove-PSEntraIDGroup -Identity 'notfound' -Force -Confirm:$false } | Should -Not -Throw

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with DELETE method via InputObject' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            $result = Remove-PSEntraIDGroup -InputObject $groupObj -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
            $result.Url | Should -Be '/groups/00000000-0000-0000-0000-000000000010'
        }

        It 'Should return batch request via Identity' {
            $result = Remove-PSEntraIDGroup -Identity 'testgroup' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'DELETE'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Remove-PSEntraIDGroup -InputObject $groupObj -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Remove-PSEntraIDGroup -InputObject $groupObj -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                $groupObj = [PSCustomObject]@{
                    PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                    Id           = '00000000-0000-0000-0000-000000000010'
                    DisplayName  = 'TestGroup'
                }
                Remove-PSEntraIDGroup -InputObject $groupObj -WhatIf
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input for InputObject parameter' {
            InModuleScope $script:ModuleName {
                $groupObj = [PSCustomObject]@{
                    PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                    Id           = '00000000-0000-0000-0000-000000000010'
                    DisplayName  = 'TestGroup'
                }
                { $groupObj | Remove-PSEntraIDGroup -Force -Confirm:$false } | Should -Not -Throw
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }
}
