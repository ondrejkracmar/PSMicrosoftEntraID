---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 08/18/2026
PlatyPS schema version: 2024-05-01
title: Get-PSEntraIDUserGuest
---

# Get-PSEntraIDUserGuest

## SYNOPSIS

Retrieves properties of users in Entra ID (Azure AD), but only Guest accounts.

## SYNTAX

### Identity (Default)

```
Get-PSEntraIDUserGuest -Identity <string[]> [-EnableException]
```

### Name

```
Get-PSEntraIDUserGuest -Name <string[]> [-EnableException]
```

### CompanyName

```
Get-PSEntraIDUserGuest -CompanyName <string[]> [-Disabled] [-EnableException]
```

### All

```
Get-PSEntraIDUserGuest -All [-Disabled] [-EnableException]
```

### Filter

```
Get-PSEntraIDUserGuest -Filter <string> [-AdvancedFilter] [-EnableException]
```

### Identities

```
Get-PSEntraIDUserGuest -Issuer <string> [-IssuerAssignedId <string>] [-SignInType <string>]
 [-EnableException]
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

### EXAMPLE 3

Get-PSEntraIDUserGuest -Issuer 'contoso.com' -IssuerAssignedId 'j.smith@contoso.com'

Returns the guest that signs in as j.smith@contoso.com at the Contoso tenant,
whatever their user principal name in this tenant happens to be.

### EXAMPLE 4

Get-PSEntraIDUserGuest -Issuer 'google.com'

Returns every guest signing in with a Google identity.
One of the four issuers
Graph will match without an issuerAssignedId.

### EXAMPLE 5

Get-PSEntraIDUserGuest -All | Group-Object HomeIssuer -NoElement | Sort-Object Count -Descending

Which external organizations the tenant's guests actually come from.
HomeIssuer
is read off the identities collection, so it is the issuer the guest signs in
with rather than a guess from the #EXT# user principal name.

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

### -Issuer

Matches guests whose identities collection carries this issuer - the home
organization's domain for a B2B guest ("contoso.com"), or the provider for a
social one ("google.com", "facebook.com"), or "mail" for an email one-time
passcode guest.

Graph matches an issuer on its own only for google.com, facebook.com, mail and
phone.
For any other issuer supply -IssuerAssignedId as well; without it the
request comes back empty rather than failing, and the cmdlet warns to say so.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identities
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IssuerAssignedId

The identifier the issuer assigned to the guest, normally their sign-in name at
the home organization.
Combined with -Issuer.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identities
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
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

### -SignInType

Narrows the identity match to one sign-in type, such as federated, userName or
emailAddress.
userPrincipalName is rejected: Graph documents it as unsupported
for filtering, and returns an empty set instead of an error.
Use -Identity to
look an account up by its UPN.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identities
  Position: Named
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

### System.String[]

{{ Fill in the Description }}

## OUTPUTS

### PSMicrosoftEntraID.Users.UserGuest

{{ Fill in the Description }}

## NOTES

Piping into Select-Object -First N logs a warning that is not a failure:

    WARNING: [<cmdlet>] Failed to: ...
| The pipeline has been stopped

The results are correct and complete.
Select-Object stops the pipeline once it
has what it asked for, and the next write throws PipelineStoppedException -
normal termination, reported as an error only because the write happens inside a
protected block.
Materialise first if the warning is in the way:

    $items = @(<cmdlet> ...)
    $items | Select-Object -First 3

or filter server-side with -Filter instead of trimming client-side.
Not silenced
on purpose: the only fix that works is to collect the whole result before
emitting any of it, which would cost streaming on every read.


## RELATED LINKS

{{ Fill in the related links here }}

