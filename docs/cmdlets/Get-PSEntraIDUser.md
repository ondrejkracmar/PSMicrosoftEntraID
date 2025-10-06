---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDUser
---

# Get-PSEntraIDUser

## SYNOPSIS

Get the properties of the specified user.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDUser -Identity <string[]> [-EnableException] [<CommonParameters>]
```

### Name

```
Get-PSEntraIDUser -Name <string[]> [-EnableException] [<CommonParameters>]
```

### CompanyName

```
Get-PSEntraIDUser -CompanyName <string[]> [-Disabled] [-EnableException] [<CommonParameters>]
```

### All

```
Get-PSEntraIDUser -All [-Disabled] [-EnableException] [<CommonParameters>]
```

### Filter

```
Get-PSEntraIDUser -Filter <string> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Get the properties of the specified user.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDUser -Identity user1@contoso.com

Get properties of Azure AD user user1@contoso.com

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

### -All

Return all accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: true
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
Aliases: []
ParameterSets:
- Name: CompanyName
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Disabled

Return disabled accounts in tenant/directory.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: All
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: CompanyName
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
- Name: Identity
  Position: Named
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Name

DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Name
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

