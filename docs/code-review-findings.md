# Code review — findings

Rolling record of a review of PSMicrosoftEntraID, area by area. Fixed items stay here
with the commit that closed them, so the same ground is not re-covered.

Areas reviewed so far: **license**, **authentication + core** (see also
`entraauth-divergence.md`), **tab expansion**, **test suite**, **build & versioning**.
Not yet reviewed: user, group, batch, device, organization, serviceannouncement,
administrativeunit.

---

## Fixed

| # | Area | Finding | Commit |
|---|---|---|---|
| 1 | license | `Select-Object -Unique` returns a **scalar** for a one-element list, so `disabledPlans` serialized as a string and Graph rejected the request. Disabling exactly one service plan — the common case — never worked, on user and group cmdlets alike. | `9db9ae7` |
| 2 | tepp | Tab completion never worked for any parameter. Scriptblocks emitted hashtables (neither PSFramework mode accepts them), registrations lacked `-Mode Full`, and the scriptblocks never declared the completer parameters — Full mode passes them **positionally**, so `$wordToComplete` and `$fakeBoundParameter` were undefined. PowerShell silently fell back to completing file paths. | `9fdc2fb` |
| 3 | tests | 40 of 54 test files never imported the module; they relied on whichever file Pester ran first in the shared runspace. 208 of 927 tests failed as a suite while each file passed alone. | `9c4698c` |
| 4 | build | The committed `bin/PSMicrosoftEntraID.dll` was **older than the C# source it is built from** — `ProvisioningStatus` existed in the source but not in the shipped type. | `9463ad4` |
| 5 | build | The pipeline computed GitVersion and stamped the module, but passed nothing to the library build, so the DLL shipped as `1.0.0.0` regardless of module version. | `36001e5` |
| 6 | core | `Resolve-PSEntraIDConfirmPreference` returned `$true` when neither `-Force` nor `-Confirm` was given, and call sites bound it as `-Confirm:$true` — which **forces** a prompt rather than deferring to `ConfirmImpact`. Every cmdlet prompted unless the caller passed `-Force`. | `cc4b1c0` |

Two of these hid behind the same weakness: **the test suite was never green**, so nothing
could gate on it. It is now 927/927.

---

## Open — needs a decision

### `Users/UserGuest .cs` has a space in its filename

`src/library/PSMicrosoftEntraID/Users/UserGuest .cs`. It compiles, but a space before the
extension breaks glob patterns, trips scripts that do not quote paths, and is easy to miss
in tooling. Rename to `UserGuest.cs`.

### `Invoke-PSEntraIDRequest` / `Invoke-PSEntraIDBatchRequest` declare no `ConfirmImpact`

Every other cmdlet with `SupportsShouldProcess` states its impact explicitly; these two do
not, so they inherit the default. They are the generic request wrappers and can issue any
verb, including DELETE — the impact they carry should be a deliberate choice, not a
default.

### Four silent `continue` paths in the license cmdlets

`Disable-/Enable-PSEntraID*LicenseServicePlan` skip out when the SKU is not on the target
(`if ([object]::Equals($assignedLicense, $null)) { continue }`) without a message, even
under `-EnableException`. The caller cannot tell "done" from "did nothing" — which is
exactly how a group template appeared to be configured when nothing had been written.
Should warn, or throw under `-EnableException`.

### `-Force` is fixed but has no test

Nothing asserts that `-Force` suppresses confirmation, that explicit `-Confirm` beats
`-Force`, or that the default path does not prompt. Finding #6 lived in the module for
months because no test covered it.

---

## Cosmetic / consistency

- `-EnableException` is written two ways: `-EnableException:$EnableException` (50 call
  sites) and `-EnableException $EnableException` (79). Both bind correctly for a switch;
  pick one.
- `Connect-PSMicrosoftEntraID` and `Get-PSEntraIDCommandRetry` have no `[OutputType]`,
  unlike every other exported function.
- Six hard-coded `graph.microsoft.com` URLs in `functions/` while `internal/identifiers/`
  exists to centralise paths.
