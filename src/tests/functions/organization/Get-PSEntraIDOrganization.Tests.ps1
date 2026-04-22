BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDOrganization' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 100 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'verifiedDomains') }
        } -ParameterFilter { $Name -like '*Select.Organization' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{ id = 'org-001'; displayName = 'Contoso'; verifiedDomains = @(@{name = 'contoso.com'}) }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestOrganizationDetail { $InputObject }
    }

    Context 'Parameter Validation' {
        It 'Should have OutputType PSMicrosoftEntraID.Organization' {
            (Get-Command Get-PSEntraIDOrganization).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Organization'
        }

        It 'Should have EnableException parameter' {
            (Get-Command Get-PSEntraIDOrganization).Parameters.ContainsKey('EnableException') | Should -Be $true
        }

        It 'Should not support ShouldProcess' {
            $command = Get-Command Get-PSEntraIDOrganization
            # It's a read-only command, no WhatIf needed (the function does use -WhatIf:$false to bypass it)
            $command.Parameters.ContainsKey('EnableException') | Should -Be $true
        }
    }

    Context 'Get organization' {
        It 'Should call API with GET to organization path' {
            Get-PSEntraIDOrganization

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'organization' -and $Method -eq 'Get'
            }
        }

        It 'Should include query parameters with count and top' {
            Get-PSEntraIDOrganization

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true' -and $Query.'$top' -ne $null
            }
        }

        It 'Should include select query parameter' {
            Get-PSEntraIDOrganization

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$select' -ne $null
            }
        }

        It 'Should convert response using ConvertFrom-RestOrganizationDetail' {
            Get-PSEntraIDOrganization

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestOrganizationDetail -Times 1
        }

        It 'Should return organization data' {
            $result = Get-PSEntraIDOrganization

            $result | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be 'Contoso'
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            Get-PSEntraIDOrganization

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
