function Invoke-EntraRetry {
	<#
	.SYNOPSIS
		Runs one Graph call and repeats it as the retry policy of the module allows.

	.DESCRIPTION
		The single retry layer for one call. The call is repeated after a failure that repeating can help:
		- an answer whose status Test-EntraRetryStatus calls transient (408, 429, 5xx except 501 and 505, and a 400
		  whose Graph error code - read from the body in ErrorDetails - is Directory_ConcurrencyViolation);
		- no answer at all (a network failure, a timeout).
		A call that is not idempotent (-NotIdempotent: a POST) is repeated only on 429 and 503 - the service said it did
		not carry it out; after a 500 or a lost answer it may have been done.
		The wait before the next attempt is the Retry-After of the answer (seconds or an HTTP date) when it has one, at
		most 5 minutes; otherwise 2^attempt seconds with a jitter of 0.8 to 1.2, also at most 5 minutes, so many callers
		throttled at once do not come back at the same moment.
		The number of repetitions is Settings.Request.RetryCount (or -RetryCount). The last failure is thrown as it is.
		Invoke-EntraRequest sends every page through this; nothing above it retries (the cmdlets call
		Invoke-PSFProtectedCommand without -RetryCount), so a request is sent at most RetryCount + 1 times.
		Every variable of this function starts with entraRetry: the script block runs in a scope below this one, and a
		name it reads from its caller (a parameter $Header, say) must not be shadowed by one of these.

	.PARAMETER ScriptBlock
		The call. It throws its failure (Invoke-RestMethod -ErrorAction Stop or an exception whose Response carries the
		HTTP answer).

	.PARAMETER NotIdempotent
		The call may change something: repeat it only when the service said it did not carry it out (429, 503).

	.PARAMETER RetryCount
		How often a failed call is repeated; default Settings.Request.RetryCount.

	.PARAMETER Report
		The run report (see Write-EntraBatchSummary): every repetition is counted under Resent with its pause, and a call
		that got through after one under Resent.Recovered.

	.EXAMPLE
		PS C:\> Invoke-EntraRetry -ScriptBlock { Invoke-RestMethod -Uri $uri -Headers $header -ErrorAction Stop }

		Reads the URL, repeating the read on throttling, server errors and lost answers.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[scriptblock]
		$ScriptBlock,

		[switch]
		$NotIdempotent,

		[ValidateRange(0, 20)]
		[int]
		$RetryCount,

		[hashtable]
		$Report
	)

	# Names of their own: the script block runs in a scope below this one and sees the variables of its caller.
	[int] $entraRetryCount = if ($PSBoundParameters.ContainsKey('RetryCount')) { $RetryCount } else { Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Fallback 5 }
	[int] $entraRetryAttempt = 0
	while ($true) {
		try {
			$entraRetryResult = & $ScriptBlock
			if ($entraRetryAttempt -gt 0 -and $null -ne $Report) { $Report['Resent.Recovered'] = [int]$Report['Resent.Recovered'] + 1 }
			break
		}
		catch {
			$entraRetryFailure = $_
			# The answer, if any: the first exception of the chain that carries an HTTP response.
			[int] $entraRetryStatus = -1
			[double] $entraRetryAfter = 0
			[bool] $entraRetryNoAnswer = $false
			$entraRetryException = $entraRetryFailure.Exception
			while ($entraRetryException) {
				$entraRetryResponse = $null
				if ($entraRetryException.PSObject.Properties['Response']) { $entraRetryResponse = $entraRetryException.Response }
				if ($entraRetryResponse -and $entraRetryResponse.PSObject.Properties['StatusCode']) {
					$entraRetryStatus = [int]$entraRetryResponse.StatusCode
					if ($entraRetryResponse.PSObject.Properties['Headers'] -and $entraRetryResponse.Headers -and $entraRetryResponse.Headers.PSObject.Properties['RetryAfter']) {
						$entraRetryHeader = $entraRetryResponse.Headers.RetryAfter
						if ($entraRetryHeader -and $entraRetryHeader.Delta) { $entraRetryAfter = $entraRetryHeader.Delta.TotalSeconds }
						elseif ($entraRetryHeader -and $entraRetryHeader.Date) { $entraRetryAfter = ($entraRetryHeader.Date - [DateTimeOffset]::UtcNow).TotalSeconds }
					}
					break
				}
				if ($entraRetryException -is [System.Net.Http.HttpRequestException] -and $entraRetryException.StatusCode) {
					$entraRetryStatus = [int]$entraRetryException.StatusCode
					break
				}
				if ($entraRetryException -is [System.Net.Http.HttpRequestException] -or $entraRetryException -is [System.TimeoutException] -or $entraRetryException -is [System.Threading.Tasks.TaskCanceledException] -or $entraRetryException -is [System.IO.IOException]) {
					$entraRetryNoAnswer = $true
					break
				}
				$entraRetryException = $entraRetryException.InnerException
			}

			# The Graph error codes of the answer's body (Invoke-RestMethod puts it into ErrorDetails): a 400
			# Directory_ConcurrencyViolation is transient. Only the codes are read, never the message text.
			[string[]] $entraRetryCodes = @()
			if ($entraRetryStatus -eq 400 -and $entraRetryFailure.ErrorDetails -and $entraRetryFailure.ErrorDetails.Message) {
				try {
					$entraRetryBody = $entraRetryFailure.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
					$entraRetryCodes = @($entraRetryBody.error.code, $entraRetryBody.error.innerError.code) | Where-Object { $_ -is [string] }
				}
				catch { $entraRetryCodes = @() }
			}
			[bool] $entraRetry = if ($entraRetryStatus -ge 0) { Test-EntraRetryStatus -Status $entraRetryStatus -ErrorCode $entraRetryCodes -NotIdempotent:$NotIdempotent }
			elseif ($entraRetryNoAnswer) { -not $NotIdempotent }
			else { $false }
			if (-not $entraRetry -or $entraRetryAttempt -ge $entraRetryCount) { throw }

			$entraRetryAttempt++
			# What the service asked for, at most 5 minutes; without it 2^attempt seconds with jitter, at most 5 minutes.
			[double] $entraRetryWait = [PSMicrosoftEntraID.Batch.RetryAfter]::Limit($entraRetryAfter)
			if ($entraRetryWait -le 0) {
				$entraRetryWait = [Math]::Min([double][PSMicrosoftEntraID.Batch.RetryAfter]::MaximumSeconds, [Math]::Pow(2, $entraRetryAttempt) * (0.8 + 0.4 * [System.Random]::Shared.NextDouble()))
			}
			if ($null -ne $Report) {
				$Report['Resent'] = [int]$Report['Resent'] + 1
				$Report['Resent.Longest'] = [Math]::Max([int]$Report['Resent.Longest'], [int][Math]::Ceiling($entraRetryWait))
				if ($entraRetryStatus -eq 429) { $Report['Throttled'] = [int]$Report['Throttled'] + 1 }
			}
			[string] $entraRetryReason = if ($entraRetryStatus -ge 0) { [string]$entraRetryStatus } else { 'no answer' }
			Write-PSFMessage -Level Verbose -String 'Request.Retry' -StringValues $entraRetryReason, ([Math]::Round($entraRetryWait, 1)), $entraRetryAttempt, $entraRetryCount
			Start-Sleep -Milliseconds ([int][Math]::Ceiling($entraRetryWait * 1000))
		}
	}
	$entraRetryResult
}
