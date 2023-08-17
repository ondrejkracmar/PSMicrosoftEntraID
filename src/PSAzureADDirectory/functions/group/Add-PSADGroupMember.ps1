function Add-PSADGroupMember {
    <#
    .SYNOPSIS
        Add a member/owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a member/owner to a security or Microsoft 365 group.

    .PARAMETER Group
        MailNickName, Mail or Id of group

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Role
        user's role

#>
    [CmdletBinding(DefaultParameterSetName = 'AddMember')]
    param(
        [Parameter(ParameterSetName = 'AddMember', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AddMember')]
        [ValidateIdentity()]
        [string]
        [Alias("Id", "MailNickName", "Mail")]
        $Group,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AddMember')]
        [ValidateIdentity()]
        [string[]]
        [Alias("Id", "UserPrincipalName", "Mail")]
        $Identity,
        [Parameter(ParameterSetName = 'AddMember', ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $False, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AddMember')]
        [ValidateSet('Member', 'Owner')]
        [string]
        $Role
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        Get-PSAADSubscribedSku | Set-PSFResultCache
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
        $memberList = [System.Collections.ArrayList]::New()
    }

    process {
        $path = ("groups/{0}" -f $group.Id)
        if ($Identity.Count -gt 1) {
            $identityUrlList = [System.Collections.ArrayList]::New()
        }
        foreach ($user in $Identity) {
            $aADUser = Get-PSAADUser -Identity $user
               
            if (Test-PSFParameterBinding -Parameter Role) {
                switch ($Role) {
                    'Owner' { 
                        $memberHash = @{
                            UserPrincipalName = $aADUser.UserPrincipalName
                            Role = $Role
                            UrlPath = Join-UriPath -Uri $path -ChildPath 'owners/$ref'
                            Body    = @{
                                "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('users' -f { $aADUser.Id })
                            }
                            Method  = 'Post'
                        }
                        $member = [pscustomobject]$memberHash
                        [void]$memberList.Add($member)
                    }
                    'Member' {
                        if ($Identity.Count -gt 1) {                            
                            [void]$identityUrlList.Add((Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )))
                                $memberHash = @{
                                    UserPrincipalName = $aADUser.UserPrincipalName
                                    Role = $Role
                                    UrlPath = $path
                                    Body    = @{
                                        "members@odata.id" = $identityUrlList
                                    }
                                    Method  = 'Patch'
                                }
                                $member = [pscustomobject]$memberHash
                                [void]$memberList.Add($member)
                                
                            }
                            else {
                                $memberHash = @{
                                    UserPrincipalName = $aADUser.UserPrincipalName
                                    Role = $Role
                                    UrlPath = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('members/$ref')
                                    Body    = @{
                                        "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )
                                    }
                                    Method  = 'Post'
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
                        Role = $Role
                        UrlPath = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('members/$ref')
                        Body    = @{
                            "@odata.id" = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath ('directoryObjects/{0}' -f $aADUser.Id )
                        }
                        Method  = 'Post'
                    }
                    $member = [pscustomobject]$memberHash
                    [void]$memberList.Add($member)
                }
            }
            foreach ($memberItem in $memberList) {
                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues (($memberItem.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ',') -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $memberItem.UrlPath -Method $memberItem.Method)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }

        end {

        }
    }