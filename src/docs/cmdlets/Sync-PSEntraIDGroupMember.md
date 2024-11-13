---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Sync-PSEntraIDGroupMember

## SYNOPSIS
Synchronize Microsoft 365 group members.

## SYNTAX

### UserIdentity (Default)
```
Sync-PSEntraIDGroupMember -DifferenceIdentity <String> -ReferenceUserIdentity <String[]> [-SyncView]
 [-EnableException] [-Force] [<CommonParameters>]
```

### GroupIdentity
```
Sync-PSEntraIDGroupMember -ReferenceIdentity <String> -DifferenceIdentity <String> [-SyncView]
 [-EnableException] [-Force] [<CommonParameters>]
```

## DESCRIPTION
Synchronize a member/owner to a security or Microsoft 365 group.

## EXAMPLES

### EXAMPLE 1
```
Sync-PSEntraIDGroupMember -Identity group1 -User user1,user2
```

Sync memebrs between group1 and group2

## PARAMETERS

### -DifferenceIdentity
MailNickName or Id of difference group or team

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnableException
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly,
but allows catching exceptions in calling scripts.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
The Force switch instructs the command to which it is applied to stop processing before any changes are made.
The command then prompts you to acknowledge each action before it continues.
When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
A confirmation prompt is displayed for each object before the Shell modifies the object.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReferenceIdentity
MailNickName or Id of reference group or team

```yaml
Type: System.String
Parameter Sets: GroupIdentity
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReferenceUserIdentity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: UserIdentity
Aliases: UserId, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SyncView
List user identities via query expression

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.Sync
## NOTES

## RELATED LINKS
