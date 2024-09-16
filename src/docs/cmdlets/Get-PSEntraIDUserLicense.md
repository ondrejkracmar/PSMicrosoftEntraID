---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUserLicense

## SYNOPSIS
Get users who are assigned licenses

## SYNTAX

### Identity (Default)
```
Get-PSEntraIDUserLicense -Identity <String[]> [-EnableException] [<CommonParameters>]
```

### SkuPartNumberCompanyName
```
Get-PSEntraIDUserLicense -CompanyName <String[]> -SkuPartNumber <String[]> [-EnableException]
 [<CommonParameters>]
```

### SkuIdCompanyName
```
Get-PSEntraIDUserLicense -CompanyName <String[]> -SkuId <String[]> [-EnableException] [<CommonParameters>]
```

### CompanyName
```
Get-PSEntraIDUserLicense -CompanyName <String[]> [-EnableException] [<CommonParameters>]
```

### SkuId
```
Get-PSEntraIDUserLicense -SkuId <String[]> [-EnableException] [<CommonParameters>]
```

### SkuPartNumber
```
Get-PSEntraIDUserLicense -SkuPartNumber <String[]> [-EnableException] [<CommonParameters>]
```

### Filter
```
Get-PSEntraIDUserLicense -Filter <String> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## DESCRIPTION
Get users who are assigned licenses

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDUserLicense -Identity username@contoso.com
```

Get licenses of user username@contoso.com

### EXAMPLE 2
```
Get-PSEntraIDUserLicense -SkuPartNumber ENTERPRISEPACK
```

Get userse with ENTERPRISEPACK licenses

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

### -CompanyName
CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: SkuPartNumberCompanyName, SkuIdCompanyName, CompanyName
Aliases: Company

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -SkuId
Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: System.String[]
Parameter Sets: SkuIdCompanyName, SkuId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkuPartNumber
Friendly name Office 365 product of subscribedSku.

```yaml
Type: System.String[]
Parameter Sets: SkuPartNumberCompanyName, SkuPartNumber
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

### PSMicrosoftEntraID.User.License
## NOTES

## RELATED LINKS
