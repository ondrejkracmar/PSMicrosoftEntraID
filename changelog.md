# Changelog

## Unreleased

### Breaking

- **The user name and password sign-in (`Connect-PSMicrosoftEntraID -Credential`, ROPC) is
  off by default.** It bypasses multi-factor authentication and Conditional Access. A connect
  with `-Credential` now fails with a message that says how to opt in:
  `Set-PSFConfig -FullName PSMicrosoftEntraID.Settings.Authentication.AllowPasswordFlow -Value $true`.
  Opted in, every such connect writes a warning. Checked on renewal of the token too.
- **`Invoke-PSEntraIDRequest` / `Invoke-EntraRequest` refuse an absolute URL on another host
  than the connected service, or over http** (`SecurityError`, before anything is sent). Pass a
  path relative to the service, or a URL on the service's own host.

### Security

- `System.Security.Cryptography.Pkcs`, a transitive reference-only dependency of the
  library, is pinned to 8.0.2 (net8.0) and 10.0.13 (net10.0), which fix
  GHSA-846f-f764-76mx (high) and GHSA-2fmv-rv2c-59x7 (moderate).

- **The access token went to any host.** An absolute `-Path` and every `@odata.nextLink` were
  sent with `Authorization: Bearer <token>`, whatever their host and scheme. Every request -
  the first and each next link - is now checked against the `ServiceUrl` of the token it would
  carry: https only, same host and port. Each service's token decides its own host (Graph,
  Graph beta, Defender for Endpoint, Defender XDR, Azure, Key Vault with its vault name).
- **Delta and skip tokens in the log.** The request layer wrote the full request URL to the
  verbose stream and into its "Request failed" warning, and the full `@odata.deltaLink` into a
  warning - all of it into the PSFramework log. Messages are now localized and show the URL by
  scheme, host and path only.
- **Browser sign-in hardened.** The state comes from the CSPRNG (it was `Get-Random`), the code
  is bound with PKCE (S256), a request to the local port without this sign-in's state no longer
  ends the sign-in, the browser gets a local result page instead of a redirect (to a random
  local port, or now and then to a YouTube video), and the wait ends after
  `Settings.Authentication.BrowserTimeoutSeconds` (300). The sign-in link is printed through
  the host, not `Write-Host`, and not logged.
- **The certificate sign-in no longer sends its signed client assertion as a bearer header** -
  the body carries it, as RFC 7523 has it.

### Changed

- **The repository follows the CodexVault standards pack 1.9.0.** `AGENTS.md`, `CLAUDE.md`,
  the Claude Code hooks (analyzer, attribution, git guard) and reviewer, the Copilot
  instructions, `.editorconfig`, `PSScriptAnalyzerSettings.psd1`, `SECURITY.md`,
  `.github/CODEOWNERS`, the pull request template, `docs/adr/` and `docs/runbooks/`.
  `.codexvault/packs.psd1` records the installation. Security reports now go through
  GitHub's private vulnerability reporting.
- **`.codexvault/public-export.psd1` declares what the public GitHub repository leaves
  out**: the agent and standards tooling, `docs/internal/`, `docs/adr/`, `docs/runbooks/`,
  `tools/`, the Azure DevOps pipeline and `src/build/`. Azure DevOps stays the source of
  truth; GitHub receives the filtered source history.
- The personal editor and container settings (`.vscode/settings.json`, `.devcontainer/`)
  and the inactive `src/editorconfig` are gone; `.gitignore` covers the protected-file
  patterns the git guard expects.

### Fixed

- **Piped records no longer inherit the previous record's properties.**
  With `ValueFromPipelineByPropertyName`, `$PSBoundParameters` keeps a key bound by an
  earlier pipeline record while the variable is reset to its default, so every cmdlet
  that decided "was this property given?" from it wrote the previous record's properties,
  with empty or default values, into the next object. Piping
  `{Id; AccountEnabled = $true; Department = 'IT'}` then `{Id; JobTitle = 'Dev'}` into
  `Set-PSEntraIDUser` sent `{"department":"","accountEnabled":false,"jobTitle":"Dev"}`
  for the second user - disabling the account and clearing the department. Affected:
  `Set-PSEntraIDUser`, `New-PSEntraIDUser` (also reset `forceChangePasswordNextSignIn`),
  `New-PSEntraIDGroup`, `Set-PSEntraIDGroup`, `New-PSEntraIDAdministrativeUnit`,
  `Set-PSEntraIDAdministrativeUnit` and `New-PSEntraIDInvitation`, which additionally
  copied every earlier guest's CC recipients onto each later invitation. Each cmdlet now
  drops the keys a record bound once that record is processed (new internal
  `Clear-PipelineBoundParameter`, rule in `docs/internal/conventions.md`), and
  `PipelineBoundParameters.Tests.ps1` asserts the serialized body of every record in a
  mixed pipeline.

- **`Sync-PSEntraIDGroupMember` no longer empties a group when a read fails.**
  The member reads ran under `-Continue`: a transient 403/429/503 on the reference group
  only warned and returned nothing, and an empty reference made the sync remove EVERY
  member of the target group. A `-ReferenceUserIdentity` that did not resolve was
  skipped silently, so that real member was removed too. Now every read runs with
  `-EnableException` and any failure aborts the sync before anything is written; an
  unresolved reference identity aborts it and names the identity; an empty reference
  with a non-empty target is refused unless the new `-AllowEmptyReference` switch says
  emptying the group is intended. Missing members are added straight to the resolved
  group in chunks of 20 (`members@odata.bind`, one PATCH per chunk) instead of one
  `Add-PSEntraIDGroupMember` call - about five requests - per member, and removals are a
  direct `DELETE .../members/{id}/$ref`, which also works for members that are not
  users. `Get-SyncDataOperation` pairs the two lists through a key index instead of a
  `.Where()` scan per item (3000 vs 2500 members: about 290 s before, a few seconds now) and no
  longer returns nothing under `-WhatIf`.

- **`Add-PSEntraIDGroupMember` sent garbage for two or more members and dropped
  members on a partial resolution.** The chunks for `members@odata.bind` were cast to
  `[string[]]`, which joined every chunk of up to 20 member URLs into ONE
  space-separated string, and `Step-Array` emitted an extra empty chunk for an exact
  multiple of 20 - Graph received
  `{"members@odata.bind":["https://.../1 https://.../2 ..."]}` followed by
  `{"members@odata.bind":[""]}`. The endpoint was chosen by how many users were
  requested rather than how many resolved, so `-User a,b` with `b` unknown sent
  `PATCH groups/{id}` with an `@odata.id` body and `a` was not added either; unresolved
  users were skipped without a word; and the request of one pipeline record was sent
  again for the next record when that one did not resolve. `Step-Array` now writes
  each chunk as one array and never an empty one, the cmdlet builds its requests per
  record from the members that actually resolved (one -> `POST members/$ref`, more ->
  `PATCH` in chunks of 20), and every unresolved user is reported with a warning.
  `Remove-PSEntraIDGroupMember`, `Add-`/`Remove-PSEntraIDGroupOwner` and
  `Add-`/`Remove-PSEntraIDAdministrativeUnitMember` skipped unresolved users, groups,
  devices and administrative units just as silently and now warn as well. The tests
  run the real `Step-Array` (the old one mocked it away) with 1, 19, 20, 21 and 40
  members and assert the serialized body of every request.

- **A misspelt service plan could assign a licence with every plan disabled.**
  `Enable-PSEntraIDUserLicenseServicePlan` and `Enable-PSEntraIDGroupLicenseServicePlan`
  resolved `-ServicePlanName` against the SKU and silently dropped what did not match;
  for a target that did not hold the SKU yet the cmdlet starts from "every plan
  disabled", so a typo assigned the licence with ALL plans disabled - a licence consumed
  for nothing, and no error. An unknown `-SkuPartNumber` went the same way with an empty
  `skuId`, and a `-ServicePlanId` the SKU does not have was never checked. All four
  service-plan cmdlets (`Enable-`/`Disable-`, user and group) now resolve the SKU and
  every requested plan once in `begin` (new internal `Resolve-LicenseServicePlan`) and
  stop before sending anything when one does not resolve. A piped user object without
  `AssignedLicenses` (a minimal delta, a custom selection) is read again instead of
  being taken for "holds no licence": `Enable-*` used to overwrite the user's disabled
  plans and `Disable-*` reported the SKU as not assigned.
- **`Compare-PSEntraIDUserList` always answered "Not connected".** It asserted a
  connection to a service named `graph`, which is never registered; it now checks the
  configured default service like every other cmdlet.
- **`Get-PSEntraIDUserMemberOf -Filter` was rejected by Graph.** The
  `ConsistencyLevel: eventual` header was built and never passed on. An identity that
  did not resolve was requested as `users//memberOf`; it is now skipped with a warning
  (or stops the command with `-EnableException`).
- **`Get-PSEntraIDUser` could return the wrong account.** The mail lookup ran before
  the userPrincipalName, so when user B's mail equalled user A's UPN a request for A
  returned B. The order is now object id (read directly, no lookup), userPrincipalName,
  then mail - in `Get-PSEntraIDUserGuest` as well.
- **Service plan tab completion threw.** The completer's loop variable `$servicePlan`
  was its own `[switch] $ServicePlan` parameter (variables are case-insensitive), so the
  first plan failed the switch conversion. It was also attached to the GUID parameter
  `-ServicePlanId` of `Enable-PSEntraIDGroupLicenseServicePlan`, where it would have
  offered names; that parameter keeps its id completion from the TEPP registration.
- **`Get-PSEntraIDGroup -Identity` did not escape its fallback path.** Without a
  mailNickName match the identity itself went into `groups/{0}` unescaped, so `#` cut
  the request short.

- **Piping group records into `Add-PSEntraIDGroupOwner` never worked.** `-Identity`
  binds by property name, but the group was resolved in `begin`, where a piped
  `Identity` is still empty - so `$records | Add-PSEntraIDGroupOwner` failed on parameter
  validation before anything was sent. The group is now resolved per pipeline record in
  `process` (and read only once while the identity stays the same, so piping users into
  one `-Identity` still costs one group read); each record's owners go to that record's
  group. `Remove-PSEntraIDGroupOwner`, `Add-`/`Remove-PSEntraIDGroupMember` and the
  administrative-unit member cmdlets were checked: their `-Identity` is not
  pipeline-bound (or is already resolved in `process`), so they were not affected.
- **`Enable-*LicenseServicePlan` could assign a licence with every plan enabled.** For
  a target that does not hold the SKU yet, the cmdlet assigns it with every plan
  disabled except the requested ones, and "every plan" came from a subscribed-SKU
  catalog read that ran non-terminating. A throttled or failed read (403, 429, 503) only
  warned, an empty answer was taken at face value, and the licence went out with
  `disabledPlans: []` - every plan on, silently. The read now stops on error
  (`-EnableException`), and an empty plan list for the SKU stops the command (localized
  `LicenseServicePlan.Catalog.Failed` / `.Empty`) before anything is written. The user
  variant reads the catalog once per call instead of once per piped user (new internal
  `Get-LicenseSkuServicePlanId`). The `Disable-*` counterparts do not build the full
  plan list - a target without the SKU is skipped with a warning - and were not affected.

- **A federated connection renewed itself as a managed identity.** The token object was
  overwritten right after it was built, so the first renewal (after ~1 hour) tried a managed
  identity sign-in. The connection now stays federated.
- **Every `-AzToken` session died after about 55 minutes.** The token was taken as valid for one
  hour from the connect, whatever its real expiry, and the renewal passed the token string where
  the object was expected and threw. The expiry now comes from `ExpiresOn` or the token's `exp`
  claim; a token of `Get-AzAccessToken` is renewed through Az.Accounts (same identity enforced),
  any other source fails with a message asking for a new connect.
- **Managed identity did not work on an Azure VM** and left `IDENTITY_ENDPOINT` set in the
  process. The instance metadata service is now used directly (after a 2 s probe, with
  Microsoft's retry schedule); the environment is never written.
- **Device code sign-in:** `slow_down` from the token endpoint was a fatal error; it now waits
  5 s longer per RFC 8628. An expired or declined code ends with a clear message; the prompt
  goes through `Write-PSFMessage` instead of `Write-Host`.
- **Client secret and federated sign-in use the v2.0 token endpoint** (`<resource>/.default`),
  as the certificate flow already did.
- **Token claims are decoded as UTF-8** (names with diacritics read as `?`), and the token
  object keeps the authentication URL its constructor was given (`$AuthenticationUr` typo).
- **`Connect-PSMicrosoftEntraID` names the cause when a connect fails** instead of only
  "Establish a connection to ... failed".

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
