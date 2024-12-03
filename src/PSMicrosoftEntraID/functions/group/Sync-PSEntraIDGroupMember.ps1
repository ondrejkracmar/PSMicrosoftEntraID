function  Sync-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Synchronize Microsoft 365 group members.

    .DESCRIPTION
        Synchronize a member/owner to a security or Microsoft 365 group.

    .PARAMETER ReferenceIdentity
        MailNickName or Id of reference group or team

    .PARAMETER DifferenceIdentity
        MailNickName or Id of difference group or team

    .PARAMETER ReferenceUserIdentity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER SyncView
        List user identities via query expression

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
            PS C:\> Sync-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Sync memebrs between group1 and group2


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('PSMicrosoftEntraID.Sync')]
    [CmdletBinding(DefaultParameterSetName = 'UserIdentity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [ValidateGroupIdentity()]
        [string]$ReferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateGroupIdentity()]
        [string]$DifferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [string[]]$ReferenceUserIdentity,
        [switch]$SyncView,
        [switch]$EnableException,
        [switch]$Force
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $referenceMemberList = [System.Collections.ArrayList]::New()
        $differenceMemberList = [System.Collections.ArrayList]::New()
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
        
        $differenceEntraIDGroup = Get-PSEntraIDGroup -Identity $DifferenceIdentity
        if (-not([object]::Equals($differenceEntraIDGroup, $null))) {
            $differenceMemberList = Get-PSEntraIDGroupMember -Identity $differenceEntraIDGroup.Id | Select-Object -Property Id
            switch ($PSCmdlet.ParameterSetName) {
                'UserIdentity' {
                    foreach ($itemUser in  $ReferenceUserIdentity) {
                        $aADUser = Get-PSEntraIDUser -Identity $itemUser
                        if (-not ([object]::Equals($aADUser, $null))) {
                            $addUser = $aADUser | Select-Object -Property Id
                            [void]$referenceMemberList.Add($addUser)
                        }
                    }
                }
                'GroupIdentity' {
                    $referenceEntraIDGroup = Get-PSEntraIDGroup -Identity $ReferenceIdentity
                    $referenceMemberList = Get-PSEntraIDGroupMember -Identity $referenceEntraIDGroup.Id | Select-Object -Property Id
                }
            }
            $syncOperationList = Get-SyncDataOperation -ReferenceObjectList $referenceMemberList -DiferenceObjectList $differenceMemberList -MatchProperty Id -DiferenceObjectUniqueKeyName Id

            if ($SyncView.IsPresent) {
                if (-not ([object]::Equals($syncOperationList, $null))) {
                    $syncOperationList
                }
            }
            else {
                if (-not ([object]::Equals($syncOperationList, $null))) {
                    foreach ($syncOperation in $syncOperationList) {
                        switch ($syncOperation.Crud) {
                            'Create' {
                                $member = Get-PSEntraIDUser -Identity $syncOperation.Fields.Id
                                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync' -Target $referenceAADGroup.MailNickName -ScriptBlock {
                                    [void](Add-PSEntraIDGroupMember -Identity $referenceAADGroup.Id -User $member.Id)
                                } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                            'Update' {
                            }
                            'Delete' {
                                $member = Get-PSEntraIDUser -Identity $syncOperation.Fields.Id
                                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync' -Target $referenceAADGroup.MailNickName -ScriptBlock {
                                    [void](Remove-PSEntraIDGroupMember -Identity $referenceAADGroup.Id -User $member.Id)
                                } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                            Default {}
                        }
                    }
                }
            }
        }
    }
    end {

    }
}