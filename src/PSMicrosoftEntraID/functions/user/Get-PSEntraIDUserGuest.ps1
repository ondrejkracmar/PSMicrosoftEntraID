function Get-PSEntraIDUserGuest {
    <#
    .SYNOPSIS
        Retrieves properties of users in Entra ID (Azure AD), but only Guest accounts.

    .DESCRIPTION
        Cmdlet for retrieving users with "userType eq 'Guest'".
        Supports multiple parameter sets (Identity, Name, CompanyName, Filter, All)
        and always returns only Guest accounts.

    .PARAMETER Identity
        UserPrincipalName, Mail, or Id of the user in the tenant.
        If the user exists but is not a Guest, no output is returned.

    .PARAMETER Name
        DisplayName, GivenName, or SurName of the user in the tenant.

    .PARAMETER CompanyName
        CompanyName of the user in the tenant.

    .PARAMETER Disabled
        Returns only disabled accounts (accountEnabled eq false).

    .PARAMETER Filter
        Custom OData filter expression for filtering users, combined with "userType eq 'Guest'".

    .PARAMETER AdvancedFilter
        Enables the use of the ConsistencyLevel = 'eventual' header (e.g., for $count).

    .PARAMETER All
        Returns all users in the tenant, but only those with "userType eq 'Guest'".

    .PARAMETER EnableException
        Enables exception throwing instead of friendly warnings.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -Identity user1@contoso.com
        Returns details for user1@contoso.com, only if it is a Guest account.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -All
        Returns all Guest accounts in the tenant.

    .NOTES
        Author: Your Name
        Last Updated: 2025-03-06
    #>
    [OutputType('PSMicrosoftEntraID.Users.UserGuest')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,

        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Name,

        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $CompanyName,

        [Parameter(Mandatory = $false, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [switch] $Disabled,

        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [switch] $AdvancedFilter,

        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet

        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }

        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else {
            [boolean] $cmdLetVerbose = $false
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        '$top'    = $query['$top']
                        '$select' = $query['$select']
                        '$filter' = "mail eq '$user'"
                    }

                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        [PSMicrosoftEntraID.Users.UserGuest[]] $userMail = ConvertFrom-RestUser -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $mailQuery -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop
                        )

                        if (-not $userMail) {
                            $userId = $user
                        }
                        else {
                            $userId = $userMail[0].Id
                        }

                        $fullUser = ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path ("users/{0}" -f $userId) -Query $query -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop
                        )

                        # Ensure the returned user is a Guest before outputting
                        if ($fullUser.UserType -eq 'Guest') {
                            $fullUser
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'Filter' {
                $completeFilter = Add-GuestFilter $Filter
                $query['$Filter'] = $completeFilter

                if ($AdvancedFilter.IsPresent) {
                    $header = @{ 'ConsistencyLevel' = 'eventual' }
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $completeFilter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $query -Method Get -Header $header -Verbose:$cmdLetVerbose -ErrorAction Stop
                        )
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $completeFilter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $query -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop
                        )
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
        }
    }
    end {}
}
