BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force

    InModuleScope $moduleName {
        if (-not $script:_EntraEndpoints) { $script:_EntraEndpoints = @{} }
        if (-not $script:_EntraEndpoints.ContainsKey('PSMicrosoftEntraID.Graph')) {
            $script:_EntraEndpoints['PSMicrosoftEntraID.Graph'] = @{ Resource = 'https://graph.microsoft.com' }
        }
        if (-not $script:_EntraEndpoints.ContainsKey('PSMicrosoftEntraID.Endpoint')) {
            $script:_EntraEndpoints['PSMicrosoftEntraID.Endpoint'] = @{ Resource = 'https://api.securitycenter.microsoft.com' }
        }
    }
}

Describe 'Connect-PSMicrosoftEntraID' -Tag 'Unit' {
    BeforeAll {
        Mock Set-PSFConfig -ModuleName PSMicrosoftEntraID { }
        Mock Get-PSFConfigValue -ModuleName PSMicrosoftEntraID { 'PSMicrosoftEntraID.Graph' }

        # The behavior receives the piped $PSBoundParameters enumerated into KeyValuePair items -
        # rebuild the hashtable from the pairs and honor -Exclude like the real command does.
        Mock ConvertTo-PSFHashtable -ModuleName PSMicrosoftEntraID {
            param(
                [Parameter(ValueFromPipeline = $true)] $InputObject,
                $ReferenceCommand,
                [string[]] $Exclude
            )
            $result = @{}
            foreach ($entry in @($InputObject)) {
                if ($entry -is [System.Collections.IDictionary]) {
                    foreach ($key in $entry.Keys) {
                        if ($key -notin $Exclude) { $result[$key] = $entry[$key] }
                    }
                }
                elseif ($null -ne $entry.Key -and $entry.Key -notin $Exclude) {
                    $result[$entry.Key] = $entry.Value
                }
            }
            $result
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

    Context 'Service handling' {
        It 'Should pass all requested services to Connect-EntraService' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Graph', 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Connect-EntraService -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service.Count -eq 2 -and
                $Service -contains 'PSMicrosoftEntraID.Graph' -and
                $Service -contains 'PSMicrosoftEntraID.Endpoint'
            } -Times 1 -Scope It
        }

        It 'Should set the default service to a single Graph-based service, never the array' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Graph', 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Set-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.DefaultService' -and $Value -eq 'PSMicrosoftEntraID.Graph'
            } -Times 1 -Scope It
        }

        It 'Should warm the license cache when a Graph service is among the connected services' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Graph', 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
            Should -Invoke Set-PSFResultCache -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should not rewrite the Graph default service on an Endpoint-only connect' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Set-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.DefaultService'
            } -Times 0 -Scope It
        }

        It 'Should update the Endpoint family default on an Endpoint-only connect' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Set-PSFConfig -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Name -eq 'Settings.DefaultServiceEndpoint' -and $Value -eq 'PSMicrosoftEntraID.Endpoint'
            } -Times 1 -Scope It
        }

        It 'Should skip the license cache on an Endpoint-only connect' {
            Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser -Service 'PSMicrosoftEntraID.Endpoint'

            Should -Invoke Connect-EntraService -ModuleName PSMicrosoftEntraID -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Endpoint'
            } -Times 1 -Scope It
            Should -Invoke Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID -Times 0 -Scope It
            Should -Invoke Set-PSFResultCache -ModuleName PSMicrosoftEntraID -Times 0 -Scope It
        }
    }

    Context 'Error handling' {
        It 'Should terminate when Connect-EntraService fails' {
            Mock Connect-EntraService -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('connect failed') }

            { Connect-PSMicrosoftEntraID -ClientID 'Graph' -TenantID 'organizations' -Browser } | Should -Throw
        }
    }
}
