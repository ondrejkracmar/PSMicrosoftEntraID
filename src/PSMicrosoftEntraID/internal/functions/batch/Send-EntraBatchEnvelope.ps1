function Send-EntraBatchEnvelope {
	<#
	.SYNOPSIS
		Posts one Graph $batch envelope and returns its sub-responses, read in C#.

	.DESCRIPTION
		The sequential transport of Invoke-EntraParallelBatch (-ThrottleLimit 1) and the seam the tests mock. Posts the
		envelope through the shared [PSMicrosoftEntraID.Batch.GraphBatchClient], which keeps the connection open and
		parses the raw answer in C#, so no PowerShell objects are built for the payload: each sub-response comes back as
		a [PSMicrosoftEntraID.Batch.BatchSubResponse] with status, Retry-After, paging links and the raw body - and with
		-ElementType the items of every successful page as typed objects.
		A failure of the envelope itself comes back as one synthetic sub-response per request: the HTTP status of the
		envelope when it was answered, 421 when it was refused before it was sent (not https, not the host of
		-AuthorizedUrl), 504 without an answer within PSMicrosoftEntraID.Settings.Request.TimeoutSeconds, 502 for an
		answer that is no $batch response, 503 for a network failure. Their messages never quote the answer.
		The envelope runs as a task waited for in short steps: Ctrl+C or a stopped pipeline cancels it at once instead
		of waiting for an answer that may never come.

	.PARAMETER Uri
		The $batch URL of the service.

	.PARAMETER Header
		The request headers, including Authorization.

	.PARAMETER Envelope
		The batch body: @{ requests = @( @{ id; method; url; headers; body } ) }.

	.PARAMETER AuthorizedUrl
		The service URL of the token in -Header. The client posts the envelope only over https to its scheme, host and
		port.

	.PARAMETER ElementType
		The type of one item of a page: successful pages are deserialized into it (Items) straight from their JSON.

	.EXAMPLE
		PS C:\> Send-EntraBatchEnvelope -Uri 'https://graph.microsoft.com/v1.0/$batch' -Header $header -Envelope $envelope -AuthorizedUrl 'https://graph.microsoft.com/v1.0'

		Posts the envelope and returns the sub-responses.
	#>
	[OutputType([PSMicrosoftEntraID.Batch.BatchSubResponse[]], [System.Array])]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Uri,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Header,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Envelope,

		[Parameter(Mandatory = $true)]
		[string]
		$AuthorizedUrl,

		[type]
		$ElementType
	)

	[string[]] $ids = @($Envelope.requests | ForEach-Object { [string]$_.id })
	[string] $body = $Envelope | ConvertTo-Json -Depth 20 -Compress
	[int] $timeoutSeconds = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Fallback 600
	$cancel = [System.Threading.CancellationTokenSource]::new()
	$task = [PSMicrosoftEntraID.Batch.GraphBatchClient]::SendAsync($Uri, $Header, $body, $ids, $timeoutSeconds, $AuthorizedUrl, $ElementType, $cancel.Token)
	try {
		# Short waits: PowerShell stops a pipeline only between statements, never inside a blocking .NET call. WaitAny
		# never throws; GetResult() raises a failure of the task as itself, not wrapped in an AggregateException.
		while ([System.Threading.Tasks.Task]::WaitAny([System.Threading.Tasks.Task[]]@($task), 200) -lt 0) { }
		, $task.GetAwaiter().GetResult()
	}
	finally {
		# Stopped while waiting: the envelope is cancelled, its connection closed. The source is released either way;
		# the envelope's own linked source keeps working after it is disposed.
		if (-not $task.IsCompleted) { $cancel.Cancel() }
		$cancel.Dispose()
	}
}
