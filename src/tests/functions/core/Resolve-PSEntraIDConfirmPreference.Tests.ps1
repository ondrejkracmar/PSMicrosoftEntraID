BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Resolve-PSEntraIDConfirmPreference' -Tag 'Unit' {

    # This decides, for every cmdlet in the module, whether the caller gets a prompt.
    # It returned $true for "no opinion" and the call sites bound that as -Confirm:$true,
    # which FORCES a prompt instead of deferring to ConfirmImpact - so everything
    # prompted unless -Force was passed. It survived for months because nothing here
    # tested it.

    It 'says nothing when the caller said nothing, so ConfirmImpact decides' {
        InModuleScope PSMicrosoftEntraID {
            $result = Resolve-PSEntraIDConfirmPreference -BoundParameters @{}
            $result | Should -BeOfType ([hashtable])
            # Empty on purpose: splatting this binds no -Confirm at all. Returning
            # @{ Confirm = $true } here is the bug this test exists for.
            $result.Keys.Count | Should -Be 0
        }
    }

    It 'suppresses confirmation for -Force' {
        InModuleScope PSMicrosoftEntraID {
            $result = Resolve-PSEntraIDConfirmPreference -BoundParameters @{ Force = $true } -Force
            $result.ContainsKey('Confirm') | Should -BeTrue
            $result.Confirm | Should -BeFalse
        }
    }

    It 'honours -Confirm:$false' {
        InModuleScope PSMicrosoftEntraID {
            $result = Resolve-PSEntraIDConfirmPreference -BoundParameters @{ Confirm = $false } -Confirm:$false
            $result.Confirm | Should -BeFalse
        }
    }

    It 'honours -Confirm:$true' {
        InModuleScope PSMicrosoftEntraID {
            $result = Resolve-PSEntraIDConfirmPreference -BoundParameters @{ Confirm = $true } -Confirm:$true
            $result.Confirm | Should -BeTrue
        }
    }

    It 'lets an explicit -Confirm beat -Force' {
        InModuleScope PSMicrosoftEntraID {
            # The caller asking to be prompted outranks the caller asking not to be.
            $result = Resolve-PSEntraIDConfirmPreference -BoundParameters @{ Force = $true; Confirm = $true } -Force -Confirm:$true
            $result.Confirm | Should -BeTrue
        }
    }
}

Describe 'Confirmation semantics the resolver relies on' -Tag 'Unit' {

    # Guards the assumption the design rests on. If a future PowerShell made
    # -Confirm:$true defer to ConfirmPreference, the splat would be unnecessary; if
    # anyone "simplifies" the resolver back to a bool, this states why they cannot.

    BeforeAll {
        function script:Test-MediumImpact {
            [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
            param()
            $PSCmdlet.ShouldProcess('target', 'action')
        }
    }

    It 'runs silently when -Confirm is not bound, at the default ConfirmPreference' {
        $ConfirmPreference | Should -Be 'High'
        Test-MediumImpact | Should -BeTrue
    }

    It 'binding -Confirm:$true forces a prompt regardless of ConfirmImpact' {
        # Non-interactive, so the prompt cannot be answered and this throws. That it
        # throws IS the point: an unbound -Confirm returns $true without asking.
        { Test-MediumImpact -Confirm:$true } | Should -Throw
    }
}
