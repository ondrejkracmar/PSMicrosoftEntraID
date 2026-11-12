BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

# This cmdlet had no coverage at all - it was the only public command in the module with
# nothing referencing it anywhere in the test tree. It also writes to the directory
# (Add/Remove-PSEntraIDGroupMember), which makes an untested diff the expensive kind.
Describe 'Sync-PSEntraIDGroupMember' -Tag 'Unit' {

    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { if ($PSBoundParameters.ContainsKey('Fallback')) { $Fallback } else { $null } }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
    }

    Context 'Deciding what to change' {

        # This was skipped while the cmdlet could not satisfy it. Both causes are fixed:
        # the member lists keep their Id PROPERTY instead of being expanded to bare
        # strings (a string has no .Id, so Compare-Object -Property Id matched everything
        # against everything and only ever produced '=='), and the Delete branch reads
        # IdentityValue rather than Fields.Id, which Get-SyncDataOperation leaves empty
        # for a delete by construction.
        It 'adds the reference users the target group is missing and removes the rest' {
            InModuleScope PSMicrosoftEntraID {
                $targetGroup = [PSMicrosoftEntraID.Groups.Group]::new()
                $targetGroup.Id = 'group-1'
                $targetGroup.MailNickName = 'target'
                Mock Get-PSEntraIDGroup { $targetGroup }

                # The target already holds B and C. The caller asks for A and B, so A has to
                # be added and C removed - B is already right and must not be touched.
                Mock Get-PSEntraIDGroupMember {
                    @(
                        [pscustomobject]@{ Id = 'b@contoso.com' }
                        [pscustomobject]@{ Id = 'c@contoso.com' }
                    )
                }
                Mock Get-PSEntraIDUser {
                    $user = [PSMicrosoftEntraID.Users.User]::new()
                    $user.Id = $Identity
                    $user
                }

                $script:added = [System.Collections.Generic.List[string]]::new()
                $script:removed = [System.Collections.Generic.List[string]]::new()
                Mock Add-PSEntraIDGroupMember { $script:added.Add([string]$User) }
                Mock Remove-PSEntraIDGroupMember { $script:removed.Add([string]$User) }

                Sync-PSEntraIDGroupMember -DifferenceIdentity 'target' -ReferenceUserIdentity 'a@contoso.com', 'b@contoso.com' -Force

                $script:added | Should -Be @('a@contoso.com')
                $script:removed | Should -Be @('c@contoso.com')
            }
        }

        It 'writes nothing when both sides already match' {
            InModuleScope PSMicrosoftEntraID {
                $targetGroup = [PSMicrosoftEntraID.Groups.Group]::new()
                $targetGroup.Id = 'group-1'
                $targetGroup.MailNickName = 'target'
                Mock Get-PSEntraIDGroup { $targetGroup }
                Mock Get-PSEntraIDGroupMember { @([pscustomobject]@{ Id = 'a@contoso.com' }) }
                Mock Get-PSEntraIDUser {
                    $user = [PSMicrosoftEntraID.Users.User]::new()
                    $user.Id = $Identity
                    $user
                }
                Mock Add-PSEntraIDGroupMember { }
                Mock Remove-PSEntraIDGroupMember { }

                Sync-PSEntraIDGroupMember -DifferenceIdentity 'target' -ReferenceUserIdentity 'a@contoso.com' -Force

                Should -Invoke Add-PSEntraIDGroupMember -Times 0
                Should -Invoke Remove-PSEntraIDGroupMember -Times 0
            }
        }
    }

    Context 'SyncView' {

        It 'reports the operations without touching the group' {
            InModuleScope PSMicrosoftEntraID {
                $targetGroup = [PSMicrosoftEntraID.Groups.Group]::new()
                $targetGroup.Id = 'group-1'
                $targetGroup.MailNickName = 'target'
                Mock Get-PSEntraIDGroup { $targetGroup }
                Mock Get-PSEntraIDGroupMember { @([pscustomobject]@{ Id = 'c@contoso.com' }) }
                Mock Get-PSEntraIDUser {
                    $user = [PSMicrosoftEntraID.Users.User]::new()
                    $user.Id = $Identity
                    $user
                }
                Mock Add-PSEntraIDGroupMember { }
                Mock Remove-PSEntraIDGroupMember { }

                $view = @(Sync-PSEntraIDGroupMember -DifferenceIdentity 'target' -ReferenceUserIdentity 'a@contoso.com' -SyncView -Force)

                $view.Crud | Should -Contain 'Create'
                $view.Crud | Should -Contain 'Delete'
                # -SyncView is the dry run; it exists precisely so an operator can look
                # before anything is written.
                Should -Invoke Add-PSEntraIDGroupMember -Times 0
                Should -Invoke Remove-PSEntraIDGroupMember -Times 0
            }
        }
    }

    Context 'Missing target' {

        It 'does nothing when the target group cannot be resolved' {
            InModuleScope PSMicrosoftEntraID {
                Mock Get-PSEntraIDGroup { $null }
                Mock Get-PSEntraIDGroupMember { }
                Mock Add-PSEntraIDGroupMember { }
                Mock Remove-PSEntraIDGroupMember { }

                Sync-PSEntraIDGroupMember -DifferenceIdentity 'nope' -ReferenceUserIdentity 'a@contoso.com' -Force

                Should -Invoke Get-PSEntraIDGroupMember -Times 0
                Should -Invoke Add-PSEntraIDGroupMember -Times 0
                Should -Invoke Remove-PSEntraIDGroupMember -Times 0
            }
        }
    }
}
