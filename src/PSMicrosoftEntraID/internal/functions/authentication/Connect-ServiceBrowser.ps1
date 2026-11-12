function Connect-ServiceBrowser {
	<#
	.SYNOPSIS
		Interactive logon using the Authorization flow and browser. Supports SSO.

	.DESCRIPTION
		Interactive logon using the Authorization flow and browser. Supports SSO.

		This flow requires an App Registration configured for the platform "Mobile and desktop applications".
		Its redirect Uri must be "http://localhost"

		The sign-in is protected by a random state (from the CSPRNG, bound to this sign-in, compared in constant time)
		and PKCE (RFC 7636, S256): the authorization code is redeemed together with a verifier that never leaves this
		process. The answer of the sign-in arrives at a local listener, which shows the browser a plain local page
		saying the sign-in is complete - no redirect anywhere else. Only an answer with the state of this sign-in is
		accepted, an error answer included; any other request to the local port (a web page pointing at localhost,
		a favicon) is refused and the wait goes on. The wait ends after
		PSMicrosoftEntraID.Settings.Authentication.BrowserTimeoutSeconds (default 300), and the listener is always
		closed.
		The verifier and the code are written nowhere; the state appears only in the link that -BrowserMode PrintLink
		prints on the host, which the user needs - the log has the endpoint of the link alone.

		Ported from PSExchangeOnline (review 2026-10-20).

	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.

	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.

	.PARAMETER SelectAccount
		Forces account selection on logon.
		As this flow supports single-sign-on, it will otherwise not prompt for anything if already signed in.
		This could be a problem if you want to connect using another (e.g. an admin) account.

	.PARAMETER Scopes
		Generally doesn't need to be changed from the default '.default'

	.PARAMETER LocalPort
		The local port that should be redirected to.
		In order to process the authentication response, we need to listen to a local web request on some port.
		Usually needs not be redirected.
		Defaults to: 8080

	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

	.PARAMETER RedirectUri
		The Redirect URI to send with the request.
		May be different from the actual local port you want to listen on (e.g. when redirecting to an alternative name on top of localhost).

	.PARAMETER Browser
		The path to the browser to use for the authentication flow.
		Provide the full path to the executable.
		The browser must accept the url to open as its only parameter.
		Defaults to your default browser.

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

	.PARAMETER NoReconnect
		Disables automatic reconnection.
		By default, this module will automatically try to reaquire a new token before the old one expires.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.

	.EXAMPLE
		PS C:\> Connect-ServiceBrowser -ClientID '<ClientID>' -TenantID '<TenantID>'

		Connects to the specified tenant using the specified client, prompting the user to authorize via Browser.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[switch]
		$SelectAccount,

		[AllowEmptyCollection()]
		[string[]]
		$Scopes,

		[int]
		$LocalPort = 8080,

		[AllowEmptyString()]
		[string]
		$RedirectUri,

		[string]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[switch]
		$NoReconnect,

		[Parameter(Mandatory = $true)]
		[string]
		$AuthenticationUrl
	)
	process {
		Add-Type -AssemblyName System.Web
		if (-not $Scopes) { $Scopes = @('.default') }

		$localUri = "http://localhost:$LocalPort"
		if (-not $RedirectUri) { $RedirectUri = $localUri }
		$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource

		if (-not $NoReconnect) {
			$actualScopes = @($actualScopes) + 'offline_access'
		}

		# The state binds the answer to this sign-in, PKCE (RFC 7636, S256) the code to this process. Both come from the
		# CSPRNG: 32 bytes each, 43 characters base64url - the shortest verifier RFC 7636 allows. (Get-Random is no
		# CSPRNG and its value is guessable.)
		[string] $state = ConvertTo-EntraBase64Url -Bytes ([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
		[string] $codeVerifier = ConvertTo-EntraBase64Url -Bytes ([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
		[string] $codeChallenge = ConvertTo-EntraBase64Url -Bytes ([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::ASCII.GetBytes($codeVerifier)))

		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/authorize"
		$parameters = [ordered]@{
			client_id             = $ClientID
			response_type         = 'code'
			redirect_uri          = $RedirectUri
			response_mode         = 'query'
			scope                 = $actualScopes -join ' '
			state                 = $state
			code_challenge        = $codeChallenge
			code_challenge_method = 'S256'
		}
		if ($SelectAccount) {
			$parameters.prompt = 'select_account'
		}

		$paramStrings = foreach ($pair in $parameters.GetEnumerator()) {
			$pair.Key, ([System.Web.HttpUtility]::UrlEncode($pair.Value)) -join '='
		}
		$uriFinal = $uri + '?' + ($paramStrings -join '&')
		[int] $timeout = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Authentication.BrowserTimeoutSeconds' -Fallback 300
		if ($timeout -lt 1) { $timeout = 300 }
		# The endpoint only: the query carries the state.
		Write-PSFMessage -Level Verbose -String 'Identity.Browser.Authorize' -StringValues $uri, $timeout

		# Start local server to catch the redirect
		$http = [System.Net.HttpListener]::new()
		$http.Prefixes.Add(("$RedirectUri/" -replace '//$', '/'))
		if ($localUri -ne $RedirectUri) { $http.Prefixes.Add(("$localUri/" -replace '//$', '/')) }
		try { $http.Start() }
		catch {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Listener') -f $LocalPort, $_.Exception.Message) -Category OpenError
		}

		$answer = $null
		try {
			switch ($BrowserMode) {
				Auto {
					# Execute in default browser
					if ($Browser) { & $Browser $uriFinal }
					else { Start-Process $uriFinal }
				}
				PrintLink {
					# On the host only: the query of the link (state, PKCE challenge) stays out of the PSFramework log,
					# which has the endpoint alone (Identity.Browser.Authorize above).
					$Host.UI.WriteLine(((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.PrintLink') -f $uriFinal))
				}
			}

			# The first request with the state of this sign-in is its answer - a code or an error. Anything else is refused
			# and the wait goes on: a favicon, or a web page that points at the (predictable) local port and must not end
			# the sign-in. The timeout ends the wait for a sign-in never completed.
			$clock = [System.Diagnostics.Stopwatch]::StartNew()
			while (-not $answer) {
				$task = $http.GetContextAsync()
				while (-not $task.IsCompleted) {
					if ($clock.Elapsed.TotalSeconds -ge $timeout) {
						Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Timeout') -f $timeout) -Category OperationTimeout
					}
					Start-Sleep -Milliseconds 200
				}
				$context = $task.GetAwaiter().GetResult()
				# By name, in any order, URL-decoded.
				$received = [System.Web.HttpUtility]::ParseQueryString($context.Request.Url.Query)
				if (-not ($received['code'] -or $received['error'])) {
					$context.Response.StatusCode = 404
					$context.Response.Close()
					continue
				}
				[bool] $stateMatches = [System.Security.Cryptography.CryptographicOperations]::FixedTimeEquals(
					[System.Text.Encoding]::UTF8.GetBytes([string]$received['state']),
					[System.Text.Encoding]::UTF8.GetBytes($state)
				)
				if ($stateMatches) { $answer = $received }
				else { Write-PSFMessage -Level Debug -String 'Identity.Browser.Ignored' }
				[string] $text = if ($stateMatches -and $received['code']) { Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Page.Done' }
				else { Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Page.Failed' }
				[string] $title = [System.Web.HttpUtility]::HtmlEncode((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Page.Title'))
				$text = [System.Web.HttpUtility]::HtmlEncode($text)
				$bytes = [System.Text.Encoding]::UTF8.GetBytes("<!DOCTYPE html><html><head><meta charset=`"utf-8`"><title>$title</title></head><body><p>$text</p></body></html>")
				$context.Response.StatusCode = if ($stateMatches) { 200 } else { 400 }
				$context.Response.ContentType = 'text/html; charset=utf-8'
				$context.Response.Headers.Add('Cache-Control', 'no-store')
				$context.Response.ContentLength64 = $bytes.Length
				$context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
				$context.Response.Close()
			}
		}
		finally {
			$http.Stop()
			$http.Close()
		}

		if ($answer['error']) {
			# What came back through the browser is cleaned before it is shown: a bare error code, and a description
			# without control characters or more than 512 characters.
			[string] $errorCode = $answer['error']
			if ($errorCode -notmatch '^[A-Za-z0-9_.-]{1,64}$') { $errorCode = 'unknown_error' }
			[string] $description = ([string]$answer['error_description'] -replace '\p{C}+', ' ').Trim()
			if ($description.Length -gt 512) { $description = $description.Substring(0, 512) + '...' }
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.Refused') -f $errorCode, $description) -Category AuthenticationError
		}

		$body = @{
			client_id     = $ClientID
			scope         = $actualScopes -join " "
			code          = $answer['code']
			code_verifier = $codeVerifier
			redirect_uri  = $RedirectUri
			grant_type    = 'authorization_code'
		}
		$uri = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
		try { $authResponse = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ErrorAction Stop }
		catch {
			if ($_ -notmatch '"error":\s*"invalid_client"') { Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ }
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.Browser.InvalidClient') -f $ClientID, $_) -Category $_.CategoryInfo.Category
		}
		Read-AuthResponse -AuthResponse $authResponse
	}
}
