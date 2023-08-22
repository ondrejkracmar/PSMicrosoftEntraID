function  Remove-PSMTGroupMember {
    <#
    .SYNOPSIS
        Remove a member/owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Remove a member/owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .EXAMPLE
            PS C:\> Remove-PSADGroupMember -Identity group1 -User user1,user2

            Remove memebr to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'UserIdentity')]
    param([Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdentity')]
        [ValidateGroupIdentity()]
        [string]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        $User
    )


    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }


    process {
        $aADGroup = Get-PSADGroup -Identity $Identity
        if (-not ([object]::Equals($aADGroup, $null))) {

            switch -Regex ($PSCmdlet.ParameterSetName) {
                '\wUser\w' {
                    foreach ($itemUser in  $User) {
                        if (-not ([object]::Equals($itemUser, $null))) {
                            $aADUser = Get-PSADUser -Identity $itemUser
                            $path = ("groups/{0}/members/{1}/$ref" -f $aADGroup.Id, $aADUser.Id)
                            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Delete' -ActionStringValues $aADUser.UserPrincipalName, $aADGroup.MailNickName -Target $aADGroup.MailNickName -ScriptBlock {
                                [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Delete)
                            } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
        }


    }


    end {

    }
}