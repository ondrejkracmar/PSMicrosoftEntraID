---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Get-PSEntraIDUserLicenseDetail

## SYNOPSIS
Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

## SYNTAX

```
Get-PSEntraIDUserLicenseDetail -Identity <String[]> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## DESCRIPTION
Return details for licenses that are directly assigned and those transitively assigned through memberships in licensed groups.

## EXAMPLES

### EXAMPLE 1
```
Get-PSEntraIDUserLicenseDetail -Identity user@domain.com
```

Get Office 365 subscriptions with their service plansPlans of specific user

## PARAMETERS

### -AdvancedFilter
{{ Fill AdvancedFilter Description }}

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

### -Identity
UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases: Id, UserPrincipalName, Mail

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku
## NOTES

## RELATED LINKS
