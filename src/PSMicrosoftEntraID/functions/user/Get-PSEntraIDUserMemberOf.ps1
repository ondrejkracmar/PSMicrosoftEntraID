function Get-PSEntraIDUserMemberOf {
    <#
    .SYNOPSIS
        List a user's direct memberships.

    .DESCRIPTION
        Get groups, directory roles, and administrative units that the user is a direct member of.
        This operation isn't transitive. To retrieve groups, directory roles, and administrative units that the user is a member through transitive membership.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Filter
        Filter expressions of direct member of accounts in tenant/directory.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserMemberOf -Identity user1@contoso.com

		Get groups, directory roles, and administrative units that the user is a direct member of user1@contoso.com

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
    [OutputType('PSMicrosoftEntraID.Groups.Group')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Filter',
        Justification = 'False positive as rule does not know that filter operates within the same scope')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Users.User[]]$InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $Identity,
        [Parameter(ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count' = 'true'
            '$top'   = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
        }
        [hashtable] $header = @{}
    }

    process {
        if (Test-PSFParameterBinding -ParameterName 'Filter') {
            # A memberOf $filter is an advanced query: without this header - which used to
            # be built here and then never passed on - Graph rejects it.
            $header['ConsistencyLevel'] = 'eventual'
            $query['$Filter'] = $Filter
        }
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $itemInputObject.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf' -f $itemInputObject.Id) -Query $query -Header $header -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity' {
                foreach ($user in $Identity) {
                    # Resolved before the request: an identity that did not resolve used to
                    # be sent as users//memberOf.
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                        Write-PSFMessage -Level Warning -String 'User.Get.Failed' -StringValues $user
                        continue
                    }
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf' -f $aADUser.Id) -Query $query -Header $header -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end {}
}
