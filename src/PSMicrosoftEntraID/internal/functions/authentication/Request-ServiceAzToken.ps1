function Request-ServiceAzToken {
	<#
	.SYNOPSIS
		Renews a connection made with -AzToken.

	.DESCRIPTION
		Renews a connection made with Connect-PSMicrosoftEntraID -AzToken by calling Get-AzAccessToken again, for the
		resource and the tenant of the current token.

		Only a token that came from Get-AzAccessToken (Az.Accounts) is renewed. A token of any other source - AzAuth,
		a hand-made object - cannot be renewed, so this fails with an error that asks for a new connect.
		Az.Accounts may be signed in as another identity by now (Connect-AzAccount, Set-AzContext). A renewed token of
		another identity than the one it replaces is refused, so the connection never changes identity silently.

		Ported from PSExchangeOnline (review finding M5, 2026-10-20).

	.PARAMETER Token
		The token object (EntraToken) of the connection to renew.

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command.
		If specified, errors are triggered in the caller's context.

	.EXAMPLE
		PS C:\> $result = Request-ServiceAzToken -Token $this

		Gets a new access token for the connection $this, made with -AzToken.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$Token,

		$Cmdlet = $PSCmdlet
	)
	process {
		$command = Get-Command -Name Get-AzAccessToken -ErrorAction Ignore
		if (-not $Token.AzTokenRenewable -or -not $command) {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.AzToken.NotRenewable') -Category AuthenticationError
		}

		$param = @{ ResourceUrl = $Token.Audience; ErrorAction = 'Stop' }
		if ($Token.TenantID) { $param.TenantId = $Token.TenantID }
		# Az.Accounts 2.17 to 4 hand the token out as plain text unless asked for a SecureString.
		if ($command.Parameters -and $command.Parameters.ContainsKey('AsSecureString')) { $param.AsSecureString = $true }
		try { $azToken = Get-AzAccessToken @param }
		catch {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.AzToken.RenewFailed') -f $_.Exception.Message) -Category AuthenticationError
		}

		$result = Connect-ServiceAzToken -AzToken $azToken -Cmdlet $Cmdlet
		# oid identifies the user or the service principal; sub stands in for a token without one.
		$before = $Token.TokenData
		$after = Read-TokenData -Token $result.AccessToken
		[string] $beforeIdentity = if ($before.oid) { $before.oid } else { $before.sub }
		[string] $afterIdentity = if ($after.oid) { $after.oid } else { $after.sub }
		if ($beforeIdentity -ne $afterIdentity -or ($before.tid -and $before.tid -ne $after.tid)) {
			Invoke-TerminatingException -Cmdlet $Cmdlet -Message (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.AzToken.OtherIdentity') -Category AuthenticationError
		}
		$result
	}
}
