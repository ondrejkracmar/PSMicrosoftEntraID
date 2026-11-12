function Connect-ServiceAzToken {
	<#
	.SYNOPSIS
		Connect with an access token object of AzAuth or Az.Accounts.

	.DESCRIPTION
		Connect with an access token object of AzAuth (Get-AzToken) or Az.Accounts (Get-AzAccessToken).
		Used mostly for delegate authentication flows to avoid interactivity.

		The token is read from the Token property, as a string or as a SecureString (Az.Accounts with
		-AsSecureString, the default from Az.Accounts 5 on). It is valid until the ExpiresOn of the object, or until
		the expiry the token itself carries (its exp claim) when the object has none - never "one hour from now".
		Renewable is true for a token of Get-AzAccessToken: Request-ServiceAzToken renews such a token by calling
		Get-AzAccessToken again. A token of any other source cannot be renewed; the connection then fails with a
		message asking for a new connect once the token has expired.

		Ported from PSExchangeOnline (review finding M5, 2026-10-20).

	.PARAMETER AzToken
		The access token object.

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command.
		If specified, errors are triggered in the caller's context.

	.EXAMPLE
		PS C:\> Connect-ServiceAzToken -AzToken (Get-AzToken -Resource 'https://graph.microsoft.com')

		Connect with an access token of AzAuth.
	#>
	[CmdletBinding()]
	param (
		$AzToken,

		$Cmdlet = $PSCmdlet
	)
	process {
		[string] $accessToken = if ($AzToken.Token -is [securestring]) { [System.Net.NetworkCredential]::new('', $AzToken.Token).Password }
		else { [string]$AzToken.Token }
		if (-not $accessToken) {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.AzToken.Missing') -Category InvalidArgument
		}
		$tokenData = Read-TokenData -Token $accessToken

		$validUntil = switch ($AzToken.ExpiresOn) {
			{ $_ -is [DateTimeOffset] } { $_.LocalDateTime; break }
			{ $_ -is [datetime] } { $_.ToLocalTime(); break }
			default { (Get-Date -Date '1970-01-01').AddSeconds([double]$tokenData.exp).ToLocalTime() }
		}
		[string] $tenantID = $AzToken.TenantId
		if (-not $tenantID) { $tenantID = $AzToken.Tenant }
		if (-not $tenantID) { $tenantID = $tokenData.tid }
		[string] $identityID = $AzToken.Identity
		if (-not $identityID) { $identityID = $AzToken.UserId }

		[pscustomobject]@{
			AccessToken = $accessToken
			ValidAfter  = (Get-Date)
			ValidUntil  = $validUntil
			TenantID    = $tenantID
			IdentityID  = $identityID
			Scopes      = $tokenData.scp -split ' '
			# PSAccessToken, and PSSecureAccessToken from Az.Accounts 2.17 on
			Renewable   = [bool]($AzToken.PSObject.TypeNames -match '^Microsoft\.Azure\.Commands\.Profile\.Models\.PS(Secure)?AccessToken$')
		}
	}
}
