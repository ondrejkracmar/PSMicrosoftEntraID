function Sync-GroupMember {
    <#
    .SYNOPSIS
        Synchronize group.

    .DESCRIPTION
        Synchronize group.

    .PARAMETER Identity
        Id, TeamId, MailNickname or Id of the group attribute populated in tenant/directory.

    .PARAMETER SyncDataOperation
        Sync object structure

    .EXAMPLE
        PS C:\> Sync-GroupMember -Identity group1 -SyncDataOperation $SyncDataOperation

		Synchronize group

#>
    param(
        [ValidateGroupIdentity()]
        [string]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Array]$SyncDataOperation
    )
    foreach ($item in $SyncDataOperation) {
        switch ($item.Crud) {
            'Create' {
                $member = Get-PSEntraIDUser -Identity $item.Fields.Identity
                Add-PSEntraIDGroupMember -Identity $Identity -User $member.Id
            }
            'Update' {
            }
            'Delete' {
                $member = Get-PSEntraIDUser -Identity $item.Fields.Identity
                Remove-PSEntraIDGroupMember -Identity $Identity -User $member.Id
            }
            Default {}
        }
    }
}
