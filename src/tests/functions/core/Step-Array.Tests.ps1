BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Step-Array' -Tag 'Unit' {
    # Add-PSEntraIDGroupMember sends members@odata.bind in chunks of 20. Step-Array used to
    # emit an empty trailing chunk for an exact multiple of the size, and its caller then
    # flattened the chunks into space-joined strings. These tests pin the chunk shape.

    It 'cuts <Count> items into chunks of <Expected> with size 20' -TestCases @(
        @{ Count = 1; Expected = @(1) }
        @{ Count = 19; Expected = @(19) }
        @{ Count = 20; Expected = @(20) }
        @{ Count = 21; Expected = @(20, 1) }
        @{ Count = 40; Expected = @(20, 20) }
        @{ Count = 41; Expected = @(20, 20, 1) }
    ) {
        $chunks = InModuleScope PSMicrosoftEntraID -Parameters @{ Count = $Count } {
            param($Count)
            , @(1..$Count | ForEach-Object { 'item{0}' -f $_ } | Step-Array -Size 20)
        }

        $chunks.Count | Should -Be $Expected.Count
        for ($index = 0; $index -lt $Expected.Count; $index++) {
            , $chunks[$index] | Should -BeOfType [object[]]
            $chunks[$index].Count | Should -Be $Expected[$index]
        }
        # Every item exactly once, in order: nothing joined, nothing lost, nothing empty.
        ($chunks | ForEach-Object { $_ }) -join ',' | Should -BeExactly ((1..$Count | ForEach-Object { 'item{0}' -f $_ }) -join ',')
    }

    It 'keeps a one-item chunk an array, not a scalar' {
        $chunks = InModuleScope PSMicrosoftEntraID {
            , @('a', 'b', 'c' | Step-Array -Size 2)
        }

        $chunks.Count | Should -Be 2
        , $chunks[1] | Should -BeOfType [object[]]
        (ConvertTo-Json -InputObject $chunks[1] -Compress) | Should -BeExactly '["c"]'
    }

    It 'chunks objects, not just strings' {
        $chunks = InModuleScope PSMicrosoftEntraID {
            , @(1..3 | ForEach-Object { [PSCustomObject]@{ Id = $_ } } | Step-Array -Size 2)
        }

        $chunks[0][1].Id | Should -Be 2
        $chunks[1][0].Id | Should -Be 3
    }

    It 'takes the items as an argument as well as from the pipeline' {
        $chunks = InModuleScope PSMicrosoftEntraID {
            , @(Step-Array -Item @('a', 'b', 'c') -Size 2)
        }

        $chunks.Count | Should -Be 2
        $chunks[0] -join ',' | Should -BeExactly 'a,b'
    }
}
