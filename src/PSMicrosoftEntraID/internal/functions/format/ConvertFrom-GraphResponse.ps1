function ConvertFrom-GraphResponse {
	<#
	.SYNOPSIS
		Converts a Graph (or Defender for Endpoint) response into typed objects of this module with GraphJson.

	.DESCRIPTION
		The single conversion path behind every ConvertFrom-Rest* function. The typed objects are built by
		[PSMicrosoftEntraID.Serialization.GraphJson] (System.Text.Json): property names match ignoring case,
		[JsonPropertyName] covers the wire names that differ (members@delta, @odata.type, @removed, id ->
		TenantId), dates become DateTime, and unknown properties are ignored.

		Two inputs:

		- JSON text (a [string]): a collection page ({"value":[...]}), a bare array or a single object.
		  Deserialized straight from the text - no PowerShell objects are built at all.
		- Parsed objects, as Invoke-EntraRequest returns them today (Invoke-RestMethod has already parsed
		  the body). They are serialized back to JSON ONCE for the whole set and deserialized in one call.

		INTERIM STEP (phase B removes it): the parsed-object path exists only because Invoke-EntraRequest
		does not hand back the response text. It uses ConvertTo-Json -Depth 100 -Compress - the maximum
		depth ConvertTo-Json supports - instead of the old -Depth 3/4/6, which silently truncated nested
		data (assignedLicenses.disabledPlans, scopedRoleMembers.roleMemberInfo). Once the request layer
		returns the body text, callers pass the string and this branch goes away.

	.PARAMETER InputObject
		The response: JSON text, one parsed object, or an array of parsed objects. $null or empty yields nothing.

	.PARAMETER Type
		The type of ONE item, e.g. [PSMicrosoftEntraID.Users.User].

	.EXAMPLE
		PS C:\> ConvertFrom-GraphResponse -InputObject $response -Type ([PSMicrosoftEntraID.Users.User])

		Returns the users of the response as PSMicrosoftEntraID.Users.User objects.
	#>
	[CmdletBinding()]
	[OutputType([System.Array])]
	param (
		[AllowNull()]
		[AllowEmptyCollection()]
		[AllowEmptyString()]
		$InputObject,

		[Parameter(Mandatory = $true)]
		[type]
		$Type
	)

	if ($null -eq $InputObject) { return }

	if ($InputObject -is [string]) {
		if ([string]::IsNullOrWhiteSpace($InputObject)) { return }
		[PSMicrosoftEntraID.Serialization.GraphJson]::DeserializeCollection($InputObject, $Type)
		return
	}

	[object[]] $items = @(@($InputObject).Where({ $null -ne $_ }))
	if ($items.Count -eq 0) { return }

	# -InputObject (not the pipeline) keeps a one-item set a JSON array.
	[string] $json = ConvertTo-Json -InputObject $items -Depth 100 -Compress
	[PSMicrosoftEntraID.Serialization.GraphJson]::Deserialize($json, $Type.MakeArrayType())
}
