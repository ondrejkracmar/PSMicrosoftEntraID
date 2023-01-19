---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Enable-PSAADUserLicenseServicePlan

## SYNOPSIS
Enable serivce plan of users's sku subscription

## SYNTAX

### IdentitySkuPartNumberPlanName (Default)
```
Enable-PSAADUserLicenseServicePlan -Identity <String[]> -SkuPartNumber <String> -ServicePlanName <String[]>
 [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuPartNumberPlanId
```
Enable-PSAADUserLicenseServicePlan -Identity <String[]> -SkuPartNumber <String> -ServicePlanId <String[]>
 [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuIdServicePlanName
```
Enable-PSAADUserLicenseServicePlan -Identity <String[]> -SkuId <String> -ServicePlanName <String[]>
 [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuIdServicePlanId
```
Enable-PSAADUserLicenseServicePlan -Identity <String[]> -SkuId <String> -ServicePlanId <String[]>
 [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Enable serivce plan of users's sku subscription

## EXAMPLES

### EXAMPLE 1
```
Enable-PSAADUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')
```

Enable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com

## PARAMETERS

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: String[]
Parameter Sets: (All)
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
Type: String
Parameter Sets: IdentitySkuIdServicePlanName, IdentitySkuIdServicePlanId
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
Parameter Sets: IdentitySkuPartNumberPlanName, IdentitySkuPartNumberPlanId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ServicePlanId
Service plan Id of subscribedSku.

```yaml
Type: String[]
Parameter Sets: IdentitySkuPartNumberPlanId, IdentitySkuIdServicePlanId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ServicePlanName
Friendly servcie plan name of subscribedSku.

```yaml
Type: String[]
Parameter Sets: IdentitySkuPartNumberPlanName, IdentitySkuIdServicePlanName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -EnableException
{{ Fill EnableException Description }}

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSAzureADDirectory.User
## NOTES

## RELATED LINKS
