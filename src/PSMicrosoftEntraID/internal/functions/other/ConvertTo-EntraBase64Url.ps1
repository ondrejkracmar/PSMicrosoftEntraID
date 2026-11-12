function ConvertTo-EntraBase64Url {
	<#
	.SYNOPSIS
		Encodes bytes as base64url without padding (RFC 4648 section 5).

	.DESCRIPTION
		Encodes bytes as base64url without padding (RFC 4648 section 5), as the state and the PKCE verifier and
		challenge of the browser sign-in need it (RFC 7636 appendix A).

	.PARAMETER Bytes
		The bytes to encode.

	.EXAMPLE
		PS C:\> ConvertTo-EntraBase64Url -Bytes ([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

		43 random characters of the base64url alphabet.
	#>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[byte[]]
		$Bytes
	)

	[System.Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}
