---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Disable-PSAADUserLicense

## SYNOPSIS
Disable user's license

## SYNTAX

### IdentitySkuPartNumberPlanName (Default)
```
Disable-PSAADUserLicense [-EnableException] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuPartNumber
```
Disable-PSAADUserLicense -Identity <String[]> -SkuPartNumber <String[]> [-EnableException] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### IdentitySkuId
```
Disable-PSAADUserLicense -Identity <String[]> -SkuId <String[]> [-EnableException] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Disable user's Office 365 subscription

## EXAMPLES

### EXAMPLE 1
```
Disable-PSAADUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK
```

Disable license (subscription) ENTERPRISEPACK of user username@contoso.com

## PARAMETERS

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: String[]
Parameter Sets: IdentitySkuPartNumber, IdentitySkuId
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
Parameter Sets: IdentitySkuId
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
Type: String[]
Parameter Sets: IdentitySkuPartNumber
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
