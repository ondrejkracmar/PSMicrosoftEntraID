Function Test-PSMicrosoftEntraIDBatchRequest {
    <#
    .SYNOPSIS
        Processes an array of batch request objects for Microsoft Entra ID.

    .PARAMETER Requests
        An array of batch request objects (either PSCustomObject or Hashtable).
        This parameter is mandatory and accepts input from the pipeline.

    .PARAMETER EnableException
        A switch to enable exceptions. If specified, exceptions will be thrown on errors.

    .EXAMPLE
        $batchRequests = @(
            [PSCustomObject]@{ RequestType = "Create"; Data = "SampleData1" },
            [PSCustomObject]@{ RequestType = "Update"; Data = "SampleData2" }
        )
        Test-PSMicrosoftEntraIDBatchRequest -Requests $batchRequests

    .EXAMPLE
        $batchRequests = @(
            @{ RequestType = "Create"; Data = "SampleData1" },
            @{ RequestType = "Update"; Data = "SampleData2" }
        )
        $batchRequests | Test-PSMicrosoftEntraIDBatchRequest -EnableException
    #>
        Param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                HelpMessage = "Provide an array of batch request objects (either PSCustomObject or Hashtable)."
            )]
            [PSMicrosoftEntraID.Batch.Request[]]$Requests,
            [switch]$EnableException
        )

        Begin {
            # Nothing special in the Begin block.
        }

        Process {
            # 1) Ensure the number of requests does not exceed 20.
            if ($Requests.Count -gt 20) {
                if ($EnableException) {
                    throw "There are more than 20 requests. The maximum allowed is 20."
                }
                else {
                    throw "ERROR: More than 20 requests (limit is 20)."
                }
            }

            # 2) Validate IDs are sequential from 1..N.
            for ($i = 0; $i -lt $Requests.Count; $i++) {
                $expectedId = ($i + 1).ToString()

                # Works for both PSCustomObject and Hashtable.
                $currentId = $Requests[$i].id

                if (-not $currentId) {
                    if ($EnableException) {
                        throw "Request at index [$i] is missing 'id'."
                    }
                    else {
                        throw "ERROR: Missing 'id' in request at index [$i]."
                    }
                }

                if ($currentId -ne $expectedId) {
                    if ($EnableException) {
                        throw "Expected 'id' to be '$expectedId' but found '$currentId' at index [$i]."
                    }
                    else {
                        throw "ERROR: 'id' mismatch at index [$i]. Expected '$expectedId', found '$currentId'."
                    }
                }
            }

            # 3) Check each request has 'method' and 'url'.
            foreach ($request in $Requests) {
                if (-not $request.method) {
                    if ($EnableException) {
                        throw "Request with 'id'='$($request.id)' is missing the 'method' property."
                    }
                    else {
                        throw "ERROR: Missing 'method' for request ID '$($request.id)'."
                    }
                }
                if (-not $request.url) {
                    if ($EnableException) {
                        throw "Request with 'id'='$($request.id)' is missing the 'url' property."
                    }
                    else {
                        throw "ERROR: Missing 'url' for request ID '$($request.id)'."
                    }
                }
            }
        }

        End {
            # If all checks passed, we return $true.
            return $true
        }
    }
