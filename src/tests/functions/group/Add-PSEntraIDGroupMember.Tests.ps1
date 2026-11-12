BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Import here rather than relying on whichever test file happened to run first:
    # Pester executes every file in ONE runspace, so an ambient import made these
    # tests pass alone and fail in a full run with
    #   RuntimeException: No modules named 'PSMicrosoftEntraID' are currently loaded.
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Add-PSEntraIDGroupMember Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should have EnableException switch parameter' {
            $command = Get-Command Add-PSEntraIDGroupMember
            $param = $command.Parameters['EnableException']
            $param | Should -Not -BeNullOrEmpty
            $param.ParameterType | Should -Be ([switch])
        }

        It 'Should have User parameter' {
            $command = Get-Command Add-PSEntraIDGroupMember
            $param = $command.Parameters['User']
            $param | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling - User Identity' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue { 
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService { 
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should continue processing valid users when one user not found and EnableException is false' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -eq 'nonexistent@test.com') { return $null }
                return [PSCustomObject]@{ 
                    Id = "id-$Identity"
                    UserPrincipalName = $Identity
                    Mail = $Identity
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { }

            $users = @('valid1@test.com', 'nonexistent@test.com', 'valid2@test.com')
            
            { Add-PSEntraIDGroupMember -Identity 'test-group' -User $users -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 3
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 0
        }

        It 'Should throw when user not found and EnableException is true' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { return $null }
            Mock -ModuleName PSMicrosoftEntraID Invoke-TerminatingException { 
                throw "User not found"
            }

            { Add-PSEntraIDGroupMember -Identity 'test-group' -User 'nonexistent@test.com' -EnableException -Confirm:$false } | Should -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-TerminatingException -Times 1
        }

        It 'Should process all valid users and skip invalid ones when EnableException is false' {
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser { 
                param($Identity)
                if ($Identity -match 'invalid') { return $null }
                return [PSCustomObject]@{ 
                    Id = "id-$Identity"
                    UserPrincipalName = $Identity
                    Mail = $Identity
                }
            }

            $users = @('valid1@test.com', 'invalid1@test.com', 'valid2@test.com', 'invalid2@test.com', 'valid3@test.com')
            
            { Add-PSEntraIDGroupMember -Identity 'test-group' -User $users -Confirm:$false } | Should -Not -Throw
            
            Should -Invoke -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser -Times 5
        }
    }

    Context 'IdentityInputObject single user' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should add a single InputObject user via POST to members/$ref' {
            InModuleScope $script:ModuleName {
                $user = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user1@test.com'
                    Mail              = 'user1@test.com'
                }
                { Add-PSEntraIDGroupMember -Identity 'group-id' -InputObject $user -Force } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'IdentityInputObject multiple users' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should add multiple InputObject users via PATCH with members@odata.bind' {
            InModuleScope $script:ModuleName {
                $users = @(
                    [PSCustomObject]@{
                        PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                        Id                = 'user-id-1'
                        UserPrincipalName = 'user1@test.com'
                        Mail              = 'user1@test.com'
                    },
                    [PSCustomObject]@{
                        PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                        Id                = 'user-id-2'
                        UserPrincipalName = 'user2@test.com'
                        Mail              = 'user2@test.com'
                    }
                )
                { Add-PSEntraIDGroupMember -Identity 'group-id' -InputObject $users -Force } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                [PSCustomObject]@{
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user@domain.com'
                    Mail              = 'user@domain.com'
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand { }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user@domain.com' -WhatIf
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 0
        }
    }

    Context 'Connection verification' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                [PSCustomObject]@{
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user@domain.com'
                    Mail              = 'user@domain.com'
                }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should call Assert-EntraConnection during execution' {
            InModuleScope $script:ModuleName {
                Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user@domain.com' -Force
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Assert-EntraConnection -Times 1
        }
    }

    Context 'Pipeline input' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand {
                & $ScriptBlock
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        }

        It 'Should accept pipeline input for InputObject parameter' {
            InModuleScope $script:ModuleName {
                $user = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'user-id-1'
                    UserPrincipalName = 'user1@test.com'
                    Mail              = 'user1@test.com'
                }
                { $user | Add-PSEntraIDGroupMember -Identity 'group-id' -Force } | Should -Not -Throw
            }
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'Wire format - chunking through the real Step-Array' {
        # Graph accepts at most 20 references per members@odata.bind PATCH. The chunks
        # used to be cast to [string[]], which joined every chunk into ONE space-separated
        # string, and an exact multiple of 20 produced an extra empty chunk:
        #   {"members@odata.bind":["https://.../1 https://.../2 ..."]}
        #   {"members@odata.bind":[""]}
        # Step-Array is deliberately NOT mocked: the defect lived in it and in the cast.
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                param($Identity)
                if ($Identity -like 'missing*') { return $null }
                [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity; Mail = $Identity }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand { & $ScriptBlock }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }

            # The JSON Graph has to receive for one chunk of the users numbered $From..$To.
            function Get-ExpectedChunkJson ([int] $From, [int] $To) {
                [string[]] $urls = @($From..$To | ForEach-Object { 'https://graph.microsoft.com/v1.0/directoryObjects/id-user{0}@test.com' -f $_ })
                @{ 'members@odata.bind' = $urls } | ConvertTo-Json -Compress -Depth 5
            }
        }

        It 'sends <Count> members as PATCH requests of at most 20 references' -TestCases @(
            @{ Count = 19; Chunks = @(, @(1, 19)) }
            @{ Count = 20; Chunks = @(, @(1, 20)) }
            @{ Count = 21; Chunks = @(@(1, 20), @(21, 21)) }
            @{ Count = 40; Chunks = @(@(1, 20), @(21, 40)) }
        ) {
            $users = @(1..$Count | ForEach-Object { 'user{0}@test.com' -f $_ })

            Add-PSEntraIDGroupMember -Identity 'group-id' -User $users -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times $Chunks.Count -Exactly
            foreach ($chunk in $Chunks) {
                $expected = Get-ExpectedChunkJson -From $chunk[0] -To $chunk[1]
                # Built as a literal: the filter cannot be trusted to see the test's variables.
                $filter = [scriptblock]::Create(
                    ('$Path -eq ''groups/group-id'' -and $Method -eq ''PATCH'' -and (($Body | ConvertTo-Json -Compress -Depth 5) -ceq ''{0}'')' -f $expected)
                )
                Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -ParameterFilter $filter -Times 1 -Exactly -Because "users $($chunk[0])..$($chunk[1]) must go out as $expected"
            }
        }

        It 'returns the same chunks as Batch.Request objects with -PassThru' {
            $users = @(1..21 | ForEach-Object { 'user{0}@test.com' -f $_ })

            $requests = @(Add-PSEntraIDGroupMember -Identity 'group-id' -User $users -PassThru)

            $requests.Count | Should -Be 2
            $requests[0].Method | Should -Be 'PATCH'
            $requests[0].Url | Should -Be '/groups/group-id'
            ($requests[0].Body | ConvertTo-Json -Compress -Depth 5) | Should -BeExactly (Get-ExpectedChunkJson -From 1 -To 20)
            ($requests[1].Body | ConvertTo-Json -Compress -Depth 5) | Should -BeExactly (Get-ExpectedChunkJson -From 21 -To 21)
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'sends one member as a POST to members/$ref' {
            Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user1@test.com' -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 1 -Exactly
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/group-id/members/$ref' -and $Method -eq 'POST' -and
                (($Body | ConvertTo-Json -Compress -Depth 5) -ceq '{"@odata.id":"https://graph.microsoft.com/v1.0/directoryObjects/id-user1@test.com"}')
            } -Times 1 -Exactly
        }

        It 'chunks User objects passed to -InputObject the same way' {
            $users = @(1..21 | ForEach-Object {
                    [PSCustomObject]@{
                        PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                        Id                = 'id-user{0}@test.com' -f $_
                        UserPrincipalName = 'user{0}@test.com' -f $_
                    }
                })

            InModuleScope PSMicrosoftEntraID -Parameters @{ Users = $users } {
                param($Users)
                Add-PSEntraIDGroupMember -Identity 'group-id' -InputObject $Users -Force
            }

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 2 -Exactly
            $filter = [scriptblock]::Create(('($Body | ConvertTo-Json -Compress -Depth 5) -ceq ''{0}''' -f (Get-ExpectedChunkJson -From 1 -To 20)))
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -ParameterFilter $filter -Times 1 -Exactly
            $filter = [scriptblock]::Create(('($Body | ConvertTo-Json -Compress -Depth 5) -ceq ''{0}''' -f (Get-ExpectedChunkJson -From 21 -To 21)))
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -ParameterFilter $filter -Times 1 -Exactly
        }
    }

    Context 'Partially resolved users and per-record state' {
        BeforeAll {
            Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
                if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            }
            Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
            Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
                [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
                [PSCustomObject]@{ Id = 'group-id'; DisplayName = 'Test Group' }
            }
            Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
                param($Identity)
                if ($Identity -like 'missing*') { return $null }
                [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity; Mail = $Identity }
            }
            Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand { & $ScriptBlock }
            Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
            Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { } -ParameterFilter { $Level -eq 'Warning' }
        }

        It 'adds the one resolved user through members/$ref when the other does not resolve' {
            # Was: PATCH groups/{id} with an @odata.id body, which Graph rejects - so the
            # user that did resolve was not added either.
            Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user1@test.com', 'missing@test.com' -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 1 -Exactly
            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/group-id/members/$ref' -and $Method -eq 'POST' -and
                (($Body | ConvertTo-Json -Compress -Depth 5) -ceq '{"@odata.id":"https://graph.microsoft.com/v1.0/directoryObjects/id-user1@test.com"}')
            } -Times 1 -Exactly
        }

        It 'warns once per user that does not resolve' {
            Add-PSEntraIDGroupMember -Identity 'group-id' -User 'user1@test.com', 'missing1@test.com', 'missing2@test.com' -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Write-PSFMessage -ParameterFilter {
                $Level -eq 'Warning' -and $String -eq 'User.Get.Failed' -and $StringValues -contains 'missing1@test.com'
            } -Times 1 -Exactly
            Should -Invoke -ModuleName PSMicrosoftEntraID Write-PSFMessage -ParameterFilter {
                $Level -eq 'Warning' -and $String -eq 'User.Get.Failed' -and $StringValues -contains 'missing2@test.com'
            } -Times 1 -Exactly
        }

        It 'does not resend the previous pipeline record when the next one does not resolve' {
            # The request of one record used to survive into the next, so an unresolved
            # record re-added the member of the record before it.
            @(
                [PSCustomObject]@{ UserPrincipalName = 'user1@test.com' }
                [PSCustomObject]@{ UserPrincipalName = 'missing@test.com' }
            ) | Add-PSEntraIDGroupMember -Identity 'group-id' -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'sends nothing when no user resolves' {
            Add-PSEntraIDGroupMember -Identity 'group-id' -User 'missing1@test.com', 'missing2@test.com' -Force

            Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 0 -Exactly
        }
    }
}
