# Changelog

## Unreleased

### Added (internal)

- **Parallel Graph `$batch` engine and a single retry policy, ported from PSExchangeOnline -
  not yet wired into any cmdlet (phase A).** `Invoke-EntraParallelBatch` keeps
  `Settings.Batch.ThrottleLimit` (default 4) envelopes of 20 in flight, retries each
  sub-request on its own `Retry-After`, follows next links per key (refusing a link to
  another host) and can return typed objects straight from the JSON text
  (`-ElementType`, `PSMicrosoftEntraID.Serialization.GraphJson`, no `-Depth 4` round trip).
  `Invoke-EntraRetry` / `Test-EntraRetryStatus` are the one retry layer phase B moves
  `Invoke-EntraRequest` onto. New settings `Settings.Batch.ThrottleLimit`,
  `Settings.Batch.RetryCount`, `Settings.Request.RetryCount`, `Settings.Request.TimeoutSeconds`.
  New xUnit project `src/library/PSMicrosoftEntraID.Tests` (not run by CI yet). See
  `docs/internal/batch-engine.md`.

## 1.5.1 (2026-09-07)

### Fixed

- **The administrative-unit reads asked Graph for a property the resource does not have.**
  `Settings.GraphApiQuery.Select.AdministrativeUnit` carried `createdDateTime`, which
  exists on user and group but NOT on `administrativeUnit`, so Graph answered every
  `Get-PSEntraIDAdministrativeUnit` / `Get-PSEntraIDAdministrativeUnitDelta` call with
  `Request_UnsupportedQuery` ("Invalid property: createdDateTime") and the whole read
  failed - in production this took down the AU leg of an inventory sync, which then
  looked like a missing `AdministrativeUnit.Read.All` consent. The property is gone and
  `membershipType`, `membershipRule` and `membershipRuleProcessingState` (real AU
  properties, they describe a dynamic unit) joined the list. New
  `src/tests/general/GraphSelectProperties.Tests.ps1` asserts the SHIPPED default
  against the resource's property set - the per-cmdlet tests mock the config away, so
  nothing caught this.

## 1.5.0 (2026-09-02)

> Supersedes the tagged-but-never-published 1.4.0: its release build failed the
> file-integrity gate (bin/assembly.ps1 was rewritten without the UTF8 BOM in
> the multi-target change), so the Publish stage never ran. Everything below
> plus the whole 1.4.0 section ships here.

### Defender for Endpoint cmdlets

- **New:** `Get-PSEntraIDMachine` - MDE machines as typed
  `PSMicrosoftEntraID.DefenderEndpoint.Machine` objects; by machine id, by the
  Entra device GUID (`-DeviceId`, server-side `aadDeviceId` filter), by raw
  `-Filter`, or all. Uses the Endpoint family default service
  (`Settings.DefaultServiceEndpoint`). Counterpart naming: `*-PSEntraIDDevice`
  reads the directory device, `*-PSEntraIDMachine` reads Defender for Endpoint.
- **New:** `Add-PSEntraIDMachineTag` / `Remove-PSEntraIDMachineTag` - machine
  tag writes (`POST /machines/{id}/tags`), pipeline from `Get-PSEntraIDMachine`,
  `-PassThru` returns the updated machine.
- **New:** `Set-PSEntraIDDeviceExtensionAttribute` - sets or clears one
  `extensionAttribute1..15` on a directory device; addresses by piped device,
  object id or device GUID (`devices(deviceId='...')`), clears with null (an
  empty string would be stored literally), and composes into `$batch` via
  `-PassThru`.
- **New:** `Get-PSEntraIDDevice` lists and filters (`-Filter`) devices - it was
  Identity-only - and sends the new `Settings.GraphApiQuery.Select.Device`
  selection, `extensionAttributes` included.
- **Fixed:** UTF8 BOM restored on `bin/assembly.ps1` (the 1.4.0 build breaker)
  and stamped on all new script files.

### Connect & services

- **New:** `Connect-PSMicrosoftEntraID -Service` accepts multiple services in one
  call (e.g. Graph + Defender for Endpoint) and each service family - resolved
  through its registered resource - now keeps its own default-service setting:
  `Settings.DefaultService` (Graph), `Settings.DefaultServiceEndpoint`,
  `Settings.DefaultServiceSecurity`, `Settings.DefaultServiceAzure`,
  `Settings.DefaultServiceAzureKeyVault`. Connecting to a non-Graph service no
  longer redirects the Graph cmdlets.
- **Fixed:** every connect with an explicit `-Service` failed - the parameter
  was splatted into `Connect-EntraService` a second time next to the explicit
  argument, and the array was space-joined into `Settings.DefaultService`.
- **Fixed:** `Invoke-PSEntraIDRequest` ignored an explicitly bound `-Service`
  (the config default overrode it) and double-bound it in the splat, failing
  every call against a non-default service.
- **Changed:** the subscribed-license cache is only populated when a
  Graph-family service is among the connected services; an Endpoint-only
  connect no longer sends `subscribedSkus` to the securitycenter URL.
- **New:** docs page `authentication/defender-for-endpoint.md` - which API and
  token audience to use, WindowsDefenderATP + Graph permissions, the
  `aadDeviceId` join key and machineTags-to-extensionAttributes examples.

### Defender for Endpoint groundwork

- **New:** `PSMicrosoftEntraID.DefenderEndpoint.Machine` - a typed model for machines
  returned by the Defender for Endpoint API (service `PSMicrosoftEntraID.Endpoint`),
  including `AadDeviceId` (the join key to the directory device) and `MachineTags`.
- **New:** `ExtensionAttributes` on the device model - the fifteen
  `extensionAttribute1..15` values, the only device property an app-only caller may
  update and the target for dynamic device group rules.
- **New:** default table views and display sets for `Devices.Device` (previously had
  none) and `DefenderEndpoint.Machine`.

### Library

- **Changed:** the compiled library now multi-targets `net8.0` and `net10.0`, split
  under `bin/net8.0` and `bin/net10.0`; `bin/assembly.ps1` picks the folder matching
  the running .NET runtime (same layout as PSContainerSync). The package reference
  moved from `Microsoft.PowerShell.SDK 7.2.24` to reference-only
  `System.Management.Automation` (7.4.13 / 7.6.1), which also clears the 7.2-line
  transitive advisories noted in the csproj.
- **Changed:** minimum PowerShell version is now 7.4 (the floor of the net8.0
  reference); PowerShell 7.6+ loads the net10.0 build.

## 1.3.4 (2026-08-29)

### Fixed
- **GET sub-requests inside `$batch` always failed with 400.** The batch serializer
  projected `headers` and `body` unconditionally, and the Request class defaults both
  to an empty hashtable - so every GET sub-request went out with `"body": {}`, which
  Graph's JSON batching rejects. `headers`/`body` are now omitted when empty; write
  sub-requests (which always populate both) serialize exactly as before. Found by the
  group-inventory owner reads, where every owner set silently came back empty.

## 1.3.2 (2026-08-28)

### Group model

- **New:** `ResourceProvisioningOptions` on the group model (and thus on
  `Get-PSEntraIDGroup`/`Get-PSEntraIDGroupDelta` output) - contains `Team` when a
  Microsoft Teams team is provisioned on top of the group, the reliable way to tell a
  team from a plain Microsoft 365 group. Added to the default
  `Settings.GraphApiQuery.Select.Group` list.
- **Fixed:** `AdministrativeUnitDelta` now carries `MembersDelta`. The AU delta query
  has always selected `members`, but the type had nowhere to put `members@delta`, so
  the converter silently dropped the membership changes the request paid for.

### Guest identities

- **New:** `Identities` on the user model - the Microsoft Graph `objectIdentity` collection
  (`signInType`, `issuer`, `issuerAssignedId`), returned by `Get-PSEntraIDUser` and
  `Get-PSEntraIDUserGuest`. It is what actually says where a guest signs in from; the
  `#EXT#` user principal name only looks like it does.
- **New:** `HomeIssuer` and `SignInTypes` on `PSMicrosoftEntraID.Users.UserGuest`, derived
  from `Identities`. `HomeIssuer` is the guest's home organization or social provider, and
  is now a column in the default guest table.
- **New:** `Get-PSEntraIDUserGuest -Issuer`, `-IssuerAssignedId` and `-SignInType` - a
  server-side filter over the identities collection. `-Issuer` is required because Graph
  supports the other two only in combination with it, and a `signInType` of
  `userPrincipalName` is refused because Graph answers that filter with an empty set
  rather than an error.

### Delta queries

- **New:** `Get-PSEntraIDUserDelta`, `Get-PSEntraIDGroupDelta`, `Get-PSEntraIDDeviceDelta`,
  `Get-PSEntraIDContactDelta` and `Get-PSEntraIDAdministrativeUnitDelta` - incremental
  reads over Graph's delta endpoints. The first call returns everything and stores a
  continuation token; later calls return only what changed, removals included, which a
  full read cannot report at all. `-MinimalDelta` asks Graph for only the properties that
  changed.
- **New:** `Export-PSEntraIDDeltaSession` and `Import-PSEntraIDDeltaSession` persist the
  delta token between runs, so a scheduled task resumes instead of re-reading the tenant.
- **New:** Strongly typed delta results per resource (`UserDelta`, `GroupDelta`,
  `DeviceDelta`, `ContactDelta`, `AdministrativeUnitDelta`), each deriving from its
  ordinary type and carrying a `ChangeType` of Changed, Deleted or Purged. Graph reports
  removals through an `@removed` annotation whose `reason` reads backwards; the enum
  spares callers that.
- **New:** `Get-PSEntraIDDevice` and a real `PSMicrosoftEntraID.Devices.Device` type.
- **Fix:** The delta continuation token was parsed by splitting the whole delta link on
  `=` and keeping the last fragment. A token carrying base64 padding truncated to nothing
  - so the session stored nothing and every later run re-read the entire tenant - and a
  link whose `$deltatoken` was not the final parameter yielded the wrong value entirely.

### Batching, licensing and reliability

- **Fix:** A sub-request throttled *inside* a `$batch` is reported in the response body
  with the envelope still HTTP 200, so request-level retry never saw it and the
  sub-request was dropped - in the one feature that exists for bulk work. Throttled
  sub-requests are now re-sent, honouring Graph's own `Retry-After`, and sub-requests
  failing for any other reason are reported rather than passing silently.
- **Fix:** `Select-Object -Unique` returns a scalar for a one-element list, so
  `disabledPlans` serialized as a string and Graph rejected the request. Disabling exactly
  one service plan - the common case - never worked, on user and group cmdlets alike.
- **Fix:** Every cmdlet prompted for confirmation unless `-Force` was passed.
  `Resolve-PSEntraIDConfirmPreference` returned `$true` when neither `-Force` nor
  `-Confirm` was given, and call sites bound that as `-Confirm:$true`, which *forces* a
  prompt rather than deferring to `ConfirmImpact`.
- **Fix:** Licensing calls that found no target or no matching SKU returned silently, so a
  caller could not tell "done" from "did nothing". They warn now.
- **Fix:** 13 Graph calls inside protected blocks omitted `-ErrorAction Stop`, so a
  non-terminating failure passed straight through and the path returned nothing while
  reporting nothing.
- **Fix:** Tab completion never worked, on any parameter. The completion scriptblocks
  emitted hashtables, the registrations lacked `-Mode Full`, and the scriptblocks did not
  declare the completer parameters - which Full mode passes positionally. PowerShell
  silently fell back to completing file paths.

### Sovereign clouds and security

- **Fix:** Six `@odata.id` bindings hard-coded `https://graph.microsoft.com/v1.0`. The
  service URL is configurable, so on US Government or China deployments those bindings
  pointed at the commercial cloud. They are derived from the connected service now.
- **Fix:** `Get-PSEntraIDContact` interpolated `-Identity` and `-Name` straight into the
  OData filter. Both are free strings, so an apostrophe in a name broke the query and
  could be used to rewrite it.

### Build and packaging

- **Upd:** The pipeline is split into Build and Publish. Publish is gated on a release tag
  and routed through the Production environment, so its approval policy applies; before
  this, queueing the pipeline on any branch published a package.
- **Upd:** The suite runs on Windows and macOS as well as Linux. Cross-platform defects
  here have been real rather than theoretical - a literal `\` path separator, and a
  licence-catalog check that compared culture-sensitive sort output.
- **Upd:** The module is published to the PowerShell Gallery, and a curated tree to
  GitHub. The previous full mirror pushed every file, internal documentation included.
- **Fix:** The committed library assembly was older than the C# source it was built from,
  and the pipeline stamped the module version but not the library, so the DLL shipped as
  `1.0.0.0` regardless.
- **Fix:** The licence catalog was generated culture-sensitively, so it could only ever
  match on the machine that produced it.
- **Fix:** 40 of 54 test files never imported the module and relied on whichever file
  Pester happened to run first. 208 of 927 tests failed as a suite while each file passed
  alone.

### This change

- **Fix:** `Sync-PSEntraIDGroupMember` could neither add a member nor remove one. Both
  member lists were flattened to bare Id strings before being compared on the `Id`
  *property*, so every entry matched every other and the `Create`/`Delete` branches were
  unreachable; the `Delete` branch also read the id from the one field that is empty for
  a delete. A second defect surfaced once those branches became reachable: the comparison
  helper threw on the "nothing to do" case. The two specifications that documented the
  gap are no longer skipped.
- **Fix:** `Install-Module PSMicrosoftEntraID` produced a module that could not import.
  PSFramework was listed in `ExternalModuleDependencies`, which tells PowerShellGet not
  to install it. Removed, and the requirement now carries a version floor.
- **Fix:** `Invoke-BatchWithThrottleRetry` had no examples in its help, which failed the
  help test and left the suite red.
- **Upd:** Manifest declares `CompatiblePSEditions = @('Core')` (the library targets
  net8.0), carries a real description and gallery-compatibility tags, and references the
  library with a forward slash so the path resolves on every platform.
- **Upd:** The C# library builds against one `Microsoft.PowerShell.SDK` version on every
  host. It used to be 7.2.24 on Windows and 7.2.12 elsewhere, so the shipped DLL was
  compiled against a different SDK than the one it was developed against.
- **Upd:** 26 stale `PSUseDeclaredVarsMoreThanAssignments` suppressions removed - the rule
  no longer fires on any of them. The vendored `Connect-EntraService.ps1` keeps its own.
- **Upd:** Repository no longer tracks Visual Studio's private state (`.vs/`, 204 files
  including Copilot snapshots), MSBuild intermediates (`obj/`, 55 files), an orphaned
  duplicate of the generated docs under `src/docs/`, an empty `src/install.ps1`, or the
  unused internal `Sync-GroupMember` helper. Line endings are pinned by a repository-root
  `.gitattributes`.
- **Upd:** The five delta cmdlets were byte-identical bodies in five files. They now share
  one internal implementation and keep only what belongs to each: its parameter block, its
  help, its Graph path and its type.
- **Upd:** The licence catalog check is a hard failure only on `main` and on release tags.
  The catalog is derived from a live Microsoft download, so upstream publishing a new SKU
  used to fail every build in every branch on a commit that changed nothing. The message
  now names that case instead of only the stale-catalog one.
- **Fix:** `-Force` was documented as doing the opposite of what it does. 24 of the 30
  cmdlets that have the parameter carried the `-Confirm` description under it, telling
  readers that `-Force` makes the command prompt them.
- **Fix:** Four defects in `Enable-`/`Disable-PSEntraIDUserLicenseServicePlan`, found by
  running the licence scenario against a live tenant and chasing every failure to root:
  the merge state ("which plans are already disabled") was read from `licenseDetails`'
  `provisioningStatus`, which trails the assignment - so a plan disabled a moment ago was
  silently re-enabled by the next call, and in `Enable` a freshly assigned SKU read as
  absent and had every plan but the requested ones disabled; pipeline input never worked,
  because SKU/plan resolution switched on `ParameterSetName` in `begin`, where it is not
  yet resolved for piped input; on pipeline input a user with nothing to disable inherited
  the previous user's list; and an empty plan list serialized as `[null]`. State now comes
  from `assignedLicenses.disabledPlans` - the field the write itself sets, the one the
  group cmdlets always used - resolution branches on `$PSBoundParameters`, and both
  cmdlets warn instead of staying silent when the target does not hold the SKU.
- **Fix:** The same `begin`-block parameter-set switch existed in all six remaining
  licence cmdlets (`Enable-`/`Disable-` × `UserLicense`/`GroupLicense`/
  `GroupLicenseServicePlan`), so pipeline input carried the same latent defect across the
  whole family. All now branch on `$PSBoundParameters`; the rule is written down in
  `docs/internal/conventions.md` together with the other invariants this week's defects
  established.
- **Fix:** The file-integrity syntax check passed only because something had imported the
  module first. The class files are typed with library types, which PowerShell resolves at
  parse time, so the check fails on its own with "Unable to find type". Both tests that
  parse now load the library themselves instead of inheriting it from run order.
- **Upd:** `-Force` and `-Confirm` are now documented as the pair they are, from both
  sides, on all 31 cmdlets that have them: `-Force` suppresses the prompt, an explicitly
  bound `-Confirm` wins over it whatever its value, and with neither the decision belongs
  to `ConfirmImpact` and `$ConfirmPreference`. The two are alternatives, not a pair to be
  passed together - the redundant `-Force -Confirm:$false` is gone from the scenario
  scripts (51 sites) and the test suite (96 sites across 20 files).
- **Upd:** `README.md`, the `about_PSMicrosoftEntraID` help topic and the authentication
  guides corrected. The examples used parameter names that do not exist
  (`-MemberIdentity`, `-OwnerIdentity`, `-MaxRetries`, `Get-PSEntraIDUserLicense -Identity`
  and others), the about topic was still the unedited template with `{{ Placeholder }}`
  text in it, and the authentication guides told readers to use a different module.

## 1.1.0 (2025-10-06)
- **New:** Enhanced administrative unit management cmdlets with improved pipeline support and parameter optimization.
- **New:** Added centralized path variables for administrative unit API endpoints for better maintainability.
- **New:** Implemented $select parameter optimization for administrative unit cmdlets to improve API performance.
- **New:** Added comprehensive InputObject parameter support for Add-PSEntraIDAdministrativeUnitMember and Remove-PSEntraIDAdministrativeUnitMember cmdlets.
- **Upd:** Refactored Remove-PSEntraIDAdministrativeUnitMember parameter structure for cleaner parameter sets and better pipeline binding.
- **Upd:** Improved type safety in administrative unit member cmdlets with proper PSTypeName attributes and specific type declarations.
- **Upd:** Enhanced pipeline parameter binding for Remove-PSEntraIDAdministrativeUnit cmdlet using PSTypeName for better object acceptance.
- **Fix:** Resolved pipeline binding issues in administrative unit cmdlets that were causing "input object cannot be bound" errors.
- **Fix:** Corrected duplicate parameter set blocks and syntax errors in Remove-PSEntraIDAdministrativeUnitMember cmdlet.
- **Fix:** Streamlined parameter set logic to eliminate ambiguous pipeline binding scenarios.

## 1.0.2 (2025-09-18)
- **Fix:** Move License and README.MD file to root folder.

## 1.0.1 (2025-09-17)
- **Fix:** Incorrect verbosing of Get-PSEntraIDContact cmdlet.

## 1.0.0 (2025-07-22)
- **New:** Added advanced cmdlets for creating and updating Microsoft Entra ID (Azure AD) groups, including support for dynamic and security-enabled groups.
- **New:** Implemented batch request support for Microsoft Graph API, allowing efficient processing of multiple requests in a single call.
- **New:** Introduced `Get-PSEntraIDContact` cmdlet for retrieving organization contacts via Graph API.
- **New:** Added robust support for user creation and update, including all relevant properties (DisplayName, GivenName, Surname, Mail, JobTitle, Department, etc.).
- **New:** Extended parameter validation and error handling throughout the module for a more predictable scripting experience.
- **Upd:** Refactored core logic for property mapping in user and group cmdlets to align with Microsoft Graph API conventions.
- **Upd:** Enhanced pipeline support in user and group creation cmdlets, enabling bulk operations from CSV or other data sources.
- **Fix:** Addressed serialization and deserialization issues for batch responses, ensuring correct mapping of headers and body properties.
- **Fix:** Improved type handling and object mapping for Graph API responses, especially in edge cases with missing or null properties.
