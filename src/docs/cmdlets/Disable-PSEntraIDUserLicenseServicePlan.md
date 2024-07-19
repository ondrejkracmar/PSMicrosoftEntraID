﻿---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Disable-PSEntraIDUserLicenseServicePlan

## SYNOPSIS
Disable serivce plan of users's sku subscription

## SYNTAX

### IdentitySkuPartNumberPlanName (Default)
```
Disable-PSEntraIDUserLicenseServicePlan -Identity <String[]> -SkuPartNumber <String>
 -ServicePlanName <String[]> [-EnableException] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### IdentitySkuPartNumberPlanId
```
Disable-PSEntraIDUserLicenseServicePlan -Identity <String[]> -SkuPartNumber <String> -ServicePlanId <String[]>
 [-EnableException] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuIdServicePlanName
```
Disable-PSEntraIDUserLicenseServicePlan -Identity <String[]> -SkuId <String> -ServicePlanName <String[]>
 [-EnableException] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentitySkuIdServicePlanId
```
Disable-PSEntraIDUserLicenseServicePlan -Identity <String[]> -SkuId <String> -ServicePlanId <String[]>
 [-EnableException] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Disable serivce plan of users's sku subscription

## EXAMPLES

### EXAMPLE 1
```
Disable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')
```

Disable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com

## PARAMETERS

### -EnableException
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user frien
dly, but allows catching exceptions in calling scripts.

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

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Id, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -ServicePlanId
Service plan Id of subscribedSku.

```yaml
Type: System.String[]
Parameter Sets: IdentitySkuPartNumberPlanId, IdentitySkuIdServicePlanId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServicePlanName
Friendly servcie plan name of subscribedSku.

```yaml
Type: System.String[]
Parameter Sets: IdentitySkuPartNumberPlanName, IdentitySkuIdServicePlanName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkuId
Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: System.String
Parameter Sets: IdentitySkuIdServicePlanName, IdentitySkuIdServicePlanId
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
Parameter Sets: IdentitySkuPartNumberPlanName, IdentitySkuPartNumberPlanId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
The command then prompts you to acknowledge each action before it continues.
When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
A confirmation prompt is displayed for each object before the Shell modifies the object.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Enables the function to simulate what it will do instead of actually executing.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

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

## NOTES

## RELATED LINKS