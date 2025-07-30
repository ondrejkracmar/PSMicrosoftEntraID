Function Invoke-PSEntraIDBatchRequest {
    <#
    .SYNOPSIS
        Invokes a Microsoft Graph batch request using an array of BatchRequestPayload objects,
        then returns a combined object with both .requests and .responses.

    .DESCRIPTION
        This function expects pipeline input of BatchRequestPayload objects
        (such as those produced by New-PSEntraIDBatchRequest).
        Each BatchRequestPayload contains up to 20 sub-requests (ID=1..20).

        For each batch payload, this function can validate the requests (Test-PSMicrosoftEntraIDBatchRequest),
        then send them to the Graph $batch endpoint (via Invoke-EntraRequest).
        It captures the Graph response (which typically has a "responses" array)
        and outputs a combined [pscustomobject] with:
           .requests   = the sub-requests
           .responses  = the sub-responses from Graph

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
        The Confirm switch instructs the command to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        This functionality is useful when you apply changes to many objects
        and want precise control over the operation of the Shell.

    .EXAMPLE
        # Suppose $payloads are returned from New-PSEntraIDBatchRequest -InputObject $requests
        $payloads = New-PSEntraIDBatchRequest -InputObject $requests

        # Then call:
        $result = $payloads | Invoke-PSMicrosoftEntraIDBatchRequest -EnableException -WhatIf -Force

        # $result now is an array of objects with .requests and .responses,
        # ready to be analyzed by a separate cmdlet that correlates them.

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([PSMicrosoftEntraID.Batch.BatchResponsePayload])]
    [CmdletBinding(
        SupportsShouldProcess = $true, # enables -WhatIf and -Confirm
        ConfirmImpact = 'High'
    )]
    Param(
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

    Begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = '$batch'
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
    }

    Process {
        foreach ($payload in $InputObject) {

            [hashtable] $body = @{
                'requests' = @($payload.Requests | Select-Object -Property @{ Name = 'id'; Expression = { $PSItem.Id } } `
                        , @{ Name = 'method'; Expression = { $PSItem.Method } } `
                        , @{ Name = 'url'; Expression = { $PSItem.Url } } `
                        , @{ Name = 'headers'; Expression = { $PSItem.Headers } } `
                        , @{ Name = 'body'; Expression = { $PSItem.Body } }
                )
            }

            Invoke-PSFProtectedCommand -ActionString 'Batch.Invoke' -ActionStringValues ($payload.Requests.Id -join ",") `
                -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) `
                -ScriptBlock {
                $batchResponseList = [System.Collections.Generic.List[psobject]]::New()
                [psobject] $batchResponse = Invoke-EntraRequest -Service $service -Header $header -Path $path -Body $body -Method Post -ErrorAction Stop
                $batchResponse.Responses | ForEach-Object { [void] $batchResponseList.Add($PSItem) }
                [PSMicrosoftEntraID.Batch.BatchResponsePayload]@{
                    Requests  = $payload.Requests
                    Responses = [PSMicrosoftEntraID.Batch.Response[]] ($batchResponseList | Select-Object -Property @{ Name = 'Id'; Expression = { $PSItem.Id } } `
                            , @{ Name = 'Status'; Expression = { $PSItem.status } } `
                            , @{ Name = 'Headers'; Expression = { $PSItem.headers } } `
                            , @{ Name = 'Body'; Expression = { $PSItem.body } })
                }
            } -EnableException:$EnableException -Confirm:$cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    End {

    }
}
