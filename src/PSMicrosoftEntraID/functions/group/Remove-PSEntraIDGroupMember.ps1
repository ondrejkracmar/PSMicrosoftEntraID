﻿function  Remove-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Remove a member/owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Remove a member/owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .EXAMPLE
            PS C:\> Remove-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Remove memebr to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Identity')]
    param([Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        $User,
        [switch]
        $EnableException
    )


    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
    }

    process {
        $aADGroup = Get-PSEntraIDGroup -Identity $Identity
        if (-not ([object]::Equals($aADGroup, $null))) {

            switch -Regex ($PSCmdlet.ParameterSetName) {
                'Identity' {
                    foreach ($itemUser in  $User) {
                        $aADUser = Get-PSEntraIDUser -Identity $itemUser
                        if (-not ([object]::Equals($aADUser, $null))) {
                            $path = ('groups/{0}/members/{1}/$ref' -f $aADGroup.Id, $aADUser.Id)
                            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Delete' -ActionStringValues $aADUser.UserPrincipalName -Target $aADGroup.MailNickName -ScriptBlock {
                                [void](Invoke-RestRequest -Service 'graph' -Path $path -Method Delete)
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