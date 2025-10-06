---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
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
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectUpdtaeDynamicGroup

```
Set-PSEntraIDGroup -InputObject <Group[]> [-EnableException] [-Force] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### InputObjectHideFromOutlookClients

```
Set-PSEntraIDGroup -InputObject <Group[]> [-HideFromOutlookClients <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectHideFromAddressLists

```
Set-PSEntraIDGroup -InputObject <Group[]> [-HideFromAddressLists <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectAutoSubscribeNewMembers

```
Set-PSEntraIDGroup -InputObject <Group[]> [-AutoSubscribeNewMembers <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectAllowExternalSenders

```
Set-PSEntraIDGroup -InputObject <Group[]> [-AllowExternalSenders <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityUpdtaeDynamicGroup

```
Set-PSEntraIDGroup -Identity <string[]> [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### IdentityHideFromOutlookClients

```
Set-PSEntraIDGroup -Identity <string[]> [-HideFromOutlookClients <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityHideFromAddressLists

```
Set-PSEntraIDGroup -Identity <string[]> [-HideFromAddressLists <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityAutoSubscribeNewMembers

```
Set-PSEntraIDGroup -Identity <string[]> [-AutoSubscribeNewMembers <bool>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityAllowExternalSenders

```
Set-PSEntraIDGroup -Identity <string[]> [-AllowExternalSenders <bool>] [-EnableException] [-Force]
 [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityUpdateGroupCommon

```
Set-PSEntraIDGroup -Identity <string[]> [-Displayname <string>] [-Description <string>]
 [-MailNickname <string>] [-GroupTypes <string[]>] [-Visibility <string>] [-EnableException]
 [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### IdentityUpdateDynamicGroup

```
Set-PSEntraIDGroup [-MembershipRule <string>] [-MembershipRuleProcessingState <string>]
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### InputObjectUpdateDynamicGroup

```
Set-PSEntraIDGroup [-MembershipRule <string>] [-MembershipRuleProcessingState <string>]
 [-EnableException] [-Force] [-PassThru] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The `Set-PSntraIDGroup` cmdlet allows you to modify specific properties of a Microsoft 365 Group.
Some properties can be updated together, while others require separate calls.
Additionally, certain
properties are read-only and can only be retrieved, not modified.

## EXAMPLES

### EXAMPLE 1

Set-PSntraIDGroup -GroupId "mailnickname1" -DisplayName "New Group Name" -Description "Updated group description" -Visibility "Private"

### EXAMPLE 2

Set-PSntraIDGroup -GroupId "mailnickname@domain.com" -AllowExternalSenders $true

### EXAMPLE 3

Set-PSntraIDGroup -GroupId "mailnickname1" -MembershipRule "(user.department -eq 'Sales')" -MembershipRuleProcessingState "On"

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

This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user frien
dly, but allows catching exceptions in calling scripts.

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

UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Id
- GroupId
- TeamId
ParameterSets:
- Name: IdentityUpdtaeDynamicGroup
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

PSMicrosoftEntraID.Users.User object in tenant/directory.

```yaml
Type: PSMicrosoftEntraID.Groups.Group[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: InputObjectUpdtaeDynamicGroup
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

When specified, the cmdlet will not execute the disable license action but will instead
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

## NOTES

- Properties like `AllowExternalSenders`, `AutoSubscribeNewMembers`, `HideFromAddressLists`, and `HideFromOutlookClients` must each be set in separate requests.
- Use `Set-PSntraIDGroup` to retrieve read-only properties such as `isSubscribedByMail` and `unseenCount`.


## RELATED LINKS

{{ Fill in the related links here }}

