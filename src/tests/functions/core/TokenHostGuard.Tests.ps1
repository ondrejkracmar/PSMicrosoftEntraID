BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

<#
The access token goes only over https and only to the host of the service it belongs to (ported from
PSExchangeOnline, review finding M3 of 2026-10-20).

Before this, Resolve-RequestUri returned any absolute -Path as it was and Invoke-EntraRequest followed every
@odata.nextLink - both with "Authorization: Bearer <token>". A next link or a -Path naming another host, or plain
http, handed the token to whoever answered there. Now every URL - the first and each next link - is checked against
the ServiceUrl of the token that would be sent (Graph, Graph beta, Defender for Endpoint, Defender XDR, Azure,
Key Vault with its %VAULTNAME% resolved) before anything is sent.
#>
Describe 'The access token goes only over https to the host of its service' -Tag 'Unit' {

    Context 'Get-EntraUriRefusal decides per service' {

        It 'allows <Uri> for <Service>' -ForEach @(
            @{ Service = 'Graph'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://graph.microsoft.com/v1.0/users?$skiptoken=x' }
            @{ Service = 'Graph (beta path on a v1.0 token)'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://graph.microsoft.com/beta/users' }
            @{ Service = 'GraphBeta'; ServiceUrl = 'https://graph.microsoft.com/beta'; Uri = 'https://GRAPH.microsoft.com/beta/users' }
            @{ Service = 'Endpoint'; ServiceUrl = 'https://api.securitycenter.microsoft.com/api'; Uri = 'https://api.securitycenter.microsoft.com/api/machines?$skip=10000' }
            @{ Service = 'Security'; ServiceUrl = 'https://api.security.microsoft.com/api'; Uri = 'https://api.security.microsoft.com/api/incidents' }
            @{ Service = 'Azure'; ServiceUrl = 'https://management.azure.com'; Uri = 'https://management.azure.com/subscriptions?api-version=2022-12-01' }
            @{ Service = 'KeyVault'; ServiceUrl = 'https://myvault.vault.azure.net'; Uri = 'https://myvault.vault.azure.net/secrets/x?api-version=7.4' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Uri = $Uri; ServiceUrl = $ServiceUrl } {
                Get-EntraUriRefusal -Uri $Uri -ServiceUrl $ServiceUrl | Should -BeNullOrEmpty
            }
        }

        It 'refuses <Case>' -ForEach @(
            @{ Case = 'another host'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://attacker.example/v1.0/users'; Expected = '*goes only to https://graph.microsoft.com*' }
            @{ Case = 'a look-alike host'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://graph.microsoft.com.attacker.example/v1.0/users'; Expected = '*goes only to*' }
            @{ Case = 'another port'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://graph.microsoft.com:8443/v1.0/users'; Expected = '*goes only to*' }
            @{ Case = 'http on the same host'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'http://graph.microsoft.com/v1.0/users'; Expected = '*only over https*' }
            @{ Case = 'user info'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'https://u:p@graph.microsoft.com/v1.0/users'; Expected = '*not an absolute URL without user info*' }
            @{ Case = 'a relative URL'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Uri = 'users'; Expected = '*not an absolute URL*' }
            @{ Case = 'a Graph URL on a Defender for Endpoint token'; ServiceUrl = 'https://api.securitycenter.microsoft.com/api'; Uri = 'https://graph.microsoft.com/v1.0/users'; Expected = '*goes only to https://api.securitycenter.microsoft.com*' }
            @{ Case = 'another vault on a Key Vault token'; ServiceUrl = 'https://myvault.vault.azure.net'; Uri = 'https://othervault.vault.azure.net/secrets/x'; Expected = '*goes only to https://myvault.vault.azure.net*' }
            @{ Case = 'an http service URL'; ServiceUrl = 'http://graph.microsoft.com/v1.0'; Uri = 'https://graph.microsoft.com/v1.0/users'; Expected = '*goes only to*' }
            @{ Case = 'no service URL'; ServiceUrl = ''; Uri = 'https://graph.microsoft.com/v1.0/users'; Expected = '*goes only to*' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Uri = $Uri; ServiceUrl = $ServiceUrl; Expected = $Expected } {
                Get-EntraUriRefusal -Uri $Uri -ServiceUrl $ServiceUrl | Should -BeLike $Expected
            }
        }

        It 'names a refused URL without its query or user info' {
            InModuleScope PSMicrosoftEntraID {
                $refusal = Get-EntraUriRefusal -Uri 'https://attacker.example/v1.0/users?$skiptoken=S3cr3tSk1p' -ServiceUrl 'https://graph.microsoft.com/v1.0'
                $refusal | Should -BeLike '*https://attacker.example/v1.0/users*'
                $refusal | Should -Not -BeLike '*S3cr3tSk1p*'
            }
        }
    }

    Context 'Resolve-EntraServiceUrl' {

        It 'fills the placeholders of a service URL literally' {
            InModuleScope PSMicrosoftEntraID {
                $token = [pscustomobject]@{ ServiceUrl = 'https://%VAULTNAME%.vault.azure.net' }
                # Registered as VaultName for the placeholder %VAULTNAME% - as services.ps1 does.
                $service = [pscustomobject]@{ Parameters = @{ VaultName = 'Name of the vault' } }
                Resolve-EntraServiceUrl -TokenObject $token -ServiceObject $service -BoundParameters @{ VaultName = 'myvault' } | Should -Be 'https://myvault.vault.azure.net'
                # Not bound: the placeholder is left empty, which the guard refuses rather than guessing a host.
                Resolve-EntraServiceUrl -TokenObject $token -ServiceObject $service -BoundParameters @{} | Should -Be 'https://.vault.azure.net'
            }
        }
    }

    Context 'Invoke-EntraRequest' {

        BeforeAll {
            InModuleScope PSMicrosoftEntraID {
                $script:guardToken = [pscustomobject]@{
                    Service    = 'GuardGraph'
                    ServiceUrl = 'https://graph.microsoft.com/v1.0'
                    Query      = @{}
                    RawOnly    = $false
                }
                $script:guardToken | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer S3cr3tAcc3ssT0k3n' } }
                $script:guardVault = [pscustomobject]@{
                    Service    = 'GuardVault'
                    ServiceUrl = 'https://%VAULTNAME%.vault.azure.net'
                    Query      = @{}
                    RawOnly    = $false
                }
                $script:guardVault | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer S3cr3tAcc3ssT0k3n' } }
                $script:_EntraTokens['GuardGraph'] = $script:guardToken
                $script:_EntraTokens['GuardVault'] = $script:guardVault
                $script:_EntraEndpoints['GuardGraph'] = [pscustomobject]@{ Parameters = @{} }
                $script:_EntraEndpoints['GuardVault'] = [pscustomobject]@{ Parameters = @{ VaultName = 'Name of the vault' } }
            }
        }

        AfterAll {
            InModuleScope PSMicrosoftEntraID {
                foreach ($name in 'GuardGraph', 'GuardVault') {
                    $script:_EntraTokens.Remove($name)
                    $script:_EntraEndpoints.Remove($name)
                }
            }
        }

        BeforeEach {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                $script:sent = [System.Collections.Generic.List[string]]::new()
                $script:nextLink = $null
                Mock Invoke-RestMethod {
                    $script:sent.Add([string]$Uri)
                    if ($Uri -like '*page2*') { [pscustomobject]@{ value = @([pscustomobject]@{ id = '2' }) } }
                    elseif ($script:nextLink) { [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }); '@odata.nextLink' = $script:nextLink } }
                    else { [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }) } }
                }
            }
        }

        It 'sends a relative path to the service host' {
            InModuleScope PSMicrosoftEntraID {
                $items = @(Invoke-EntraRequest -Service GuardGraph -Path 'users')
                $items.id | Should -Be '1'
                $script:sent | Should -Be @('https://graph.microsoft.com/v1.0/users')
            }
        }

        It 'accepts an absolute -Path on the same host' {
            InModuleScope PSMicrosoftEntraID {
                $null = Invoke-EntraRequest -Service GuardGraph -Path 'https://graph.microsoft.com/beta/users'
                $script:sent | Should -Be @('https://graph.microsoft.com/beta/users')
            }
        }

        It 'refuses an absolute -Path (<Case>) before anything is sent' -ForEach @(
            @{ Case = 'another host'; Path = 'https://attacker.example/v1.0/users?$skiptoken=S3cr3tSk1p' }
            @{ Case = 'http'; Path = 'http://graph.microsoft.com/v1.0/users' }
            @{ Case = 'user info'; Path = 'https://user:S3cr3tP4ss@graph.microsoft.com/v1.0/users' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Path = $Path } {
                $caught = { Invoke-EntraRequest -Service GuardGraph -Path $Path } | Should -Throw -PassThru
                $caught.FullyQualifiedErrorId | Should -BeLike 'PSMicrosoftEntraID.RequestUriRefused*'
                $caught.CategoryInfo.Category | Should -Be 'SecurityError'
                $caught.Exception | Should -BeOfType [System.Security.SecurityException]
                $caught.Exception.Message | Should -Not -BeLike '*S3cr3t*'
                [string]$caught.TargetObject | Should -Not -BeLike '*S3cr3t*'
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            }
        }

        It 'follows a next link on the same host' {
            InModuleScope PSMicrosoftEntraID {
                $script:nextLink = 'https://graph.microsoft.com/v1.0/page2?$skiptoken=abc'
                $items = @(Invoke-EntraRequest -Service GuardGraph -Path 'users')
                $items.id | Should -Be @('1', '2')
                $script:sent.Count | Should -Be 2
            }
        }

        It 'refuses a next link (<Case>): the first page is returned, nothing is sent for the link' -ForEach @(
            @{ Case = 'another host'; Link = 'https://attacker.example/v1.0/page2?$skiptoken=S3cr3tSk1p' }
            @{ Case = 'http'; Link = 'http://graph.microsoft.com/v1.0/page2?$skiptoken=S3cr3tSk1p' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Link = $Link } {
                $script:nextLink = $Link
                $received = [System.Collections.Generic.List[object]]::new()
                $caught = { Invoke-EntraRequest -Service GuardGraph -Path 'users' | ForEach-Object { $received.Add($_) } } | Should -Throw -PassThru
                $received.id | Should -Be @('1')
                $caught.CategoryInfo.Category | Should -Be 'SecurityError'
                $caught.Exception.Message | Should -Not -BeLike '*S3cr3tSk1p*'
                $script:sent | Should -Be @('https://graph.microsoft.com/v1.0/users')
            }
        }

        It 'does not follow a next link with -NoPaging, so nothing is checked or sent for it' {
            InModuleScope PSMicrosoftEntraID {
                $script:nextLink = 'https://attacker.example/v1.0/page2'
                $items = @(Invoke-EntraRequest -Service GuardGraph -Path 'users' -NoPaging)
                $items.id | Should -Be '1'
                $script:sent.Count | Should -Be 1
            }
        }

        It 'resolves the vault name of a Key Vault token before it compares hosts' {
            InModuleScope PSMicrosoftEntraID {
                $null = Invoke-EntraRequest -Service GuardVault -Path 'secrets/x' -VaultName 'myvault'
                $script:sent | Should -Be @('https://myvault.vault.azure.net/secrets/x')
                { Invoke-EntraRequest -Service GuardVault -Path 'https://othervault.vault.azure.net/secrets/x' -VaultName 'myvault' } | Should -Throw '*goes only to https://myvault.vault.azure.net*'
                $script:sent.Count | Should -Be 1
            }
        }

        It 'holds an explicit -Token to its own service URL, whatever -Service says' {
            InModuleScope PSMicrosoftEntraID {
                # A real token object of the Defender for Endpoint API: valid for an hour, so GetHeader() does not renew it.
                $endpoint = [EntraToken]::new()
                $endpoint.Service = 'GuardGraph'
                $endpoint.ServiceUrl = 'https://api.securitycenter.microsoft.com/api'
                $endpoint.AccessToken = 'S3cr3tAcc3ssT0k3n'
                $endpoint.ValidUntil = (Get-Date).AddHours(1)
                $null = Invoke-EntraRequest -Token $endpoint -Path 'machines'
                $script:sent | Should -Be @('https://api.securitycenter.microsoft.com/api/machines')
                { Invoke-EntraRequest -Token $endpoint -Path 'https://graph.microsoft.com/v1.0/users' } | Should -Throw '*goes only to https://api.securitycenter.microsoft.com*'
                $script:sent.Count | Should -Be 1
            }
        }
    }
}
