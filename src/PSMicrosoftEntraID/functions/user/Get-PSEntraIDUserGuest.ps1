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

    .PARAMETER Issuer
        Matches guests whose identities collection carries this issuer - the home
        organization's domain for a B2B guest ("contoso.com"), or the provider for a
        social one ("google.com", "facebook.com"), or "mail" for an email one-time
        passcode guest.

        Graph matches an issuer on its own only for google.com, facebook.com, mail and
        phone. For any other issuer supply -IssuerAssignedId as well; without it the
        request comes back empty rather than failing, and the cmdlet warns to say so.

    .PARAMETER IssuerAssignedId
        The identifier the issuer assigned to the guest, normally their sign-in name at
        the home organization. Combined with -Issuer.

    .PARAMETER SignInType
        Narrows the identity match to one sign-in type, such as federated, userName or
        emailAddress. userPrincipalName is rejected: Graph documents it as unsupported
        for filtering, and returns an empty set instead of an error. Use -Identity to
        look an account up by its UPN.

    .PARAMETER EnableException
        Enables exception throwing instead of friendly warnings.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -Identity user1@contoso.com

        Returns details for user1@contoso.com, only if it is a Guest account.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -All

        Returns all Guest accounts in the tenant.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -Issuer 'contoso.com' -IssuerAssignedId 'j.smith@contoso.com'

        Returns the guest that signs in as j.smith@contoso.com at the Contoso tenant,
        whatever their user principal name in this tenant happens to be.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -Issuer 'google.com'

        Returns every guest signing in with a Google identity. One of the four issuers
        Graph will match without an issuerAssignedId.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserGuest -All | Group-Object HomeIssuer -NoElement | Sort-Object Count -Descending

        Which external organizations the tenant's guests actually come from. HomeIssuer
        is read off the identities collection, so it is the issuer the guest signs in
        with rather than a guess from the #EXT# user principal name.

        .NOTES
        Piping into Select-Object -First N logs a warning that is not a failure:

            WARNING: [<cmdlet>] Failed to: ... | The pipeline has been stopped

        The results are correct and complete. Select-Object stops the pipeline once it
        has what it asked for, and the next write throws PipelineStoppedException -
        normal termination, reported as an error only because the write happens inside a
        protected block. Materialise first if the warning is in the way:

            $items = @(<cmdlet> ...)
            $items | Select-Object -First 3

        or filter server-side with -Filter instead of trimming client-side. Not silenced
        on purpose: the only fix that works is to collect the whole result before
        emitting any of it, which would cost streaming on every read.

#>
    [OutputType('PSMicrosoftEntraID.Users.UserGuest')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
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

        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Identities')]
        [ValidateNotNullOrEmpty()]
        [string] $Issuer,

        [Parameter(Mandatory = $false, ParameterSetName = 'Identities')]
        [ValidateNotNullOrEmpty()]
        [string] $IssuerAssignedId,

        [Parameter(Mandatory = $false, ParameterSetName = 'Identities')]
        [ValidateNotNullOrEmpty()]
        [string] $SignInType,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet

        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserGuest).Value -join ',')
        }

        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    [hashtable] $mailQuery = @{
                        #'$count'  = 'true'
                        '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f (ConvertTo-ODataFilterString -Value $user))
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        [PSMicrosoftEntraID.Users.UserGuest[]] $userMail = ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $mailQuery -Method Get -ErrorAction Stop
                        )

                        if (-not $userMail) {
                            $userId = $user
                        }
                        else {
                            $userId = $userMail[0].Id
                        }

                        # Escaped because a guest's UPN always contains '#EXT#', and an
                        # unescaped '#' starts the URI fragment - the path is silently
                        # truncated and Graph answers for a user that does not exist.
                        # See the same fix in Get-PSEntraIDUser.
                        $fullUser = ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path ("users/{0}" -f [uri]::EscapeDataString($userId)) -Query $query -Method Get -ErrorAction Stop
                        )

                        if ($fullUser.UserType -eq 'Guest') {
                            $fullUser
                        }
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Filter' {
                $completeFilter = Add-GuestFilter $Filter
                $query['$Filter'] = $completeFilter

                if ($AdvancedFilter.IsPresent) {
                    $header = @{ 'ConsistencyLevel' = 'eventual' }
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $completeFilter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $query -Method Get -Header $header -ErrorAction Stop
                        )
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $completeFilter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (
                            Invoke-EntraRequest -Service $service -Path 'users' -Query $query -Method Get -ErrorAction Stop
                        )
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'CompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                if ($Disabled.IsPresent) {
                    $completeFilter = Add-GuestFilter ('companyName in ({0}) and accountEnabled eq false' -f $companyNameList)
                    $query['$Filter'] = $completeFilter
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues ('companyName in ({0}) and accountEnabled eq false' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
                else {
                    $completeFilter = Add-GuestFilter ('companyName in ({0})' -f $companyNameList)
                    $query['$Filter'] = $completeFilter
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues ('companyName in ({0})' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUserGuest -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identities' {
                $identityFilter = New-EntraIdentityFilter -Cmdlet $PSCmdlet -Issuer $Issuer -IssuerAssignedId $IssuerAssignedId -SignInType $SignInType
                $completeFilter = Add-GuestFilter $identityFilter
                $query['$Filter'] = $completeFilter

                # A lambda over a collection is an advanced query in Graph's terms, so the
                # eventual consistency header is not optional here the way -AdvancedFilter
                # is on the Filter set. Without it Graph rejects the request outright.
                [hashtable] $header = @{ 'ConsistencyLevel' = 'eventual' }

                Invoke-PSFProtectedCommand -ActionString 'User.Identity.Filter' -ActionStringValues $identityFilter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestUserGuest -InputObject (
                        Invoke-EntraRequest -Service $service -Path 'users' -Query $query -Method Get -Header $header -ErrorAction Stop
                    )
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                if (Test-PSFFunctionInterrupt) { return }
            }
            'All' {
                if ($All.IsPresent) {
                    if ($Disabled.IsPresent) {
                        [hashtable] $header = @{}
                        $header['ConsistencyLevel'] = 'eventual'
                        $completeFilter = Add-GuestFilter "accountEnabled eq false"
                        $query['$Filter'] = $completeFilter
                        Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues 'accountEnabled eq false' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUserGuest -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -ErrorAction Stop)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                    else {
                        $query['$Filter'] = "userType eq 'Guest'"
                        Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUserGuest -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -ErrorAction Stop)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
        }
    }
    end {}
}
