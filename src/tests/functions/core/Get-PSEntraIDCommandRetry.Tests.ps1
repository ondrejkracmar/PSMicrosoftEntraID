BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDCommandRetry Tests' -Tag 'Unit' {
    Context 'Basic Functionality' {
        It 'Should return a hashtable with RetryCount and RetryWaitInSeconds keys' {
            $result = Get-PSEntraIDCommandRetry

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'RetryCount'
            $result.Keys | Should -Contain 'RetryWaitInSeconds'
        }

        It 'Should return numeric values' {
            $result = Get-PSEntraIDCommandRetry

            $result.RetryCount | Should -BeOfType [int]
            $result.RetryWaitInSeconds | Should -BeOfType [int]
        }

        It 'Should return non-negative values' {
            $result = Get-PSEntraIDCommandRetry

            $result.RetryCount | Should -BeGreaterOrEqual 0
            $result.RetryWaitInSeconds | Should -BeGreaterOrEqual 0
        }
    }

    Context 'Integration with Set-PSEntraIDCommandRetry' {
        It 'Should return updated values after using Set-PSEntraIDCommandRetry' {
            # Set known values
            Set-PSEntraIDCommandRetry -RetryCount 5 -RetryWaitInSeconds 3

            # Get values
            $result = Get-PSEntraIDCommandRetry

            $result.RetryCount | Should -Be 5
            $result.RetryWaitInSeconds | Should -Be 3

            # Reset to defaults
            Set-PSEntraIDCommandRetry -RetryCount 0 -RetryWaitInSeconds 0
        }
    }
}
