BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Get-PSEntraID*Delta' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { if ($PSBoundParameters.ContainsKey('Fallback')) { $Fallback } else { $null } }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { $Name }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }

        $script:cmdlets = @(
            @{ Name = 'Get-PSEntraIDUserDelta'; Path = 'users/delta'; Type = 'PSMicrosoftEntraID.Users.UserDelta' }
            @{ Name = 'Get-PSEntraIDGroupDelta'; Path = 'groups/delta'; Type = 'PSMicrosoftEntraID.Groups.GroupDelta' }
            @{ Name = 'Get-PSEntraIDDeviceDelta'; Path = 'devices/delta'; Type = 'PSMicrosoftEntraID.Devices.DeviceDelta' }
            @{ Name = 'Get-PSEntraIDContactDelta'; Path = 'contacts/delta'; Type = 'PSMicrosoftEntraID.Contacts.ContactDelta' }
            @{ Name = 'Get-PSEntraIDAdministrativeUnitDelta'; Path = 'directory/administrativeUnits/delta'; Type = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnitDelta' }
        )
    }

    It 'all five are exported and declare their delta type' -ForEach @(
        @{ Name = 'Get-PSEntraIDUserDelta'; Type = 'PSMicrosoftEntraID.Users.UserDelta' }
        @{ Name = 'Get-PSEntraIDGroupDelta'; Type = 'PSMicrosoftEntraID.Groups.GroupDelta' }
        @{ Name = 'Get-PSEntraIDDeviceDelta'; Type = 'PSMicrosoftEntraID.Devices.DeviceDelta' }
        @{ Name = 'Get-PSEntraIDContactDelta'; Type = 'PSMicrosoftEntraID.Contacts.ContactDelta' }
        @{ Name = 'Get-PSEntraIDAdministrativeUnitDelta'; Type = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnitDelta' }
    ) {
        $command = Get-Command $Name -ErrorAction SilentlyContinue
        $command | Should -Not -BeNullOrEmpty
        $command.OutputType.Name | Should -Contain $Type
        $command.Parameters.Keys | Should -Contain 'DeltaSession'
        $command.Parameters.Keys | Should -Contain 'MinimalDelta'
    }

    It 'hits the right Graph delta endpoint' -ForEach @(
        @{ Name = 'Get-PSEntraIDUserDelta'; Path = 'users/delta' }
        @{ Name = 'Get-PSEntraIDGroupDelta'; Path = 'groups/delta' }
        @{ Name = 'Get-PSEntraIDDeviceDelta'; Path = 'devices/delta' }
        @{ Name = 'Get-PSEntraIDContactDelta'; Path = 'contacts/delta' }
        @{ Name = 'Get-PSEntraIDAdministrativeUnitDelta'; Path = 'directory/administrativeUnits/delta' }
    ) {
        InModuleScope PSMicrosoftEntraID -Parameters @{ CmdletName = $Name; ExpectedPath = $Path } {
            param($CmdletName, $ExpectedPath)
            $script:seenPath = $null
            Mock Invoke-EntraRequest { $script:seenPath = $Path; [pscustomobject]@{ value = @() } }

            & $CmdletName -DeltaSession @{}

            $script:seenPath | Should -Be $ExpectedPath
        }
    }

    It 'selects the full property list, and members where membership travels' {
        InModuleScope PSMicrosoftEntraID {
            $script:seenQuery = $null
            Mock Invoke-EntraRequest { $script:seenQuery = $Query; [pscustomobject]@{ value = @() } }

            # Unselected, Graph returns only the DEFAULT property set - no
            # assignedLicenses, companyName or identities - and a delta query also
            # tracks only the selected properties' changes: an assignedLicenses-only
            # change produced no delta event at all until the property was selected.
            # Measured live 2026-08-19; this is what broke the licence inventory
            # delta sync.
            Get-PSEntraIDUserDelta -DeltaSession @{}
            $script:seenQuery.'$select' | Should -Match 'assignedLicenses'
            $script:seenQuery.'$select' | Should -Match 'companyName'
            $script:seenQuery.'$select' | Should -Match 'identities'

            # Groups additionally select 'members' - that is what carries membership
            # changes as members@delta; dropping it would regress the endpoint's
            # main use.
            Get-PSEntraIDGroupDelta -DeltaSession @{}
            $script:seenQuery.'$select' | Should -Match 'members'
            $script:seenQuery.'$select' | Should -Match 'displayName'
        }
    }

    It 'passes the delta session through so the token round-trips' {
        InModuleScope PSMicrosoftEntraID {
            $script:seenSession = $null
            Mock Invoke-EntraRequest {
                $script:seenSession = $DeltaSession
                # Invoke-EntraRequest is what writes the token back into the caller's
                # hashtable; simulate that here.
                $DeltaSession['users/delta'] = @{ Token = 'tok-1' }
                [pscustomobject]@{ value = @() }
            }

            $session = @{}
            Get-PSEntraIDUserDelta -DeltaSession $session

            $script:seenSession | Should -Not -BeNullOrEmpty
            # The same hashtable instance, so the caller sees the new token.
            $session['users/delta'].Token | Should -Be 'tok-1'
        }
    }

    It 'omits the delta session entirely when none was given' {
        InModuleScope PSMicrosoftEntraID {
            # Read the parameter itself, not $PSBoundParameters: inside a Pester mock
            # that dictionary does not reliably reflect splatted arguments.
            $script:sawSession = 'unset'
            Mock Invoke-EntraRequest {
                $script:sawSession = $DeltaSession
                [pscustomobject]@{ value = @() }
            }

            # Without a session the call should read everything rather than start
            # tracking a token nobody asked for.
            Get-PSEntraIDUserDelta

            $script:sawSession | Should -BeNullOrEmpty
        }
    }

    It 'forwards -MinimalDelta only when asked' {
        InModuleScope PSMicrosoftEntraID {
            $script:minimal = $null
            Mock Invoke-EntraRequest {
                $script:minimal = [bool]$MinimalDelta
                [pscustomobject]@{ value = @() }
            }

            Get-PSEntraIDUserDelta -DeltaSession @{}
            $script:minimal | Should -BeFalse

            Get-PSEntraIDUserDelta -DeltaSession @{} -MinimalDelta
            $script:minimal | Should -BeTrue
        }
    }

    It 'returns typed results, removed ones included' {
        InModuleScope PSMicrosoftEntraID {
            Mock Invoke-EntraRequest {
                [pscustomobject]@{ value = @(
                        [pscustomobject]@{ id = 'u1'; userPrincipalName = 'a@x.test' }
                        [pscustomobject]@{ id = 'u2'; '@removed' = [pscustomobject]@{ reason = 'changed' } }
                    ) }
            }

            $result = @(Get-PSEntraIDUserDelta -DeltaSession @{})

            $result.Count | Should -Be 2
            $result[0] | Should -BeOfType ([PSMicrosoftEntraID.Users.UserDelta])
            # Inheritance is the point of the design: a UserDelta is still a User.
            $result[0] -is [PSMicrosoftEntraID.Users.User] | Should -BeTrue
            $result[1].Removed | Should -BeTrue
        }
    }
}
