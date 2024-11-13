---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDGroup

## SYNOPSIS
Get the properties of the specified group.

## SYNTAX

### Identity (Default)
```
Get-PSEntraIDGroup -Identity <String[]> [-EnableException] [<CommonParameters>]
```

### DisplayName
```
Get-PSEntraIDGroup -DisplayName <String[]> [-EnableException] [<CommonParameters>]
```

### Filter
```
Get-PSEntraIDGroup -Filter <String> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

### All
```
Get-PSEntraIDGroup [-All] [-EnableException] [<CommonParameters>]
```

## DESCRIPTION
Get the properties of the specified group.

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDGroup -Identity group1
```

Get properties of Azure AD group group1

## PARAMETERS

### -AdvancedFilter
Switch advanced filter for filtering accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Filter
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Return all accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisplayName
DIsplayName of the group attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: DisplayName
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

### -Filter
Filter expressions of accounts in tenant/directory.

```yaml
Type: System.String
Parameter Sets: Filter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
MailnicName, Mail or Id of the group attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: Identity
Aliases: Id, GroupId, TeamId, MailNickName

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

### PSMicrosoftEntraID.Groups.Group
## NOTES

## RELATED LINKS
