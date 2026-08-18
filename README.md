# PSMicrosoftEntraID

A PowerShell module for administering Microsoft Entra ID (formerly Azure Active Directory)
over Microsoft Graph: users and guests, groups and their membership, administrative units,
contacts, devices, organization and Message Center, and licence assignment down to
individual service plans.

## Why this module

Anyone can wrap `Invoke-RestMethod` around a Graph endpoint. What costs time is everything
around it, and that is where most of the work here has gone.

**Typed output, not a heap of PSCustomObject.** Every cmdlet returns a real .NET type from
the module's compiled library, with `types`/`views` XML behind it and an `[OutputType]` on
every exported function. `Get-PSEntraIDUser` returns a `PSMicrosoftEntraID.Users.User`, not
whatever shape the JSON happened to have on the day you wrote your script. Your code binds
to properties that exist, your IDE completes them, and a change in the Graph response
surfaces as a conversion problem rather than as a `$null` three functions downstream.

**Writes ask before they act.** Every cmdlet that changes the directory declares
`SupportsShouldProcess` with an explicit `ConfirmImpact`, so `-WhatIf` and `-Confirm` work
the way PowerShell users expect. Rarer than that: the interaction between `-Force`,
`-Confirm` and `$ConfirmPreference` is pinned by its own tests, written after a defect in
exactly that logic made every cmdlet prompt when it should not have.

**Throttling handled at both levels.** Graph throttles requests, and it also throttles
individual sub-requests *inside* a `$batch` — reporting those in the response body while
the envelope still comes back HTTP 200. Retry logic that inspects the HTTP status never
sees the second kind, and silently drops work in the one feature built for bulk
operations. This module retries both, honouring Graph's own `Retry-After` where it sends
one. It is the kind of thing that only shows up on a large tenant, which is exactly when
you cannot afford it.

**Incremental reads with sessions you can persist.** The `Get-PSEntraID*Delta` cmdlets
wrap Graph's delta endpoints: the first call returns everything and stores a token, and
every call after that returns only what changed — including what was *removed*, which a
full read cannot tell you. The token lives in a plain hashtable that
`Export-PSEntraIDDeltaSession` and `Import-PSEntraIDDeltaSession` write to and read from
disk, so a scheduled task picks up where the last run left off instead of re-reading the
tenant every night.

**Sovereign clouds are not an afterthought.** Service URLs are configurable and no Graph
endpoint is hard-coded, so US Government and China deployments are addressable rather than
theoretical.

## Prerequisites

- PowerShell **7.2 or later**. Windows PowerShell 5.1 is **not** supported — the module
  ships a `net8.0` library that Desktop edition cannot load.
- A Microsoft Entra ID tenant and an app registration with the permissions for what you
  intend to do. See [API Permissions](docs/authentication/api-permissions.md) and
  [Cmdlet Permissions](docs/authentication/cmdlet-permissions.md).
- The [PSFramework](https://github.com/PowershellFrameworkCollective/psframework) module,
  installed automatically as a dependency.

## Installation

```powershell
Install-Module -Name PSMicrosoftEntraID -Scope CurrentUser
Import-Module PSMicrosoftEntraID
```

## Getting started

### Connect

```powershell
# Interactive browser sign-in
Connect-PSMicrosoftEntraID -ClientID 'your-app-id' -TenantID 'your-tenant-id' -Browser

# Device code, for a host with no browser
Connect-PSMicrosoftEntraID -ClientID 'your-app-id' -TenantID 'your-tenant-id' -DeviceCode

# App-only with a client secret. The parameter takes a SecureString - the secret never
# has to appear as a literal in your script or in your session history.
$secret = Read-Host -AsSecureString 'Client secret'
Connect-PSMicrosoftEntraID -ClientID 'your-app-id' -TenantID 'your-tenant-id' -ClientSecret $secret

# App-only with a certificate
Connect-PSMicrosoftEntraID -ClientID 'your-app-id' -TenantID 'your-tenant-id' -CertificateThumbprint '0123...'
```

Other supported flows: managed identity, Azure CLI/Az session, refresh token, workload
identity federation. See the [Authentication Overview](docs/authentication/overview.md).

### Users

```powershell
# One user, by UPN, mail or object id
Get-PSEntraIDUser -Identity 'john.doe@contoso.com'

# Every user in the tenant
Get-PSEntraIDUser -All

# Server-side filter
Get-PSEntraIDUser -Filter "startswith(displayName,'John')"

# By company, disabled accounts only
Get-PSEntraIDUser -CompanyName 'Contoso' -Disabled
```

```powershell
# Create a user. Password is a SecureString, and AccountEnabled is a [bool].
$password = Read-Host -AsSecureString 'Initial password'
New-PSEntraIDUser -DisplayName 'Jane Smith' `
                  -UserPrincipalName 'jane.smith@contoso.com' `
                  -MailNickname 'jane.smith' `
                  -Password $password `
                  -AccountEnabled $true

# Update properties
Set-PSEntraIDUser -Identity 'jane.smith@contoso.com' -Department 'IT' -JobTitle 'System Administrator'

# Usage location, which licensing requires. Either the two-letter code or the country name.
Set-PSEntraIDUserUsageLocation -Identity 'jane.smith@contoso.com' -UsageLocationCode 'US'
Set-PSEntraIDUserUsageLocation -Identity 'jane.smith@contoso.com' -UsageLocationCountry 'United States'

# Groups the user belongs to
Get-PSEntraIDUserMemberOf -Identity 'jane.smith@contoso.com'
```

### Guests

```powershell
# Invite one
New-PSEntraIDInvitation -InvitedUserEmailAddress 'external@partner.com' `
                        -InviteRedirectUrl 'https://myapps.microsoft.com'

# Every guest in the tenant
Get-PSEntraIDUserGuest -All
```

Guests carry an `Identities` collection — Graph's
[objectIdentity](https://learn.microsoft.com/en-us/graph/api/resources/objectidentity)
resource — which is what actually says where the account signs in from. The `#EXT#` user
principal name only looks like it does: it is a mangled copy of the address the invitation
went to, it does not follow the guest renaming themselves at home, and for a social
account it says nothing about the provider.

```powershell
# Where do our guests actually come from?
Get-PSEntraIDUserGuest -All | Group-Object HomeIssuer -NoElement | Sort-Object Count -Descending

# Find one guest by their home identity, whatever their UPN in this tenant is
Get-PSEntraIDUserGuest -Issuer 'contoso.com' -IssuerAssignedId 'j.smith@contoso.com'

# Every guest signing in with a Google identity
Get-PSEntraIDUserGuest -Issuer 'google.com'
```

> Graph matches an issuer on its own only for `google.com`, `facebook.com`, `mail` and
> `phone`. For any other issuer supply `-IssuerAssignedId` as well — without it the
> request comes back empty rather than failing, and the cmdlet warns to say so.

### Groups

```powershell
# Security group
New-PSEntraIDGroup -Displayname 'IT Security Team' -MailNickname 'it-security' -SecurityEnabled $true

# Microsoft 365 group
New-PSEntraIDGroup -Displayname 'Project Alpha' -MailNickname 'project-alpha' `
                   -GroupTypes 'Unified' -MailEnabled $true -SecurityEnabled $false

Set-PSEntraIDGroup -Identity 'it-security' -Description 'Security team for IT operations'
```

```powershell
# Membership. The member parameter is -User on all four of these.
Add-PSEntraIDGroupMember    -Identity 'it-security' -User 'john.doe@contoso.com'
Remove-PSEntraIDGroupMember -Identity 'it-security' -User 'john.doe@contoso.com'
Add-PSEntraIDGroupOwner     -Identity 'it-security' -User 'manager@contoso.com'
Remove-PSEntraIDGroupOwner  -Identity 'it-security' -User 'manager@contoso.com'

Get-PSEntraIDGroupMember -Identity 'it-security'
Get-PSEntraIDGroupMember -Identity 'it-security' -Owner
```

```powershell
# Make a group's membership match a list of users: adds what is missing, removes the rest.
# -SyncView reports what it would do without touching anything.
Sync-PSEntraIDGroupMember -DifferenceIdentity 'it-security' `
                          -ReferenceUserIdentity 'user1@contoso.com', 'user2@contoso.com' `
                          -SyncView

# Make one group's membership match another group's
Sync-PSEntraIDGroupMember -ReferenceIdentity 'hr-all' -DifferenceIdentity 'hr-mailing'
```

### Licences

```powershell
# What the tenant owns
Get-PSEntraIDSubscribedLicense

# What one user holds, in detail
Get-PSEntraIDUserLicenseDetail -Identity 'john.doe@contoso.com'

# Who holds a given SKU. This cmdlet queries BY LICENCE, not by user.
Get-PSEntraIDUserLicense -SkuPartNumber 'ENTERPRISEPACK'
Get-PSEntraIDUserLicense -ServicePlanName 'TEAMS1'
Get-PSEntraIDUserLicense -CompanyName 'Contoso' -SkuPartNumber 'ENTERPRISEPACK'
```

```powershell
# Assign and remove, per user
Enable-PSEntraIDUserLicense  -Identity 'john.doe@contoso.com' -SkuPartNumber 'ENTERPRISEPACK'
Disable-PSEntraIDUserLicense -Identity 'john.doe@contoso.com' -SkuPartNumber 'ENTERPRISEPACK'

# Individual service plans within a SKU
Enable-PSEntraIDUserLicenseServicePlan  -Identity 'john.doe@contoso.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'TEAMS1'
Disable-PSEntraIDUserLicenseServicePlan -Identity 'john.doe@contoso.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'TEAMS1'

# The same, group-based
Enable-PSEntraIDGroupLicense  -Identity 'it-security' -SkuPartNumber 'ENTERPRISEPACK'
Get-PSEntraIDGroupLicenseDetail -Identity 'it-security'
```

A worked example — licence every unlicensed user in one department:

```powershell
$users = Get-PSEntraIDUser -Filter "department eq 'IT'"

foreach ($user in $users) {
    # Returns one SubscriptionSku per licence held, so nothing back means unlicensed.
    if (@(Get-PSEntraIDUserLicenseDetail -Identity $user.UserPrincipalName).Count -gt 0) { continue }

    # Usage location first - Graph refuses the assignment without one.
    Set-PSEntraIDUserUsageLocation -Identity $user.UserPrincipalName -UsageLocationCode 'US' -Force
    Enable-PSEntraIDUserLicense    -Identity $user.UserPrincipalName -SkuPartNumber 'ENTERPRISEPACK' -Force
}
```

### Administrative units

```powershell
New-PSEntraIDAdministrativeUnit -DisplayName 'Sales Department' -Description 'Administrative unit for sales'

Add-PSEntraIDAdministrativeUnitMember    -Identity 'Sales Department' -User 'sales1@contoso.com'
Get-PSEntraIDAdministrativeUnitMember    -Identity 'Sales Department'
Remove-PSEntraIDAdministrativeUnitMember -Identity 'Sales Department' -User 'sales1@contoso.com'
```

### Delta — reading only what changed

```powershell
# First call returns everything and stores a token in the session hashtable.
$session = @{}
$users = Get-PSEntraIDUserDelta -DeltaSession $session

# Every call after that returns only what changed since, removals included.
$changed = Get-PSEntraIDUserDelta -DeltaSession $session
$changed | Where-Object Removed
```

For a scheduled task, persist the session between runs:

```powershell
$session = if (Test-Path .\users.delta.json) { Import-PSEntraIDDeltaSession -Path .\users.delta.json } else { @{} }

Get-PSEntraIDUserDelta -DeltaSession $session | ForEach-Object { <# ... #> }

Export-PSEntraIDDeltaSession -DeltaSession $session -Path .\users.delta.json -Force
```

The same shape exists for groups, devices, contacts and administrative units:
`Get-PSEntraIDGroupDelta`, `Get-PSEntraIDDeviceDelta`, `Get-PSEntraIDContactDelta`,
`Get-PSEntraIDAdministrativeUnitDelta`. Add `-MinimalDelta` to have Graph return only the
properties that changed.

### Batch requests

Cmdlets that write accept `-PassThru`, which returns a
`PSMicrosoftEntraID.Batch.Request` describing the call instead of making it. Collect those
and send them in one round trip:

```powershell
$requests = @(
    Disable-PSEntraIDUserLicense -Identity 'user1@contoso.com' -SkuPartNumber 'ENTERPRISEPACK' -PassThru
    Disable-PSEntraIDUserLicense -Identity 'user2@contoso.com' -SkuPartNumber 'ENTERPRISEPACK' -PassThru
    Set-PSEntraIDUser           -Identity 'user3@contoso.com' -Department 'HR' -PassThru
)

# New-PSEntraIDBatchRequest packs the requests into payloads of at most 20, which is
# Graph's own limit, so a list of any length is fine.
$results = $requests | New-PSEntraIDBatchRequest | Invoke-PSEntraIDBatchRequest

$results | Where-Object Status -ge 400
```

Sub-requests that Graph throttles are re-sent rather than dropped, and any that fail for
another reason come back with their status rather than passing silently.

### Anything not wrapped yet

```powershell
Invoke-PSEntraIDRequest -Path 'users/john.doe@contoso.com/authentication/methods' -Method Get
```

### Retry behaviour

```powershell
Set-PSEntraIDCommandRetry -RetryCount 5 -RetryWaitInSeconds 2
Get-PSEntraIDCommandRetry
```

## Documentation

### Authentication and setup
- [Authentication Overview](docs/authentication/overview.md)
- [Creating Applications](docs/authentication/creating-applications.md)
- [Managing Applications](docs/authentication/managing-applications.md)
- [API Permissions](docs/authentication/api-permissions.md)
- [Cmdlet Permissions](docs/authentication/cmdlet-permissions.md)
- [Application vs Delegated Permissions](docs/authentication/application-vs-delegate.md)

Per-method guides:
[Browser](docs/authentication/authenticate-browser.md) ·
[Device code](docs/authentication/authenticate-devicecode.md) ·
[Client secret](docs/authentication/authenticate-clientsecret.md) ·
[Certificate](docs/authentication/authenticate-certificate.md)

### Cmdlet reference

#### Connection
- [Connect-PSMicrosoftEntraID](docs/cmdlets/Connect-PSMicrosoftEntraID.md)
- [Disconnect-PSMicrosoftEntraID](docs/cmdlets/Disconnect-PSMicrosoftEntraID.md)

#### Users and guests
- [Get-PSEntraIDUser](docs/cmdlets/Get-PSEntraIDUser.md)
- [Get-PSEntraIDUserGuest](docs/cmdlets/Get-PSEntraIDUserGuest.md)
- [Get-PSEntraIDUserMemberOf](docs/cmdlets/Get-PSEntraIDUserMemberOf.md)
- [New-PSEntraIDUser](docs/cmdlets/New-PSEntraIDUser.md)
- [Set-PSEntraIDUser](docs/cmdlets/Set-PSEntraIDUser.md)
- [Set-PSEntraIDUserUsageLocation](docs/cmdlets/Set-PSEntraIDUserUsageLocation.md)
- [Remove-PSEntraIDUser](docs/cmdlets/Remove-PSEntraIDUser.md)
- [New-PSEntraIDInvitation](docs/cmdlets/New-PSEntraIDInvitation.md)
- [Compare-PSEntraIDUserList](docs/cmdlets/Compare-PSEntraIDUserList.md)

#### Groups
- [Get-PSEntraIDGroup](docs/cmdlets/Get-PSEntraIDGroup.md)
- [Get-PSEntraIDGroupAdditionalProperty](docs/cmdlets/Get-PSEntraIDGroupAdditionalProperty.md)
- [Get-PSEntraIDGroupMember](docs/cmdlets/Get-PSEntraIDGroupMember.md)
- [New-PSEntraIDGroup](docs/cmdlets/New-PSEntraIDGroup.md)
- [Set-PSEntraIDGroup](docs/cmdlets/Set-PSEntraIDGroup.md)
- [Remove-PSEntraIDGroup](docs/cmdlets/Remove-PSEntraIDGroup.md)
- [Add-PSEntraIDGroupMember](docs/cmdlets/Add-PSEntraIDGroupMember.md)
- [Remove-PSEntraIDGroupMember](docs/cmdlets/Remove-PSEntraIDGroupMember.md)
- [Add-PSEntraIDGroupOwner](docs/cmdlets/Add-PSEntraIDGroupOwner.md)
- [Remove-PSEntraIDGroupOwner](docs/cmdlets/Remove-PSEntraIDGroupOwner.md)
- [Sync-PSEntraIDGroupMember](docs/cmdlets/Sync-PSEntraIDGroupMember.md)

#### Administrative units
- [Get-PSEntraIDAdministrativeUnit](docs/cmdlets/Get-PSEntraIDAdministrativeUnit.md)
- [Get-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Get-PSEntraIDAdministrativeUnitMember.md)
- [New-PSEntraIDAdministrativeUnit](docs/cmdlets/New-PSEntraIDAdministrativeUnit.md)
- [Set-PSEntraIDAdministrativeUnit](docs/cmdlets/Set-PSEntraIDAdministrativeUnit.md)
- [Remove-PSEntraIDAdministrativeUnit](docs/cmdlets/Remove-PSEntraIDAdministrativeUnit.md)
- [Add-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Add-PSEntraIDAdministrativeUnitMember.md)
- [Remove-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Remove-PSEntraIDAdministrativeUnitMember.md)

#### Licences
- [Get-PSEntraIDSubscribedLicense](docs/cmdlets/Get-PSEntraIDSubscribedLicense.md)
- [Get-PSEntraIDLicenseIdentifier](docs/cmdlets/Get-PSEntraIDLicenseIdentifier.md)
- [Get-PSEntraIDUsageLocation](docs/cmdlets/Get-PSEntraIDUsageLocation.md)
- [Get-PSEntraIDUserLicense](docs/cmdlets/Get-PSEntraIDUserLicense.md)
- [Get-PSEntraIDUserLicenseDetail](docs/cmdlets/Get-PSEntraIDUserLicenseDetail.md)
- [Enable-PSEntraIDUserLicense](docs/cmdlets/Enable-PSEntraIDUserLicense.md)
- [Disable-PSEntraIDUserLicense](docs/cmdlets/Disable-PSEntraIDUserLicense.md)
- [Enable-PSEntraIDUserLicenseServicePlan](docs/cmdlets/Enable-PSEntraIDUserLicenseServicePlan.md)
- [Disable-PSEntraIDUserLicenseServicePlan](docs/cmdlets/Disable-PSEntraIDUserLicenseServicePlan.md)
- [Get-PSEntraIDGroupLicense](docs/cmdlets/Get-PSEntraIDGroupLicense.md)
- [Get-PSEntraIDGroupLicenseDetail](docs/cmdlets/Get-PSEntraIDGroupLicenseDetail.md)
- [Enable-PSEntraIDGroupLicense](docs/cmdlets/Enable-PSEntraIDGroupLicense.md)
- [Disable-PSEntraIDGroupLicense](docs/cmdlets/Disable-PSEntraIDGroupLicense.md)
- [Enable-PSEntraIDGroupLicenseServicePlan](docs/cmdlets/Enable-PSEntraIDGroupLicenseServicePlan.md)
- [Disable-PSEntraIDGroupLicenseServicePlan](docs/cmdlets/Disable-PSEntraIDGroupLicenseServicePlan.md)

#### Delta
- [Get-PSEntraIDUserDelta](docs/cmdlets/Get-PSEntraIDUserDelta.md)
- [Get-PSEntraIDGroupDelta](docs/cmdlets/Get-PSEntraIDGroupDelta.md)
- [Get-PSEntraIDDeviceDelta](docs/cmdlets/Get-PSEntraIDDeviceDelta.md)
- [Get-PSEntraIDContactDelta](docs/cmdlets/Get-PSEntraIDContactDelta.md)
- [Get-PSEntraIDAdministrativeUnitDelta](docs/cmdlets/Get-PSEntraIDAdministrativeUnitDelta.md)
- [Export-PSEntraIDDeltaSession](docs/cmdlets/Export-PSEntraIDDeltaSession.md)
- [Import-PSEntraIDDeltaSession](docs/cmdlets/Import-PSEntraIDDeltaSession.md)

#### Directory and organization
- [Get-PSEntraIDOrganization](docs/cmdlets/Get-PSEntraIDOrganization.md)
- [Get-PSEntraIDContact](docs/cmdlets/Get-PSEntraIDContact.md)
- [Get-PSEntraIDDevice](docs/cmdlets/Get-PSEntraIDDevice.md)
- [Get-PSEntraIDMessageCenter](docs/cmdlets/Get-PSEntraIDMessageCenter.md)

#### Core
- [Invoke-PSEntraIDRequest](docs/cmdlets/Invoke-PSEntraIDRequest.md)
- [Invoke-PSEntraIDBatchRequest](docs/cmdlets/Invoke-PSEntraIDBatchRequest.md)
- [New-PSEntraIDBatchRequest](docs/cmdlets/New-PSEntraIDBatchRequest.md)
- [Get-PSEntraIDCommandRetry](docs/cmdlets/Get-PSEntraIDCommandRetry.md)
- [Set-PSEntraIDCommandRetry](docs/cmdlets/Set-PSEntraIDCommandRetry.md)

## Getting help

```powershell
Get-Help Get-PSEntraIDUserGuest -Full
Get-Command -Module PSMicrosoftEntraID
```

### One known message

Piping a read cmdlet into `Select-Object -First N` logs a warning that is not a failure:

```
WARNING: [Get-PSEntraIDUser] Failed to: List users with filter '...' | The pipeline has been stopped
```

The results are correct and complete. `Select-Object -First` stops the pipeline once it
has what it asked for, and the upstream command's next write throws
`PipelineStoppedException` — normal termination, reported as an error only because the
write happens inside a protected block. The only fix that works is to buffer the whole
result before emitting any of it, which would cost streaming on every read cmdlet, so the
warning stays. Materialise first if it is in the way:

```powershell
$users = @(Get-PSEntraIDUser -All)
$users | Select-Object -First 3
```

## Contributing

Issues and pull requests are welcome. Please run the test suite before submitting:

```powershell
./src/tests/pester.ps1
```

## License

[MIT](LICENSE).
