# EntraAuth: what we changed and why

The authentication and core request layer of this module is vendored from
[EntraAuth](https://github.com/FriedrichWeinmann/EntraAuth) by Friedrich Weinmann.
36 files overlap. This file records every place ours deliberately differs, so an
upgrade can be a mechanical diff instead of an archaeology exercise.

**Last reconciled against upstream 1.8.55 (2026-08-16).**

## How to upgrade

1. Clone upstream at the new tag.
2. Diff the 36 overlapping files with `diff -w -B` — whitespace is not signal here, and
   ignoring it is what turns "35 files differ" into "7 files differ".
3. Every file **not** listed below can be taken from upstream verbatim.
4. For the files listed below, re-apply the change described and update this document.

## Ours — keep through upgrades

| File | Change | Why |
|---|---|---|
| `Connect-EntraService.ps1` | Adds the `AzToken` parameter set and its branch, calling `Connect-ServiceAzToken` | Authentication via the [AzAuth](https://github.com/PalmEmanuel/AzAuth) module (Azure.Identity MSAL). `Connect-ServiceAzToken.ps1` is ours alone and has no upstream counterpart. |
| `Assert-EntraConnection.ps1` | Error text names `Connect-PSMicrosoftEntraID` instead of `Connect-EntraService` | Users of this module never see `Connect-EntraService`; pointing them at a command they do not have is a dead end. |
| `Register-EntraService.ps1` | `[PSMicrosoftEntraID.Environment]` instead of `[Environment]` | Not cosmetic. Bare `[Environment]` resolves to `System.Environment`; that upstream works is an accident of load order. |
| `Connect-ServiceFederated.ps1` | `[PSMicrosoftEntraID.FederationProvider]` instead of `[FederationProvider]` | Same reason. |
| `Register-EntraFederationProvider.ps1` | `[PSMicrosoftEntraID.FederationProvider]` instead of `[FederationProvider]` | Same reason. |

## Ours — a fix upstream has not taken yet

| File | Change |
|---|---|
| `Set-EntraService.ps1` | Upstream writes the `NoRefresh` switch into `HelpUrl`:<br>`if ($PSBoundParameters.Keys -contains 'NoRefresh') { $service.HelpUrl = $NoRefresh.ToBool() }`<br>Ours assigns `$service.NoRefresh`. **Do not take upstream's version.** Worth an upstream issue. |

## Theirs — features we have not taken

None outstanding.

`Invoke-EntraRequest.ps1` used to be listed here: it lacked delta query support
(`-DeltaSession`, `-MinimalDelta`, the `$deltaToken` query injection, the
`Prefer: return=minimal` header and harvesting `@odata.deltaLink`). Since it had no local
changes worth keeping beyond a weakened `-Token` type, the whole file was taken from
upstream 1.8.55 verbatim. It is now identical to upstream — do not treat it as a
divergence.

That also restored `[EntraToken]` on `-Token`, which we had weakened to `[object]`. The
reason was the test suite: every test file injected a fake `EntraToken` C# class via
`Add-Type`, and a type added that way lives in the AppDomain for the rest of the session,
colliding with the module's real PowerShell class. The fake class is gone as of the
test-isolation change, so the upstream type constraint holds again.

## Structure

Upstream keeps its classes in `internal/scripts/` with a numeric load order
(`01-`, `02-`, …); we keep them in `internal/classes/` and compile `Environment` into the
library. Different organisation, not a gap — nothing is missing on either side.
