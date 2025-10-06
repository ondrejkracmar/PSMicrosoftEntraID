---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
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
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityInputObjectDevice

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -InputObjectDevice <Device[]>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityInputObjectGroup

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -InputObjectGroup <Group[]>
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityDevice

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -Device <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityGroup

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -Group <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityUser

```
Remove-PSEntraIDAdministrativeUnitMember -Identity <string> -User <string[]> [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
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

The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
The command then prompts you to acknowledge each action before it continues.
When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
A confirmation prompt is displayed for each object before the Shell modifies the object.

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

### -Force

The Force switch instructs the command to which it is applied to stop processing before any changes are made.
The command then prompts you to acknowledge each action before it continues.
When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
A confirmation prompt is displayed for each object before the Shell modifies the object.

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

{{ Fill InputObjectDevice Description }}

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

{{ Fill InputObjectGroup Description }}

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

{{ Fill InputObjectUser Description }}

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

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

