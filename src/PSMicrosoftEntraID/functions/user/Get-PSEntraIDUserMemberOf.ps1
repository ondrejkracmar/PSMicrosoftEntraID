using namespace PSMicrosoftEntraID.Groups
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
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUserMemberOf -Identity user1@contoso.com

		Get groups, directory roles, and administrative units that the user is a direct member of user1@contoso.com

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
        [string[]]$Identity,
        [Parameter(ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [switch]$EnableException
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            #'$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InoutObject' {
                foreach ($itemInputObject in $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $itemInputObject.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        if(Test-PSFParameterBinding -ParameterName 'Filter')
                        {
                                $header = @{}
                                $header['ConsistencyLevel'] = 'eventual'
                                $query['$Filter'] = $Filter
                                ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf/{1}' -f $itemInputObject.Id) -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                        else{
                                ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf' -f $itemInputObject.Id) -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity' {
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        #'$count'  = 'true'
                        '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $userMail = ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $mailQuery -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        if (-not([object]::Equals($userMail, $null))) {
                            $userId = $userMail[0].Id

                        }
                        else {
                            $userId = $user
                        }
                        if(Test-PSFParameterBinding -ParameterName 'Filter')
                        {
                            $header = @{}
                            $header['ConsistencyLevel'] = 'eventual'
                            $query['$Filter'] = $Filter
                            ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf/{1}' -f $userId) -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                        else{
                            ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}/memberOf' -f $userId) -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end {}
}