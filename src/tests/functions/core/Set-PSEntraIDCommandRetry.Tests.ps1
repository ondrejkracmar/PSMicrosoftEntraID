BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Import here rather than relying on whichever test file happened to run first:
    # Pester executes every file in ONE runspace, so an ambient import made these
    # tests pass alone and fail in a full run with
    #   RuntimeException: No modules named 'PSMicrosoftEntraID' are currently loaded.
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
    $script:requestBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount'
    $script:batchBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount'
}

AfterAll {
    Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value $script:requestBefore
    Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value $script:batchBefore
}

Describe 'Set-PSEntraIDCommandRetry Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should accept RetryCount and BatchRetryCount from 0 to 20' {
            { Set-PSEntraIDCommandRetry -RetryCount 0 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -RetryCount 20 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -BatchRetryCount 0 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -BatchRetryCount 20 } | Should -Not -Throw
        }

        It 'Should reject values outside 0 to 20' {
            { Set-PSEntraIDCommandRetry -RetryCount -1 } | Should -Throw
            { Set-PSEntraIDCommandRetry -RetryCount 21 } | Should -Throw
            { Set-PSEntraIDCommandRetry -BatchRetryCount 21 } | Should -Throw
        }
    }

    Context 'Configuration Updates' {
        It 'Should set Settings.Request.RetryCount, the one retry of a single request' {
            Set-PSEntraIDCommandRetry -RetryCount 7
            Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' | Should -Be 7
            (Get-PSEntraIDCommandRetry).RetryCount | Should -Be 7
        }

        It 'Should set Settings.Batch.RetryCount, the retry of a batch sub-request' {
            Set-PSEntraIDCommandRetry -BatchRetryCount 3
            Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' | Should -Be 3
            (Get-PSEntraIDCommandRetry).BatchRetryCount | Should -Be 3
        }

        It 'Should change nothing when called without parameters' {
            Set-PSEntraIDCommandRetry -RetryCount 4 -BatchRetryCount 6
            Set-PSEntraIDCommandRetry
            $result = Get-PSEntraIDCommandRetry
            $result.RetryCount | Should -Be 4
            $result.BatchRetryCount | Should -Be 6
        }

        It 'Should accept RetryWaitInSeconds for old scripts, change nothing and warn' {
            Set-PSEntraIDCommandRetry -RetryCount 2
            Set-PSEntraIDCommandRetry -RetryWaitInSeconds 5 -WarningVariable warned -WarningAction SilentlyContinue
            @($warned).Count | Should -Be 1
            (Get-PSEntraIDCommandRetry).RetryCount | Should -Be 2
        }

        It 'Should leave the removed Settings.Command keys alone: no module code reads or writes them' {
            $moduleRoot = (Get-Module PSMicrosoftEntraID).ModuleBase
            $hits = Get-ChildItem -Path $moduleRoot -Recurse -Include '*.ps1', '*.psm1' | Select-String -Pattern '[''"][^''"#]*Settings\.Command\.'
            $hits | Should -BeNullOrEmpty
        }
    }
}
