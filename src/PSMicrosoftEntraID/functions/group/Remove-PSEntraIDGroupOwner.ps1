﻿function  Remove-PSEntraIDGroupOwner {
    <#
    .SYNOPSIS
        Remove a owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Remove a owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

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

            Remove owner to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Identity')]
    param([Parameter(Mandatory = $True, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [string]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
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
        Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Delete' -ActionStringValues ((($User | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $Identity -ScriptBlock {
            $group = Get-PSEntraIDGroup -Identity $Identity
            if (-not ([object]::Equals($group, $null))) {
                switch -Regex ($PSCmdlet.ParameterSetName) {
                    'Identity' {
                        foreach ($itemUser in  $User) {
                            $aADUser = Get-PSEntraIDUser -Identity $itemUser
                            if (-not ([object]::Equals($aADUser, $null))) {

                                $path = ('groups/{0}/owners/{1}/$ref' -f $group.Id, $aADUser.Id)
                                try {
                                    [void](Invoke-EntraRequest -Service $service -Path $path -Method Delete -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                                }
                                catch {
                                    if ($EnableException.IsPresent) {
                                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupOwner.Delete.Failed) -f $Identity)
                                    }
                                }
                            }
                            else {
                                if ($EnableException.IsPresent) {
                                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                                }
                            }
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