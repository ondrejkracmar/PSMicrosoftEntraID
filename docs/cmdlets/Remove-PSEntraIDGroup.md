---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/19/2026
PlatyPS schema version: 2024-05-01
title: Remove-PSEntraIDGroup
---

# Remove-PSEntraIDGroup

## SYNOPSIS

Delete group

## SYNTAX

### InputObject (Default)

```
Remove-PSEntraIDGroup -InputObject <Group[]> [-EnableException] [-Force] [-PassThru] [-WhatIf]
 [-Confirm]
```

### Identity

```
Remove-PSEntraIDGroup -Identity <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf]
 [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Delete Azure AD group
      When deleted, group resources are moved to a temporary container and can be restored within 30 days.
After that time, they are permanently deleted.

## EXAMPLES

### EXAMPLE 1

Remove-PSEntraIDGroup -Identity groupname@contoso.com

Delete group groupname@contoso.com from Azure AD (Entra ID)

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

groupPrincipalName, Mail or Id of the group attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- GroupId
- TeamId
- MailNickname
ParameterSets:
- Name: Identity
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

PSMicrosoftEntraID.Groups.Group object in tenant/directory.

```yaml
Type: PSMicrosoftEntraID.Groups.Group[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: InputObject
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

### PSMicrosoftEntraID.Groups.Group[]

{{ Fill in the Description }}

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.Request

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

