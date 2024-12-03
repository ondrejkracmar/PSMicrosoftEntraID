---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Set-PSEntraIDGroup

## SYNOPSIS
Updates the specified properties of a Microsoft 365 Group.

## SYNTAX

### UodtaeGroupCommon (Default)
```
Set-PSEntraIDGroup -Identity <String[]> [-Displayname <String>] [-Description <String>]
 [-MailNickname <String>] [-GroupTypes <String[]>] [-Visibility <String>] [-EnableException] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### UodtaeDynamicGroup
```
Set-PSEntraIDGroup -Identity <String[]> -MembershipRule <String> -MembershipRuleProcessingState <String>
 [-EnableException] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### HideFromOutlookClients
```
Set-PSEntraIDGroup -Identity <String[]> -HideFromOutlookClients <Boolean> [-EnableException] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### HideFromAddressLists
```
Set-PSEntraIDGroup -Identity <String[]> -HideFromAddressLists <Boolean> [-EnableException] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### AutoSubscribeNewMembers
```
Set-PSEntraIDGroup -Identity <String[]> -AutoSubscribeNewMembers <Boolean> [-EnableException] [-Force]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

### AllowExternalSenders
```
Set-PSEntraIDGroup -Identity <String[]> -AllowExternalSenders <Boolean> [-EnableException] [-Force] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The \`Set-PSntraIDGroup\` cmdlet allows you to modify specific properties of a Microsoft 365 Group.
Some properties can be updated together, while others require separate calls.
Additionally, certain
properties are read-only and can only be retrieved, not modified..

## EXAMPLES

### EXAMPLE 1
```
Set-PSntraIDGroup -GroupId "mailnickname1" -DisplayName "New Group Name" -Description "Updated group description" -Visibility "Private"
```

### EXAMPLE 2
```
Set-PSntraIDGroup -GroupId "mailnickname@domain.com" -AllowExternalSenders $true
```

### EXAMPLE 3
```
Set-PSntraIDGroup -GroupId "mailnickname1" -MembershipRule "(user.department -eq 'Sales')" -MembershipRuleProcessingState "On"
```

## PARAMETERS

### -AllowExternalSenders
Specifies whether external users can send messages to the group.
Note: This parameter must be set in a separate call and cannot be combined with other properties in a single \`PATCH\` request.

```yaml
Type: System.Nullable`1[System.Boolean]
Parameter Sets: AllowExternalSenders
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AutoSubscribeNewMembers
Indicates whether new members are automatically subscribed to receive email notifications.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
Parameter Sets: AutoSubscribeNewMembers
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Description
Specifies the description of the group.
This can be updated with other properties.

```yaml
Type: System.String
Parameter Sets: UodtaeGroupCommon
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Displayname
Specifies the display name of the group.
This can be updated in conjunction with other group settings.

```yaml
Type: System.String
Parameter Sets: UodtaeGroupCommon
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -EnableException
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user frien
dly, but allows catching exceptions in calling scripts.

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

### -GroupTypes
Specifies the type of the group.
For Microsoft 365 groups, use \`Unified\`.
This can be combined with other parameters in the same update request.

```yaml
Type: System.String[]
Parameter Sets: UodtaeGroupCommon
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HideFromAddressLists
Hides the group from global address lists.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
Parameter Sets: HideFromAddressLists
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HideFromOutlookClients
Hides the group from Outlook clients.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
Parameter Sets: HideFromOutlookClients
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Id, GroupId, TeamId

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -MailNickname
Sets the mail alias (nickname) of the group.
This can be updated along with other modifiable properties.

```yaml
Type: System.String
Parameter Sets: UodtaeGroupCommon
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MembershipRule
Defines the membership rule for a dynamic group.
This parameter is specific to dynamic groups and should be used with \`MembershipRuleProcessingState\`.

```yaml
Type: System.String
Parameter Sets: UodtaeDynamicGroup
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MembershipRuleProcessingState
Sets the processing state of the membership rule.
Accepted values are \`On\`, \`Paused\`, and \`Off\`.
This should be used with \`MembershipRule\` and is specific to dynamic groups.

```yaml
Type: System.String
Parameter Sets: UodtaeDynamicGroup
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Visibility
Defines the visibility of the group.
Accepted values are \`Public\` and \`Private\`.
This parameter can be updated in conjunction with other properties.

```yaml
Type: System.String
Parameter Sets: UodtaeGroupCommon
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Confirm
The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
The command then prompts you to acknowledge each action before it continues.
When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
A confirmation prompt is displayed for each object before the Shell modifies the object.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Enables the function to simulate what it will do instead of actually executing.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
- Properties like \`AllowExternalSenders\`, \`AutoSubscribeNewMembers\`, \`HideFromAddressLists\`, and \`HideFromOutlookClients\` must each be set in separate requests.
- Use \`Set-PSntraIDGroup\` to retrieve read-only properties such as \`isSubscribedByMail\` and \`unseenCount\`.

## RELATED LINKS
