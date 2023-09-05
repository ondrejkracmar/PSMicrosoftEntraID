﻿function  Sync-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Synchronize Microsoft 365 group members.

    .DESCRIPTION
        Synchronize a member/owner to a security or Microsoft 365 group.

    .PARAMETER ReferenceIdentity
        MailNickName or Id of reference group or team

    .PARAMETER DifferenceIdentity
        MailNickName or Id of difference group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER SyncView
        List user identities via query expression

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
            PS C:\> Remove-PSADGroupMember -Identity group1 -User user1,user2

            Remove memebr to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('PSMicrosoftEntraID.Sync')]
    [CmdletBinding(DefaultParameterSetName = 'UserIdentity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [ValidateGroupIdentity()]
        [string]
        $ReferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'QueryExpressionIdentity')]
        [ValidateGroupIdentity()]
        [string]
        $DifferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        $User,
        #[Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'QueryExpressionIdentity')]
        #[ValidateNotNullOrEmpty()]
        #[string]
        #$QueryExpression,
        [switch]
        $SyncView,
        [switch]
        $EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $referenceMemberList = [System.Collections.ArrayList]::New()
        $differenceMemberList = [System.Collections.ArrayList]::New()
    }

    process {
        $referenceAADGroup = Get-PSEntraIDGroup -Identity $ReferenceIdentity
        if (-not ([object]::Equals($referenceAADGroup, $null))) {
            $referenceMemberList = Get-PSEntraIDGroupMember -Identity $referenceAADGroup.Id | Select-Object -Property Id
            switch ($PSCmdlet.ParameterSetName) {
                'UserIdentity' {
                    foreach ($itemUser in  $User) {
                        $aADUser = Get-PSEntraIDUser -Identity $itemUser
                        if (-not ([object]::Equals($aADUser, $null))) {
                            [void]$differenceMemberList.Add($aADUser.Id)
                        }
                    }
                }
                'GroupIdentity' {
                    $differenceMemberList = Get-PSEntraIDGroupMember -Identity $DifferenceIdentity | Select-Object -Property Id
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
                                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                            'Update' {
                            }
                            'Delete' {
                                $member = Get-PSEntraIDUser -Identity $syncOperation.Fields.Id
                                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync' -Target $referenceAADGroup.MailNickName -ScriptBlock {
                                    [void](Remove-PSEntraIDGroupMember -Identity $referenceAADGroup.Id -User $member.Id)
                                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
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