---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDOrganization

## SYNOPSIS
Get the properties and relationships of the currently authenticated organization.

## SYNTAX

```
Get-PSEntraIDOrganization [-EnableException] [<CommonParameters>]
```

## DESCRIPTION
Get the properties and relationships of the currently authenticated organization.

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDOrganization
```

Get collection of EntraID organization

## PARAMETERS

### -EnableException
This parameters disables user-friendly warnings and enables the throwing of exceptions.
This is less user friendly,
but allows catching exceptions in calling scripts.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.Organization
## NOTES

## RELATED LINKS
