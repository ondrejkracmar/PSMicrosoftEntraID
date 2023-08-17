---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Get-PSAADLicenseServicePlan

## SYNOPSIS
Get service plans of license

## SYNTAX

### SkuPartNumber (Default)
```
Get-PSAADLicenseServicePlan -SkuPartNumber <String> [<CommonParameters>]
```

### SkuId
```
Get-PSAADLicenseServicePlan -SkuId <Object> [<CommonParameters>]
```

## DESCRIPTION
Get service plans of license

## EXAMPLES

### EXAMPLE 1
```
Get-PSAADLicenseServicePlan -SkuPartNumber ENTERPRISEPACK
```

Get service plans of ENTERPRISEPACK license

## PARAMETERS

### -SkuId
Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: Object
Parameter Sets: SkuId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SkuPartNumber
Friendly name Office 365 product of subscribedSku.

```yaml
Type: String
Parameter Sets: SkuPartNumber
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSAzureADDirectory.License.ServicePlan
## NOTES

## RELATED LINKS
