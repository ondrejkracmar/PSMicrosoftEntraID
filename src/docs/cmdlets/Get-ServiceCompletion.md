---
external help file:
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-ServiceCompletion

## SYNOPSIS
Returns the values to complete for.service names.

## SYNTAX

```
Get-ServiceCompletion [[-ArgumentList] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Returns the values to complete for.service names.
Use this command in argument completers.

## EXAMPLES

### EXAMPLE 1
```
Get-ServiceCompletion -ArgumentList $args
```

Returns the values to complete for.service names.

## PARAMETERS

### -ArgumentList
The arguments an argumentcompleter receives.
The third item will be the word to complete.

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.CompletionResult
## NOTES

## RELATED LINKS
