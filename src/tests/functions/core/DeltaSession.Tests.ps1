BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Export/Import-PSEntraIDDeltaSession' -Tag 'Unit' {

    # These exist because the obvious hand-rolled round-trip is wrong: ConvertFrom-Json
    # hands back a PSCustomObject and -DeltaSession takes a hashtable, so the mistake
    # only shows up later, at the delta call.

    BeforeEach {
        $script:tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("delta-{0}.json" -f [guid]::NewGuid())
    }
    AfterEach {
        if (Test-Path -LiteralPath $script:tmp) { Remove-Item -LiteralPath $script:tmp -Force -ErrorAction SilentlyContinue }
    }

    It 'round-trips a session and gives back a hashtable, not a PSCustomObject' {
        $session = @{ 'users/delta' = @{ Token = 'abc123' } }
        Export-PSEntraIDDeltaSession -DeltaSession $session -Path $script:tmp -Confirm:$false

        $loaded = Import-PSEntraIDDeltaSession -Path $script:tmp

        $loaded | Should -BeOfType ([hashtable])
        # The nested entry must be a hashtable too - the delta parameter indexes into it.
        $loaded['users/delta'] | Should -BeOfType ([hashtable])
        $loaded['users/delta'].Token | Should -Be 'abc123'
    }

    It 'returns an empty session when the file does not exist yet' {
        # The first run of a scheduled task has nothing to load, and an empty session is
        # exactly what a first run wants. No existence check in the calling script.
        $loaded = Import-PSEntraIDDeltaSession -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'no-such-delta-file.json')

        $loaded | Should -BeOfType ([hashtable])
        $loaded.Keys.Count | Should -Be 0
    }

    It 'keeps several endpoints apart in one file' {
        $session = @{
            'users/delta'  = @{ Token = 'u-token' }
            'groups/delta' = @{ Token = 'g-token' }
        }
        Export-PSEntraIDDeltaSession -DeltaSession $session -Path $script:tmp -Confirm:$false
        $loaded = Import-PSEntraIDDeltaSession -Path $script:tmp

        $loaded.Keys.Count | Should -Be 2
        $loaded['users/delta'].Token | Should -Be 'u-token'
        $loaded['groups/delta'].Token | Should -Be 'g-token'
    }

    It 'survives a session that a delta call has not filled in yet' {
        Export-PSEntraIDDeltaSession -DeltaSession @{} -Path $script:tmp -Confirm:$false
        $loaded = Import-PSEntraIDDeltaSession -Path $script:tmp

        $loaded | Should -BeOfType ([hashtable])
        $loaded.Keys.Count | Should -Be 0
    }

    It 'honours -WhatIf and writes nothing' {
        Export-PSEntraIDDeltaSession -DeltaSession @{ 'users/delta' = @{ Token = 'x' } } -Path $script:tmp -WhatIf
        Test-Path -LiteralPath $script:tmp | Should -BeFalse
    }
}
