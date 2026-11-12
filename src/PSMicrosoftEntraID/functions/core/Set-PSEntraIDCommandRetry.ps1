function Set-PSEntraIDCommandRetry {
    <#
.SYNOPSIS
    Sets how often the module sends a failed Graph request again.

.DESCRIPTION
    The module has one retry layer: Invoke-EntraRequest repeats a failed request
    (Settings.Request.RetryCount) and the batch engine repeats a failed sub-request of a
    $batch (Settings.Batch.RetryCount). Repeated are throttling (429), 408 and server errors
    (5xx except 501 and 505) and requests without an answer; a POST only on 429 and 503,
    where the service says it did not carry it out. The wait is the Retry-After the service
    asks for (at most 5 minutes), otherwise 2^attempt seconds with jitter.

    Only the values that are passed are changed; a call without parameters changes nothing.
    The settings hold for the session; persist them with Register-PSFConfig.

.PARAMETER RetryCount
    How often a failed request is sent again, 0 to 20 (Settings.Request.RetryCount, default 5).
    0 sends every request once.

.PARAMETER BatchRetryCount
    How often a failed sub-request of a $batch is sent again, 0 to 20
    (Settings.Batch.RetryCount, default 5).

.PARAMETER RetryWaitInSeconds
    No longer used: the wait comes from the Retry-After of the answer or the exponential
    backoff. Accepted so existing scripts keep running; passing it writes a warning.

.EXAMPLE
    Set-PSEntraIDCommandRetry -RetryCount 3

    Sends a failed request at most three more times.

.EXAMPLE
    Set-PSEntraIDCommandRetry -RetryCount 0 -BatchRetryCount 0

    Turns retrying off: every request and every sub-request is sent once.

.NOTES
    Updates the settings PSMicrosoftEntraID.Settings.Request.RetryCount and
    PSMicrosoftEntraID.Settings.Batch.RetryCount for the session.
#>
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Configuration setter only updates in-memory PSFConfig values; no remote state is changed.')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateRange(0, 20)]
        [int] $RetryCount,

        [Parameter()]
        [ValidateRange(0, 20)]
        [int] $BatchRetryCount,

        [Parameter()]
        [ValidateRange(0, 10)]
        [int] $RetryWaitInSeconds
    )

    if ($PSBoundParameters.ContainsKey('RetryCount')) {
        Set-PSFConfig -FullName ('{0}.Settings.Request.RetryCount' -f $script:ModuleName) -Value $RetryCount -EnableException
    }
    if ($PSBoundParameters.ContainsKey('BatchRetryCount')) {
        Set-PSFConfig -FullName ('{0}.Settings.Batch.RetryCount' -f $script:ModuleName) -Value $BatchRetryCount -EnableException
    }
    if ($PSBoundParameters.ContainsKey('RetryWaitInSeconds')) {
        Write-PSFMessage -Level Warning -String 'CommandRetry.WaitIgnored' -StringValues $RetryWaitInSeconds
    }
}
