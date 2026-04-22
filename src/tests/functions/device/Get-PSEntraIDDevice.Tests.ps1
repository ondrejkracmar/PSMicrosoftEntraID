BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDDevice' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
    }

    Context 'Parameter Validation' {
        It 'Should have Identity parameter set' {
            $command = Get-Command Get-PSEntraIDDevice
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have OutputType PSMicrosoftEntraID.Devices.Device' {
            (Get-Command Get-PSEntraIDDevice).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Devices.Device'
        }

        It 'Should have mandatory Identity parameter with aliases' {
            $param = (Get-Command Get-PSEntraIDDevice).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
            $param.Aliases | Should -Contain 'Id'
            $param.Aliases | Should -Contain 'DeviceId'
        }

        It 'Should accept pipeline input for Identity' {
            $param = (Get-Command Get-PSEntraIDDevice).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'Get device by displayName (lookup match found)' {
        BeforeEach {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                # First call: displayName lookup returns match
                [PSCustomObject]@{ Id = 'device-001'; displayName = 'MyLaptop' }
            } -ParameterFilter { $Query -and $Query.'$Filter' -like "displayName*" }

            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                # Second call: get full device details by Id
                [PSCustomObject]@{
                    id            = 'device-001'
                    displayName   = 'MyLaptop'
                    operatingSystem = 'Windows'
                    deviceId      = 'hw-device-id'
                }
            } -ParameterFilter { $Path -like 'devices/device-001' }
        }

        It 'Should first query by displayName then fetch by resolved Id' {
            Get-PSEntraIDDevice -Identity 'MyLaptop'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2
        }

        It 'Should return device details with PSTypeName' {
            $result = Get-PSEntraIDDevice -Identity 'MyLaptop'

            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 'device-001'
        }
    }

    Context 'Get device by Id directly (no displayName match)' {
        BeforeEach {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $null
            } -ParameterFilter { $Query -and $Query.'$Filter' -like "displayName*" }

            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                [PSCustomObject]@{
                    id            = '00000000-0000-0000-0000-000000000099'
                    displayName   = 'DirectDevice'
                    operatingSystem = 'Linux'
                }
            } -ParameterFilter { $Path -like 'devices/00000000-0000-0000-0000-000000000099' }
        }

        It 'Should fall back to using Identity as Id' {
            Get-PSEntraIDDevice -Identity '00000000-0000-0000-0000-000000000099'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'devices/00000000-0000-0000-0000-000000000099'
            }
        }
    }

    Context 'Get device when API returns null details' {
        BeforeEach {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $null
            }
        }

        It 'Should return fallback device object with PSTypeName' {
            $result = Get-PSEntraIDDevice -Identity 'unknown-device'

            $result | Should -Not -BeNullOrEmpty
            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Devices.Device'
            $result.DisplayName | Should -Be 'unknown-device'
        }
    }

    Context 'Connection handling' {
        BeforeEach {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest { $null }
        }

        It 'Should assert Entra connection' {
            Get-PSEntraIDDevice -Identity 'test-device'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
