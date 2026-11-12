function Get-EntraUriRefusal {
	<#
	.SYNOPSIS
		Tells why a request URL may not get the access token of a connection; nothing when it may.

	.DESCRIPTION
		Every request Invoke-EntraRequest sends with a connection's token - a relative path, an absolute -Path, an
		@odata.nextLink while paging - goes only:
		- to an absolute URL without user info;
		- over https;
		- to the scheme, host and port of the service URL the token belongs to (its ServiceUrl, with the service's
		  parameters resolved - e.g. https://graph.microsoft.com/v1.0 for Graph, https://api.securitycenter.microsoft.com/api
		  for Defender for Endpoint, https://<vault>.vault.azure.net for Key Vault). The path is not compared: /beta on a
		  v1.0 connection is the same host.
		Returns the localized reason a URL is refused, naming it by scheme, host and path only (Get-EntraLogUri) -
		never its query, user info or the token. Returns nothing when the URL may be sent.

		Ported from PSExchangeOnline (Get-ExoUriRefusal, review finding M3, 2026-10-20).

	.PARAMETER Uri
		The request URL.

	.PARAMETER ServiceUrl
		The service URL of the token (with its parameters resolved).

	.EXAMPLE
		PS C:\> Get-EntraUriRefusal -Uri $nextLink -ServiceUrl $token.ServiceUrl

		Nothing when the next link stays on the connection's service over https; otherwise why it is not followed.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Uri,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$ServiceUrl
	)

	[uri] $target = $null
	if (-not $Uri -or -not [uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$target) -or $target.UserInfo) {
		return (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Request.UriInvalid')
	}

	[string] $logUri = Get-EntraLogUri -Uri $Uri
	if ($target.Scheme -ne 'https') {
		return ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Request.UriNotHttps') -f $logUri)
	}

	[uri] $service = $null
	[string] $serviceOrigin = ''
	if ($ServiceUrl -and [uri]::TryCreate($ServiceUrl.Trim(), [System.UriKind]::Absolute, [ref]$service)) {
		$serviceOrigin = $service.GetComponents([System.UriComponents]::SchemeAndServer, [System.UriFormat]::UriEscaped)
	}
	[bool] $sameOrigin = $service -and $service.Scheme -eq 'https' -and
		$target.Scheme -eq $service.Scheme -and $target.IdnHost -eq $service.IdnHost -and $target.Port -eq $service.Port
	if (-not $sameOrigin) {
		return ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Request.UriForeignHost') -f $logUri, $serviceOrigin)
	}
}
