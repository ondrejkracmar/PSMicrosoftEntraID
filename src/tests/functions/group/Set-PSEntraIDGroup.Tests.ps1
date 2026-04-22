BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Set-PSEntraIDGroup' -Tag 'Unit' {

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
        It 'Should have multiple parameter sets for separate-update properties' {
            $command = Get-Command Set-PSEntraIDGroup
            $command.ParameterSets.Name | Should -Contain 'InputObjectUpdateGroupCommon'
            $command.ParameterSets.Name | Should -Contain 'IdentityUpdateGroupCommon'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Set-PSEntraIDGroup
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have expected group property parameters' {
            $command = Get-Command Set-PSEntraIDGroup
            $expectedParams = @('Displayname', 'Description', 'MailNickname', 'Visibility', 'GroupTypes',
                'AllowExternalSenders', 'AutoSubscribeNewMembers', 'HideFromAddressLists',
                'HideFromOutlookClients', 'MembershipRule', 'MembershipRuleProcessingState')
            foreach ($param in $expectedParams) {
                $command.Parameters.ContainsKey($param) | Should -Be $true
            }
        }

        It 'Should have Visibility with ValidateSet' {
            $param = (Get-Command Set-PSEntraIDGroup).Parameters['Visibility']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet.ValidValues | Should -Contain 'Public'
            $validateSet.ValidValues | Should -Contain 'Private'
            $validateSet.ValidValues | Should -Contain 'HiddenMembership'
        }
    }

    Context 'Update common group properties by InputObject' {
        It 'Should call API with PATCH method' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'Updated Group' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and $Path -eq 'groups/00000000-0000-0000-0000-000000000010'
            }
        }

        It 'Should include only specified properties in body' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'New Name' -Description 'New Description' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.displayName -eq 'New Name' -and $Body.description -eq 'New Description'
            }
        }

        It 'Should include Content-Type header' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'Test' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }
    }

    Context 'Update group by Identity' {
        It 'Should resolve group and call PATCH' {
            Set-PSEntraIDGroup -Identity 'testgroup' -Displayname 'Updated' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Patch' -and $Body.displayName -eq 'Updated'
            }
        }

        It 'Should handle group not found with EnableException' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $null }

            Set-PSEntraIDGroup -Identity 'notfound' -Displayname 'Test' -EnableException -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1
        }
    }

    Context 'Update visibility' {
        It 'Should include visibility in body' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Set-PSEntraIDGroup -InputObject $groupObj -Visibility 'Private' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.visibility -eq 'Private'
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request with PATCH method' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            $result = Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'Updated' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'PATCH'
            $result.Url | Should -Be '/groups/00000000-0000-0000-0000-000000000010'
        }

        It 'Should not call Invoke-EntraRequest when PassThru' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
            }

            Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'Updated' -PassThru

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

            Set-PSEntraIDGroup -InputObject $groupObj -Displayname 'Test' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }

    Context 'AllowExternalSenders parameter set' {
        It 'Should call Invoke-PSFProtectedCommand with AllowExternalSenders' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -AllowExternalSenders $true -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }

    Context 'AutoSubscribeNewMembers parameter set' {
        It 'Should call Invoke-PSFProtectedCommand with AutoSubscribeNewMembers' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -AutoSubscribeNewMembers $true -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }

    Context 'HideFromAddressLists parameter set' {
        It 'Should call Invoke-PSFProtectedCommand with HideFromAddressLists' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -HideFromAddressLists $true -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }

    Context 'HideFromOutlookClients parameter set' {
        It 'Should call Invoke-PSFProtectedCommand with HideFromOutlookClients' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -HideFromOutlookClients $true -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }

    Context 'UpdateDynamicGroup parameter set' {
        It 'Should call Invoke-PSFProtectedCommand with MembershipRule' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -MembershipRule '(user.department -eq "Sales")' -MembershipRuleProcessingState 'On' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
        }

        It 'Should not call Invoke-EntraRequest when WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Set-PSEntraIDGroup -Identity 'test-group-id' -DisplayName 'NewName' -WhatIf

                Should -Invoke -CommandName Invoke-EntraRequest -Times 0 -Exactly
            }
        }
    }

    Context 'Pipeline input' {
        It 'Should accept pipeline input and call Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $groupObj = [PSCustomObject]@{
                    PSTypeName  = 'PSMicrosoftEntraID.Groups.Group'
                    Id          = 'test-group-id'
                    DisplayName = 'TestGroup'
                }

                $groupObj | Set-PSEntraIDGroup -DisplayName 'NewName' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }
}
