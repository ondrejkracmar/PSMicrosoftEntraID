---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUser

## SYNOPSIS
Get the properties of the specified user.

## SYNTAX

### Identity (Default)
```
Get-PSEntraIDUser -Identity <String[]> [-EnableException] [<CommonParameters>]
```

### Name
```
Get-PSEntraIDUser -Name <String[]> [-EnableException] [<CommonParameters>]
```

### CompanyName
```
Get-PSEntraIDUser -CompanyName <String[]> [-Disabled] [-EnableException] [<CommonParameters>]
```

### All
```
Get-PSEntraIDUser [-Disabled] [-All] [-EnableException] [<CommonParameters>]
```

### Filter
```
Get-PSEntraIDUser -Filter <String> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
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

### -CompanyName
CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: CompanyName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Disabled
Return disabled accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: CompanyName, All
Aliases:

Required: False
Position: Named
Default value: False
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
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: Identity
Aliases: Id, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: Name
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

### PSMicrosoftEntraID.User
## NOTES

## RELATED LINKS
