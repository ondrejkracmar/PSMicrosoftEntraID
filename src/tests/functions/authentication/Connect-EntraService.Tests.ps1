BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force

    InModuleScope $moduleName {
        if (-not $script:_EntraEndpoints) { $script:_EntraEndpoints = @{} }
        if (-not $script:_EntraEndpoints.ContainsKey('PSMicrosoftEntraID.Graph')) {
            $script:_EntraEndpoints['PSMicrosoftEntraID.Graph'] = @{}
        }
    }
}

Describe 'Connect-EntraService (internal)' -Tag 'Unit' {
    BeforeAll {
        # Keep this test focused on the label->GUID mapping in Begin.
        # We use the -RefreshToken parameter set and stop before token construction.
        Mock Get-EntraService -ModuleName PSMicrosoftEntraID {
            [PSCustomObject]@{
                Resource      = 'https://graph.microsoft.com'
                ServiceUrl    = 'https://graph.microsoft.com'
                DefaultScopes = @('https://graph.microsoft.com/.default')
                NoRefresh     = $false
            }
        }
    }

    It "Should resolve ClientID label 'Graph' to the first-party GUID" {
        $graphGuid = '14d82eec-204b-4c2f-b7e8-296a70dab67e'

        $script:capturedClientID = $null
        Mock Connect-ServiceRefreshToken -ModuleName PSMicrosoftEntraID {
            param(
                [string]$ClientID,
                [string]$TenantID,
                [string]$Resource,
                [string]$AuthenticationUrl,
                [string]$RefreshToken,
                [string[]]$Scopes
            )
            $script:capturedClientID = $ClientID
            throw [System.Exception]::new('StopAfterCapture')
        }

        InModuleScope PSMicrosoftEntraID {
            { Connect-EntraService -ClientID 'Graph' -TenantID 'organizations' -RefreshToken 'rt' -Service 'PSMicrosoftEntraID.Graph' } | Should -Throw
        }

        $script:capturedClientID | Should -Be $graphGuid
    }

    It "Should resolve ClientID label 'Azure' to the first-party GUID" {
        $azureGuid = '1950a258-227b-4e31-a9cf-717495945fc2'

        $script:capturedClientID = $null
        Mock Connect-ServiceRefreshToken -ModuleName PSMicrosoftEntraID {
            param(
                [string]$ClientID,
                [string]$TenantID,
                [string]$Resource,
                [string]$AuthenticationUrl,
                [string]$RefreshToken,
                [string[]]$Scopes
            )
            $script:capturedClientID = $ClientID
            throw [System.Exception]::new('StopAfterCapture')
        }

        InModuleScope PSMicrosoftEntraID {
            { Connect-EntraService -ClientID 'Azure' -TenantID 'organizations' -RefreshToken 'rt' -Service 'PSMicrosoftEntraID.Graph' } | Should -Throw
        }

        $script:capturedClientID | Should -Be $azureGuid
    }
}
