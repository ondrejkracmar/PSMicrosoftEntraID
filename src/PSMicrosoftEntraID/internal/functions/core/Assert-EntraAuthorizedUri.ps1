function Assert-EntraAuthorizedUri {
	<#
	.SYNOPSIS
		Stops the calling command before it sends the access token to a URL that may not get it.

	.DESCRIPTION
		Raises a terminating error in the calling command unless the URL is https on the scheme, host and port of the
		service URL the token belongs to (Get-EntraUriRefusal). Nothing is sent when it fails.
		The error record holds no secret: its message and target object name the URL by scheme, host and path only
		(no query with delta or skip tokens, no user info), and neither the token nor the headers are part of it.
		The exception is a SecurityException (category SecurityError).

		Ported from PSExchangeOnline (Assert-ExoAuthorizedUri, review finding M3, 2026-10-20).

	.PARAMETER Uri
		The request URL.

	.PARAMETER ServiceUrl
		The service URL of the token (with its parameters resolved).

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command; the error is raised in its name.

	.EXAMPLE
		PS C:\> Assert-EntraAuthorizedUri -Uri $parameters.Uri -ServiceUrl $authorizedUrl -Cmdlet $PSCmdlet

		Stops the request unless it stays on the connection's service over https.
	#>
	[CmdletBinding()]
	param (
		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Uri,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$ServiceUrl,

		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)

	[string] $refusal = Get-EntraUriRefusal -Uri $Uri -ServiceUrl $ServiceUrl
	if (-not $refusal) { return }
	Write-PSFMessage -Level Debug -String 'Request.UriRefused' -StringValues $refusal
	$exception = [System.Security.SecurityException]::new($refusal)
	$record = [System.Management.Automation.ErrorRecord]::new($exception, 'PSMicrosoftEntraID.RequestUriRefused', [System.Management.Automation.ErrorCategory]::SecurityError, (Get-EntraLogUri -Uri $Uri))
	$Cmdlet.ThrowTerminatingError($record)
}
