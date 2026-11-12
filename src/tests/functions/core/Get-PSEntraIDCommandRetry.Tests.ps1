BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Import here rather than relying on whichever test file happened to run first:
    # Pester executes every file in ONE runspace, so an ambient import made these
    # tests pass alone and fail in a full run with
    #   RuntimeException: No modules named 'PSMicrosoftEntraID' are currently loaded.
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Get-PSEntraIDCommandRetry Tests' -Tag 'Unit' {
    Context 'Basic Functionality' {
        It 'Should return a hashtable with RetryCount and BatchRetryCount' {
            $result = Get-PSEntraIDCommandRetry

            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'RetryCount'
            $result.Keys | Should -Contain 'BatchRetryCount'
            $result.RetryCount | Should -BeOfType [int]
            $result.BatchRetryCount | Should -BeOfType [int]
        }

        It 'Should read Settings.Request.RetryCount and Settings.Batch.RetryCount' {
            $result = Get-PSEntraIDCommandRetry

            $result.RetryCount | Should -Be (Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount')
            $result.BatchRetryCount | Should -Be (Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount')
        }
    }
}
