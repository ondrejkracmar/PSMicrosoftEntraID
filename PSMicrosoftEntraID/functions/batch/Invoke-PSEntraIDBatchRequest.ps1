function Invoke-PSEntraIDBatchRequest {
    <#
    .SYNOPSIS
        Invokes a Microsoft Graph batch request using an array of BatchRequestPayload objects,
        then returns a combined object with both the requests and responses.

    .DESCRIPTION
        This function expects pipeline input of BatchRequestPayload objects
        (such as those produced by New-PSEntraIDBatchRequest).
        Each BatchRequestPayload contains up to 20 sub-requests (ID=1..20).

        For each batch payload, this function can validate the requests (Test-PSMicrosoftEntraIDBatchRequest),
        then send them to the Graph batch endpoint (via Invoke-EntraRequest).
        It captures the Graph response (which typically has a 'responses' array)
        and outputs a combined PSCustomObject with:
            requests   = the sub-requests
            responses  = the sub-responses from Graph

        This allows a subsequent cmdlet (e.g. Invoke-PSMicrosoftEntraIDBatchResponse) to correlate them by id.

    .PARAMETER InputObject
        An array of BatchRequestPayload objects to be processed. Each object
        has a .Requests list containing up to 20 Request objects.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        Less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER Force
        The Force switch instructs the command to stop processing before any changes are made
        and prompt for confirmation (depending on your logic in the code).
        When used, you can step through changes to ensure only specific objects are modified.

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
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = '$batch'
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    }

    process {
        foreach ($payload in $InputObject) {

            # Building the body and re-sending throttled sub-requests lives in
            # Invoke-BatchWithThrottleRetry: Graph reports a throttled SUB-request inside
            # the batch body with the envelope still HTTP 200, so Invoke-EntraRequest's
            # retry never sees it and the sub-request used to be dropped in silence.
            Invoke-PSFProtectedCommand -ActionString 'Batch.Invoke' -ActionStringValues ($payload.Requests.Id -join ",") `
                -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) `
                -ScriptBlock {
                [PSMicrosoftEntraID.Batch.BatchResponsePayload]@{
                    Requests  = $payload.Requests
                    Responses = Invoke-BatchWithThrottleRetry -Payload $payload -Service $service -Header $header -Path $path -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    end {

    }
}
