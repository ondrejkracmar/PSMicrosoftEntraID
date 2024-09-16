---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Compare-PSEntraIDUserList

## SYNOPSIS
Compare two list user of user.

## SYNTAX

```
Compare-PSEntraIDUserList -ReferenceIdentity <String[]> -DifferenceIdentity <String[]> [<CommonParameters>]
```

## DESCRIPTION
Compare two list user of user.

## EXAMPLES

### EXAMPLE 1
```
Compare-PSEntraIDUserList -ReferenceIdentity $UserList1 -DifferenceIdentity $UserList2
```

Remove memebr to Azure AD group group1

## PARAMETERS

### -DifferenceIdentity
Difference list of users

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReferenceIdentity
Reference list of users

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Collections.ArrayList
## NOTES

## RELATED LINKS
