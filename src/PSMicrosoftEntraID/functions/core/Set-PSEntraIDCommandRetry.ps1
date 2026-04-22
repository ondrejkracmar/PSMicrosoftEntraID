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

    Configures the module to retry failing commands up to 3 times with 5 seconds between attempts.

.NOTES
    Updates configuration settings under $script:ModuleName.
#>
    [OutputType([void])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Configuration setter only updates in-memory PSFConfig values; no remote state is changed.')]
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