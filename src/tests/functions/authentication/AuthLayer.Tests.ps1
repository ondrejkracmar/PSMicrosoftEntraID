BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force

    function global:New-TestJwt {
        # An unsigned JWT with the given claims: header.payload.signature, base64url, the payload UTF-8 JSON.
        param ([hashtable] $Claims)
        $encode = { param ($Text) [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Text)).TrimEnd('=').Replace('+', '-').Replace('/', '_') }
        '{0}.{1}.sig' -f (& $encode '{"alg":"none","typ":"JWT"}'), (& $encode ($Claims | ConvertTo-Json -Compress))
    }

    function global:ConvertTo-TestUnixTime {
        param ([datetime] $Date)
        [int64]($Date.ToUniversalTime() - [datetime]::new(1970, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc)).TotalSeconds
    }

    function global:New-TestHttpError {
        # An error record as Invoke-RestMethod raises it for an HTTP failure: the answer's body in ErrorDetails.
        param ([string] $Body, [int] $Status = 400)
        $response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]$Status)
        $exception = [Microsoft.PowerShell.Commands.HttpResponseException]::new("Response status code does not indicate success: $Status.", $response)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, 'WebCmdletWebResponseException', 'InvalidOperation', $null)
        if ($Body) { $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Body) }
        $record
    }

    $script:exp = ConvertTo-TestUnixTime -Date (Get-Date).AddHours(2)
    $script:jwt = New-TestJwt -Claims @{ aud = 'https://graph.microsoft.com'; tid = 'tenant-1'; oid = 'object-1'; exp = $script:exp; scp = 'User.Read' }
}

AfterAll {
    Remove-Item -Path Function:\New-TestJwt, Function:\ConvertTo-TestUnixTime, Function:\New-TestHttpError -ErrorAction Ignore
}

Describe 'Authentication layer (ported from the PSExchangeOnline review of 2026-10-20)' -Tag 'Unit' {

    Context 'Federated credential: the token stays federated (H1)' {

        It 'connects as Federated and renews through the federated flow, never as a managed identity' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:federatedResult = [pscustomobject]@{ AccessToken = $Jwt; ValidAfter = (Get-Date); ValidUntil = (Get-Date).AddHours(1); Scopes = @(); RefreshToken = $null }
                Mock Connect-ServiceFederated {
                    $script:federatedResult
                    [PSMicrosoftEntraID.FederationProvider]@{ Assertion = 'assertion-1' }
                }
                Mock Connect-ServiceIdentity { throw 'a federated token must not be renewed as a managed identity' }

                $token = Connect-EntraService -ClientID 'client-1' -TenantID 'tenant-1' -Federated -Assertion 'assertion-1' -Service 'PSMicrosoftEntraID.Graph' -Resource 'https://graph.microsoft.com'
                $token.Type | Should -Be 'Federated'
                $token.ClientID | Should -Be 'client-1'
                $token.FederationProvider.Assertion | Should -Be 'assertion-1'

                $token.RenewToken()
                Should -Invoke Connect-ServiceFederated -Times 2 -Exactly -Scope It
                Should -Invoke Connect-ServiceFederated -Times 2 -Exactly -Scope It -ParameterFilter { $Assertion -eq 'assertion-1' -and $ClientID -eq 'client-1' }
                Should -Invoke Connect-ServiceIdentity -Times 0 -Exactly -Scope It
            }
        }
    }

    Context 'AzToken: the real expiry, and a renewal that works or says why not (M5)' {

        BeforeAll {
            if (-not (Get-Command Get-AzAccessToken -ErrorAction Ignore)) {
                $script:definedAzAccessToken = $true
                function global:Get-AzAccessToken { param ([string] $ResourceUrl, [string] $TenantId, [switch] $AsSecureString) }
            }
        }

        AfterAll {
            if ($script:definedAzAccessToken) { Remove-Item -Path Function:\Get-AzAccessToken -ErrorAction Ignore }
        }

        It 'takes ValidUntil from the exp claim when the object has no ExpiresOn' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt; Exp = $script:exp } {
                $result = Connect-ServiceAzToken -AzToken ([pscustomobject]@{ Token = $Jwt })
                $expected = [datetime]::new(1970, 1, 1, 0, 0, 0, [System.DateTimeKind]::Utc).AddSeconds($Exp).ToLocalTime()
                [Math]::Abs(($result.ValidUntil - $expected).TotalSeconds) | Should -BeLessThan 2
                # Not "one hour from now", which killed every -AzToken session after ~55 minutes.
                [Math]::Abs(($result.ValidUntil - (Get-Date).AddHours(1)).TotalMinutes) | Should -BeGreaterThan 30
                $result.TenantID | Should -Be 'tenant-1'
                $result.Renewable | Should -BeFalse
            }
        }

        It 'takes ValidUntil from ExpiresOn and reads a SecureString token' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $expiresOn = [DateTimeOffset]::Now.AddMinutes(90)
                $secure = ConvertTo-SecureString $Jwt -AsPlainText -Force
                $result = Connect-ServiceAzToken -AzToken ([pscustomobject]@{ Token = $secure; ExpiresOn = $expiresOn; TenantId = 'tenant-1' })
                $result.AccessToken | Should -Be $Jwt
                [Math]::Abs(($result.ValidUntil - $expiresOn.LocalDateTime).TotalSeconds) | Should -BeLessThan 1
            }
        }

        It 'refuses an object without a token with a clear message' {
            InModuleScope PSMicrosoftEntraID {
                { Connect-ServiceAzToken -AzToken ([pscustomobject]@{ Token = '' }) } | Should -Throw '*carries no access token*'
            }
        }

        It 'connects, keeps the authentication URL, and fails with a re-connect message once a non-renewable token expired' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $token = Connect-EntraService -AzToken ([pscustomobject]@{ Token = $Jwt }) -Service 'PSMicrosoftEntraID.Graph' -Resource 'https://graph.microsoft.com'
                $token.Type | Should -Be 'AzToken'
                $token.AuthenticationUrl | Should -Be 'https://login.microsoftonline.com'
                $token.ValidUntil | Should -BeGreaterThan (Get-Date).AddMinutes(90)
                $token.AzTokenRenewable | Should -BeFalse

                $token.ValidUntil = (Get-Date).AddMinutes(-1)
                # Before: Connect-ServiceAzToken got the access-token STRING, read .Token from it and threw "No access token found".
                { $token.GetHeader() } | Should -Throw '*cannot be renewed*Connect-PSMicrosoftEntraID -AzToken*'
            }
        }

        It 'renews a token of Get-AzAccessToken by asking Az.Accounts again' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:renewedJwt = New-TestJwt -Claims @{ aud = 'https://graph.microsoft.com'; tid = 'tenant-1'; oid = 'object-1'; exp = 4102444800; scp = 'User.Read'; uti = 'renewed' }
                Mock Get-AzAccessToken { [pscustomobject]@{ PSTypeName = 'Microsoft.Azure.Commands.Profile.Models.PSAccessToken'; Token = $script:renewedJwt; TenantId = 'tenant-1' } }

                $original = [pscustomobject]@{ PSTypeName = 'Microsoft.Azure.Commands.Profile.Models.PSAccessToken'; Token = $Jwt; TenantId = 'tenant-1' }
                $token = Connect-EntraService -AzToken $original -Service 'PSMicrosoftEntraID.Graph' -Resource 'https://graph.microsoft.com'
                $token.AzTokenRenewable | Should -BeTrue

                $token.ValidUntil = (Get-Date).AddMinutes(-1)
                $header = $token.GetHeader()
                $header.Authorization | Should -Be "Bearer $script:renewedJwt"
                Should -Invoke Get-AzAccessToken -Times 1 -Exactly -Scope It -ParameterFilter { $ResourceUrl -eq 'https://graph.microsoft.com' -and $TenantId -eq 'tenant-1' }
            }
        }

        It 'refuses a renewed token of another identity' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:otherJwt = New-TestJwt -Claims @{ aud = 'https://graph.microsoft.com'; tid = 'tenant-1'; oid = 'object-OTHER'; exp = 4102444800 }
                Mock Get-AzAccessToken { [pscustomobject]@{ Token = $script:otherJwt } }

                $token = Connect-EntraService -AzToken ([pscustomobject]@{ PSTypeName = 'Microsoft.Azure.Commands.Profile.Models.PSAccessToken'; Token = $Jwt }) -Service 'PSMicrosoftEntraID.Graph' -Resource 'https://graph.microsoft.com'
                $token.ValidUntil = (Get-Date).AddMinutes(-1)
                { $token.GetHeader() } | Should -Throw '*another identity or tenant*'
            }
        }
    }

    Context 'Browser sign-in: CSPRNG state, PKCE S256, no external redirect, timeout' {

        BeforeAll {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
            $listener.Start()
            $script:port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
            $listener.Stop()
        }

        BeforeEach {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt; Port = $script:port } {
                $script:browserPort = $Port
                $script:browserJwt = $Jwt
                $script:authorizeUrl = $null
                $script:tokenBody = $null
                $script:pending = [System.Collections.Generic.List[object]]::new()
                $script:browserAnswer = 'code'
                Mock Invoke-RestMethod {
                    $script:tokenBody = $Body
                    [pscustomobject]@{ access_token = $script:browserJwt; expires_in = 3600; refresh_token = 'refresh-1' }
                }
                # The "browser": reads the authorize URL and calls the local listener back, as Entra ID would redirect it.
                Mock Start-Process {
                    $script:authorizeUrl = [string]$FilePath
                    Add-Type -AssemblyName System.Web
                    $query = [System.Web.HttpUtility]::ParseQueryString(([uri]$script:authorizeUrl).Query)
                    $client = [System.Net.Http.HttpClient]::new()
                    $callback = switch ($script:browserAnswer) {
                        'code' { 'http://localhost:{0}/?code=C0de-1&state={1}&session_state=s' -f $script:browserPort, [uri]::EscapeDataString($query['state']) }
                        'wrongState' { 'http://localhost:{0}/?code=C0de-1&state=guessed' -f $script:browserPort }
                        'error' { 'http://localhost:{0}/?error=access_denied&error_description={1}&state={2}' -f $script:browserPort, [uri]::EscapeDataString("The user cancelled`r`n"), [uri]::EscapeDataString($query['state']) }
                    }
                    $script:pending.Add($client.GetAsync($callback))
                }
            }
        }

        AfterEach {
            Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Authentication.BrowserTimeoutSeconds' -Value 300
        }

        It 'sends a 43-character CSPRNG state and an S256 challenge, and redeems the code with the matching verifier' {
            InModuleScope PSMicrosoftEntraID {
                $result = Connect-ServiceBrowser -TenantID 'tenant-1' -ClientID 'client-1' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com'
                $result.AccessToken | Should -Be $script:browserJwt

                $query = [System.Web.HttpUtility]::ParseQueryString(([uri]$script:authorizeUrl).Query)
                $query['state'] | Should -Match '^[A-Za-z0-9_-]{43}$'
                $query['code_challenge_method'] | Should -Be 'S256'
                $script:tokenBody.code | Should -Be 'C0de-1'
                $script:tokenBody.code_verifier | Should -Match '^[A-Za-z0-9_-]{43}$'
                $hash = [System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::ASCII.GetBytes($script:tokenBody.code_verifier))
                $query['code_challenge'] | Should -Be ([Convert]::ToBase64String($hash).TrimEnd('=').Replace('+', '-').Replace('/', '_'))

                # The browser gets a local page, not a redirect (the vendored code sent it to a random port, or to YouTube).
                $response = $script:pending[0].GetAwaiter().GetResult()
                [int]$response.StatusCode | Should -Be 200
                $response.Headers.Location | Should -BeNullOrEmpty
                $response.Content.ReadAsStringAsync().GetAwaiter().GetResult() | Should -BeLike '*Sign-in complete*'
            }
        }

        It 'uses a new state for every sign-in' {
            InModuleScope PSMicrosoftEntraID {
                $null = Connect-ServiceBrowser -TenantID 't' -ClientID 'c' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com'
                $first = [System.Web.HttpUtility]::ParseQueryString(([uri]$script:authorizeUrl).Query)['state']
                $null = Connect-ServiceBrowser -TenantID 't' -ClientID 'c' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com'
                $second = [System.Web.HttpUtility]::ParseQueryString(([uri]$script:authorizeUrl).Query)['state']
                $first | Should -Not -Be $second
            }
        }

        It 'refuses an answer with another state, redeems nothing, and gives up after the timeout' {
            InModuleScope PSMicrosoftEntraID {
                $script:browserAnswer = 'wrongState'
                Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Authentication.BrowserTimeoutSeconds' -Value 2
                { Connect-ServiceBrowser -TenantID 't' -ClientID 'c' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com' } | Should -Throw '*not completed within 2 seconds*'
                [int]$script:pending[0].GetAwaiter().GetResult().StatusCode | Should -Be 400
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            }
        }

        It 'reports an error answer with the state of the sign-in, cleaned of control characters' {
            InModuleScope PSMicrosoftEntraID {
                $script:browserAnswer = 'error'
                $caught = { Connect-ServiceBrowser -TenantID 't' -ClientID 'c' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com' } | Should -Throw -PassThru
                $caught.Exception.Message | Should -Be 'The sign-in was refused: access_denied. The user cancelled'
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            }
        }

        It 'logs the authorize endpoint without the state' {
            InModuleScope PSMicrosoftEntraID {
                $null = Connect-ServiceBrowser -TenantID 't' -ClientID 'c' -Resource 'https://graph.microsoft.com' -LocalPort $script:browserPort -AuthenticationUrl 'https://login.microsoftonline.com'
                $state = [System.Web.HttpUtility]::ParseQueryString(([uri]$script:authorizeUrl).Query)['state']
                $log = Get-PSFMessage | Where-Object { $_.String -eq 'Identity.Browser.Authorize' } | Select-Object -Last 1
                $log.Message | Should -BeLike '*https://login.microsoftonline.com/t/oauth2/v2.0/authorize in the browser*'
                $log.Message | Should -Not -BeLike "*$state*"
            }
        }
    }

    Context 'Device code: RFC 8628 polling' {

        BeforeEach {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:deviceJwt = $Jwt
                $script:sleeps = [System.Collections.Generic.List[int]]::new()
                $script:pollAnswers = [System.Collections.Generic.Queue[string]]::new()
                Mock Start-Sleep { $script:sleeps.Add($Seconds) }
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/devicecode' } {
                    [pscustomobject]@{ message = 'Enter ABCD'; device_code = 'device-1'; interval = 1; expires_in = 900 }
                }
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/token' } {
                    $answer = $script:pollAnswers.Dequeue()
                    if ($answer -eq 'ok') { return [pscustomobject]@{ access_token = $script:deviceJwt; expires_in = 3600 } }
                    throw (New-TestHttpError -Body ('{{"error":"{0}"}}' -f $answer))
                }
            }
        }

        It 'waits five seconds more after slow_down and keeps polling through authorization_pending' {
            InModuleScope PSMicrosoftEntraID {
                foreach ($answer in 'slow_down', 'authorization_pending', 'ok') { $script:pollAnswers.Enqueue($answer) }
                $result = Connect-ServiceDeviceCode -Resource 'https://graph.microsoft.com' -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com'
                $result.AccessToken | Should -Be $script:deviceJwt
                $script:sleeps | Should -Be @(1, 6, 6)
            }
        }

        It 'ends with a clear message when <Answer>' -ForEach @(
            @{ Answer = 'expired_token'; Expected = '*device code expired*' }
            @{ Answer = 'access_denied'; Expected = '*was declined*' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Answer = $Answer; Expected = $Expected } {
                $script:pollAnswers.Enqueue($Answer)
                { Connect-ServiceDeviceCode -Resource 'https://graph.microsoft.com' -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com' } | Should -Throw $Expected
            }
        }
    }

    Context 'Password (ROPC) flow is opt-in (M4)' {

        AfterEach {
            Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Authentication.AllowPasswordFlow' -Value $false
        }

        It 'is turned off by default: a SecurityError, nothing sent' {
            (Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Authentication.AllowPasswordFlow') | Should -BeFalse
            InModuleScope PSMicrosoftEntraID {
                Mock Invoke-RestMethod { }
                $credential = [pscredential]::new('max@contoso.com', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
                $caught = { Connect-ServicePassword -Resource 'https://graph.microsoft.com' -Credential $credential -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com' } | Should -Throw -PassThru
                $caught.CategoryInfo.Category | Should -Be 'SecurityError'
                $caught.Exception.Message | Should -BeLike '*AllowPasswordFlow*'
                Should -Invoke Invoke-RestMethod -Times 0 -Exactly -Scope It
            }
        }

        It 'signs in when opted in' {
            Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Authentication.AllowPasswordFlow' -Value $true
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:passwordJwt = $Jwt
                Mock Invoke-RestMethod { [pscustomobject]@{ access_token = $script:passwordJwt; expires_in = 3600 } }
                $credential = [pscredential]::new('max@contoso.com', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
                $result = Connect-ServicePassword -Resource 'https://graph.microsoft.com' -Credential $credential -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com'
                $result.AccessToken | Should -Be $Jwt
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter { $Body.grant_type -eq 'password' }
            }
        }

        It 'surfaces the reason through Connect-PSMicrosoftEntraID' {
            InModuleScope PSMicrosoftEntraID {
                Mock Invoke-RestMethod { }
                Mock Get-EntraService { [pscustomobject]@{ Resource = 'https://graph.microsoft.com'; ServiceUrl = 'https://graph.microsoft.com/v1.0'; DefaultScopes = @(); NoRefresh = $false } }
                $credential = [pscredential]::new('max@contoso.com', (ConvertTo-SecureString 'pw' -AsPlainText -Force))
                { Connect-PSMicrosoftEntraID -ClientID 'c' -TenantID 't' -Credential $credential } | Should -Throw '*failed:*AllowPasswordFlow*'
            }
        }
    }

    Context 'Managed identity on a VM and on App Service (M6)' {

        BeforeAll {
            $script:savedEnv = @{}
            foreach ($name in 'IDENTITY_ENDPOINT', 'IDENTITY_HEADER', 'IDENTITY_API_VERSION') {
                $script:savedEnv[$name] = [System.Environment]::GetEnvironmentVariable($name)
            }
        }

        AfterEach {
            foreach ($pair in $script:savedEnv.GetEnumerator()) { [System.Environment]::SetEnvironmentVariable($pair.Key, $pair.Value) }
        }

        BeforeEach {
            foreach ($name in $script:savedEnv.Keys) { [System.Environment]::SetEnvironmentVariable($name, $null) }
        }

        It 'gets the token from the instance metadata service of a VM and writes no environment variable' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:imdsJwt = $Jwt
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/metadata/instance*' } { [pscustomobject]@{ compute = [pscustomobject]@{ azEnvironment = 'AzurePublicCloud' } } }
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/metadata/identity/oauth2/token*' } { [pscustomobject]@{ access_token = $script:imdsJwt; expires_in = '3600' } }

                $result = Connect-ServiceIdentity -Resource 'https://graph.microsoft.com' -IdentityID 'client-1' -IdentityType 'ClientID'
                $result.AccessToken | Should -Be $Jwt
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Uri -eq 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fgraph.microsoft.com&client_id=client-1' -and
                    $Headers.Metadata -eq 'true' -and $NoProxy
                }
                $env:IDENTITY_ENDPOINT | Should -BeNullOrEmpty
                $env:IDENTITY_API_VERSION | Should -BeNullOrEmpty
            }
        }

        It 'retries the instance metadata service while the identity is being assigned (404)' {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:imdsJwt = $Jwt
                $script:imdsCalls = 0
                Mock Start-Sleep { }
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/metadata/instance*' } { [pscustomobject]@{ compute = [pscustomobject]@{ azEnvironment = 'AzurePublicCloud' } } }
                Mock Invoke-RestMethod -ParameterFilter { $Uri -like '*/metadata/identity/oauth2/token*' } {
                    $script:imdsCalls++
                    if ($script:imdsCalls -eq 1) { throw (New-TestHttpError -Status 404) }
                    [pscustomobject]@{ access_token = $script:imdsJwt; expires_in = '3600' }
                }
                $result = Connect-ServiceIdentity -Resource 'https://graph.microsoft.com'
                $result.AccessToken | Should -Be $Jwt
                Should -Invoke Start-Sleep -Times 1 -Exactly -Scope It -ParameterFilter { $Seconds -eq 1 }
            }
        }

        It 'fails fast with a clear message outside Azure' {
            InModuleScope PSMicrosoftEntraID {
                Mock Invoke-RestMethod { throw 'no route to host' }
                { Connect-ServiceIdentity -Resource 'https://graph.microsoft.com' } | Should -Throw '*No managed identity was found*'
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter { $TimeoutSec -eq 2 }
            }
        }

        It 'uses IDENTITY_ENDPOINT with the X-IDENTITY-HEADER on App Service' {
            $env:IDENTITY_ENDPOINT = 'http://localhost:42356/msi/token'
            $env:IDENTITY_HEADER = 'header-1'
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:appJwt = $Jwt
                Mock Invoke-RestMethod { [pscustomobject]@{ access_token = $script:appJwt; expires_on = '4102444800' } }
                $null = Connect-ServiceIdentity -Resource 'https://graph.microsoft.com'
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Uri -like 'http://localhost:42356/msi/token?resource=*&api-version=2019-08-01' -and $Headers['X-IDENTITY-HEADER'] -eq 'header-1'
                }
            }
        }
    }

    Context 'Token requests: assertion in the body only (L1), the v2.0 endpoint (Q7)' {

        BeforeEach {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Jwt = $script:jwt } {
                $script:requestJwt = $Jwt
                Mock Invoke-RestMethod { [pscustomobject]@{ access_token = $script:requestJwt; expires_in = 3600 } }
            }
        }

        It 'sends the signed client assertion of a certificate in the body, never as a bearer header' {
            InModuleScope PSMicrosoftEntraID {
                $rsa = [System.Security.Cryptography.RSA]::Create(2048)
                $request = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=PSMicrosoftEntraID test', $rsa, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
                $certificate = $request.CreateSelfSigned((Get-Date).AddDays(-1), (Get-Date).AddDays(1))
                $null = Connect-ServiceCertificate -Resource 'https://graph.microsoft.com' -Certificate $certificate -TenantID 't' -ClientID 'c' -AuthenticationUrl 'https://login.microsoftonline.com'
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Body.client_assertion -and -not ($Headers -and $Headers.Authorization)
                }
            }
        }

        It 'asks the v2.0 endpoint for the .default scope with a client secret' {
            InModuleScope PSMicrosoftEntraID {
                $secret = ConvertTo-SecureString 'secret-1' -AsPlainText -Force
                $null = Connect-ServiceClientSecret -Resource 'https://graph.microsoft.com/' -ClientSecret $secret -TenantID 't' -ClientID 'c' -AuthenticationUrl 'https://login.microsoftonline.com'
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Uri -eq 'https://login.microsoftonline.com/t/oauth2/v2.0/token' -and $Body.scope -eq 'https://graph.microsoft.com/.default' -and -not $Body.ContainsKey('resource')
                }
            }
        }

        It 'asks the v2.0 endpoint for the .default scope with a federated assertion' {
            InModuleScope PSMicrosoftEntraID {
                $null = Connect-ServiceFederated -Resource 'https://api.securitycenter.microsoft.com' -Assertion 'assertion-1' -TenantID 't' -ClientID 'c' -AuthenticationUrl 'https://login.microsoftonline.com'
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -Scope It -ParameterFilter {
                    $Uri -eq 'https://login.microsoftonline.com/t/oauth2/v2.0/token' -and $Body.scope -eq 'https://api.securitycenter.microsoft.com/.default' -and $Body.client_assertion -eq 'assertion-1'
                }
            }
        }
    }

    Context 'Token data (Q6)' {

        It 'decodes the claims as UTF-8 base64url' {
            InModuleScope PSMicrosoftEntraID {
                # 'Kračmar Ondřej' - and a payload whose base64 holds '-' and '_'.
                $jwt = New-TestJwt -Claims @{ aud = 'https://graph.microsoft.com'; tid = 't'; name = "Kra$([char]0x010D)mar Ond$([char]0x0159)ej"; extra = '???>>>' }
                (Read-TokenData -Token $jwt).name | Should -Be "Kra$([char]0x010D)mar Ond$([char]0x0159)ej"
                $token = [EntraToken]::new()
                $token.SetTokenMetadata([pscustomobject]@{ AccessToken = $jwt; ValidAfter = (Get-Date); ValidUntil = (Get-Date).AddHours(1); Scopes = @() })
                $token.TokenData.name | Should -Be "Kra$([char]0x010D)mar Ond$([char]0x0159)ej"
                $token.TokenData.extra | Should -Be '???>>>'
            }
        }

        It 'keeps the authentication URL passed to the token-object constructor' {
            InModuleScope PSMicrosoftEntraID {
                $token = [EntraToken]::new('Graph', 'access', 't', 'id', [string[]]@(), 'https://graph.microsoft.com/v1.0', 'https://login.microsoftonline.us', 'AzToken')
                $token.AuthenticationUrl | Should -Be 'https://login.microsoftonline.us'
            }
        }
    }
}
