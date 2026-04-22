BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Set-PSEntraIDCommandRetry Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should accept valid RetryCount values (0-10)' {
            { Set-PSEntraIDCommandRetry -RetryCount 0 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -RetryCount 5 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -RetryCount 10 } | Should -Not -Throw
        }

        It 'Should accept valid RetryWaitInSeconds values (0-10)' {
            { Set-PSEntraIDCommandRetry -RetryWaitInSeconds 0 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -RetryWaitInSeconds 5 } | Should -Not -Throw
            { Set-PSEntraIDCommandRetry -RetryWaitInSeconds 10 } | Should -Not -Throw
        }

        It 'Should reject RetryCount values outside range (0-10)' {
            { Set-PSEntraIDCommandRetry -RetryCount -1 } | Should -Throw
            { Set-PSEntraIDCommandRetry -RetryCount 11 } | Should -Throw
        }

        It 'Should reject RetryWaitInSeconds values outside range (0-10)' {
            { Set-PSEntraIDCommandRetry -RetryWaitInSeconds -1 } | Should -Throw
            { Set-PSEntraIDCommandRetry -RetryWaitInSeconds 11 } | Should -Throw
        }
    }

    Context 'Configuration Updates' {
        It 'Should update RetryCount configuration' {
            Set-PSEntraIDCommandRetry -RetryCount 7

            $result = Get-PSEntraIDCommandRetry
            $result.RetryCount | Should -Be 7

            # Reset
            Set-PSEntraIDCommandRetry -RetryCount 0
        }

        It 'Should update RetryWaitInSeconds configuration' {
            Set-PSEntraIDCommandRetry -RetryWaitInSeconds 4

            $result = Get-PSEntraIDCommandRetry
            $result.RetryWaitInSeconds | Should -Be 4

            # Reset
            Set-PSEntraIDCommandRetry -RetryWaitInSeconds 0
        }

        It 'Should update both parameters simultaneously' {
            Set-PSEntraIDCommandRetry -RetryCount 3 -RetryWaitInSeconds 2

            $result = Get-PSEntraIDCommandRetry
            $result.RetryCount | Should -Be 3
            $result.RetryWaitInSeconds | Should -Be 2

            # Reset
            Set-PSEntraIDCommandRetry -RetryCount 0 -RetryWaitInSeconds 0
        }
    }

    Context 'Default Values' {
        It 'Should use default value 0 for RetryCount when not specified' {
            Set-PSEntraIDCommandRetry

            $result = Get-PSEntraIDCommandRetry
            $result.RetryCount | Should -Be 0
        }

        It 'Should use default value 0 for RetryWaitInSeconds when not specified' {
            Set-PSEntraIDCommandRetry

            $result = Get-PSEntraIDCommandRetry
            $result.RetryWaitInSeconds | Should -Be 0
        }
    }
}
