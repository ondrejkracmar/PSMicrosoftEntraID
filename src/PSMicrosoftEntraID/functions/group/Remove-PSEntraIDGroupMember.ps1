function  Remove-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Remove a member/owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Remove a member/owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the disable license action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
            PS C:\> Remove-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Remove member user1, user2 from Microsoft EntraID group with name group1
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentityInputObject')]
    param([Parameter(Mandatory = $True, ParameterSetName = 'IdentityUser')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityInputObject')]
        [ValidateGroupIdentity()]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [string] $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUser')]
        [ValidateUserIdentity()]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [string[]] $User,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch]$PassThru
    )


    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
        [PSMicrosoftEntraID.Groups.Group] $group = Get-PSEntraIDGroup -Identity $Identity
        if ([object]::Equals($group, $null)) {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityUser' {
                foreach ($itemUser in  $User) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $itemUser
                    if (-not([object]::Equals($aADUser, $null))) {
                        [string] $path = ('groups/{0}/members/{1}/$ref' -f $group.Id, $aADUser.Id)
                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'DELETE'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Delete' -ActionStringValues $aADUser.UserPrincipalName -Target $group.DisplayName -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Method Delete -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                        }
                    }
                }
            }
            'IdentityInputObject' {
                foreach ($itemInputObject in  $InputObject) {
                    [string] $path = ('groups/{0}/members/{1}/$ref' -f $group.Id, $itemInputObject.Id)
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'DELETE'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'GroupMember.Delete' -ActionStringValues $itemInputObject.UserPrincipalName -Target $group.DisplayName -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Method Delete -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
        }
    }

    end {

    }
}