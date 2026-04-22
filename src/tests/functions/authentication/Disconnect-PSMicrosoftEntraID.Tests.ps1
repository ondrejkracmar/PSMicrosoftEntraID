BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force

    InModuleScope $moduleName {
        if (-not $script:_EntraEndpoints) { $script:_EntraEndpoints = @{} }
        if (-not $script:_EntraEndpoints.ContainsKey('PSMicrosoftEntraID.Graph')) {
            $script:_EntraEndpoints['PSMicrosoftEntraID.Graph'] = @{}
        }
        if (-not $script:_EntraTokens) { $script:_EntraTokens = @{} }
    }
}

Describe 'Disconnect-PSMicrosoftEntraID' -Tag 'Unit' {
    BeforeAll {
        Mock Clear-PSFResultCache -ModuleName PSMicrosoftEntraID { }
        Mock Get-PSFLocalizedString -ModuleName PSMicrosoftEntraID { 'Disconnected' }
    }

    It 'Should clear token for default service' {
        InModuleScope PSMicrosoftEntraID {
            $script:_EntraTokens['PSMicrosoftEntraID.Graph'] = 'token'
        }

        Disconnect-PSMicrosoftEntraID

        InModuleScope PSMicrosoftEntraID {
            $script:_EntraTokens['PSMicrosoftEntraID.Graph'] | Should -BeNullOrEmpty
        }
    }

    It 'Should clear cache when verbose' {
        InModuleScope PSMicrosoftEntraID {
            $script:_EntraTokens['PSMicrosoftEntraID.Graph'] = 'token'
        }

        Disconnect-PSMicrosoftEntraID -Verbose

        Should -Invoke Clear-PSFResultCache -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
    }
}
