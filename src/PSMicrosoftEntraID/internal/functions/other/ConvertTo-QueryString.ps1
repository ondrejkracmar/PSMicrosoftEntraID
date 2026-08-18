function ConvertTo-QueryString {
	<#
    .SYNOPSIS
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .DESCRIPTION
        Convert conditions in a hashtable to a Query string to append to a webrequest.
    
    .PARAMETER QueryHash
        Hashtable of query modifiers - usually filter conditions - to include in a web request.

	.PARAMETER DefaultQuery
		Default query parameters defined in the service configuration.
		Default query settings are overriden by explicit query parameters.
    
    .EXAMPLE
        PS C:\> ConvertTo-QueryString -QueryHash $Query

        Converts the conditions in the specified hashtable to a Query string to append to a webrequest.
    #>
	[OutputType([string])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[Hashtable]
		$QueryHash,

		[AllowNull()]
		[hashtable]
		$DefaultQuery
	)

	process {
		if ($DefaultQuery) { $query = $DefaultQuery.Clone() }
		else { $query = @{} }

		foreach ($key in $QueryHash.Keys) {
			$query[$key] = $QueryHash[$key]
		}
		if ($query.Count -lt 1) { return '' }


		$elements = foreach ($pair in $query.GetEnumerator()) {
			# The VALUE is percent-encoded; nothing here did that before, and two of the
			# characters this module actually sends are URL metacharacters:
			#
			#   '#'  starts the URI fragment, so a $Filter naming any guest - every guest
			#        UPN contains '#EXT#' - was silently truncated mid-literal and Graph
			#        answered "unterminated string literal". Found by the live guest
			#        scenario, which could not read the one guest it was pointed at.
			#   '+'  decodes to a SPACE in a query string, so a base64 delta token
			#        containing '+' would come back to Graph corrupted.
			#
			# Keys are left as-is on purpose: they are this module's own literals
			# ('$select', '$Filter', ...) and encoding '$' would only obscure the URL in
			# every log for no correctness gain.
			'{0}={1}' -f $pair.Name, [uri]::EscapeDataString(($pair.Value -join ","))
		}
		'?{0}' -f ($elements -join '&')
	}
}