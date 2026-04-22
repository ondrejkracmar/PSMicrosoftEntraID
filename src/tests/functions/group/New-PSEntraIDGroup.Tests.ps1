BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'New-PSEntraIDGroup Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should have mandatory Displayname parameter' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['Displayname']
            $param | Should -Not -BeNullOrEmpty
            @($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }).Count | Should -BeGreaterThan 0
        }

        It 'Should have mandatory MailNickname parameter' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['MailNickname']
            $param | Should -Not -BeNullOrEmpty
            @($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }).Count | Should -BeGreaterThan 0
        }

        It 'Should have optional Owners parameter' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['Owners']
            $param | Should -Not -BeNullOrEmpty
            @($param.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }).Count | Should -Be 0
        }

        It 'Should have optional Members parameter' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['Members']
            $param | Should -Not -BeNullOrEmpty
            $param.Attributes.Mandatory | Should -Not -Contain $true
        }

        It 'Should have EnableException switch parameter' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['EnableException']
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType | Should -Be ([switch])
        }
    }

    Context 'Pipeline Support' {
        It 'Should accept parameters from pipeline by property name' {
            $command = Get-Command New-PSEntraIDGroup
            $param = $command.Parameters['Displayname']
            $pipelineAttr = $param.Attributes | Where-Object { $_.TypeId.Name -eq 'ParameterAttribute' }
            ($pipelineAttr.ValueFromPipelineByPropertyName -contains $true) | Should -Be $true
        }
    }

    Context 'ShouldProcess Support' {
        It 'Should support WhatIf and Confirm' {
            $command = Get-Command New-PSEntraIDGroup
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Error Handling - Owners' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue { 
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService { 
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should continue processing valid owners when one owner not found and EnableException is false' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -eq 'nonexistent@test.com') { return $null }
                return [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { }

            $owners = @('valid1@test.com', 'nonexistent@test.com', 'valid2@test.com')
            
            { New-PSEntraIDGroup -Displayname 'Test' -MailNickname 'test' -Owners $owners -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 3
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 0
        }

        It 'Should throw when owner not found and EnableException is true' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { return $null }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { 
                throw "User not found"
            }

            { New-PSEntraIDGroup -Displayname 'Test' -MailNickname 'test' -Owners 'nonexistent@test.com' -EnableException -Confirm:$false } | Should -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 1
        }

        It 'Should process all valid owners and skip invalid ones when EnableException is false' {
            $processedIds = @()
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -match 'invalid') { return $null }
                return [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest {
                param($Body)
                $processedIds = $Body['owners@odata.bind']
            }

            $owners = @('valid1@test.com', 'invalid1@test.com', 'valid2@test.com', 'invalid2@test.com', 'valid3@test.com')
            
            New-PSEntraIDGroup -Displayname 'Test' -MailNickname 'test' -Owners $owners -Confirm:$false
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 5
        }
    }

    Context 'Error Handling - Members' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue { 
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService { 
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -match 'nonexistent|invalid') { return $null }
                return [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should continue processing valid members when one member not found and EnableException is false' {
            $members = @('valid1@test.com', 'nonexistent@test.com', 'valid2@test.com')
            
            { New-PSEntraIDGroup -Displayname 'Test' -MailNickname 'test' -Members $members -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 3
        }

        It 'Should process both owners and members with mixed valid/invalid identities' {            $owners = @('valid-owner@test.com', 'invalid-owner@test.com')
            $members = @('valid-member@test.com', 'invalid-member@test.com')
            
            { New-PSEntraIDGroup -Displayname 'Test' -MailNickname 'test' -Owners $owners -Members $members -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 4
        }
    }

    Context 'Dynamic group creation' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should create a dynamic group with MembershipRule and MembershipRuleProcessingState' {
            New-PSEntraIDGroup -DisplayName 'DynGroup' -MailNickname 'dyngroup' -MailEnabled $false -SecurityEnabled $true -GroupTypes 'DynamicMembership' -MembershipRule '(user.department -eq "Sales")' -MembershipRuleProcessingState 'On' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'ResourceBehaviorOptions parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should pass ResourceBehaviorOptions when specified' {
            New-PSEntraIDGroup -DisplayName 'RBOGroup' -MailNickname 'rbogroup' -MailEnabled $false -SecurityEnabled $true -ResourceBehaviorOptions 'AllowOnlyMembersToPost' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'Connection verification' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should call Assert-EntraConnection during execution' {
            New-PSEntraIDGroup -DisplayName 'ConnTest' -MailNickname 'conntest' -MailEnabled $false -SecurityEnabled $true -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        }

        It 'Should not invoke Invoke-EntraRequest when using -WhatIf' {
            New-PSEntraIDGroup -DisplayName 'TestGroup' -MailNickname 'testgroup' -MailEnabled $false -SecurityEnabled $true -WhatIf

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0
        }
    }

    Context 'PassThru parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
                if ($FullName -like '*RetryCount') { return 0 }
                if ($FullName -like '*RetryWaitInSeconds') { return 0 }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                [PSCustomObject]@{ id = '00000000-0000-0000-0000-000000000001'; displayName = 'PassThruGroup' }
            }
        }

        It 'Should return a batch request object when -PassThru is specified' {
            $result = New-PSEntraIDGroup -DisplayName 'PassThruGroup' -MailNickname 'passthrugroup' -MailEnabled $false -SecurityEnabled $true -PassThru

            $result | Should -Not -BeNullOrEmpty
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Be '/groups'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0
        }
    }
}
