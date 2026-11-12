function Connect-ServiceDeviceCode {
	<#
	.SYNOPSIS
		Connects to Azure AD using the Device Code authentication workflow.

	.DESCRIPTION
		Connects to Azure AD using the Device Code authentication workflow.

		Polls the token endpoint as RFC 8628 (section 3.5) asks: every 'interval' seconds (5 when the answer names
		none), five seconds more after each slow_down, on through authorization_pending, and until the code expires
		(expires_in). A declined sign-in (access_denied) or an expired code ends it with an error that says so.
		The message with the user code is shown on the host (Write-PSFMessage -Level Important); the device code
		itself is never shown or logged.

		Ported from PSExchangeOnline (review 2026-10-20).

	.PARAMETER Resource
		The resource owning the api permissions / scopes requested.

	.PARAMETER ClientID
		The ID of the registered app used with this authentication request.

	.PARAMETER TenantID
		The ID of the tenant connected to with this authentication request.

	.PARAMETER Scopes
		The scopes to request.
		Automatically scoped to the service specified via Service Url.
		Defaults to ".Default"

	.PARAMETER NoReconnect
		Disables automatic reconnection.
		By default, this module will automatically try to reaquire a new token before the old one expires.

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.

	.EXAMPLE
		PS C:\> Connect-ServiceDeviceCode -Resource 'https://graph.microsoft.com' -ClientID '<ClientID>' -TenantID '<TenantID>' -AuthenticationUrl 'https://login.microsoftonline.com'

		Connects to the specified tenant using the specified client, prompting the user to authorize via Device Code workflow.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,

		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,

		[AllowEmptyCollection()]
		[string[]]
		$Scopes,

		[switch]
		$NoReconnect,

		[Parameter(Mandatory = $true)]
		[string]
		$AuthenticationUrl
	)

	if (-not $Scopes) { $Scopes = @('.default') }
	$actualScopes = $Scopes | Resolve-ScopeName -Resource $Resource

	if (-not $NoReconnect) {
		$actualScopes = @($actualScopes) + 'offline_access'
	}

	try {
		$initialResponse = Invoke-RestMethod -Method POST -Uri "$AuthenticationUrl/$TenantID/oauth2/v2.0/devicecode" -Body @{
			client_id = $ClientID
			scope     = $actualScopes -join " "
		} -ErrorAction Stop
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}

	# Level Important is shown on the host: the user has to read the code to sign in.
	Write-PSFMessage -Level Important -String 'Identity.DeviceCode.Prompt' -StringValues $initialResponse.message

	$paramRetrieve = @{
		Uri                = "$AuthenticationUrl/$TenantID/oauth2/v2.0/token"
		Method             = 'POST'
		Body               = @{
			grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
			client_id   = $ClientID
			device_code = $initialResponse.device_code
		}
		# A redirect would resend the device code to the host it names.
		MaximumRedirection = 0
		ErrorAction        = 'Stop'
	}
	# RFC 8628 3.2: 'interval' is optional and defaults to 5 seconds; 'expires_in' is required (15 minutes if missing).
	[int] $interval = 5
	if (([int] $initialResponse.interval) -gt 0) { $interval = [int] $initialResponse.interval }
	[int] $expiresIn = 900
	if (([int] $initialResponse.expires_in) -gt 0) { $expiresIn = [int] $initialResponse.expires_in }
	$limit = (Get-Date).AddSeconds($expiresIn)
	$authResponse = $null
	# Labelled: 'continue' inside a switch would only end the switch.
	:poll while ($true) {
		# A poll that would start after the code expired cannot succeed.
		if ((Get-Date).AddSeconds($interval) -gt $limit) {
			Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.DeviceCode.Expired') -f $expiresIn) -Category AuthenticationError
		}
		Start-Sleep -Seconds $interval
		try { $authResponse = Invoke-RestMethod @paramRetrieve }
		catch {
			$failure = $_
			[string] $errorCode = ''
			try { $errorCode = ($failure.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop).error }
			catch { $errorCode = '' }
			switch ($errorCode) {
				'authorization_pending' { continue poll }
				'slow_down' {
					# RFC 8628 3.5: this and every later poll waits five seconds more.
					$interval += 5
					Write-PSFMessage -Level Verbose -String 'Identity.DeviceCode.SlowDown' -StringValues $interval
					continue poll
				}
				'expired_token' {
					Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.DeviceCode.Expired') -f $expiresIn) -Category AuthenticationError
				}
				'access_denied' {
					Invoke-TerminatingException -Cmdlet $PSCmdlet -Message (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.DeviceCode.Denied') -Category PermissionDenied
				}
			}
			$PSCmdlet.ThrowTerminatingError($failure)
		}
		if ($authResponse) { break poll }
	}

	Read-AuthResponse -AuthResponse $authResponse
}
