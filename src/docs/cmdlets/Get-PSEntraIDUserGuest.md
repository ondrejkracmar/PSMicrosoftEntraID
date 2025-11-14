---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDUserGuest
---

# Get-PSEntraIDUserGuest

## SYNOPSIS

Retrieves properties of users in Entra ID (Azure AD), but only Guest accounts.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDUserGuest -Identity <string[]> [-EnableException] [<CommonParameters>]
```

### Name

```
Get-PSEntraIDUserGuest -Name <string[]> [-EnableException] [<CommonParameters>]
```

### CompanyName

```
Get-PSEntraIDUserGuest -CompanyName <string[]> [-Disabled] [-EnableException] [<CommonParameters>]
```

### All

```
Get-PSEntraIDUserGuest -All [-Disabled] [-EnableException] [<CommonParameters>]
```

### Filter

```
Get-PSEntraIDUserGuest -Filter <string> [-AdvancedFilter] [-EnableException] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Cmdlet for retrieving users with "userType eq 'Guest'".
Supports multiple parameter sets (Identity, Name, CompanyName, Filter, All)
and always returns only Guest accounts.

## EXAMPLES

### EXAMPLE 1

Get-PSEntraIDUserGuest -Identity user1@contoso.com
Returns details for user1@contoso.com, only if it is a Guest account.

### EXAMPLE 2

Get-PSEntraIDUserGuest -All
Returns all Guest accounts in the tenant.

## PARAMETERS

### -AdvancedFilter

Enables the use of the ConsistencyLevel = 'eventual' header (e.g., for $count).

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

Returns all users in the tenant, but only those with "userType eq 'Guest'".

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

CompanyName of the user in the tenant.

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

Returns only disabled accounts (accountEnabled eq false).

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

Enables exception throwing instead of friendly warnings.

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

Custom OData filter expression for filtering users, combined with "userType eq 'Guest'".

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

UserPrincipalName, Mail, or Id of the user in the tenant.
If the user exists but is not a Guest, no output is returned.

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

DisplayName, GivenName, or SurName of the user in the tenant.

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

### PSMicrosoftEntraID.Users.UserGuest

{{ Fill in the Description }}

## NOTES

Author: Your Name
Last Updated: 2025-03-06


## RELATED LINKS

{{ Fill in the related links here }}

