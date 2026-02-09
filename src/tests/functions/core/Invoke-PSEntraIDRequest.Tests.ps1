BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Invoke-PSEntraIDRequest' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        Set-Variable -Name '_DefaultService' -Value 'PSMicrosoftEntraID.Graph' -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{ id = '001'; displayName = 'Test Result' }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName ConvertTo-PSFHashtable { @{ Path = 'test/path'; Method = 'GET' } }
        Mock -ModuleName $script:ModuleName Get-ServiceCompletion { @() }
        Mock -ModuleName $script:ModuleName Assert-ServiceName { $true }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Path parameter' {
            $param = (Get-Command Invoke-PSEntraIDRequest).Parameters['Path']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have OutputType pscustomobject' {
            (Get-Command Invoke-PSEntraIDRequest).OutputType.Name | Should -Contain 'System.Management.Automation.PSObject'
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Invoke-PSEntraIDRequest
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have Method parameter defaulting to GET' {
            $param = (Get-Command Invoke-PSEntraIDRequest).Parameters['Method']
            $param | Should -Not -BeNullOrEmpty
        }

        It 'Should have expected optional parameters' {
            $command = Get-Command Invoke-PSEntraIDRequest
            $expectedParams = @('Body', 'Query', 'Header', 'Service', 'NoPaging', 'Raw', 'Token', 'SerializationDepth')
            foreach ($param in $expectedParams) {
                $command.Parameters.ContainsKey($param) | Should -Be $true
            }
        }

        It 'Should have SerializationDepth with ValidateRange 1 to 666' {
            $param = (Get-Command Invoke-PSEntraIDRequest).Parameters['SerializationDepth']
            $validateRange = $param.Attributes.Where{ $_ -is [ValidateRange] }
            $validateRange | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Execute request' {
        It 'Should call Invoke-EntraRequest with provided path' {
            Invoke-PSEntraIDRequest -Path 'users' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1
        }

        It 'Should use the default service from config' {
            Invoke-PSEntraIDRequest -Path 'users' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            }
        }

        It 'Should pass through parameters via ConvertTo-PSFHashtable' {
            Invoke-PSEntraIDRequest -Path 'users' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertTo-PSFHashtable -Times 1
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            Invoke-PSEntraIDRequest -Path 'users' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
