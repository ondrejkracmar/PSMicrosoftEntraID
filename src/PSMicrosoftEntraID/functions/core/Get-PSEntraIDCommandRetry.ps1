function Get-PSEntraIDCommandRetry {
    <#
.SYNOPSIS
    Returns how often the module sends a failed Graph request again.

.DESCRIPTION
    Returns the retry settings of the module's one retry layer as a hashtable:
    RetryCount (Settings.Request.RetryCount, repetitions of a single request) and
    BatchRetryCount (Settings.Batch.RetryCount, repetitions of a $batch sub-request).

.EXAMPLE
    Get-PSEntraIDCommandRetry

    Returns:
    @{
        RetryCount      = 5
        BatchRetryCount = 5
    }
#>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param ()

    return @{
        RetryCount      = [int](Get-PSFConfigValue -FullName ('{0}.Settings.Request.RetryCount' -f $script:ModuleName) -Fallback 5)
        BatchRetryCount = [int](Get-PSFConfigValue -FullName ('{0}.Settings.Batch.RetryCount' -f $script:ModuleName) -Fallback 5)
    }
}
