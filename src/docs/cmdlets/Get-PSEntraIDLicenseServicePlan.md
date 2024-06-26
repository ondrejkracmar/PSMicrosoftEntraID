﻿---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDLicenseServicePlan

## SYNOPSIS
Get service plans of license

## SYNTAX

### SkuPartNumber (Default)
```
Get-PSEntraIDLicenseServicePlan -SkuPartNumber <String> [-EnableException] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### SkuId
```
Get-PSEntraIDLicenseServicePlan -SkuId <String> [-EnableException] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Get service plans of license

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDLicenseServicePlan -SkuPartNumber ENTERPRISEPACK
```

Get service plans of ENTERPRISEPACK license

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
Parameter Sets: SkuId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SkuPartNumber
Friendly name Office 365 product of subscribedSku.

```yaml
Type: System.String
Parameter Sets: SkuPartNumber
Aliases:

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

### PSMicrosoftEntraID.License.ServicePlan
## NOTES

## RELATED LINKS
