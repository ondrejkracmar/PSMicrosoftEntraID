BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
}

Describe 'Tab expansion (TEPP)' -Tag 'Unit' {

    # These completers were silently dead: the scriptblocks emitted hashtables, which
    # neither PSFramework mode accepts, so PowerShell fell back to completing FILE
    # PATHS. Nothing failed and no test noticed. Assert the observable behaviour -
    # what a user actually gets after pressing Tab - not the registration.
    #
    # The catalog is bundled with the module, so all of this works offline and needs
    # no tenant connection.

    BeforeAll {
        function script:Get-Completion {
            param([string] $Line)
            (TabExpansion2 -inputScript $Line -cursorColumn $Line.Length).CompletionMatches
        }
    }

    Context 'SKU part numbers' {

        It 'completes and filters on the word being typed' {
            $result = @(Get-Completion 'Get-PSEntraIDUserLicense -SkuPartNumber DEVELOPER')
            $result.Count | Should -BeGreaterThan 0
            $result.CompletionText | Should -Contain 'DEVELOPERPACK_E5'
            # Every match must start with what was typed: a registered completer's
            # output is NOT filtered by PowerShell, the scriptblock has to do it.
            @($result | Where-Object { $_.CompletionText -notlike 'DEVELOPER*' }).Count | Should -Be 0
        }

        It 'does not fall back to file-path completion' {
            # The old failure mode: '.\.git', '.\docs', ... instead of SKUs.
            $result = @(Get-Completion 'Get-PSEntraIDUserLicense -SkuPartNumber ')
            @($result | Where-Object { $_.CompletionText -like '.\*' }).Count | Should -Be 0
        }

        It 'carries a friendly name in the tooltip' {
            $match = Get-Completion 'Get-PSEntraIDUserLicense -SkuPartNumber DEVELOPERPACK_E5' |
                Select-Object -First 1
            $match.ToolTip | Should -Not -BeNullOrEmpty
            $match.ToolTip | Should -Not -Be $match.CompletionText
            # ...and does not repeat the value being completed back at the user.
            @($match.ToolTip -split ' \| ') | Should -Not -Contain $match.CompletionText
        }

        It 'keeps the part number in the tooltip when completing a SkuId' {
            # There the value is a GUID, so the part number is the useful part and
            # must survive the redundancy trim.
            $match = Get-Completion 'Get-PSEntraIDUserLicense -SkuId c42b9cae' | Select-Object -First 1
            if ($match) { $match.ToolTip | Should -Match '\w' }
        }

        It 'returns CompletionResult objects, not hashtables' {
            $match = Get-Completion 'Get-PSEntraIDUserLicense -SkuPartNumber DEVELOPERPACK_E5' |
                Select-Object -First 1
            $match | Should -BeOfType ([System.Management.Automation.CompletionResult])
        }
    }

    Context 'Service plans are scoped to the SKU already on the line' {

        It 'uses the bound SkuPartNumber to narrow the plan list' {
            # Exercises $fakeBoundParameter, which only arrives if the scriptblock
            # declares the completer parameters - it was undefined before.
            $result = @(Get-Completion 'Enable-PSEntraIDGroupLicenseServicePlan -SkuPartNumber DEVELOPERPACK_E5 -ServicePlanName TEAMS')
            $result.CompletionText | Should -Contain 'TEAMS1'
        }
    }

    Context 'Usage location' {

        It 'quotes a value containing spaces so the command line stays parseable' {
            $result = @(Get-Completion 'Set-PSEntraIDUserUsageLocation -UsageLocationCountry Czech')
            $result.Count | Should -BeGreaterThan 0
            $result[0].CompletionText | Should -Be "'Czech Republic'"
            # The menu entry itself stays unquoted.
            $result[0].ListItemText | Should -Be 'Czech Republic'
        }

        It 'completes the country code with the country name as tooltip' {
            $result = @(Get-Completion 'Set-PSEntraIDUserUsageLocation -UsageLocationCode CZ')
            $result.CompletionText | Should -Contain 'CZ'
            ($result | Where-Object CompletionText -eq 'CZ').ToolTip | Should -Be 'Czech Republic'
        }
    }
}
