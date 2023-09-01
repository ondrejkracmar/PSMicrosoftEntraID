function Sync-GroupMember {
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
