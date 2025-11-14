---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDUserLicense
---

# Get-PSEntraIDUserLicense

## SYNOPSIS

Get users who are assigned licenses

## SYNTAX

### CompanyName (Default)

```
Get-PSEntraIDUserLicense -CompanyName <string[]> [-EnableException] [<CommonParameters>]
```

### ServicePlanNameCompanyName

```
Get-PSEntraIDUserLicense -CompanyName <string[]> -ServicePlanName <string[]> [-EnableException]
 [<CommonParameters>]
```

### ServicePlanIdCompanyName

```
Get-PSEntraIDUserLicense -CompanyName <string[]> -ServicePlanId <string[]> [-EnableException]
 [<CommonParameters>]
```

### SkuPartNumberCompanyName

```
Get-PSEntraIDUserLicense -CompanyName <string[]> -SkuPartNumber <string[]> [-EnableException]
 [<CommonParameters>]
```

### SkuIdCompanyName

```
Get-PSEntraIDUserLicense -CompanyName <string[]> -SkuId <string[]> [-EnableException]
 [<CommonParameters>]
```

### SkuId

```
Get-PSEntraIDUserLicense -SkuId <string[]> [-EnableException] [<CommonParameters>]
```

### SkuPartNumber

```
Get-PSEntraIDUserLicense -SkuPartNumber <string[]> [-EnableException] [<CommonParameters>]
```

### ServicePlanId

```
Get-PSEntraIDUserLicense -ServicePlanId <string[]> [-EnableException] [<CommonParameters>]
```

### ServicePlanName

```
Get-PSEntraIDUserLicense -ServicePlanName <string[]> [-EnableException] [<CommonParameters>]
```

### Filter

```
Get-PSEntraIDUserLicense -Filter <string> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Get users who are assigned licenses with disabled and enabled service plans

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDUserLicense -Identity username@contoso.com

Get licenses of user username@contoso.com with service plans

## PARAMETERS

### -AdvancedFilter

Switch advanced filter for filtering accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filter
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CompanyName

CompanyName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Company
ParameterSets:
- Name: ServicePlanNameCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: ServicePlanIdCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: SkuPartNumberCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: SkuIdCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: CompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly,
but allows catching exceptions in calling scripts.

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

### -Filter

Filter expressions of accounts in tenant/directory.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Filter
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServicePlanId

Office 365 product GUID is identified using a GUID of ServicePlan.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ServicePlanIdCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ServicePlanId
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

Friendly name Office 365 product of ServicePlanName.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ServicePlanNameCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: ServicePlanName
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

Office 365 product GUID is identified using a GUID of SubscribedSku.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SkuIdCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: SkuId
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

Friendly name Office 365 product of SubscribedSku.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: SkuPartNumberCompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: SkuPartNumber
  Position: Named
  IsRequired: true
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

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Users.User

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

