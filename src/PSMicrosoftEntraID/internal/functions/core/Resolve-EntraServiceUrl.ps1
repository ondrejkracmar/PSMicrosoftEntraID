function Resolve-EntraServiceUrl {
	<#
	.SYNOPSIS
		Returns the service URL of a token with the service's parameters filled in - the URL its token belongs to.

	.DESCRIPTION
		A registered service can carry parameters in its URL (%VAULTNAME% in https://%VAULTNAME%.vault.azure.net);
		Invoke-EntraRequest fills them from its bound parameters, as Resolve-RequestUri does for the request URL.
		This is the URL the token guard (Get-EntraUriRefusal) compares every request with. A parameter that is not
		bound leaves its placeholder empty, which the guard then refuses rather than guessing a host.

		Ported from PSExchangeOnline (Resolve-ExoServiceUrl, review finding M3, 2026-10-20).

	.PARAMETER TokenObject
		The token of the request.

	.PARAMETER ServiceObject
		The registered service of the token (if any); its Parameters name the placeholders.

	.PARAMETER BoundParameters
		The parameters of the calling command.

	.EXAMPLE
		PS C:\> Resolve-EntraServiceUrl -TokenObject $tokenObject -ServiceObject $serviceObject -BoundParameters $PSBoundParameters

		The service URL of the token, e.g. https://graph.microsoft.com/v1.0.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$TokenObject,

		[AllowNull()]
		$ServiceObject,

		[AllowNull()]
		$BoundParameters
	)

	[string] $url = ([string]$TokenObject.ServiceUrl).Trim()
	if (-not $ServiceObject -or -not $ServiceObject.Parameters) { return $url }
	foreach ($key in $ServiceObject.Parameters.Keys) {
		[string] $value = if ($BoundParameters -and $BoundParameters.ContainsKey($key)) { [string]$BoundParameters[$key] } else { '' }
		# Literal, not -replace: a key is no pattern and a value no replacement text ('$&', '$1'). Case-insensitive, as
		# Resolve-RequestUri's -replace is: the Key Vault service registers the parameter VaultName for %VAULTNAME%, and a
		# case-sensitive replace left the placeholder in, so the guard refused every Key Vault request.
		$url = $url.Replace("%$key%", $value, [System.StringComparison]::OrdinalIgnoreCase)
	}
	$url
}
