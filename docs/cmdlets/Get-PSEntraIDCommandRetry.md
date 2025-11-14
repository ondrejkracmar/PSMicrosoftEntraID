---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

