Function Test-PSMicrosoftEntraIDBatchRequest {
	<#
		.SYNOPSIS
			Validates the structure and sequencing of Microsoft Entra ID (Azure AD) batch requests.

		.DESCRIPTION
			This cmdlet validates a collection of batch requests, where each request is a hashtable
			representing Microsoft Entra ID (Azure AD) operations. It checks that:
			  1. The array contains no more than 20 requests.
			  2. Each request has 'id', 'method', and 'url'.
			  3. The 'id' values are unique and form a continuous range from "1" to the total count
				 (in any order).

		.PARAMETER Requests
			An array of hashtables representing the batch requests.
			Each hashtable must at least contain:
				id     = '1'    # (string)
				method = 'GET'  # (string)
				url    = '/...' # (string)

		.EXAMPLE
			$requests = @(
				@{ id = '3'; method = 'GET';   url = '/some/url3' },
				@{ id = '1'; method = 'GET';   url = '/some/url1' },
				@{ id = '2'; method = 'PATCH'; url = '/some/url2' }
			)

			Test-PSMicrosoftEntraIDBatchRequest -Requests $requests

			This example validates three requests. Their IDs (1, 2, 3) are out of order but still
			form a valid sequence: "1", "2", and "3".

		.EXAMPLE
			# For a JSON file, you might do something like:
			$json = Get-Content -Path .\requests.json -Raw | ConvertFrom-Json

			# Suppose $json.requests is an array of PSCustomObject.
			# Convert them to hashtables if needed:
			$requests = $json.requests | ForEach-Object {
				@{
					id     = $_.id
					method = $_.method
					url    = $_.url
					# ... and copy any other needed properties ...
				}
			}

			Test-PSMicrosoftEntraIDBatchRequest -Requests $requests

			This example shows how you might convert each PSCustomObject to a hashtable before
			calling the cmdlet.

		.OUTPUT
			System.Boolean
			Returns $true if all validations pass; otherwise throws an exception.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(
			Mandatory = $true,
			ValueFromPipeline = $true,
			HelpMessage = "Provide an array of batch request objects as hashtables."
		)]
		[hashtable[]]$Requests
	)

	Begin {
		# No special initialization
	}

	Process {
		# 1) Ensure the number of requests does not exceed 20.
		if ($Requests.Count -gt 20) {
			throw "There are more than 20 requests. The maximum allowed is 20."
		}

		# 2) Check that each hashtable has 'id', 'method', and 'url'.
		foreach ($request in $Requests) {
			if (-not $request.ContainsKey('id')) {
				throw "One of the requests is missing the 'id' property."
			}
			if (-not $request.ContainsKey('method')) {
				throw "Request with 'id'='$($request['id'])' is missing the 'method' property."
			}
			if (-not $request.ContainsKey('url')) {
				throw "Request with 'id'='$($request['id'])' is missing the 'url' property."
			}
		}

		# 3) Validate that 'id' values form a continuous sequence 1..N (any order)
		#    and that there are no duplicates.

		# Collect all IDs
		$allIds = $Requests | ForEach-Object { $_['id'] }

		# Expected sequence of IDs from '1' to the count of requests (as strings)
		$expectedIds = 1..$Requests.Count | ForEach-Object { $_.ToString() }

		# Check for duplicates
		$uniqueIds = $allIds | Select-Object -Unique
		if ($uniqueIds.Count -ne $Requests.Count) {
			throw "Duplicate 'id' values found among the requests."
		}

		# Ensure each expected ID is present
		foreach ($id in $expectedIds) {
			if ($id -notin $allIds) {
				throw "Missing 'id'='$id' in the request collection."
			}
		}
	}

	End {
		# Return $true if all checks are successful
		return $true
	}
}
