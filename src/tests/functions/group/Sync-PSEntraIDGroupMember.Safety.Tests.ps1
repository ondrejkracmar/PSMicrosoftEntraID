BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

# Sync-PSEntraIDGroupMember deletes every target member the reference does not contain.
# The reads feeding it ran under -Continue: a transient 403/429/503 only warned and
# returned NOTHING, an empty reference meant "remove everyone", and an unresolvable
# -ReferenceUserIdentity was skipped silently so that real member was removed.
#
# These tests run the REAL read path - Get-PSEntraIDGroupMember, Get-PSEntraIDUser,
# Invoke-PSFProtectedCommand and Get-SyncDataOperation - and fake only the HTTP layer
# (Invoke-EntraRequest), so a swallowed error in any of them shows up as a request
# that should never have been sent.
Describe 'Sync-PSEntraIDGroupMember safety' -Tag 'Unit' {

    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { if ($PSBoundParameters.ContainsKey('Fallback')) { $Fallback } else { $null } }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Get-EntraService { [pscustomobject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' } }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup {
            $group = [PSMicrosoftEntraID.Groups.Group]::new()
            # By name ('target') or by the id this mock handed out before ('target-id').
            $group.Id = if ($Identity -like '*-id') { $Identity } else { "$Identity-id" }
            $group.MailNickName = $Identity
            $group
        }

        # One fake tenant per test, read by the Invoke-EntraRequest mock below:
        #   Members[groupId] = member ids, or an exception message to throw
        #   Users[upn]       = object id, absent = 404 (an object id always resolves)
        # Object ids must look like ids: the member cmdlets validate the identity format.
        function Get-Oid ([int] $Number) { '00000000-0000-0000-0000-{0:d12}' -f $Number }

        function Set-FakeTenant ([hashtable] $Members, [hashtable] $Users = @{}) {
            $global:SyncFake = @{ Members = $Members; Users = $Users; Requests = [System.Collections.Generic.List[object]]::new() }
        }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            $fake = $global:SyncFake
            if ($Method -ne 'Get') {
                $fake.Requests.Add([pscustomobject]@{ Method = "$Method".ToUpperInvariant(); Path = $Path; Body = $(if ($null -ne $Body) { $Body | ConvertTo-Json -Compress -Depth 5 }) })
                return
            }
            if ($Path -match '^groups/(?<id>[^/]+)/members$') {
                $content = $fake.Members[$Matches.id]
                if ($content -is [string]) { throw $content }
                return @($content | ForEach-Object { [pscustomobject]@{ id = $_ } })
            }
            if ($Path -eq 'users') { return }   # mail lookup: nobody matches by mail
            if ($Path -match '^users/(?<identity>.+)$') {
                $identity = [uri]::UnescapeDataString($Matches.identity)
                if ($fake.Users.ContainsKey($identity)) { return [pscustomobject]@{ id = $fake.Users[$identity]; userPrincipalName = $identity } }
                # An object id always resolves - every member in the fake tenant exists.
                if ($identity -as [guid]) { return [pscustomobject]@{ id = $identity; userPrincipalName = "$identity@contoso.com" } }
                throw "Response status code does not indicate success: 404 (Not Found). Request_ResourceNotFound '$identity'"
            }
            throw "unexpected request $Method $Path"
        }
    }

    AfterAll {
        Remove-Variable -Name SyncFake -Scope Global -ErrorAction Ignore
    }

    Context 'A failed read aborts the sync' {

        It 'removes nobody when reading the reference group fails' {
            Set-FakeTenant -Members @{
                'target-id' = @((Get-Oid 1), (Get-Oid 2))
                'ref-id'    = 'Response status code does not indicate success: 503 (Service Unavailable).'
            }

            { Sync-PSEntraIDGroupMember -ReferenceIdentity 'ref' -DifferenceIdentity 'target' -Force -WarningAction SilentlyContinue } | Should -Throw

            $global:SyncFake.Requests | Should -BeNullOrEmpty
        }

        It 'adds nobody when reading the target group fails' {
            Set-FakeTenant -Members @{
                'target-id' = 'Response status code does not indicate success: 429 (Too Many Requests).'
                'ref-id'    = @((Get-Oid 1), (Get-Oid 2))
            }

            { Sync-PSEntraIDGroupMember -ReferenceIdentity 'ref' -DifferenceIdentity 'target' -Force -WarningAction SilentlyContinue } | Should -Throw

            $global:SyncFake.Requests | Should -BeNullOrEmpty
        }

        It 'removes nobody when a reference user cannot be resolved' {
            Set-FakeTenant -Members @{ 'target-id' = @((Get-Oid 11), (Get-Oid 19)) } -Users @{ 'a@contoso.com' = (Get-Oid 11) }

            { Sync-PSEntraIDGroupMember -DifferenceIdentity 'target' -ReferenceUserIdentity 'a@contoso.com', 'ghost@contoso.com' -Force -WarningAction SilentlyContinue } |
                Should -Throw -ExpectedMessage '*ghost@contoso.com*'

            $global:SyncFake.Requests | Should -BeNullOrEmpty
        }
    }

    Context 'An empty reference' {

        It 'is refused - it would remove every member' {
            Set-FakeTenant -Members @{ 'target-id' = @((Get-Oid 1), (Get-Oid 2)); 'ref-id' = @() }

            { Sync-PSEntraIDGroupMember -ReferenceIdentity 'ref' -DifferenceIdentity 'target' -Force } | Should -Throw -ExpectedMessage '*AllowEmptyReference*'

            $global:SyncFake.Requests | Should -BeNullOrEmpty
        }

        It 'empties the group when -AllowEmptyReference says so' {
            Set-FakeTenant -Members @{ 'target-id' = @((Get-Oid 1), (Get-Oid 2)); 'ref-id' = @() }

            Sync-PSEntraIDGroupMember -ReferenceIdentity 'ref' -DifferenceIdentity 'target' -AllowEmptyReference -Force

            @($global:SyncFake.Requests | ForEach-Object { '{0} {1}' -f $_.Method, $_.Path } | Sort-Object) |
                Should -Be @(("DELETE groups/target-id/members/$(Get-Oid 1)/`$ref"), ("DELETE groups/target-id/members/$(Get-Oid 2)/`$ref"))
        }
    }

    Context 'Writes' {

        It 'adds missing members in chunks of 20 with one PATCH per chunk' {
            $referenceIds = 101..145 | ForEach-Object { Get-Oid $_ }
            Set-FakeTenant -Members @{ 'target-id' = @(Get-Oid 101); 'ref-id' = $referenceIds }

            Sync-PSEntraIDGroupMember -ReferenceIdentity 'ref' -DifferenceIdentity 'target' -Force

            $requests = @($global:SyncFake.Requests)
            $requests.Count | Should -Be 3
            $requests.Method | Sort-Object -Unique | Should -Be 'PATCH'
            $requests.Path | Sort-Object -Unique | Should -Be 'groups/target-id'
            $bound = @($requests | ForEach-Object { , @(($_.Body | ConvertFrom-Json).'members@odata.bind') })
            $bound[0].Count | Should -Be 20
            $bound[1].Count | Should -Be 20
            $bound[2].Count | Should -Be 4
            @($bound | ForEach-Object { $_ }) | Should -Be @($referenceIds | Select-Object -Skip 1 | ForEach-Object { "https://graph.microsoft.com/v1.0/directoryObjects/$_" })
        }

        It 'adds and removes against the resolved group without looking it up again' {
            Set-FakeTenant -Members @{ 'target-id' = @((Get-Oid 12), (Get-Oid 13)) } -Users @{ 'a@contoso.com' = (Get-Oid 11); 'b@contoso.com' = (Get-Oid 12) }

            Sync-PSEntraIDGroupMember -DifferenceIdentity 'target' -ReferenceUserIdentity 'a@contoso.com', 'b@contoso.com' -Force

            $requests = @($global:SyncFake.Requests)
            $requests.Count | Should -Be 2
            $requests[0].Method | Should -Be 'PATCH'
            $requests[0].Path | Should -Be 'groups/target-id'
            $requests[0].Body | Should -Be ('{"members@odata.bind":["https://graph.microsoft.com/v1.0/directoryObjects/' + (Get-Oid 11) + '"]}')
            $requests[1].Method | Should -Be 'DELETE'
            $requests[1].Path | Should -Be "groups/target-id/members/$(Get-Oid 13)/`$ref"
            Should -Invoke -ModuleName $script:ModuleName Get-PSEntraIDGroup -Times 1 -Exactly
        }
    }
}

Describe 'Get-SyncDataOperation' -Tag 'Unit' {

    It 'pairs large lists by key and returns each operation once' {
        InModuleScope PSMicrosoftEntraID {
            $reference = @(1..3000 | ForEach-Object { [pscustomobject]@{ Id = "u$_" } })
            $difference = @(1501..4000 | ForEach-Object { [pscustomobject]@{ Id = "u$_" } }) + [pscustomobject]@{ Id = 'u4000' }

            $elapsed = Measure-Command {
                $script:operations = @(Get-SyncDataOperation -ReferenceObjectList $reference -DiferenceObjectList $difference -MatchProperty Id -DiferenceObjectUniqueKeyName Id)
            }

            @($script:operations | Where-Object Crud -eq 'Create').Count | Should -Be 1500
            @($script:operations | Where-Object Crud -eq 'Delete').Count | Should -Be 1000
            @($script:operations | Where-Object Crud -eq 'Update').Count | Should -Be 0
            ($script:operations | Where-Object Crud -eq 'Create' | Select-Object -First 1).Fields.Id | Should -Be 'u1'
            ($script:operations | Where-Object Crud -eq 'Delete' | Select-Object -First 1).IdentityValue | Should -Be 'u3001'
            # Linear, not one .Where() scan of the other list per item: the old code took
            # minutes here.
            $elapsed.TotalSeconds | Should -BeLessThan 30
        }
    }

    It 'still reports an update when a matched object differs' {
        InModuleScope PSMicrosoftEntraID {
            $operations = @(Get-SyncDataOperation -ReferenceObjectList @([pscustomobject]@{ Id = 'u1'; Department = 'IT' }) -DiferenceObjectList @([pscustomobject]@{ Id = 'u1'; Department = 'HR' }) -MatchProperty Id -DiferenceObjectUniqueKeyName Id)

            $operations.Count | Should -Be 1
            $operations[0].Crud | Should -Be 'Update'
            $operations[0].IdentityValue | Should -Be 'u1'
            $operations[0].Fields.Department | Should -Be 'IT'
        }
    }
}
