function Add-PSADGroupMember {
    <#
    .SYNOPSIS
        Add a member/owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a member/owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Role
        user's role (Member or Owner)

    .EXAMPLE
            PS C:\> Add-PSADGroupMember -Identity group1 -User user1,user2

            Add memebr to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'UserIdentity')]
    param(
        [Parameter(ParameterSetName = 'UserIdentity', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdentity')]
        [ValidateGroupIdentity()]
        [string]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("UserId","UserPrincipalName", "Mail")]
        $User,        
        [Parameter(Mandatory = $False, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdentity')]
        [ValidateSet('Member', 'Owner')]
        [string]
        $Role
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
        $memberList = [System.Collections.ArrayList]::New()
    }

    process {
        $group = Get-PSAADGroup -Identity $Identity
        if (-not([object]::Equals($group, $null))) {
            $path = ("groups/{0}" -f $group.Id)
            if ($Identity.Count -gt 1) {
                $identityUrlList = [System.Collections.ArrayList]::New()
            }
            foreach ($user in $Identity) {
                $aADUser = Get-PSAADUser -Identity $user
                if (-not([object]::Equals($aADUser, $null))) {
                    if (Test-PSFParameterBinding -ParameterName Role) {
                        switch ($Role) {
                            'Owner' {
                                $memberHash = @{
                                    UserPrincipalName = $aADUser.UserPrincipalName
                                    Role              = $Role
                                    UrlPath           = Join-UriPath -Uri $path -ChildPath 'owners/$ref'
                                    Body              = @{
                                        "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('users' -f { $aADUser.Id })
                                    }
                                    Method            = 'Post'
                                }
                                $member = [pscustomobject]$memberHash
                                [void]$memberList.Add($member)
                            }
                            'Member' {
                                if ($Identity.Count -gt 1) {
                                    [void]$identityUrlList.Add((Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )))
                                    $memberHash = @{
                                        UserPrincipalName = $aADUser.UserPrincipalName
                                        Role              = $Role
                                        UrlPath           = $path
                                        Body              = @{
                                            "members@odata.id" = $identityUrlList
                                        }
                                        Method            = 'Patch'
                                    }
                                    $member = [pscustomobject]$memberHash
                                    [void]$memberList.Add($member)

                                }
                                else {
                                    $memberHash = @{
                                        UserPrincipalName = $aADUser.UserPrincipalName
                                        Role              = $Role
                                        UrlPath           = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('members/$ref')
                                        Body              = @{
                                            "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )
                                        }
                                        Method            = 'Post'
                                    }
                                    $member = [pscustomobject]$memberHash
                                    [void]$memberList.Add($member)
                                }
                            }
                            Default {

                            }
                        }
                    }
                    else {
                        $memberHash = @{
                            UserPrincipalName = $aADUser.UserPrincipalName
                            Role              = $Role
                            UrlPath           = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('members/$ref')
                            Body              = @{
                                "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )
                            }
                            Method            = 'Post'
                        }
                        $member = [pscustomobject]$memberHash
                        [void]$memberList.Add($member)
                    }
                }
            }
            foreach ($memberItem in $memberList) {
                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues ((($memberItem.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','),$group.MailNickName) -Target $group.MailNickName -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $memberItem.UrlPath -Method $memberItem.Method)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
    }
    end {

    }
}