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
                $member = Get-PSAADUser -Identity $item.Fields.Identity
                Add-PSAADGroupMember -Identity $Identity -User $member.Id
            }
            'Update' {
            }
            'Delete' {
                $member = Get-PSAADUser -Identity $item.Fields.Identity
                Remove-PSAADGroupMember -Identity $Identity -User $member.Id
            }
            Default {}
        }
    }
}
