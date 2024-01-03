---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# New-PSEntraIDInvitation

## SYNOPSIS
Get the properties of the specified user.

## SYNTAX

### UserEmailAddres (Default)
```
New-PSEntraIDInvitation [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### UserEmailAddress
```
New-PSEntraIDInvitation -InvitedUserEmailAddress <String> -InvitedUserDisplayName <String>
 -InviteRedirectUrl <String> [-SendInvitationMessage <Boolean>] [-InviteMessage <String>]
 [-MessageLanguage <String>] [-CCRecipient <PSObject[]>] [-EnableException] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Get the properties of the specified user.

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDUser -Identity user1@contoso.com
```

Get properties of Azure AD user user1@contoso.com

## PARAMETERS

### -CCRecipient
Name and mail of CC recipients

```yaml
Type: System.Management.Automation.PSObject[]
Parameter Sets: UserEmailAddress
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

### -InvitedUserDisplayName
DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

```yaml
Type: System.String
Parameter Sets: UserEmailAddress
Aliases: UserDisplayNameName, DisplayNameName, Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InvitedUserEmailAddress
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String
Parameter Sets: UserEmailAddress
Aliases: UserEmailAddress, EmailAddres, Mail, UserPrincipalName, InvitedUserPrincipalName

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InviteMessage
The invitation message

```yaml
Type: System.String
Parameter Sets: UserEmailAddress
Aliases: Message

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -InviteRedirectUrl
The URL that the user will be redirected to after redemption.

```yaml
Type: System.String
Parameter Sets: UserEmailAddress
Aliases: RedirectUrl, Url

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -MessageLanguage
Langueage of invite message.

```yaml
Type: System.String
Parameter Sets: UserEmailAddress
Aliases: Language

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SendInvitationMessage
Switch if senf invitation message

```yaml
Type: System.Boolean
Parameter Sets: UserEmailAddress
Aliases:

Required: False
Position: Named
Default value: False
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

## RELATED LINKS
