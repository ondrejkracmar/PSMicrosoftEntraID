---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/19/2026
PlatyPS schema version: 2024-05-01
title: Remove-PSEntraIDAdministrativeUnitMember
---

# Remove-PSEntraIDAdministrativeUnitMember

## SYNOPSIS

Remove a member from an administrative unit.

## SYNTAX

### IdentityInputObjectUser (Default)

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -InputObjectUser <User[]>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityInputObjectDevice

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -InputObjectDevice <Device[]>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityInputObjectGroup

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -InputObjectGroup <Group[]>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityDevice

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -Device <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityGroup

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -Group <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityUser

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -User <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Remove a member from an administrative unit.
This cmdlet can remove users, groups, and devices from administrative units.

## EXAMPLES

### EXAMPLE 1

Remove-PSEntraIDAdministrativeUnitMember -Identity "Marketing AU" -User "user1@contoso.com","user2@contoso.com"

Remove users from administrative unit "Marketing AU"

### EXAMPLE 2

Remove-PSEntraIDAdministrativeUnitMember -Identity "Finance AU" -Group "Finance-Team"

Remove a group from administrative unit "Finance AU"

### EXAMPLE 3

Get-PSEntraIDAdministrativeUnit -DisplayName "HR AU" | Remove-PSEntraIDAdministrativeUnitMember -User "former-employee@contoso.com"

Remove a user from administrative unit "HR AU" using pipeline

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

### -Device

DisplayName or Id of the device attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityDevice
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -EnableException

This parameter disables user-friendly warnings and enables the throwing of exceptions.
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

### -Group

DisplayName, MailNickName or Id of the group attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Identity

DisplayName or Id of the administrative unit.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- AdministrativeUnitId
ParameterSets:
- Name: IdentityInputObjectDevice
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentityInputObjectGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentityInputObjectUser
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentityDevice
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentityGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: IdentityUser
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObjectDevice

Device object(s) to remove from the administrative unit.

```yaml
Type: System.Object[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityInputObjectDevice
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObjectGroup

Group object(s) to remove from the administrative unit.

```yaml
Type: PSMicrosoftEntraID.Groups.Group[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityInputObjectGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -InputObjectUser

User object(s) to remove from the administrative unit.

```yaml
Type: PSMicrosoftEntraID.Users.User[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityInputObjectUser
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

When specified, the cmdlet will not execute the remove member action but will instead
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

### -User

UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUser
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

### PSMicrosoftEntraID.Groups.Group[]

{{ Fill in the Description }}

### System.Object[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.Request

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

