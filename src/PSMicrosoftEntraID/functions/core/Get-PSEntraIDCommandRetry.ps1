function Get-PSEntraIDCommandRetry {
    <#
.SYNOPSIS
    Returns the current retry configuration values used in protected commands.

.DESCRIPTION
    Loads the RetryCount and RetryWaitInSeconds from PSFramework configuration
    and returns them as a hashtable.

.EXAMPLE
    Get-PSEntraIDCommandRetry

    Returns:
    @{
        RetryCount = 3
        RetryWaitInSeconds = 5
    }
#>
    $retryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
    $retryWait = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName)

    return @{
        RetryCount         = $retryCount
        RetryWaitInSeconds = $retryWait
    }
}
