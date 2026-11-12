function Get-EntraLogUri {
	<#
	.SYNOPSIS
		Returns a request URL in a form that is safe to log: scheme, host, port and path - no user info, no query.

	.DESCRIPTION
		Request URLs carry delta and skip tokens in their query (an @odata.nextLink, an @odata.deltaLink, a request
		resumed with $deltaToken). Warnings and verbose messages end up in the PSFramework log, so they show only
		scheme, host, port and path; user info (user:password@) and the fragment are dropped as well.
		A text .NET cannot parse as an absolute URL is trimmed and its backslashes read as '/'. When it holds an '@'
		and a ':' or '//' before its query, nothing of its authority can be told apart safely, so only a fixed marker
		is returned, after the scheme when the text starts with one ('https://<unparseable URL>'). Any other text is
		kept up to the first '?' or '#' (a relative path such as 'users/a@contoso.com').
		A URL .NET does parse but reads without a host ('user:password@host/path' is scheme 'user' with the rest as
		its path) and that holds an '@' is shown by its scheme and the marker only.

		Ported from PSExchangeOnline (Get-ExoLogUri, review 2026-10-20).

	.PARAMETER Uri
		The request URL.

	.EXAMPLE
		PS C:\> Get-EntraLogUri -Uri 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=x'

		Returns https://graph.microsoft.com/v1.0/users/delta.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Uri
	)

	if (-not $Uri) { return '' }
	[uri] $parsed = $null
	if ([uri]::TryCreate($Uri, [System.UriKind]::Absolute, [ref]$parsed)) {
		# Without a host ('user:password@host/path' reads as scheme 'user') the would-be user info is in the path.
		if (-not $parsed.Host -and $Uri.Contains('@')) { return '{0}://<unparseable URL>' -f $parsed.Scheme }
		return $parsed.GetComponents([System.UriComponents]::SchemeAndServer -bor [System.UriComponents]::Path, [System.UriFormat]::UriEscaped)
	}
	[string] $text = $Uri.Trim().Replace('\', '/')
	# A scheme or an authority shows before the query; a ':' in a query (a time in a filter) says nothing about it.
	[string] $head = ($text -split '[?#]', 2)[0]
	if ($text.Contains('@') -and ($head.Contains(':') -or $head.Contains('//'))) {
		if ($text -match '^(?<scheme>[a-z][a-z0-9+.-]*):') { return '{0}://<unparseable URL>' -f $Matches.scheme.ToLowerInvariant() }
		return '<unparseable URL>'
	}
	$head
}
