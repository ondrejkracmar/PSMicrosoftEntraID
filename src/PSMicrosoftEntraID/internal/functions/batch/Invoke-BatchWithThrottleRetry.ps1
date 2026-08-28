function Invoke-BatchWithThrottleRetry {
    <#
    .SYNOPSIS
        Posts a Graph $batch and re-sends the sub-requests Graph throttled, until they
        get through or the retry budget runs out.

    .DESCRIPTION
        Graph reports throttling of a SUB-request inside the batch body - the envelope
        still comes back HTTP 200 with a 429 on that one entry. The retry logic in
        Invoke-EntraRequest inspects the HTTP error, so it never sees this: a throttled
        sub-request used to be dropped silently, in the one feature that exists for bulk
        work.

        Each pass keeps every response that is not a 429 and re-posts only the throttled
        ids. The wait comes from the sub-response's own Retry-After header when Graph
        sends one, because Graph knows better than we do; otherwise the caller's retry
        wait is used, doubling each pass so a busy tenant is not hammered.

        Responses are returned in the original request order regardless of how many
        passes it took, so callers can still line them up with their requests.

        Sub-requests that fail for any other reason are returned untouched - retrying a
        403 would only produce another 403. The caller sees them in Status.

    .PARAMETER Payload
        The BatchRequestPayload to send.

    .PARAMETER Service
        Entra service name to send through.

    .PARAMETER Header
        Headers for the batch request itself.

    .PARAMETER Path
        Batch endpoint path, normally '$batch'.

    .PARAMETER RetryCount
        How many extra passes to make over throttled sub-requests. 0 disables retrying
        and restores the previous behaviour.

    .PARAMETER RetryWait
        Fallback wait when Graph sends no Retry-After. Doubles per pass.

    .EXAMPLE
        PS C:\> Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{ 'Content-Type' = 'application/json' } -Path '$batch'

        Posts the batch once. With no retry budget a throttled sub-request comes back
        with its 429 rather than being re-sent - the behaviour callers had before.

    .EXAMPLE
        PS C:\> Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header $header -Path '$batch' -RetryCount 5 -RetryWait (New-TimeSpan -Seconds 10)

        Makes up to five extra passes over whichever sub-requests Graph throttled,
        waiting as long as Graph's own Retry-After asks and falling back to ten seconds
        (doubling each pass) when it sends none.
    #>
    [CmdletBinding()]
    [OutputType([PSMicrosoftEntraID.Batch.Response[]])]
    param (
        [Parameter(Mandatory = $true)] [PSMicrosoftEntraID.Batch.BatchRequestPayload] $Payload,
        [Parameter(Mandatory = $true)] [string] $Service,
        [Parameter(Mandatory = $true)] [hashtable] $Header,
        [Parameter(Mandatory = $true)] [string] $Path,
        [Parameter()] [int] $RetryCount = 0,
        [Parameter()] [timespan] $RetryWait = [timespan]::FromSeconds(5)
    )

    # Graph's own throttling status. Anything else is the caller's business.
    $throttledStatus = 429

    $pending = @($Payload.Requests)
    $collected = [System.Collections.Generic.Dictionary[string, object]]::new()
    $wait = $RetryWait
    $attempt = 0

    while ($pending.Count -gt 0) {
        # headers/body only when they carry something: Graph's JSON batching rejects a
        # GET sub-request that has a body - and the Request class defaults both to an
        # empty hashtable, so the unconditional projection sent "body": {} with every
        # GET and each such sub-request came back 400. Write sub-requests (which always
        # populate both) serialize exactly as before.
        [hashtable] $body = @{
            'requests' = @(foreach ($request in $pending) {
                    $entry = [ordered]@{
                        'id'     = $request.Id
                        'method' = $request.Method
                        'url'    = $request.Url
                    }
                    if ($request.Headers -and $request.Headers.Count -gt 0) { $entry['headers'] = $request.Headers }
                    if ($request.Body -and $request.Body.Count -gt 0) { $entry['body'] = $request.Body }
                    [pscustomobject] $entry
                })
        }

        $batchResponse = Invoke-EntraRequest -Service $Service -Header $Header -Path $Path -Body $body -Method Post -ErrorAction Stop

        $throttled = [System.Collections.Generic.List[object]]::new()
        [int] $retryAfter = 0
        foreach ($response in @($batchResponse.Responses)) {
            if ([int]$response.status -eq $throttledStatus -and $attempt -lt $RetryCount) {
                $request = $pending | Where-Object { [string]$_.Id -eq [string]$response.id } | Select-Object -First 1
                if ($request) {
                    $throttled.Add($request)
                    # Graph puts the wait it wants in the sub-response's headers.
                    if ($response.headers -and $response.headers.PSObject.Properties['Retry-After']) {
                        $headerWait = 0
                        if ([int]::TryParse([string]$response.headers.'Retry-After', [ref]$headerWait) -and $headerWait -gt $retryAfter) {
                            $retryAfter = $headerWait
                        }
                    }
                    continue
                }
            }
            $collected[[string]$response.id] = $response
        }

        if ($throttled.Count -eq 0) { break }

        $attempt++
        $sleep = if ($retryAfter -gt 0) { [timespan]::FromSeconds($retryAfter) } else { $wait }
        Write-PSFMessage -Level Warning -String 'Batch.Throttled' -StringValues $throttled.Count, [int]$sleep.TotalSeconds, $attempt, $RetryCount
        Start-Sleep -Seconds ([int]$sleep.TotalSeconds)
        $wait = [timespan]::FromSeconds($wait.TotalSeconds * 2)
        $pending = @($throttled)
    }

    # Original request order, whatever order the passes resolved in.
    $ordered = foreach ($request in @($Payload.Requests)) {
        $key = [string]$request.Id
        if ($collected.ContainsKey($key)) { $collected[$key] }
    }

    $failed = @($ordered | Where-Object { [int]$_.status -ge 400 })
    if ($failed.Count -gt 0) {
        # A batch envelope comes back HTTP 200 even when every sub-request was rejected.
        # Without this the caller cannot tell that batch from a completely successful one.
        Write-PSFMessage -Level Warning -String 'Batch.SubRequestFailed' -StringValues $failed.Count, @($Payload.Requests).Count, (($failed | ForEach-Object { '{0}:{1}' -f $_.id, $_.status }) -join ', ')
    }

    [PSMicrosoftEntraID.Batch.Response[]] (@($ordered) | Select-Object -Property @{ Name = 'Id'; Expression = { $PSItem.id } } `
            , @{ Name = 'Status'; Expression = { $PSItem.status } } `
            , @{ Name = 'Headers'; Expression = { $PSItem.headers } } `
            , @{ Name = 'Body'; Expression = { $PSItem.body } })
}
