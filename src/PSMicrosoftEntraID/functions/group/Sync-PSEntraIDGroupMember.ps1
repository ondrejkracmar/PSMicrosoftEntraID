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

    .PARAMETER AllowEmptyReference
        Allows an empty reference, which removes every member of the difference group.

        Without it the sync refuses an empty reference: an empty member list is far more
        often a read that came back with nothing than a deliberate "empty this group",
        and the two cannot be told apart afterwards.

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
        [switch] $AllowEmptyReference,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        # Graph accepts at most 20 members@odata.bind entries per PATCH.
        [int] $addChunkSize = 20
    }

    process {
        # Every read below runs with -EnableException and anything it throws aborts the
        # whole sync. The reads used to run under -Continue: a transient 403/429/503 only
        # warned and returned NOTHING, and nothing on the reference side means "remove
        # every member" further down. A sync that cannot see both sides must not write.
        [PSMicrosoftEntraID.Groups.Group] $differenceEntraIDGroup = $null
        try { $differenceEntraIDGroup = Get-PSEntraIDGroup -Identity $DifferenceIdentity -EnableException }
        catch {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Sync.ReadFailed) -f $DifferenceIdentity, $DifferenceIdentity, $_.Exception.Message)
        }
        if ([object]::Equals($differenceEntraIDGroup, $null)) {
            if ($EnableException.IsPresent) {
                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $DifferenceIdentity)
            }
            return
        }
        [string] $targetName = if ($differenceEntraIDGroup.MailNickName) { $differenceEntraIDGroup.MailNickName } else { $differenceEntraIDGroup.Id }

        # -Property Id, NOT -ExpandProperty Id. Both lists go to Get-SyncDataOperation,
        # which matches on the Id PROPERTY - a bare [string] has no .Id.
        try { $differenceMemberList = @(Get-PSEntraIDGroupMember -InputObject $differenceEntraIDGroup -EnableException | Select-Object -Property Id) }
        catch {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Sync.ReadFailed) -f $targetName, $targetName, $_.Exception.Message)
        }

        [System.Collections.Generic.List[object]] $referenceMemberList = [System.Collections.Generic.List[object]]::new()
        switch ($PSCmdlet.ParameterSetName) {
            'UserIdentity' {
                # An identity that does not resolve aborts the sync. Skipping it - as this
                # did - leaves that user out of the reference, and a user missing from the
                # reference is a user the sync removes from the group.
                [System.Collections.Generic.List[string]] $unresolvedList = [System.Collections.Generic.List[string]]::new()
                foreach ($itemUser in $ReferenceUserIdentity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = $null
                    try { $aADUser = Get-PSEntraIDUser -Identity $itemUser -EnableException }
                    catch {
                        $unresolvedList.Add(("'{0}' ({1})" -f $itemUser, $_.Exception.Message))
                        continue
                    }
                    if ([object]::Equals($aADUser, $null)) { $unresolvedList.Add(("'{0}'" -f $itemUser)) }
                    else { $referenceMemberList.Add(($aADUser | Select-Object -Property Id)) }
                }
                if ($unresolvedList.Count -gt 0) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Category ObjectNotFound -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Sync.Unresolved) -f $targetName, ($unresolvedList -join ', '))
                }
            }
            'GroupIdentity' {
                try {
                    [PSMicrosoftEntraID.Groups.Group] $referenceEntraIDGroup = Get-PSEntraIDGroup -Identity $ReferenceIdentity -EnableException
                    if ([object]::Equals($referenceEntraIDGroup, $null)) {
                        throw ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $ReferenceIdentity)
                    }
                    foreach ($referenceMember in @(Get-PSEntraIDGroupMember -InputObject $referenceEntraIDGroup -EnableException | Select-Object -Property Id)) {
                        $referenceMemberList.Add($referenceMember)
                    }
                }
                catch {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -ErrorRecord $_ -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Sync.ReadFailed) -f $targetName, $ReferenceIdentity, $_.Exception.Message)
                }
            }
        }

        if ($referenceMemberList.Count -eq 0 -and $differenceMemberList.Count -gt 0 -and -not $AllowEmptyReference.IsPresent) {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Category InvalidData -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Sync.EmptyReference) -f $targetName, $differenceMemberList.Count)
        }

        $syncOperationList = @(Get-SyncDataOperation -ReferenceObjectList $referenceMemberList -DiferenceObjectList $differenceMemberList -MatchProperty Id -DiferenceObjectUniqueKeyName Id)

        if ($SyncView.IsPresent) {
            foreach ($syncOperation in $syncOperationList) { $syncOperation }
            return
        }

        # Writes go straight to the group resolved above. Add-/Remove-PSEntraIDGroupMember
        # per member re-resolved the group and the user on every call (~5 requests a
        # member) and could only address users.
        [string] $serviceUrl = (Get-EntraService -Name $service).ServiceUrl
        [string[]] $createIdList = @($syncOperationList | Where-Object Crud -eq 'Create' | ForEach-Object { $_.Fields.Id })
        for ($index = 0; $index -lt $createIdList.Count; $index += $addChunkSize) {
            [string[]] $chunk = $createIdList[$index..([math]::Min($index + $addChunkSize, $createIdList.Count) - 1)]
            [hashtable] $body = @{ 'members@odata.bind' = @($chunk | ForEach-Object { '{0}/directoryObjects/{1}' -f $serviceUrl, $_ }) }
            [string] $path = 'groups/{0}' -f [uri]::EscapeDataString($differenceEntraIDGroup.Id)
            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync.Add' -ActionStringValues $chunk.Count, $targetName -Target $targetName -ScriptBlock {
                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue
            if (Test-PSFFunctionInterrupt) { return }
        }
        foreach ($syncOperation in @($syncOperationList | Where-Object Crud -eq 'Delete')) {
            # IdentityValue, not Fields.Id: Get-SyncDataOperation leaves Fields empty for a
            # delete and carries the id in IdentityValue.
            [string] $memberId = $syncOperation.IdentityValue
            [string] $path = 'groups/{0}/members/{1}/$ref' -f [uri]::EscapeDataString($differenceEntraIDGroup.Id), [uri]::EscapeDataString($memberId)
            Invoke-PSFProtectedCommand -ActionString 'GroupMember.Sync.Remove' -ActionStringValues $memberId, $targetName -Target $targetName -ScriptBlock {
                [void] (Invoke-EntraRequest -Service $service -Path $path -Method Delete -ErrorAction Stop)
            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
    end {

    }
}
