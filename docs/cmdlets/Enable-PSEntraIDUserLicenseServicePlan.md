---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/19/2026
PlatyPS schema version: 2024-05-01
title: Enable-PSEntraIDUserLicenseServicePlan
---

# Enable-PSEntraIDUserLicenseServicePlan

## SYNOPSIS

Enable service plan of user's sku subscription.

## SYNTAX

### InputObjectSkuPartNumberPlanName (Default)

```
Enable-PSEntraIDUserLicenseServicePlan -InputObject <User[]> -SkuPartNumber <string>
 -ServicePlanName <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectSkuPartNumberPlanId

```
Enable-PSEntraIDUserLicenseServicePlan -InputObject <User[]> -SkuPartNumber <string>
 -ServicePlanId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectSkuIdServicePlanName

```
Enable-PSEntraIDUserLicenseServicePlan -InputObject <User[]> -SkuId <string>
 -ServicePlanName <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectSkuIdServicePlanId

```
Enable-PSEntraIDUserLicenseServicePlan -InputObject <User[]> -SkuId <string>
 -ServicePlanId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentitySkuPartNumberPlanName

```
Enable-PSEntraIDUserLicenseServicePlan -Identity <string[]> -SkuPartNumber <string>
 -ServicePlanName <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentitySkuPartNumberPlanId

```
Enable-PSEntraIDUserLicenseServicePlan -Identity <string[]> -SkuPartNumber <string>
 -ServicePlanId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentitySkuIdServicePlanName

```
Enable-PSEntraIDUserLicenseServicePlan -Identity <string[]> -SkuId <string>
 -ServicePlanName <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentitySkuIdServicePlanId

```
Enable-PSEntraIDUserLicenseServicePlan -Identity <string[]> -SkuId <string>
 -ServicePlanId <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Enable service plan of user's sku subscription.

## EXAMPLES

### EXAMPLE 1

Enable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

Enable service plan Office Pro Plus, Exchange Online of subscription ENTERPRISEPACK for user username@contoso.com

## PARAMETERS

### -Confirm

Prompts for confirmation before the command makes a change.
-Confirm:$false
suppresses that prompt.

Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
prompts even alongside -Force, and the two are alternatives rather than a pair.

Left unbound, the decision belongs to this command's ConfirmImpact and the
session ConfirmPreference, which is the PowerShell default behaviour.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

This parameter disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly, but allows catching exceptions in calling scripts.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Force

Suppresses the confirmation prompt, for unattended use.

An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
prompts even with -Force present.
The two are therefore alternatives rather
than a pair - passing both says nothing the second one does not already say.

Without either, whether the command prompts is left to its ConfirmImpact and
the session ConfirmPreference, which is the PowerShell default behaviour.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Identity

UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- UserPrincipalName
- Mail
ParameterSets:
- Name: IdentitySkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentitySkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentitySkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentitySkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObject

PSMicrosoftEntraID.Users.User object in tenant/directory.

```yaml
Type: PSMicrosoftEntraID.Users.User[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: InputObjectSkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PassThru

When specified, the cmdlet will not execute the action but will instead
return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServicePlanId

Service plan Id of subscribedSku.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentitySkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentitySkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServicePlanName

Friendly service plan name of subscribedSku.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentitySkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentitySkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SkuId

Office 365 product GUID is identified using a GUID of subscribedSku.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentitySkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentitySkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuIdServicePlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SkuPartNumber

Friendly name Office 365 product of subscribedSku.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentitySkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentitySkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuPartNumberPlanName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectSkuPartNumberPlanId
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -WhatIf

Enables the function to simulate what it will do instead of actually executing.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### PSMicrosoftEntraID.Users.User[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.Request

{{ Fill in the Description }}

## NOTES

Graph's assignLicense REPLACES the disabledPlans list on every call - there is no
server-side merge and no ETag.
This cmdlet reads the user's current disabled
plans and removes the requested ones from that list.
With -Identity that read
happens inside the call, and a read seconds after a previous write can hit a
directory replica the write has not reached yet - in which case the merge starts
from stale state and the earlier change is lost.
Name every plan in one call, or
pass -InputObject with a user object whose AssignedLicenses reflect the state you
mean to merge into; either pattern is deterministic.


## RELATED LINKS

{{ Fill in the related links here }}

