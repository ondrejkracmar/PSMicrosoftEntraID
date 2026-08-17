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
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .EXAMPLE
            PS C:\> Sync-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Sync members between group1 and group2


#>
    [OutputType('PSMicrosoftEntraID.Sync')]
    [CmdletBinding(DefaultParameterSetName = 'UserIdentity', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [ValidateGroupIdentity()]
        [string] $ReferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'GroupIdentity')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateGroupIdentity()]
        [string] $DifferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [string[]] $ReferenceUserIdentity,
        [Parameter()]
        [switch] $SyncView,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [System.Collections.Generic.List[object]] $referenceMemberList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $differenceMemberList = [System.Collections.Generic.List[object]]::new()
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    }

    process {

        [PSMicrosoftEntraID.Groups.Group] $differenceEntraIDGroup = Get-PSEntraIDGroup -Identity $DifferenceIdentity
        if ([object]::Equals($differenceEntraIDGroup, $null)) {
            return
        }

        # -Property Id, NOT -ExpandProperty Id. Both lists go to Get-SyncDataOperation,
        # which runs Compare-Object -Property Id over them - and a bare [string] has no
        # .Id, so expanding here made every entry compare $null against $null. Everything
        # matched, everything came back '==', and the Create and Delete branches below
        # were unreachable: the sync could neither add a member nor remove one.
        $differenceMemberList = Get-PSEntraIDGroupMember -Identity $differenceEntraIDGroup.Id | Select-Object -Property Id
        switch ($PSCmdlet.ParameterSetName) {
            'UserIdentity' {
                foreach ($itemUser in $ReferenceUserIdentity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $itemUser
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                        }
                    }
                    else {
                        [void]$referenceMemberList.Add(($aADUser | Select-Object -Property Id))
                    }
                }
            }
            'GroupIdentity' {
                [PSMicrosoftEntraID.Groups.Group] $referenceEntraIDGroup = Get-PSEntraIDGroup -Identity $ReferenceIdentity
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
                            # The id is already resolved - it came from Get-PSEntraIDUser
                            # in the UserIdentity set, or off the reference group's own
                            # members. Looking it up again cost a round trip per member
                            # and answered a question nobody asked.
                            $memberId = $syncOperation.Fields.Id
                            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync' -Target $differenceEntraIDGroup.MailNickName -ScriptBlock {
                                [void] (Add-PSEntraIDGroupMember -Identity $differenceEntraIDGroup.Id -User $memberId)
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                        'Update' {
                        }
                        'Delete' {
                            # IdentityValue, not Fields.Id: Get-SyncDataOperation sets
                            # Fields = @{} for a delete and carries the id in
                            # IdentityValue, so reading Fields.Id here was always null.
                            $memberId = $syncOperation.IdentityValue
                            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync' -Target $differenceEntraIDGroup.MailNickName -ScriptBlock {
                                [void] (Remove-PSEntraIDGroupMember -Identity $differenceEntraIDGroup.Id -User $memberId)
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                        Default {}
                    }
                }
            }
        }
    }
    end {

    }
}
