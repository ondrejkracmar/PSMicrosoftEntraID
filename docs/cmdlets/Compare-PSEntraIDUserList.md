---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Compare-PSEntraIDUserList
---

# Compare-PSEntraIDUserList

## SYNOPSIS

Compare two list user of user.

## SYNTAX

### UserIdentity (Default)

```
Compare-PSEntraIDUserList -ReferenceIdentity <string[]> -DifferenceIdentity <string[]>
 [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Compare two list user of user.

## EXAMPLES

### EXAMPLE 1

Compare-PSEntraIDUserList -ReferenceIdentity $UserList1 -DifferenceIdentity $UserList2

Remove memebr to Azure AD group group1

## PARAMETERS

### -DifferenceIdentity

Difference list of users

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: UserIdentity
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ReferenceIdentity

Reference list of users

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: UserIdentity
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

## OUTPUTS

### System.Collections.ArrayList

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

