---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Set-PSEntraIDCommandRetry
---

# Set-PSEntraIDCommandRetry

## SYNOPSIS

Sets default retry parameters for PSF protected commands.

## SYNTAX

### __AllParameterSets

```
Set-PSEntraIDCommandRetry [[-RetryCount] <int>] [[-RetryWaitInSeconds] <int>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Configures RetryCount and RetryWaitInSeconds used with Invoke-PSFProtectedCommand.
Ensures values are between 0 and 10.

## EXAMPLES

### EXAMPLE 1

Set-PSEntraIDCommandRetry -RetryCount 3 -RetryWaitInSeconds 5

## PARAMETERS

### -RetryCount

Number of retry attempts.
Must be between 0 and 10.

```yaml
Type: System.Int32
DefaultValue: 0
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

### -RetryWaitInSeconds

Wait time in seconds between retries.
Must be between 0 and 10.

```yaml
Type: System.Int32
DefaultValue: 0
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
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

## NOTES

Updates configuration settings under $script:ModuleName.


## RELATED LINKS

{{ Fill in the related links here }}

