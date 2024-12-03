function Connect-ServiceAzToken {
	<#
	.SYNOPSIS
		Connect with the authentication response.
	
	.DESCRIPTION
		Connect with the Connect with the authentication response.
		Used mostly for delegate authentication flows to avoid interactivity.

	.PARAMETER AzToken
		AzToken object.
	
	.EXAMPLE
		PS C:\> Connect-ServiceAzToken -AzToken $AzToken
		
		Connect with the authentication response.
	#>
	[CmdletBinding()]
	param (
		$AzToken,
		$Cmdlet = $PSCmdlet
	)
	process {
		if (-not $AzToken.Token) {
			throw "Failed to access token: No access token found!"
		}
		$tokenData = Read-TokenData -Token $AzToken.Token
		[pscustomobject]@{
			AccessToken  = $AzToken.Token
			ValidAfter   = (Get-Date)
			ValidUntil   = (Get-Date).AddHours(1)
			TenantID	 = $AzToken.TenantID
			IdentityID	 = $AzToken.Identity
			Scopes       = $tokenData.scp -split ' '
		}
	}
}