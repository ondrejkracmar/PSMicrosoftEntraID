﻿function  Remove-PSEntraIDGroupOwner {
    <#
    .SYNOPSIS
        Remove a owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Remove a owner to a security or Microsoft 365 group.

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

    .EXAMPLE
            PS C:\> Remove-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Remove owner user1,user2 form Microsoft EntraID group with name group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentityInputObject')]
    param([Parameter(Mandatory = $True, ParameterSetName = 'IdentityInputObject')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityUser')]
        [ValidateGroupIdentity()]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [string]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [PSMicrosoftEntraID.Users.User[]]$InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUser')]
        [ValidateUserIdentity()]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [string[]]$User,
        [switch]$EnableException,
        [switch]$Force
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool]$cmdLetConfirm = $false
        }
        else {
            [bool]$cmdLetConfirm = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityUser' {
                $userActionString = ($User | ForEach-Object { "{0}" -f $_ }) -join ','
            }
            'IdentityInputObject' {
                $userActionString = ($InputObject.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
            }
        }
        Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Delete' -ActionStringValues ((($userActionString | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $Identity -ScriptBlock {
            $group = Get-PSEntraIDGroup -Identity $Identity
            if (-not ([object]::Equals($group, $null))) {
                switch ($PSCmdlet.ParameterSetName) {
                    'IdentityUser' {
                        foreach ($itemUser in  $User) {
                            $aADUser = Get-PSEntraIDUser -Identity $itemUser
                            if (-not ([object]::Equals($aADUser, $null))) {
                                $path = ('groups/{0}/owners/{1}/$ref' -f $group.Id, $aADUser.Id)
                                [void](Invoke-EntraRequest -Service $service -Path $path -Method Delete -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                            }
                            else {
                                if ($EnableException.IsPresent) {
                                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                                }
                            }
                        }
                    }
                    'IdentityInput' {
                        foreach ($itemInputObject in  $InoutObject) {
                            $path = ('groups/{0}/owners/{1}/$ref' -f $group.Id, $itemInputObject.Id)
                            [void](Invoke-EntraRequest -Service $service -Path $path -Method Delete -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                    }
                }
            }
            else {
                if ($EnableException.IsPresent) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
                }
            }
        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue #-RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {

    }
}