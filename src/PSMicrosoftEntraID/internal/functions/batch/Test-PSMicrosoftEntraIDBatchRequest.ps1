Function Test-PSMicrosoftEntraIDBatchRequest {
    <#
        .SYNOPSIS
            Validates the structure and sequencing of Microsoft Entra ID (Azure AD) batch requests.

        .DESCRIPTION
            This cmdlet validates a collection of batch requests for Microsoft Entra ID (Azure AD).
            It checks that:
              1. The array contains no more than 20 requests.
              2. Each request has an 'id', 'method', and 'url'.
              3. The 'id' values are sequential strings from "1" to the total count.

        .PARAMETER Requests
            An array of requests (either [PSCustomObject[]] or [hashtable[]]) typically originating
            from a JSON structure (for example, by using ConvertFrom-Json on a file that contains
            a property named 'requests').

    #>
        [CmdletBinding()]
        Param (
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                HelpMessage = "Provide an array of batch request objects (either PSCustomObject or Hashtable)."
            )]
            [object[]]$Requests,

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
