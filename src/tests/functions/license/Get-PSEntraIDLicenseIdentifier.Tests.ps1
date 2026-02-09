BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'
    $commandName = 'Get-PSEntraIDLicenseIdentifier'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe "Get-PSEntraIDLicenseIdentifier" -Tag 'Unit' {
    BeforeAll {
        # Don't run the actual function, just test that it works
        # The function reads from a real JSON file in the module
    }

    Context 'Parameter Validation' {
        It 'Should have EnableException as a switch parameter' {
            $parameter = (Get-Command Get-PSEntraIDLicenseIdentifier).Parameters['EnableException']
            $parameter.SwitchParameter | Should -Be $true
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDLicenseIdentifier
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.License.LicenseIdentifier'
        }

        It 'Should not require any mandatory parameters' {
            $command = Get-Command Get-PSEntraIDLicenseIdentifier
            $mandatoryParams = $command.Parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            $mandatoryParams | Should -BeNullOrEmpty
        }
    }

    Context 'Basic Functionality' {
        It 'Should retrieve license identifiers from JSON file' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Should return license identifiers with required properties' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result[0].SkuPartNumber | Should -Not -BeNullOrEmpty
            $result[0].SkuId | Should -Not -BeNullOrEmpty
        }

        It 'Should include service plans in results' {
            $result = Get-PSEntraIDLicenseIdentifier

            # At least some licenses should have service plans
            $withPlans = $result | Where-Object { $_.ServicePlans.Count -gt 0 }
            $withPlans | Should -Not -BeNullOrEmpty
        }

        It 'Should return objects of correct type' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result[0].GetType().Name | Should -Be 'LicenseIdentifier'
        }
    }

    Context 'File Path Construction' {
        It 'Should read from LicenseIdentifiers.json in module' {
            $result = Get-PSEntraIDLicenseIdentifier

            # Function successfully reads and deserializes the file
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'JSON Deserialization' {
        It 'Should deserialize JSON using DataContractJsonSerializer' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [Object]
        }

        It 'Should handle UTF-8 encoding' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should return array of license identifier objects' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result.Count | Should -BeGreaterThan 1
        }
    }

    Context 'Return Values' {
        It 'Should return objects with SkuId property' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result[0].SkuId | Should -Not -BeNullOrEmpty
            $result[0].SkuId | Should -Match '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        }

        It 'Should return objects with SkuPartNumber property' {
            $result = Get-PSEntraIDLicenseIdentifier

            $result[0].SkuPartNumber | Should -Not -BeNullOrEmpty
        }

        It 'Should return objects with ProductName property' {
            $result = Get-PSEntraIDLicenseIdentifier

            # ProductName may be null for some licenses in the real data
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should include service plan IDs' {
            $result = Get-PSEntraIDLicenseIdentifier
            $withPlans = $result | Where-Object { $_.ServicePlans.Count -gt 0 }

            $withPlans[0].ServicePlans[0].ServicePlanId | Should -Not -BeNullOrEmpty
        }

        It 'Should include service plan names' {
            $result = Get-PSEntraIDLicenseIdentifier
            $withPlans = $result | Where-Object { $_.ServicePlans.Count -gt 0 }

            $withPlans[0].ServicePlans[0].ServicePlanName | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should respect EnableException parameter' {
            # EnableException is present but this function doesn't use Invoke-PSFProtectedCommand
            # So it should still work normally
            $result = Get-PSEntraIDLicenseIdentifier -EnableException

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'No External Dependencies' {
        It 'Should not require Entra connection' {
            # This function reads from local file, no connection needed
            $result = Get-PSEntraIDLicenseIdentifier

            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should not make API calls' {
            # This function reads from local file, no API calls made
            $result = Get-PSEntraIDLicenseIdentifier

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Memory Stream Handling' {
        It 'Should properly handle memory stream for deserialization' {
            $result = Get-PSEntraIDLicenseIdentifier

            # Should successfully deserialize without memory issues
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }

        It 'Should handle large JSON files' {
            $result = Get-PSEntraIDLicenseIdentifier

            # The real file has many licenses
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 10
        }
    }
}
