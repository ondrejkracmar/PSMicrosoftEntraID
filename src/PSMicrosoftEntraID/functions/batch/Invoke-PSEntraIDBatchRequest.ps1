function Invoke-PSEntraIDBatchRequest {
    <#
    .SYNOPSIS
        Invokes Microsoft Graph batch requests from BatchRequestPayload objects and returns
        the requests together with their responses.

    .DESCRIPTION
        This function expects pipeline input of BatchRequestPayload objects (such as those
        produced by New-PSEntraIDBatchRequest). Each BatchRequestPayload contains up to 20
        sub-requests.

        The sub-requests of all payloads are sent through the module's batch engine: they are
        packed into Graph $batch envelopes of 20, and Settings.Batch.ThrottleLimit envelopes
        (default 4) are in flight at the same time. The payloads are collected while the
        pipeline delivers them and sent once it ends, so the first result appears only after
        the last payload arrived.

        Each sub-request is retried on its own: one answered 408, 429 or 5xx (except 501 and
        505) is sent again after its own Retry-After (at most 5 minutes; otherwise 2^attempt
        seconds with jitter), up to Settings.Batch.RetryCount times (default 5). A POST
        sub-request is sent again only on 429 and 503, where Graph says it did not carry it
        out. The envelope itself is never sent again as a whole, and nothing else retries.

        For each payload one BatchResponsePayload is returned, in the order of the input:
            Requests  = the sub-requests of the payload
            Responses = one response per sub-request, in the order of the requests (Id, Status,
                        Headers, Body)

        A sub-request that failed for good keeps its response (with its status) in the output
        and is also reported as ONE non-terminating error whose target is the request; the run
        ends with ONE warning summarising failures and re-sends. With -EnableException no error
        records are written and the command throws at the end, after all results were returned.

        Ctrl+C or a pipeline stopped downstream (Select-Object -First) cancels every envelope
        still in flight.

    .PARAMETER InputObject
        An array of BatchRequestPayload objects to be processed. Each object
        has a .Requests list containing up to 20 Request objects.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        Less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER Force
        Sends the batches without asking for confirmation.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .EXAMPLE
        PS C:\> $payloads | Invoke-PSEntraIDBatchRequest -EnableException

        Sends one or more BatchRequestPayload objects (created by New-PSEntraIDBatchRequest)
        to the Microsoft Graph $batch endpoint and returns BatchResponsePayload objects that
        correlate the original requests with the responses returned by Graph.

    #>
    [OutputType([PSMicrosoftEntraID.Batch.BatchResponsePayload])]
    [CmdletBinding(
        SupportsShouldProcess = $true, # enables -WhatIf and -Confirm
        ConfirmImpact = 'High'
    )]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "One or more BatchRequestPayload objects, each with up to 20 sub-requests."
        )]
        [PSMicrosoftEntraID.Batch.BatchRequestPayload[]] $InputObject,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        # -Force skips the prompt; an explicitly bound -Confirm, $true or $false, wins over it.
        if ($Force -and -not $PSBoundParameters.ContainsKey('Confirm')) { $ConfirmPreference = 'None' }
        [string] $platform = Get-PSFLocalizedString -Module $script:ModuleName -Name 'Identity.Platform'
        [string] $actionText = Get-PSFLocalizedString -Module $script:ModuleName -Name 'Batch.Invoke'
        # The confirmed payloads, sent together in end.
        $payloads = [System.Collections.Generic.List[object]]::new()
        # The run's report: failures and re-sends for the one summary.
        [hashtable] $report = @{}
    }

    process {
        foreach ($payload in $InputObject) {
            # One confirmation per payload: No skips it, Yes to All and No to All answer the payloads that follow.
            if (-not $PSCmdlet.ShouldProcess($platform, ($actionText -f ($payload.Requests.Id -join ',')))) { continue }
            $payloads.Add($payload)
        }
    }

    end {
        if ($payloads.Count -eq 0) { return }

        # The engine's requests. A key names the payload (its position in the input) and the request id.
        $requests = [System.Collections.Generic.List[object]]::new()
        $pending = @{}
        for ($index = 0; $index -lt $payloads.Count; $index++) {
            [object[]] $payloadRequests = @($payloads[$index].Requests)
            $pending[$index] = @{ Payload = $payloads[$index]; Responses = @{}; Expected = $payloadRequests.Count }
            foreach ($request in $payloadRequests) {
                $entry = [ordered]@{ Key = ('{0}/{1}' -f ($index + 1), $request.Id); Method = $request.Method; Url = $request.Url }
                # Headers and body only when they carry something: Graph rejects a GET sub-request with a body, and the
                # Request class defaults both to an empty hashtable.
                if ($request.Headers -and $request.Headers.Count -gt 0) { $entry.Headers = $request.Headers }
                if ($request.Body -and $request.Body.Count -gt 0) { $entry.Body = $request.Body }
                $requests.Add([pscustomobject]$entry)
            }
        }

        # Results are written in the order of the input: a payload once all its responses arrived and every payload
        # before it was written.
        $emit = @{ Next = 0 }
        $writeReady = {
            while ($pending.ContainsKey($emit.Next) -and $pending[$emit.Next].Responses.Count -ge $pending[$emit.Next].Expected) {
                $state = $pending[$emit.Next]
                $pending.Remove($emit.Next)
                $emit.Next++
                [PSMicrosoftEntraID.Batch.BatchResponsePayload]@{
                    Requests  = $state.Payload.Requests
                    Responses = [PSMicrosoftEntraID.Batch.Response[]]@(foreach ($request in @($state.Payload.Requests)) { $state.Responses[[string]$request.Id] })
                }
            }
        }
        # Payloads without requests at the head of the input.
        & $writeReady

        [bool] $completed = $false
        try {
            Invoke-EntraParallelBatch -Request $requests.ToArray() -Service $service -Report $report | & {
                process {
                    $page = $_
                    [string[]] $keyParts = ([string]$page.Key).Split('/', 2)
                    [int] $index = [int]$keyParts[0] - 1
                    $state = $pending[$index]
                    $request = @($state.Payload.Requests) | Where-Object { [string]$_.Id -eq $keyParts[1] } | Select-Object -First 1
                    $body = $null
                    if ($page.Body) { $body = $page.Body | ConvertFrom-Json }
                    elseif ($page.Error) {
                        # No answer from Graph (refused, cancelled, timed out, unreadable): the reason in Graph's shape.
                        $body = [pscustomobject]@{ error = [pscustomobject]@{ code = 'PSMicrosoftEntraID.BatchClient'; message = $page.Error } }
                    }
                    $headers = $null
                    if ($page.Headers) { $headers = $page.Headers | ConvertFrom-Json }
                    $state.Responses[$keyParts[1]] = [PSMicrosoftEntraID.Batch.Response]@{
                        Id      = $keyParts[1]
                        Status  = $page.Status
                        Headers = $headers
                        Body    = $body
                    }
                    if (-not $page.Succeeded) {
                        [string] $label = (Get-PSFLocalizedString -Module $script:ModuleName -Name 'Batch.Request.Label') -f ($index + 1), $keyParts[1]
                        Write-EntraItemFailure -Cmdlet $PSCmdlet -Report $report -Target $request -Label $label -Status $page.Status -Reason $page.Error -EnableException $EnableException.IsPresent
                    }
                    & $writeReady
                }
            }
            $completed = $true
        }
        finally {
            # Ended early by an error with -EnableException: the summary of what was sent until then. A stopped
            # pipeline (Ctrl+C, Select-Object -First) writes nothing more; the engine cancelled what was in flight.
            if (-not $completed -and $EnableException) { Write-EntraBatchSummary -Report $report -FunctionName $MyInvocation.MyCommand.Name }
        }
        # Not expected - the engine returns one final page per request - but a payload missing a response is still
        # written, with the responses it has.
        foreach ($index in @($pending.Keys)) { $pending[$index].Expected = $pending[$index].Responses.Count }
        & $writeReady

        Write-EntraBatchSummary -Report $report -FunctionName $MyInvocation.MyCommand.Name
        if ($EnableException -and $report['Items.Reported'] -and $report['Items.Reported'].Count -gt 0) {
            [string] $message = (Get-PSFLocalizedString -Module $script:ModuleName -Name 'Batch.Failed') -f $report['Items.Reported'].Count, $requests.Count
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message $message -Category ConnectionError
        }
    }
}
