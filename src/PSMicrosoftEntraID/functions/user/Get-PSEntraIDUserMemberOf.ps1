﻿function Get-PSEntraIDUserMemberOf {
    <#
    .SYNOPSIS
        List a user's direct memberships.

    .DESCRIPTION
        Get groups, directory roles, and administrative units that the user is a direct member of.
        This operation isn't transitive. To retrieve groups, directory roles, and administrative units that the user is a member through transitive membership.

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
    [OutputType('PSMicrosoftEntraID.User')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$Identity,
        [Parameter(ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [switch]$EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            #'$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        #'$count'  = 'true'
                        '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $userMail = Invoke-RestRequest -Service 'graph' -Path ('users') -Query $mailQuery -Method Get -ErrorAction Stop | ConvertFrom-RestUser
                        if (-not([object]::Equals($userMail, $null))) {
                            $userId = $userMail[0].Id

                        }
                        else {
                            $userId = $user
                        }
                        if(Test-PSFParameterBinding -ParameterName Filter)
                        {
                            $header = @{}
                            $header['ConsistencyLevel'] = 'eventual'
                            $query['$Filter'] = $Filter
                            Invoke-RestRequest -Service 'graph' -Path ('users/{0}/memberOf/{1}' -f $userId) -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestUser
                        }
                        else{
                            Invoke-RestRequest -Service 'graph' -Path ('users/{0}/memberOf' -f $userId) -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestUser
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
        }
    }
    end {}
}