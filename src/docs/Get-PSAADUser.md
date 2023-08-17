---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Get-PSAADUser

## SYNOPSIS
Get the properties of the specified user.

## SYNTAX

### Identity (Default)
```
Get-PSAADUser -Identity <String[]> [<CommonParameters>]
```

### Name
```
Get-PSAADUser -Name <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### CompanyName
```
Get-PSAADUser -CompanyName <String[]> [-Disabled] [-PageSize <Int32>] [<CommonParameters>]
```

### All
```
Get-PSAADUser [-Disabled] [-All] [-PageSize <Int32>] [<CommonParameters>]
```

### Filter
```
Get-PSAADUser -Filter <String> [-AdvancedFilter] [-PageSize <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Get the properties of the specified user.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: String[]
Parameter Sets: Identity
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CompanyName
{{ Fill CompanyName Description }}

```yaml
Type: String[]
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
Type: SwitchParameter
Parameter Sets: CompanyName, All
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
Type: String
Parameter Sets: Filter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdvancedFilter
Switch advanced filter for filtering accounts in tenant/directory.

```yaml
Type: SwitchParameter
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
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Value of returned result set contains multiple pages of data.

```yaml
Type: Int32
Parameter Sets: Name, CompanyName, All, Filter
Aliases:

Required: False
Position: Named
Default value: 100
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
