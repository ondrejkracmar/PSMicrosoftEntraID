function Set-PSEntraIDCommandRetry {
    <#
.SYNOPSIS
    Sets default retry parameters for PSF protected commands.

.DESCRIPTION
    Configures RetryCount and RetryWaitInSeconds used with Invoke-PSFProtectedCommand.
    Ensures values are between 0 and 10.

.PARAMETER RetryCount
    Number of retry attempts. Must be between 0 and 10.

.PARAMETER RetryWaitInSeconds
    Wait time in seconds between retries. Must be between 0 and 10.

.EXAMPLE
    Set-PSEntraIDCommandRetry -RetryCount 3 -RetryWaitInSeconds 5

.NOTES
    Updates configuration settings under $script:ModuleName.
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateRange(0, 10)]
        [int] $RetryCount = 0,

        [Parameter()]
        [ValidateRange(0, 10)]
        [int] $RetryWaitInSeconds = 0
    )

    Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Command.RetryCount' -Value $RetryCount -Description "Retry count for protected command execution."
    Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Command.RetryWaitInSeconds' -Value $RetryWaitInSeconds -Description "Wait time (in seconds) between retry attempts for protected commands."
}