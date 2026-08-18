---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/18/2026
PlatyPS schema version: 2024-05-01
title: Set-PSEntraIDGroup
---

# Set-PSEntraIDGroup

## SYNOPSIS

Updates the specified properties of a Microsoft 365 Group.

## SYNTAX

### InputObjectUpdateGroupCommon (Default)

```
Set-PSEntraIDGroup -InputObject <Group[]> [-Displayname <string>] [-Description <string>]
 [-MailNickname <string>] [-GroupTypes <string[]>] [-Visibility <string>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectUpdateDynamicGroup

```
Set-PSEntraIDGroup -InputObject <Group[]> [-MembershipRule <string>]
 [-MembershipRuleProcessingState <string>] [-EnableException] [-Force] [-PassThru] [-WhatIf]
 [-Confirm]
```

### InputObjectHideFromOutlookClients

```
Set-PSEntraIDGroup -InputObject <Group[]> [-HideFromOutlookClients <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectHideFromAddressLists

```
Set-PSEntraIDGroup -InputObject <Group[]> [-HideFromAddressLists <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectAutoSubscribeNewMembers

```
Set-PSEntraIDGroup -InputObject <Group[]> [-AutoSubscribeNewMembers <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### InputObjectAllowExternalSenders

```
Set-PSEntraIDGroup -InputObject <Group[]> [-AllowExternalSenders <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityUpdateDynamicGroup

```
Set-PSEntraIDGroup -Identity <string[]> [-MembershipRule <string>]
 [-MembershipRuleProcessingState <string>] [-EnableException] [-Force] [-PassThru] [-WhatIf]
 [-Confirm]
```

### IdentityHideFromOutlookClients

```
Set-PSEntraIDGroup -Identity <string[]> [-HideFromOutlookClients <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityHideFromAddressLists

```
Set-PSEntraIDGroup -Identity <string[]> [-HideFromAddressLists <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityAutoSubscribeNewMembers

```
Set-PSEntraIDGroup -Identity <string[]> [-AutoSubscribeNewMembers <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityAllowExternalSenders

```
Set-PSEntraIDGroup -Identity <string[]> [-AllowExternalSenders <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm]
```

### IdentityUpdateGroupCommon

```
Set-PSEntraIDGroup -Identity <string[]> [-Displayname <string>] [-Description <string>]
 [-MailNickname <string>] [-GroupTypes <string[]>] [-Visibility <string>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The `Set-PSEntraIDGroup` cmdlet allows you to modify specific properties of a Microsoft 365 Group.
Some properties can be updated together, while others require separate calls.
Additionally, certain
properties are read-only and can only be retrieved, not modified.

## EXAMPLES

### EXAMPLE 1

Set-PSEntraIDGroup -Identity "mailnickname1" -DisplayName "New Group Name" -Description "Updated group description" -Visibility "Private"

Updates the display name, description and visibility of the specified group.

### EXAMPLE 2

Set-PSEntraIDGroup -Identity "mailnickname@domain.com" -AllowExternalSenders $true

Allows external senders to send mail to the specified group.

### EXAMPLE 3

Set-PSEntraIDGroup -Identity "mailnickname1" -MembershipRule "(user.department -eq 'Sales')" -MembershipRuleProcessingState "On"

Configures the dynamic membership rule for the group and enables rule processing.

## PARAMETERS

### -AllowExternalSenders

Specifies whether external users can send messages to the group.
Note: This parameter must be set in a separate call and cannot be combined with other properties in a single `PATCH` request.

```yaml
Type: System.Nullable`1[System.Boolean]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityAllowExternalSenders
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectAllowExternalSenders
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -AutoSubscribeNewMembers

Indicates whether new members are automatically subscribed to receive email notifications.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityAutoSubscribeNewMembers
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectAutoSubscribeNewMembers
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -Description

Specifies the description of the group.
This can be updated with other properties.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Displayname

Specifies the display name of the group.
This can be updated in conjunction with other group settings.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
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

### -GroupTypes

Specifies the type of the group.
For Microsoft 365 groups, use `Unified`.
This can be combined with other parameters in the same update request.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -HideFromAddressLists

Hides the group from global address lists.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityHideFromAddressLists
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectHideFromAddressLists
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -HideFromOutlookClients

Hides the group from Outlook clients.
Note: This parameter must be updated in a separate call from other properties.

```yaml
Type: System.Nullable`1[System.Boolean]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityHideFromOutlookClients
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectHideFromOutlookClients
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

DisplayName, MailNickname, Mail or Id of the group attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- GroupId
- TeamId
ParameterSets:
- Name: IdentityUpdateDynamicGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentityHideFromOutlookClients
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentityHideFromAddressLists
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentityAutoSubscribeNewMembers
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentityAllowExternalSenders
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: IdentityUpdateGroupCommon
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
- Name: InputObjectUpdateDynamicGroup
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectHideFromOutlookClients
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectHideFromAddressLists
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectAutoSubscribeNewMembers
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectAllowExternalSenders
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MailNickname

Sets the mail alias (nickname) of the group.
This can be updated along with other modifiable properties.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MembershipRule

Defines the membership rule for a dynamic group.
This parameter is specific to dynamic groups and should be used with `MembershipRuleProcessingState`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateDynamicGroup
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateDynamicGroup
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MembershipRuleProcessingState

Sets the processing state of the membership rule.
Accepted values are `On`, `Paused`, and `Off`.
This should be used with `MembershipRule` and is specific to dynamic groups.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateDynamicGroup
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateDynamicGroup
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
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

### -Visibility

Defines the visibility of the group.
Accepted values are `Public` and `Private`.
This parameter can be updated in conjunction with other properties.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: IdentityUpdateGroupCommon
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
- Name: InputObjectUpdateGroupCommon
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

### System.String

{{ Fill in the Description }}

### System.Boolean

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Batch.Request

{{ Fill in the Description }}

## NOTES

- Properties like `AllowExternalSenders`, `AutoSubscribeNewMembers`, `HideFromAddressLists`, and `HideFromOutlookClients` must each be set in separate requests.
- Use `Set-PSEntraIDGroup` to retrieve read-only properties such as `isSubscribedByMail` and `unseenCount`.


## RELATED LINKS

{{ Fill in the related links here }}

