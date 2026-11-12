function Read-TokenData {
	<#
	.SYNOPSIS
		Reads a JWT token and converts it into a custom object showing its properties.
	
	.DESCRIPTION
		Reads a JWT token and converts it into a custom object showing its properties.
	
	.PARAMETER Token
		The JWT Token to parse
	
	.EXAMPLE
		PS C:\> Read-TokenData -Token $authresponse.access_token
		
		Reads the settings on the returned access token.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
        [string]
        $Token
	)
	process {
		$tokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
		# Pad with "=" until string length modulus 4 reaches 0
		while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
		$bytes = [System.Convert]::FromBase64String($tokenPayload)
		# UTF-8: a name claim can hold any character; ASCII turned them into '?'.
		[System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
	}
}