function Test-EntraRetryStatus {
	<#
	.SYNOPSIS
		Tells whether an answer with this HTTP status is worth sending again - the one status decision of the module.

	.DESCRIPTION
		The status part of the retry policy, shared by every path that repeats a Graph call: Invoke-EntraRetry asks
		it for a failed single call, Invoke-EntraParallelBatch for each sub-response of a $batch.
		- A call that is safe to repeat (GET, PUT, PATCH, DELETE): 408 Request Timeout, 429 Too Many Requests and the
		  server errors (5xx) except 501 Not Implemented and 505 HTTP Version Not Supported, which answer the same
		  every time.
		- A call that may have changed something (-NotIdempotent: a POST): only 429 and 503, where the service says
		  it did not carry the call out; after a 500 or a timeout the object may already have been created.
		- A 400 whose Graph error code (error.code or error.innerError.code, -ErrorCode) is
		  Directory_ConcurrencyViolation, for every method: the directory refused the change because another one to the
		  same object was in progress - nothing was carried out, and Graph itself says to wait briefly and retry. Every
		  other 400 is final.
		Every other status is final. This function is the one place the rule lives.

	.PARAMETER Status
		The HTTP status of the answer.

	.PARAMETER NotIdempotent
		The call may have changed something: only 429 and 503 are repeated (and a 400 Directory_ConcurrencyViolation).

	.PARAMETER ErrorCode
		The Graph error codes of the answer (error.code, error.innerError.code), if any.

	.EXAMPLE
		PS C:\> Test-EntraRetryStatus -Status 503 -NotIdempotent

		True: the service did not process the POST, it may be sent again.
	#>
	[OutputType([bool])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[int]
		$Status,

		[switch]
		$NotIdempotent,

		[AllowNull()]
		[AllowEmptyCollection()]
		[string[]]
		$ErrorCode
	)

	# A concurrency conflict: refused, not carried out - safe to repeat whatever the method.
	if ($Status -eq 400 -and @($ErrorCode) -contains 'Directory_ConcurrencyViolation') { return $true }
	if ($NotIdempotent) { return $Status -in 429, 503 }
	$Status -in 408, 429 -or ($Status -ge 500 -and $Status -le 599 -and $Status -notin 501, 505)
}
