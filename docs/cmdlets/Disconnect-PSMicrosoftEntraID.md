---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/18/2026
PlatyPS schema version: 2024-05-01
title: Disconnect-PSMicrosoftEntraID
---

# Disconnect-PSMicrosoftEntraID

## SYNOPSIS

Disconnect from an Microsoft EntraID Service.

## SYNTAX

### __AllParameterSets

```
Disconnect-PSMicrosoftEntraID [[-Service] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Disconnect from an Microsoft EntraID Service.

## EXAMPLES

### EXAMPLE 1

Disconnect-PSMicrosoftEntraID

Disconnects the current session from the default Microsoft EntraID service.

## PARAMETERS

### -Service

The service for which to retrieve the token.
Defaults to: Default Service

```yaml
Type: System.String
DefaultValue: $script:_DefaultService
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
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

## OUTPUTS

### System.Void

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

