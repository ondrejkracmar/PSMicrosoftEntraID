---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUserMemberOf

## SYNOPSIS
List a user's direct memberships.

## SYNTAX

```
Get-PSEntraIDUserMemberOf -Identity <String[]> [-Filter <String>] [-EnableException] [<CommonParameters>]
```

## DESCRIPTION
Get groups, directory roles, and administrative units that the user is a direct member of.
This operation isn't transitive.
To retrieve groups, directory roles, and administrative units that the user is a member through transitive membership.

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDUserMemberOf -Identity user1@contoso.com
```

Get groups, directory roles, and administrative units that the user is a direct member of user1@contoso.com

## PARAMETERS

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

### -Filter
Filter expressions of direct member of accounts in tenant/directory.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Id, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.User
## NOTES

## RELATED LINKS
