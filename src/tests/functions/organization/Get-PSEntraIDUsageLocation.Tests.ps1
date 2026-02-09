BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDUsageLocation Tests' -Tag 'Unit' {
    Context 'Parameter Validation' {
        It 'Should not have any parameters' {
            $command = Get-Command Get-PSEntraIDUsageLocation
            $params = $command.Parameters.Keys | Where-Object {
                $_ -notin [System.Management.Automation.Cmdlet]::CommonParameters
            }

            $params.Count | Should -Be 0
        }
    }

    Context 'Output Type' {
        It 'Should have System.Collections.Hashtable as output type' {
            $command = Get-Command Get-PSEntraIDUsageLocation
            $outputType = $command.OutputType

            $outputType.Name | Should -Contain 'System.Collections.Hashtable'
        }

        It 'Should return a hashtable' {
            $result = Get-PSEntraIDUsageLocation

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [hashtable]
        }
    }

    Context 'CmdletBinding' {
        It 'Should be an advanced function' {
            $command = Get-Command Get-PSEntraIDUsageLocation

            $command.CmdletBinding | Should -Be $true
        }
    }

    Context 'Functionality' {
        It 'Should load usage locations from JSON file' {
            $result = Get-PSEntraIDUsageLocation

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Should contain common country codes' {
            $result = Get-PSEntraIDUsageLocation

            # Test for some common countries that should be in the list
            $result.Keys | Should -Contain 'United States of America (the)'
            $result['United States of America (the)'] | Should -Be 'US'
        }

        It 'Should have string keys and string values' {
            $result = Get-PSEntraIDUsageLocation

            foreach ($key in $result.Keys) {
                $key | Should -BeOfType [string]
                $result[$key] | Should -BeOfType [string]
            }
        }

        It 'Should return consistent results on multiple calls' {
            $result1 = Get-PSEntraIDUsageLocation
            $result2 = Get-PSEntraIDUsageLocation

            $result1.Count | Should -Be $result2.Count
            
            foreach ($key in $result1.Keys) {
                $result2.Keys | Should -Contain $key
                $result2[$key] | Should -Be $result1[$key]
            }
        }
    }

    Context 'File Access' {
        It 'Should reference UsageLocation.json file' {
            $functionContent = (Get-Command Get-PSEntraIDUsageLocation).ScriptBlock.ToString()

            $functionContent | Should -Match 'UsageLocation\.json'
        }

        It 'Should use Join-Path for file location' {
            $functionContent = (Get-Command Get-PSEntraIDUsageLocation).ScriptBlock.ToString()

            $functionContent | Should -Match 'Join-Path'
        }

        It 'Should convert JSON to hashtable' {
            $functionContent = (Get-Command Get-PSEntraIDUsageLocation).ScriptBlock.ToString()

            $functionContent | Should -Match 'ConvertFrom-Json'
            $functionContent | Should -Match 'ConvertTo-PSFHashtable'
        }
    }
}
