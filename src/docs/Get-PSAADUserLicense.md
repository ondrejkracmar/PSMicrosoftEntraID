---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Get-PSAADUserLicense

## SYNOPSIS
Get users who are assigned licenses

## SYNTAX

### Identity (Default)
```
Get-PSAADUserLicense -Identity <String[]> [<CommonParameters>]
```

### SkuPartNumberCompanyName
```
Get-PSAADUserLicense -CompanyName <String[]> -SkuPartNumber <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### SkuIdCompanyName
```
Get-PSAADUserLicense -CompanyName <String[]> -SkuId <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### CompanyName
```
Get-PSAADUserLicense -CompanyName <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### SkuId
```
Get-PSAADUserLicense -SkuId <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### SkuPartNumber
```
Get-PSAADUserLicense -SkuPartNumber <String[]> [-PageSize <Int32>] [<CommonParameters>]
```

### Filter
```
Get-PSAADUserLicense -Filter <String> [-AdvancedFilter] [-PageSize <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Get users who are assigned licenses

## EXAMPLES

### EXAMPLE 1
```
Get-PSAADUserLicense -Identity username@contoso.com
```

Get licenses of user username@contoso.com

### EXAMPLE 2
```
Get-PSAADUserLicense -SkuPartNumber ENTERPRISEPACK
```

Get userse with ENTERPRISEPACK licenses

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

### -CompanyName
{{ Fill CompanyName Description }}

```yaml
Type: String[]
Parameter Sets: SkuPartNumberCompanyName, SkuIdCompanyName, CompanyName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SkuId
Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: String[]
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
Type: String[]
Parameter Sets: SkuPartNumberCompanyName, SkuPartNumber
Aliases:

Required: True
Position: Named
Default value: None
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

### -PageSize
Value of returned result set contains multiple pages of data.

```yaml
Type: Int32
Parameter Sets: SkuPartNumberCompanyName, SkuIdCompanyName, CompanyName, SkuId, SkuPartNumber, Filter
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

### PSAzureADDirectory.User.License
## NOTES

## RELATED LINKS
