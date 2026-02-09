BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force

    InModuleScope $moduleName {
        if (-not $script:_EntraEndpoints) { $script:_EntraEndpoints = @{} }
        if (-not $script:_EntraEndpoints.ContainsKey('PSMicrosoftEntraID.Graph')) {
            $script:_EntraEndpoints['PSMicrosoftEntraID.Graph'] = @{}
        }
    }
}

Describe 'Connect-PSMicrosoftEntraID' -Tag 'Unit' {
    BeforeAll {
        Mock Set-PSFConfig -ModuleName PSMicrosoftEntraID { }
        Mock Get-PSFConfigValue -ModuleName PSMicrosoftEntraID { 'PSMicrosoftEntraID.Graph' }

        Mock ConvertTo-PSFHashtable -ModuleName PSMicrosoftEntraID {
            param($InputObject, $ReferenceCommand)
            return $InputObject
        }

        Mock Connect-EntraService -ModuleName PSMicrosoftEntraID { }

        Mock Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID {
            @(
                [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'; SkuPartNumber = 'ENTERPRISEPACK' }
            )
        }

        Mock Set-PSFResultCache -ModuleName PSMicrosoftEntraID { }

        Mock Get-PSFLocalizedString -ModuleName PSMicrosoftEntraID { 'Connect failed' }
        Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('Terminating') }
    }

    Context 'Parameter Validation' {
        It 'Should include core parameter sets' {
            $command = Get-Command Connect-PSMicrosoftEntraID
            $command.ParameterSets.Name | Should -Contain 'Browser'
            $command.ParameterSets.Name | Should -Contain 'DeviceCode'
            $command.ParameterSets.Name | Should -Contain 'Refresh'
            $command.ParameterSets.Name | Should -Contain 'AppCertificate'
            $command.ParameterSets.Name | Should -Contain 'AppSecret'
            $command.ParameterSets.Name | Should -Contain 'UsernamePassword'
            $command.ParameterSets.Name | Should -Contain 'KeyVault'
            $command.ParameterSets.Name | Should -Contain 'Identity'
            $command.ParameterSets.Name | Should -Contain 'AzAccount'
            $command.ParameterSets.Name | Should -Contain 'Federated'
        }
    }

    Context 'Happy path' {
        It 'Should connect and cache subscribed SKUs' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser

            Should -Invoke Connect-EntraService -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Set-PSFResultCache -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should set default service config' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser

            Should -Invoke Set-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.DefaultService'
            } -Times 1 -Scope It
        }
    }

    Context 'Error handling' {
        It 'Should terminate when Connect-EntraService fails' {
            Mock Connect-EntraService -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('connect failed') }

            { Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser } | Should -Throw
        }
    }
}
