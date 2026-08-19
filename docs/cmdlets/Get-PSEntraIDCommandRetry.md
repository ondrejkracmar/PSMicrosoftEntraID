---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/19/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDCommandRetry
---

# Get-PSEntraIDCommandRetry

## SYNOPSIS

Returns the current retry configuration values used in protected commands.

## SYNTAX

### __AllParameterSets

```
Get-PSEntraIDCommandRetry
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Loads the RetryCount and RetryWaitInSeconds from PSFramework configuration
and returns them as a hashtable.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDCommandRetry

Returns:
@{
    RetryCount = 3
    RetryWaitInSeconds = 5
}

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Collections.Hashtable

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

