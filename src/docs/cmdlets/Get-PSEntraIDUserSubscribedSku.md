---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUserSubscribedSku

## SYNOPSIS
Get users who are assigned licenses

## SYNTAX

### SkuPartNumberCompanyName (Default)
```
Get-PSEntraIDUserSubscribedSku -CompanyName <String[]> -SkuPartNumber <String> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SkuIdCompanyName
```
Get-PSEntraIDUserSubscribedSku -CompanyName <String[]> -SkuId <String> [-EnableException]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### SkuId
```
Get-PSEntraIDUserSubscribedSku -SkuId <String> [-EnableException] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### SkuPartNumber
```
Get-PSEntraIDUserSubscribedSku -SkuPartNumber <String> [-EnableException] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
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
Get-PSEntraIDUserSubscribedSku -SkuPartNumber ENTERPRISEPACK
```

Get userse with ENTERPRISEPACK subscription

## PARAMETERS

### -CompanyName
CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: SkuPartNumberCompanyName
Aliases: Company

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

```yaml
Type: System.String[]
Parameter Sets: SkuIdCompanyName
Aliases: Company

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkuId
Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: System.String
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
Type: System.String
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

### PSMicrosoftEntraID.User.SubscribedSku
## NOTES

## RELATED LINKS
