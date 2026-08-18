function Invoke-EntraRequest {
	<#
	.SYNOPSIS
		Executes a web request against an entra-based service
	
	.DESCRIPTION
		Executes a web request against an entra-based service
		Handles all the authentication details once connected using Connect-EntraService.
	
	.PARAMETER Path
		The relative path of the endpoint to query.
		For example, to retrieve Microsoft Graph users, it would be a plain "users".
		To access details on a particular defender for endpoint machine instead it would look thus: "machines/1e5bc9d7e413ddd7902c2932e418702b84d0cc07"
	
	.PARAMETER Body
		Any body content needed for the request.

    .PARAMETER Query
        Any query content to include in the request.
        In opposite to -Body this is attached to the request Url and usually used for filtering.
	
	.PARAMETER Method
		The Rest Method to use.
		Defaults to GET
	
	.PARAMETER RequiredScopes
		Any authentication scopes needed.
		Used for documentary purposes only.

	.PARAMETER Header
		Any additional headers to include on top of authentication and content-type.

	.PARAMETER ContentType
		Specify the content-type of this request.
		Equivalent to specifying it as a header entry, but added as dedicated parameter for user convenience.
	
	.PARAMETER Service
		Which service to execute against.
		Determines the API endpoint called to.
		Defaults to "Graph"

	.PARAMETER SerializationDepth
		How deeply to serialize the request body when converting it to json.
		Defaults to: 99

	.PARAMETER Token
		A Token as created and maintained by this module.
		If specified, it will override the -Service parameter.

	.PARAMETER NoPaging
		Do not automatically page through responses sets.
		By default, Invoke-EntraRequest is going to keep retrieving result pages until all data has been retrieved.

	.PARAMETER Raw
		Do not process the response object and instead return the raw result returned by the API.

	.PARAMETER DeltaSession
		A hashtable including delta sessions.
		Use together with the delta endpoints, e.g. for the Graph API's user delta endpoint:
		https://learn.microsoft.com/en-us/graph/api/user-delta
		Provide an empty hashtable on the first request, the delta token data will be inserted into it.
		Provide the same token for subsequent delta requests.

		This allows retrieving changes over time, without having to reload the entire dataset.

	.PARAMETER MinimalDelta
		When receiving delta data, only return the changed properties (plus a unique identifier), rather than the full object.
		Only used together with DeltaSession
	
	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Path 'alerts' -RequiredScopes 'Alert.Read'
	
		Return a list of defender alerts.

	.EXAMPLE
		PS C:\> Invoke-EntraRequest -Path 'users/delta' -DeltaSession $delta

		Retrieves all users on first request.
		Subsequent calls will only return users that have been changed in the meantime.
#>
	[CmdletBinding(DefaultParameterSetName = 'default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		$Body,

		[Hashtable]
		$Query = @{ },
		
		[string]
		$Method = 'GET',
		
		[string[]]
		$RequiredScopes,

		[hashtable]
		$Header = @{},

		[string]
		$ContentType,
		
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ -IncludeTokens })]
		[string]
		$Service = $script:_DefaultService,

		[ValidateRange(1, 666)]
		[int]
		$SerializationDepth = 99,

		[EntraToken]
		$Token,

		[switch]
		$NoPaging,

		[switch]
		$Raw,

		[hashtable]
		$DeltaSession,

		[switch]
		$MinimalDelta
	)
	
	DynamicParam {
		if ($Resource) { return }

		$actualService = $Service
		if (-not $actualService) { $actualService = $script:_DefaultService }
		$serviceObject = $script:_EntraEndpoints.$actualService
		if (-not $serviceObject) { return }
		if ($serviceObject.Parameters.Count -lt 1) { return }

		$results = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
		foreach ($pair in $serviceObject.Parameters.GetEnumerator()) {
			$parameterAttribute = [System.Management.Automation.ParameterAttribute]::new()
			$parameterAttribute.ParameterSetName = '__AllParameterSets'
			$parameterAttribute.Mandatory = $true
			$parameterAttribute.HelpMessage = $pair.Value
			$attributesCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
			$attributesCollection.Add($parameterAttribute)
			$RuntimeParam = [System.Management.Automation.RuntimeDefinedParameter]::new($pair.Key, [object], $attributesCollection)

			$results.Add($pair.Key, $RuntimeParam)
		}

		$results
	}

	begin {
		if ($Token) {
			$tokenObject = $Token
		}
		else {
			Assert-EntraConnection -Service $Service -Cmdlet $PSCmdlet -RequiredScopes $RequiredScopes
			$tokenObject = $script:_EntraTokens.$Service
		}
		
		$serviceObject = $script:_EntraEndpoints.$($tokenObject.Service)
		if ($ContentType) { $Header['Content-Type'] = $ContentType }
	}
	process {
		$parameters = @{
			Method = $Method
			Uri    = Resolve-RequestUri -TokenObject $tokenObject -ServiceObject $serviceObject -BoundParameters $PSBoundParameters
		}
		$originalUri = $parameters.Uri
		
		if ($PSBoundParameters.Keys -contains 'Body') {
			if ($Body -is [string]) {
				$parameters.Body = $Body
			}
			else {
				$parameters.Body = $Body | ConvertTo-Json -Compress -Depth $SerializationDepth
			}
		}
		# In PS5.1, some methods cannot contain a body
		$noBodyMethods = 'Default', 'Get', 'Head'
		if ($PSVersionTable.PSVersion.Major -lt 6 -and $Method -in $noBodyMethods) {
			$parameters.Remove('Body')
		}
		
		$queryClone = $Query.Clone()
		if ($DeltaSession -and $DeltaSession[$originalUri].Token) {
			$queryClone['$deltaToken'] = $DeltaSession[$originalUri].Token
		}
		$parameters.Uri += ConvertTo-QueryString -QueryHash $queryClone -DefaultQuery $tokenObject.Query

		do {
			$tempHeader = $tokenObject.GetHeader().Clone() # GetHeader() automatically refreshes expired tokens
			foreach ($pair in $Header.GetEnumerator()) { $tempHeader[$pair.Key] = $pair.Value }
			if ($MinimalDelta) { $tempHeader['Prefer'] = 'return=minimal' }
			$parameters.Headers = $tempHeader
			Write-Verbose "Executing Request: $($Method) -> $($parameters.Uri)"
			try { $result = Invoke-RestMethod @parameters -ErrorAction Stop }
			catch {
				$letItBurn = $true
				$failure = $_

				if ($_.ErrorDetails.Message) {
					$details = $_.ErrorDetails.Message | ConvertFrom-Json
					if ($details.Error.Code -eq 'TooManyRequests') {
						Write-Verbose "Throttling: $($details.error.message)"
						$delay = 1 + ($details.error.message -replace '^.+ (\d+) .+$', '$1' -as [int])
						if ($delay -gt 5) { Write-Warning "Request is being throttled for $delay seconds" }
						Start-Sleep -Seconds $delay
						try {
							$result = Invoke-RestMethod @parameters -ErrorAction Stop
							$letItBurn = $false
						}
						catch {
							$failure = $_
						}
					}
				}

				if ($letItBurn) {
					Write-Warning "Request failed: $($Method) -> $($parameters.Uri)"
					$PSCmdlet.ThrowTerminatingError($failure)
				}
			}
			if (-not $Raw -and -not $tokenObject.RawOnly -and $result.PSObject.Properties.Where{ $_.Name -eq 'value' }) { $result.Value }
			else { $result }
			$parameters.Uri = $result.'@odata.nextLink'

			if ($DeltaSession -and $result.'@odata.deltaLink') {
				# Parse the query properly instead of splitting the whole link on '=' and
				# taking the last piece. That shortcut breaks on both shapes Graph
				# actually returns: a token carrying base64 '=' padding truncates to an
				# empty string, and a link where $deltatoken is not the final parameter
				# yields the value of whatever came last. Both fail silently - an empty
				# token makes every run a full read, a wrong one is sent back to Graph as
				# if it were real.
				$deltaToken = $null
				$queryPart = ([string]$result.'@odata.deltaLink' -split '\?', 2)[1]
				if ($queryPart) {
					foreach ($pair in ($queryPart -split '&')) {
						# Split on the FIRST '=' only: the name is ours to match, the
						# value is opaque and may contain more of them.
						$keyValue = $pair -split '=', 2
						if ($keyValue.Count -eq 2 -and $keyValue[0] -in '$deltatoken', '%24deltatoken') {
							# DECODED before storing. This substring is cut out of a URL,
							# so whatever percent-encoding the link carried is still in
							# it - and ConvertTo-QueryString now encodes every value on
							# the way out. Storing the raw substring would double-encode
							# on the next request ('%2B' -> '%252B') and hand Graph a
							# corrupted token. Decode here, encode exactly once there.
							$deltaToken = [uri]::UnescapeDataString($keyValue[1])
							break
						}
					}
				}

				if ($deltaToken) {
					if (-not $DeltaSession[$originalUri]) {
						$DeltaSession[$originalUri] = @{}
					}
					$DeltaSession[$originalUri]['Token'] = $deltaToken
				}
				else {
					# Keep whatever token we already had rather than replacing it with
					# nothing: losing it costs a full re-read, and an empty one guarantees
					# that re-read happens on every run from here on.
					Write-Warning "Delta link returned without a usable token, keeping the previous one: $($result.'@odata.deltaLink')"
				}
			}
		}
		while ($parameters.Uri -and -not $NoPaging)
	}
}