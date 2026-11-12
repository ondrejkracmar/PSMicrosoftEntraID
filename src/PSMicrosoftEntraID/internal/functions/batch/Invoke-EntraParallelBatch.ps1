function Invoke-EntraParallelBatch {
	<#
	.SYNOPSIS
		Runs many independent Graph requests through $batch, several envelopes at a time.

	.DESCRIPTION
		The batch engine (see docs/internal/batch-engine.md); Invoke-PSEntraIDBatchRequest sends through it.
		- Packs ready requests into $batch envelopes of 20 and keeps up to -ThrottleLimit envelopes in flight at all
		  times as asynchronous .NET tasks on one shared HttpClient ([PSMicrosoftEntraID.Batch.GraphBatchClient]): the
		  connections stay open between envelopes, the moment an envelope is answered its pages are emitted and the
		  next one is sent, and no runspaces are involved. -ThrottleLimit 1 sends one envelope at a time through
		  Send-EntraBatchEnvelope (the seam the tests mock).
		- Every request carries its own method, URL, headers (ConsistencyLevel: eventual for advanced queries) and
		  body. The Authorization header is taken from the connected token for every envelope, so long runs keep a
		  fresh token.
		- A sub-request answered with a status Test-EntraRetryStatus calls transient (408, 429, 5xx but 501 and 505, a
		  400 Directory_ConcurrencyViolation for any method;
		  a POST only 429 and 503) is sent again after its OWN Retry-After (seconds or an HTTP date, at most 5 minutes;
		  without one 2^attempt seconds with a jitter of 0.8 to 1.2), up to Settings.Batch.RetryCount times; a 401 is
		  sent once more with a fresh header. A waiting request waits on its own while the rest keeps flowing - the
		  engine sleeps only when nothing is ready and nothing is in flight. This is the only retry layer of a run.
		- With -FollowNextLink, a page carrying @odata.nextLink queues the next page of the same key, until -First
		  items were returned for that key. A next link that is not https on the host of the service URL, or not under
		  the service URL, is not followed: the key ends with a page of status 421 whose Error says why (no query, no
		  token).
		- Envelopes go only over https to the host of the service URL; the client refuses any other before it is sent
		  (status 421 for each sub-request, not retried).
		- Every envelope may take Settings.Request.TimeoutSeconds; one without an answer by then comes back as 504
		  and is retried like an unavailable one. The envelopes of a run share one cancellation: when the run ends early
		  - Ctrl+C, a stopped pipeline, an error - every envelope still in flight is cancelled.
		Emits one object per final page, as it arrives: Key, Status, Succeeded, Body (raw JSON of the Graph body; null
		with -ElementType), Items (typed objects with -ElementType), Headers (raw JSON of the sub-response headers),
		NextLink, DeltaLink, ItemCount, Error (message when the page failed). The -Report hashtable collects the run for one summary (Write-EntraBatchSummary).

	.PARAMETER Request
		The requests: objects with Key (any caller identifier; pages of one key share it), Url (relative to the version
		root, starting with '/'), and optional Method (default GET), Headers (hashtable) and Body (object or JSON text).

	.PARAMETER Service
		The connected service whose token and service URL are used.

	.PARAMETER ThrottleLimit
		Envelopes in flight at the same time, 1 to 20; default Settings.Batch.ThrottleLimit.

	.PARAMETER FollowNextLink
		Queue the next page of a key whenever a page carries @odata.nextLink.

	.PARAMETER First
		With -FollowNextLink: stop paging a key after this many items in total. 0 = all.

	.PARAMETER ElementType
		The type of one item of a page; the pages are deserialized into it straight from their JSON text in C#
		([PSMicrosoftEntraID.Serialization.GraphJson]). A page that does not convert fails with the reason in Error.

	.PARAMETER Report
		The run report: Requests (final pages), Failed (pages that failed), Failed.Examples (up to five keys), Resent
		(sub-requests sent again), Resent.Recovered, Resent.Longest (seconds), Throttled (429 answers).

	.EXAMPLE
		PS C:\> $reads = $groupIds | ForEach-Object { [pscustomobject]@{ Key = $_; Url = "/groups/$_/members?`$select=id" } }
		PS C:\> Invoke-EntraParallelBatch -Request $reads -Service 'PSMicrosoftEntraID.Graph' -FollowNextLink -Report $report

		Reads all member pages of all groups, the configured number of envelopes in flight at a time.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[object[]]
		$Request,

		[Parameter(Mandatory = $true)]
		[string]
		$Service,

		[ValidateRange(1, 20)]
		[int]
		$ThrottleLimit,

		[switch]
		$FollowNextLink,

		[ValidateRange(0, [int]::MaxValue)]
		[int]
		$First = 0,

		[type]
		$ElementType,

		[hashtable]
		$Report
	)

	$token = $script:_EntraTokens[$Service]
	if (-not $token) {
		Invoke-TerminatingException -Cmdlet $PSCmdlet -Message "Not connected to the service '$Service'." -Category InvalidOperation
	}
	if (-not $PSBoundParameters.ContainsKey('ThrottleLimit')) { $ThrottleLimit = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.ThrottleLimit' -Fallback 4 }
	[string] $serviceUrl = ([string]$token.ServiceUrl).TrimEnd('/')
	[string] $batchUri = '{0}/$batch' -f $serviceUrl
	[int] $maxRetry = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Fallback 5
	[int] $timeoutSeconds = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Fallback 600
	# The helpers below are closures; they read these locals rather than the parameters.
	$runReport = if ($null -ne $Report) { $Report } else { @{} }
	[bool] $followNext = $FollowNextLink.IsPresent
	[int] $firstLimit = $First
	$itemType = $ElementType

	$queue = [System.Collections.Generic.Queue[object]]::new()
	foreach ($item in $Request) {
		[string] $method = if ($item.PSObject.Properties['Method'] -and $item.Method) { ([string]$item.Method).ToUpperInvariant() } else { 'GET' }
		$queue.Enqueue([pscustomobject]@{
				Key       = $item.Key
				Method    = $method
				Url       = [string]$item.Url
				Headers   = $(if ($item.PSObject.Properties['Headers']) { $item.Headers })
				Body      = $(if ($item.PSObject.Properties['Body']) { $item.Body })
				Attempt   = 0
				NotBefore = [datetime]::MinValue
			})
	}
	# Requests waiting for their own Retry-After.
	$waiting = [System.Collections.Generic.List[object]]::new()
	$itemsPerKey = @{}
	# The time the engine last slept until: what it waited for is released even when the sleep returned a moment early.
	$clock = @{ WokeAt = [datetime]::MinValue }

	#region Helpers (closures over the state above)
	$releaseWaiting = {
		$now = [datetime]::UtcNow
		if ($clock.WokeAt -gt $now) { $now = $clock.WokeAt }
		# In the order they started waiting, so the pages of a run keep their order where they can.
		$index = 0
		while ($index -lt $waiting.Count) {
			if ($waiting[$index].NotBefore -le $now) {
				$queue.Enqueue($waiting[$index])
				$waiting.RemoveAt($index)
			}
			else { $index++ }
		}
	}

	$newEnvelope = {
		# Takes up to 20 ready entries; returns $null when nothing is ready.
		if ($queue.Count -eq 0) { return $null }
		$entries = [System.Collections.Generic.List[object]]::new()
		while ($queue.Count -gt 0 -and $entries.Count -lt 20) { $entries.Add($queue.Dequeue()) }
		$requests = for ($index = 0; $index -lt $entries.Count; $index++) {
			$entry = $entries[$index]
			$subRequest = @{ id = [string]($index + 1); method = $entry.Method; url = $entry.Url }
			$headers = @{}
			if ($entry.Headers) { foreach ($name in @($entry.Headers.Keys)) { $headers[$name] = $entry.Headers[$name] } }
			if ($null -ne $entry.Body) {
				# Graph requires the content type of every sub-request that has a body.
				if (-not @($headers.Keys | Where-Object { $_ -eq 'Content-Type' })) { $headers['Content-Type'] = 'application/json' }
				$subRequest.body = if ($entry.Body -is [string]) { $entry.Body | ConvertFrom-Json } else { $entry.Body }
			}
			if ($headers.Count -gt 0) { $subRequest.headers = $headers }
			$subRequest
		}
		# A fresh header per envelope keeps long runs authenticated (GetHeader renews an expiring token).
		[hashtable] $header = $token.GetHeader().Clone()
		$header.Remove('Content-Type')
		[pscustomobject]@{ Entries = $entries; Envelope = @{ requests = @($requests) }; Header = $header }
	}

	$newPage = {
		param ($Entry, [int]$Status, $Response, [string]$ErrorText)
		[bool] $succeeded = $Status -ge 200 -and $Status -lt 400 -and -not $ErrorText
		$runReport['Requests'] = [int]$runReport['Requests'] + 1
		if ($Entry.Attempt -gt 0 -and $succeeded) { $runReport['Resent.Recovered'] = [int]$runReport['Resent.Recovered'] + 1 }
		if (-not $succeeded) {
			$runReport['Failed'] = [int]$runReport['Failed'] + 1
			if (-not $runReport.ContainsKey('Failed.Examples')) { $runReport['Failed.Examples'] = [System.Collections.Generic.List[string]]::new() }
			if ($runReport['Failed.Examples'].Count -lt 5) { $runReport['Failed.Examples'].Add(('{0} ({1})' -f $Entry.Key, $Status)) }
		}
		[pscustomobject]@{
			Key       = $Entry.Key
			Status    = $Status
			Succeeded = $succeeded
			Body      = $(if ($Response -and -not $itemType) { $Response.Body })
			Items     = $(if ($Response -and $itemType) { $Response.Items })
			Headers   = $(if ($Response) { $Response.Headers })
			NextLink  = $(if ($Response) { $Response.NextLink })
			DeltaLink = $(if ($Response) { $Response.DeltaLink })
			ItemCount = $(if ($Response) { $Response.ItemCount } else { 0 })
			Error     = $ErrorText
		}
	}

	$processResponses = {
		param ($Entries, $Responses)
		foreach ($response in @($Responses)) {
			$entry = $Entries[[int]$response.Id - 1]
			[int] $status = $response.Status
			# Transient as the status decision of the module says; a POST only when the service did not carry it out.
			[bool] $transient = $status -ge 400 -and $entry.Attempt -lt $maxRetry -and (Test-EntraRetryStatus -Status $status -ErrorCode @($response.ErrorCode, $response.InnerErrorCode) -NotIdempotent:($entry.Method -eq 'POST'))
			# 401 once: the token may have expired; the next envelope takes a fresh header.
			[bool] $reauth = $status -eq 401 -and $entry.Attempt -lt 1
			if ($transient -or $reauth) {
				$entry.Attempt++
				[double] $wait = 0
				if (-not $reauth) {
					$wait = [PSMicrosoftEntraID.Batch.RetryAfter]::Limit($response.RetryAfter)
					if ($wait -le 0) { $wait = [Math]::Min([double][PSMicrosoftEntraID.Batch.RetryAfter]::MaximumSeconds, [Math]::Pow(2, $entry.Attempt) * (0.8 + 0.4 * [System.Random]::Shared.NextDouble())) }
				}
				$runReport['Resent'] = [int]$runReport['Resent'] + 1
				$runReport['Resent.Longest'] = [Math]::Max([int]$runReport['Resent.Longest'], [int][Math]::Ceiling($wait))
				if ($status -eq 429) { $runReport['Throttled'] = [int]$runReport['Throttled'] + 1 }
				Write-PSFMessage -Level Debug -String 'Batch.Parallel.Resend' -StringValues $entry.Key, $status, ([Math]::Round($wait, 1)), $entry.Attempt, $maxRetry
				$entry.NotBefore = [datetime]::UtcNow.AddSeconds($wait)
				$waiting.Add($entry)
				continue
			}

			[string] $errorText = if ($status -lt 200 -or $status -ge 400) { [string]$response.ErrorMessage } elseif ($response.ConversionError) { [string]$response.ConversionError } else { '' }
			& $newPage $entry $status $response $errorText
			if ($errorText -or -not $followNext) { continue }

			$keyName = [string]$entry.Key
			$itemsPerKey[$keyName] = [int]$itemsPerKey[$keyName] + $response.ItemCount
			[string] $nextLink = [string]$response.NextLink
			if (-not $nextLink -or ($firstLimit -gt 0 -and $itemsPerKey[$keyName] -ge $firstLimit)) { continue }
			# A next link on another host, over http or outside the service URL is not followed - not even re-aimed
			# at the service: the key ends with a failed page (421, not retried).
			[string] $refusal = [PSMicrosoftEntraID.Batch.GraphBatchClient]::CheckUri($nextLink, $serviceUrl)
			if (-not $refusal -and -not $nextLink.StartsWith($serviceUrl + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
				$refusal = (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.NextLinkNotUnderService') -f $serviceUrl
			}
			if ($refusal) {
				Write-PSFMessage -Level Debug -String 'Batch.NextLinkRefused' -StringValues $refusal
				$refused = [pscustomobject]@{ Key = $entry.Key; Attempt = 0 }
				& $newPage $refused 421 $null ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.NextLinkRefused') -f $refusal)
				continue
			}
			# Sub-request URLs are relative to the version root. The next page carries the same headers (a
			# ConsistencyLevel the first page needed, the next ones need too) and is always a GET.
			$queue.Enqueue([pscustomobject]@{ Key = $entry.Key; Method = 'GET'; Url = $nextLink.Substring($serviceUrl.Length); Headers = $entry.Headers; Body = $null; Attempt = 0; NotBefore = [datetime]::MinValue })
		}
	}

	$sleepUntilReady = {
		# 50 ms past the earliest: requests that became due together go out in one envelope, none before its time.
		$next = ([datetime](($waiting | Measure-Object -Property NotBefore -Minimum).Minimum)).AddMilliseconds(50)
		[int] $sleepMs = [Math]::Max(50, [Math]::Ceiling(($next - [datetime]::UtcNow).TotalMilliseconds))
		Write-PSFMessage -Level Verbose -String 'Batch.Parallel.Throttled' -StringValues ([Math]::Round($sleepMs / 1000, 1))
		Start-Sleep -Milliseconds $sleepMs
		$clock.WokeAt = $next
	}
	#endregion Helpers

	#region Sequential: one envelope at a time in this runspace (and the seam the tests mock)
	if ($ThrottleLimit -le 1) {
		while ($queue.Count -gt 0 -or $waiting.Count -gt 0) {
			& $releaseWaiting
			$envelope = & $newEnvelope
			if (-not $envelope) {
				& $sleepUntilReady
				continue
			}
			$responses = Send-EntraBatchEnvelope -Uri $batchUri -Header $envelope.Header -Envelope $envelope.Envelope -AuthorizedUrl $serviceUrl -ElementType $itemType
			& $processResponses $envelope.Entries $responses
		}
		return
	}
	#endregion Sequential

	#region Parallel: ThrottleLimit envelopes always in flight as .NET tasks on one shared HttpClient
	$inFlight = [System.Collections.Generic.List[object]]::new()
	# One cancellation for the whole run: whatever ends it early cancels every envelope still in flight.
	$cancel = [System.Threading.CancellationTokenSource]::new()
	try {
		while ($queue.Count -gt 0 -or $waiting.Count -gt 0 -or $inFlight.Count -gt 0) {
			& $releaseWaiting
			# Keep the pipe full.
			while ($inFlight.Count -lt $ThrottleLimit) {
				$envelope = & $newEnvelope
				if (-not $envelope) { break }
				[string[]] $ids = @($envelope.Envelope.requests | ForEach-Object { [string]$_.id })
				[string] $body = $envelope.Envelope | ConvertTo-Json -Depth 20 -Compress
				$inFlight.Add([pscustomobject]@{ Task = [PSMicrosoftEntraID.Batch.GraphBatchClient]::SendAsync($batchUri, $envelope.Header, $body, $ids, $timeoutSeconds, $serviceUrl, $itemType, $cancel.Token); Entries = $envelope.Entries })
			}

			if ($inFlight.Count -eq 0) {
				& $sleepUntilReady
				continue
			}

			# Wait for whichever envelope finishes first, in short steps, so waiting requests are released on time and
			# a stop is noticed.
			[System.Threading.Tasks.Task[]] $tasks = @($inFlight | ForEach-Object { $_.Task })
			$null = [System.Threading.Tasks.Task]::WaitAny($tasks, 250)
			for ($index = $inFlight.Count - 1; $index -ge 0; $index--) {
				$flight = $inFlight[$index]
				if (-not $flight.Task.IsCompleted) { continue }
				$inFlight.RemoveAt($index)
				& $processResponses $flight.Entries $flight.Task.GetAwaiter().GetResult()
			}
		}
	}
	finally {
		# Ended early (stop, error): the envelopes still in flight are cancelled and their connections closed.
		$cancel.Cancel()
		$cancel.Dispose()
	}
	#endregion Parallel
}
