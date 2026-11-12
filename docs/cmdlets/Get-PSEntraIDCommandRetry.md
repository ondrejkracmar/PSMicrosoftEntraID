---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 11.12.2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDCommandRetry
---

# Get-PSEntraIDCommandRetry

## SYNOPSIS

Returns how often the module sends a failed Graph request again.

## SYNTAX

### __AllParameterSets

```
Get-PSEntraIDCommandRetry
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns the retry settings of the module's one retry layer as a hashtable:
RetryCount (Settings.Request.RetryCount, repetitions of a single request) and
BatchRetryCount (Settings.Batch.RetryCount, repetitions of a $batch sub-request).

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDCommandRetry

Returns:
@{
    RetryCount      = 5
    BatchRetryCount = 5
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

