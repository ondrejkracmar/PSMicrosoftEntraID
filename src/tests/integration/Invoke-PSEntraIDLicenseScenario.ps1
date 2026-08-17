<#
.SYNOPSIS
    Exercises the licensing and group cmdlets against a real tenant and reports which
    combinations behave as expected.

.DESCRIPTION
    The unit suite mocks Graph, so it proves the module sends what it means to send. It
    cannot prove Graph agrees. This script closes that gap for the two areas that carry
    the most combinations and the least coverage:

      - assigning and removing a SKU when the user starts with NOTHING, which is the
        case the licensing tool hits constantly and the one most likely to be wrong;
      - enabling and disabling INDIVIDUAL service plans, where the semantics are
        cumulative (each call rewrites the whole disabledPlans array) and an off-by-one
        silently re-enables something a customer disabled on purpose;
      - the same on groups, where assignment is inherited rather than direct.

    HOW IT DECIDES. Every scenario states what it expects the user's licence state to be
    afterwards, the script reads that state back from Graph and compares. A scenario that
    throws is reported, not swallowed - an unexpected terminating error is a result.

    STATE IS RESTORED. The test user's licences are captured before anything runs and put
    back in the finally block, including on Ctrl+C. Restoration is best-effort and is
    reported separately, so a failure to restore is visible rather than assumed.

    THIS WRITES TO A REAL TENANT. Use a test user and a test group. The script refuses to
    touch a user that already holds licences unless -AllowLicensedUser is given, because
    the SKU scenarios strip the user bare to reach the "has nothing" starting point.

.PARAMETER TenantId
    Directory (tenant) id.

.PARAMETER ClientId
    Application (client) id of the app registration used to connect.

.PARAMETER ClientSecret
    The client secret, as a SecureString. Produce it interactively so it never reaches a
    command line, a script file or the session history:

        $secret = Read-Host -AsSecureString 'Client secret'

.PARAMETER UserPrincipalName
    The test user. Its licence state is rewritten repeatedly and restored at the end.

.PARAMETER SkuPartNumber
    SKU to test with, e.g. 'DEVELOPERPACK_E5'. Must be subscribed and have a free unit.

.PARAMETER GroupDisplayName
    Existing group used for the group scenarios. Group licensing is inherited, so use a
    group whose membership and licences are yours to change.

.PARAMETER SkipGroupScenarios
    Run only the user licence scenarios.

.PARAMETER AllowLicensedUser
    Proceed even when the test user already holds licences. Their original assignment is
    still captured and restored, but understand that the run removes them in between.

.PARAMETER JsonPath
    Write the full result set here as JSON, for diffing between module versions.

.EXAMPLE
    PS C:\> $secret = Read-Host -AsSecureString 'Client secret'
    PS C:\> ./Invoke-PSEntraIDLicenseScenario.ps1 -TenantId $tid -ClientId $cid `
                -ClientSecret $secret -UserPrincipalName 'lic.test@contoso.com' `
                -SkuPartNumber 'DEVELOPERPACK_E5' -GroupDisplayName 'LIC-TEST-GRP'

    Runs the whole matrix and prints a pass/fail table.

.EXAMPLE
    PS C:\> ./Invoke-PSEntraIDLicenseScenario.ps1 ... -SkipGroupScenarios -JsonPath ./run.json

    User licence scenarios only, results kept for comparison against a later run.
#>
# Write-Host is deliberate: this is an interactive console tool whose entire purpose is a
# running commentary an operator watches. Its results also go to -JsonPath for anything
# that needs to consume them.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
# The group verifiers take $state to satisfy the harness contract but read group state
# instead, which is not visible in the user licence snapshot.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)] [string] $TenantId,
    [Parameter(Mandatory = $true)] [string] $ClientId,
    [Parameter(Mandatory = $true)] [System.Security.SecureString] $ClientSecret,
    [Parameter(Mandatory = $true)] [string] $UserPrincipalName,
    [Parameter(Mandatory = $true)] [string] $SkuPartNumber,
    [Parameter()] [string] $GroupDisplayName,
    [Parameter()] [switch] $SkipGroupScenarios,
    [Parameter()] [switch] $AllowLicensedUser,
    [Parameter()] [string] $JsonPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Harness ---------------------------------------------------------------------

$script:results = [System.Collections.Generic.List[object]]::new()

function Write-Head {
    param([string] $Text)
    Write-Host ''
    Write-Host "=== $Text " -ForegroundColor Cyan -NoNewline
    Write-Host ('=' * [Math]::Max(0, 68 - $Text.Length)) -ForegroundColor Cyan
}

function Get-UserLicenseState {
    <#
        The state every expectation is written against: which SKUs the user holds and,
        per SKU, which plans Graph reports as Disabled. ProvisioningStatus is the only
        place the disabled set is observable after the fact - the assignment call takes
        disabledPlans, but the read side reports status per plan.
    #>
    param([string] $Upn)

    $state = @{}
    $detail = @(Get-PSEntraIDUserLicenseDetail -Identity $Upn -ErrorAction SilentlyContinue)
    foreach ($sku in $detail) {
        if (-not $sku) { continue }
        $disabled = @(
            foreach ($plan in @($sku.ServicePlans)) {
                if ($plan -and $plan.ProvisioningStatus -eq 'Disabled') { $plan.ServicePlanName }
            }
        )
        $state[$sku.SkuPartNumber] = [pscustomobject]@{
            SkuId         = $sku.SkuId
            DisabledPlans = @($disabled | Sort-Object)
            PlanCount     = @($sku.ServicePlans).Count
        }
    }
    $state
}

function Test-Scenario {
    <#
        One scenario: do something, read the state back, let the caller judge it.

        The Verify block receives the post-state and returns $true / $false plus, when it
        disagrees, a reason. Anything thrown by Act is caught and recorded - for the
        negative scenarios (disable a plan on a SKU the user does not hold) an error IS
        the expected outcome, so ExpectError says so instead of failing the run.
    #>
    param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string] $Given,
        [Parameter(Mandatory = $true)] [scriptblock] $Act,
        [Parameter(Mandatory = $true)] [scriptblock] $Verify,
        [Parameter()] [switch] $ExpectError
    )

    Write-Host ("  {0,-58}" -f $Name) -NoNewline
    $record = [ordered]@{
        Name    = $Name
        Given   = $Given
        Result  = 'Unknown'
        Detail  = ''
        Error   = ''
        State   = $null
    }

    $threw = $null
    try { & $Act | Out-Null }
    catch { $threw = $_ }

    # Assignment is not instantaneous. Graph accepts the call and reflects it on the
    # read side a moment later; without this the next scenario reads the previous state
    # and every expectation shifts by one.
    Start-Sleep -Seconds 3

    $state = Get-UserLicenseState -Upn $UserPrincipalName
    $record.State = $state

    if ($threw) {
        $record.Error = $threw.Exception.Message
        if ($ExpectError) {
            $record.Result = 'Pass'
            $record.Detail = 'failed as expected'
        }
        else {
            $record.Result = 'Error'
            $record.Detail = 'unexpected terminating error'
        }
    }
    else {
        if ($ExpectError) {
            $record.Result = 'Fail'
            $record.Detail = 'expected an error, the call succeeded'
        }
        else {
            $verdict = & $Verify $state
            if ($verdict -is [array]) { $ok, $why = $verdict }
            else { $ok = $verdict; $why = '' }

            if ($ok) { $record.Result = 'Pass'; $record.Detail = $why }
            else { $record.Result = 'Fail'; $record.Detail = $why }
        }
    }

    switch ($record.Result) {
        'Pass' { Write-Host ' PASS' -ForegroundColor Green }
        'Fail' { Write-Host ' FAIL' -ForegroundColor Red }
        default { Write-Host ' ERROR' -ForegroundColor Magenta }
    }
    if ($record.Detail) { Write-Host "      $($record.Detail)" -ForegroundColor DarkGray }
    if ($record.Error) { Write-Host "      $($record.Error)" -ForegroundColor DarkGray }

    $script:results.Add([pscustomobject]$record)
}

function Clear-UserLicense {
    # Back to the "user has nothing" starting point, which is what several scenarios are
    # about. Only the SKU under test is removed - anything else the user holds is not
    # this script's business beyond the snapshot.
    param([string] $Upn, [string] $Sku)

    $state = Get-UserLicenseState -Upn $Upn
    if ($state.ContainsKey($Sku)) {
        Disable-PSEntraIDUserLicense -Identity $Upn -SkuPartNumber $Sku -Force -Confirm:$false | Out-Null
        Start-Sleep -Seconds 3
    }
}

#endregion Harness

#region Connect and preflight -------------------------------------------------------

Write-Head 'Connecting'

Import-Module PSMicrosoftEntraID -ErrorAction Stop
Connect-PSMicrosoftEntraID -ClientID $ClientId -TenantID $TenantId -ClientSecret $ClientSecret -ErrorAction Stop | Out-Null
Write-Host "  connected to $TenantId" -ForegroundColor Green

$subscribed = @(Get-PSEntraIDSubscribedLicense | Where-Object SkuPartNumber -EQ $SkuPartNumber)
if ($subscribed.Count -eq 0) {
    throw "SKU '$SkuPartNumber' is not subscribed in this tenant. Available: $((Get-PSEntraIDSubscribedLicense).SkuPartNumber -join ', ')"
}
$targetSku = $subscribed[0]

# Every scenario below assigns the SKU at least once; without a free unit they would all
# fail for the same uninteresting reason.
$free = [int]$targetSku.PrepaidUnits.Enabled - [int]$targetSku.ConsumedUnits
Write-Host "  SKU $SkuPartNumber ($($targetSku.SkuId)) - $free free unit(s)" -ForegroundColor Green
if ($free -lt 1) { throw "No free units of '$SkuPartNumber'; the assignment scenarios cannot run." }

$allPlans = @($targetSku.ServicePlans | Where-Object { $_.AppliesTo -eq 'User' } | Sort-Object ServicePlanName)
if ($allPlans.Count -lt 3) { throw "SKU '$SkuPartNumber' exposes $($allPlans.Count) user plan(s); the plan scenarios need at least three." }
$planA, $planB, $planC = $allPlans[0], $allPlans[1], $allPlans[2]
Write-Host "  plans under test: $($planA.ServicePlanName), $($planB.ServicePlanName), $($planC.ServicePlanName) (of $($allPlans.Count))" -ForegroundColor Green

$originalState = Get-UserLicenseState -Upn $UserPrincipalName
if ($originalState.Keys.Count -gt 0 -and -not $AllowLicensedUser) {
    throw ("User '{0}' already holds: {1}. The SKU scenarios start from an unlicensed user and would remove them. Re-run with -AllowLicensedUser if that is intended." -f $UserPrincipalName, ($originalState.Keys -join ', '))
}
Write-Host "  captured original state: $(if ($originalState.Keys.Count) { $originalState.Keys -join ', ' } else { '(no licences)' })" -ForegroundColor Green

if (-not $PSCmdlet.ShouldProcess("$UserPrincipalName / $SkuPartNumber", 'Run licence scenarios against the live tenant')) { return }

#endregion Connect and preflight

try {
    #region User licence scenarios --------------------------------------------------

    Write-Head 'User: SKU assignment from nothing'

    Clear-UserLicense -Upn $UserPrincipalName -Sku $SkuPartNumber

    Test-Scenario -Name 'assign SKU by part number to an unlicensed user' `
        -Given 'user holds nothing' `
        -Act { Enable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false } `
        -Verify {
            param($state)
            if (-not $state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU was not assigned') }
            if ($state[$SkuPartNumber].DisabledPlans.Count -gt 0) {
                return @($false, "assigned but $($state[$SkuPartNumber].DisabledPlans.Count) plan(s) came back disabled: $($state[$SkuPartNumber].DisabledPlans -join ', ')")
            }
            @($true, 'assigned with every plan enabled')
        }

    Test-Scenario -Name 'assigning the same SKU again is idempotent' `
        -Given 'user already holds the SKU' `
        -Act { Enable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false } `
        -Verify {
            param($state)
            if (-not $state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU disappeared') }
            if ($state[$SkuPartNumber].DisabledPlans.Count -gt 0) { return @($false, 'a repeat assignment disabled plans') }
            @($true, 'unchanged')
        }

    Test-Scenario -Name 'remove the SKU' `
        -Given 'user holds the SKU' `
        -Act { Disable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false } `
        -Verify {
            param($state)
            if ($state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU is still assigned') }
            @($true, 'removed')
        }

    Test-Scenario -Name 'assign SKU by SkuId (the other parameter set)' `
        -Given 'user holds nothing' `
        -Act { Enable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuId $targetSku.SkuId -Force -Confirm:$false } `
        -Verify {
            param($state)
            if (-not $state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU was not assigned via SkuId') }
            @($true, 'assigned')
        }

    Write-Head 'User: service plans on a SKU the user already holds'

    Test-Scenario -Name 'disable one plan, leave the rest' `
        -Given 'SKU assigned, nothing disabled' `
        -Act { Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false } `
        -Verify {
            param($state)
            if (-not $state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU vanished') }
            $disabled = $state[$SkuPartNumber].DisabledPlans
            if ($disabled -notcontains $planA.ServicePlanName) { return @($false, "$($planA.ServicePlanName) is not disabled") }
            if ($disabled.Count -ne 1) { return @($false, "expected exactly one disabled plan, got: $($disabled -join ', ')") }
            @($true, "only $($planA.ServicePlanName) disabled")
        }

    Test-Scenario -Name 'disable a second plan - must ADD, not replace' `
        -Given "$($planA.ServicePlanName) already disabled" `
        -Act { Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planB.ServicePlanName -Force -Confirm:$false } `
        -Verify {
            param($state)
            $disabled = $state[$SkuPartNumber].DisabledPlans
            # The regression this scenario exists for: the disabledPlans array is sent
            # whole on every call, so a call that forgets to merge silently re-enables
            # everything a customer disabled earlier.
            if ($disabled -notcontains $planA.ServicePlanName) { return @($false, "$($planA.ServicePlanName) was re-enabled - the second call replaced the list instead of adding to it") }
            if ($disabled -notcontains $planB.ServicePlanName) { return @($false, "$($planB.ServicePlanName) is not disabled") }
            @($true, "both disabled: $($disabled -join ', ')")
        }

    Test-Scenario -Name 're-enable one plan, the other stays disabled' `
        -Given 'two plans disabled' `
        -Act { Enable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false } `
        -Verify {
            param($state)
            $disabled = $state[$SkuPartNumber].DisabledPlans
            if ($disabled -contains $planA.ServicePlanName) { return @($false, "$($planA.ServicePlanName) is still disabled") }
            if ($disabled -notcontains $planB.ServicePlanName) { return @($false, "$($planB.ServicePlanName) was re-enabled too - enabling one plan must not clear the whole list") }
            @($true, "$($planA.ServicePlanName) back on, $($planB.ServicePlanName) still off")
        }

    Test-Scenario -Name 'enable a plan that is already enabled (no-op)' `
        -Given "$($planA.ServicePlanName) enabled" `
        -Act { Enable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false } `
        -Verify {
            param($state)
            $disabled = $state[$SkuPartNumber].DisabledPlans
            if ($disabled -notcontains $planB.ServicePlanName) { return @($false, 'the no-op cleared an unrelated disabled plan') }
            @($true, 'no change')
        }

    Test-Scenario -Name 'disable a plan by ServicePlanId (the other parameter set)' `
        -Given 'SKU assigned' `
        -Act { Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanId $planC.ServicePlanId -Force -Confirm:$false } `
        -Verify {
            param($state)
            $disabled = $state[$SkuPartNumber].DisabledPlans
            if ($disabled -notcontains $planC.ServicePlanName) { return @($false, "$($planC.ServicePlanName) is not disabled") }
            @($true, "disabled by id: $($planC.ServicePlanName)")
        }

    Write-Head 'User: service plans when the user has NO SKU'

    Clear-UserLicense -Upn $UserPrincipalName -Sku $SkuPartNumber

    Test-Scenario -Name 'enable a single plan on a SKU the user does not hold' `
        -Given 'user holds nothing' `
        -Act { Enable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false } `
        -Verify {
            param($state)
            # This is the case the licensing tool leans on: ask for one plan and expect
            # the SKU to arrive with everything ELSE switched off. Whether the module
            # does that, refuses, or assigns the SKU wide open is exactly what needs
            # observing rather than assuming.
            if (-not $state.ContainsKey($SkuPartNumber)) {
                return @($false, 'no SKU was assigned - enabling a plan does not imply the licence')
            }
            $disabled = $state[$SkuPartNumber].DisabledPlans
            $expectedDisabled = $allPlans.Count - 1
            if ($disabled.Count -eq 0) {
                return @($false, "the SKU was assigned with ALL $($state[$SkuPartNumber].PlanCount) plans enabled, not just $($planA.ServicePlanName)")
            }
            if ($disabled -contains $planA.ServicePlanName) {
                return @($false, "$($planA.ServicePlanName) was the plan asked for, yet it came back disabled")
            }
            @($true, "SKU assigned with $($disabled.Count) of $expectedDisabled other plan(s) disabled")
        }

    Clear-UserLicense -Upn $UserPrincipalName -Sku $SkuPartNumber

    Test-Scenario -Name 'disable a plan on a SKU the user does not hold' `
        -Given 'user holds nothing' `
        -Act { Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false -EnableException } `
        -Verify { param($state) @($true, '') } `
        -ExpectError

    Write-Head 'User: edge cases'

    Enable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false | Out-Null
    Start-Sleep -Seconds 3

    Test-Scenario -Name 'disable EVERY plan of the SKU' `
        -Given 'SKU assigned, all plans enabled' `
        -Act {
            Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber `
                -ServicePlanName @($allPlans.ServicePlanName) -Force -Confirm:$false
        } `
        -Verify {
            param($state)
            # A SKU with everything disabled still consumes a unit. Worth knowing whether
            # the module leaves it assigned or drops it, because the two differ in cost.
            if (-not $state.ContainsKey($SkuPartNumber)) {
                return @($true, 'the SKU was removed entirely once every plan was disabled')
            }
            $disabled = $state[$SkuPartNumber].DisabledPlans
            @($true, "SKU still assigned with $($disabled.Count) of $($state[$SkuPartNumber].PlanCount) plan(s) disabled - still consumes a unit")
        }

    Test-Scenario -Name 'remove a SKU that is already removed' `
        -Given 'SKU not assigned' `
        -Act {
            Disable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false | Out-Null
            Disable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $SkuPartNumber -Force -Confirm:$false
        } `
        -Verify {
            param($state)
            if ($state.ContainsKey($SkuPartNumber)) { return @($false, 'SKU is still assigned') }
            @($true, 'second removal is harmless')
        }

    #endregion User licence scenarios

    #region Group scenarios ---------------------------------------------------------

    if (-not $SkipGroupScenarios) {
        if (-not $GroupDisplayName) {
            Write-Warning 'No -GroupDisplayName given; group scenarios skipped.'
        }
        else {
            Write-Head 'Groups: membership'

            $group = Get-PSEntraIDGroup -Identity $GroupDisplayName -ErrorAction SilentlyContinue
            if (-not $group) { throw "Group '$GroupDisplayName' not found." }
            Write-Host "  group $($group.DisplayName) ($($group.Id))" -ForegroundColor Green

            $memberBefore = @(Get-PSEntraIDGroupMember -Identity $group.Id | Select-Object -ExpandProperty Id)
            $userObject = Get-PSEntraIDUser -Identity $UserPrincipalName
            $wasMember = $memberBefore -contains $userObject.Id

            if ($wasMember) {
                Remove-PSEntraIDGroupMember -Identity $group.Id -User $userObject.Id -Force -Confirm:$false | Out-Null
                Start-Sleep -Seconds 3
            }

            Test-Scenario -Name 'add the user to the group' `
                -Given 'user is not a member' `
                -Act { Add-PSEntraIDGroupMember -Identity $group.Id -User $userObject.Id -Force -Confirm:$false } `
                -Verify {
                    param($state)
                    $members = @(Get-PSEntraIDGroupMember -Identity $group.Id | Select-Object -ExpandProperty Id)
                    if ($members -notcontains $userObject.Id) { return @($false, 'user is not in the group') }
                    @($true, "group now has $($members.Count) member(s)")
                }

            Test-Scenario -Name 'adding the same member again' `
                -Given 'user is already a member' `
                -Act { Add-PSEntraIDGroupMember -Identity $group.Id -User $userObject.Id -Force -Confirm:$false } `
                -Verify {
                    param($state)
                    $members = @(Get-PSEntraIDGroupMember -Identity $group.Id | Where-Object { $_.Id -eq $userObject.Id })
                    if ($members.Count -ne 1) { return @($false, "user appears $($members.Count) time(s)") }
                    @($true, 'still exactly one membership')
                }

            Test-Scenario -Name 'remove the user from the group' `
                -Given 'user is a member' `
                -Act { Remove-PSEntraIDGroupMember -Identity $group.Id -User $userObject.Id -Force -Confirm:$false } `
                -Verify {
                    param($state)
                    $members = @(Get-PSEntraIDGroupMember -Identity $group.Id | Select-Object -ExpandProperty Id)
                    if ($members -contains $userObject.Id) { return @($false, 'user is still a member') }
                    @($true, 'removed')
                }

            Write-Head 'Groups: licensing'

            $groupLicenseBefore = @(Get-PSEntraIDGroupLicense -Identity $group.Id -ErrorAction SilentlyContinue)
            Write-Host "  group currently carries $($groupLicenseBefore.Count) licence assignment(s)" -ForegroundColor DarkGray

            Test-Scenario -Name 'assign the SKU to the group' `
                -Given 'group has no such licence' `
                -Act { Enable-PSEntraIDGroupLicense -Identity $group.Id -SkuPartNumber $SkuPartNumber -Force -Confirm:$false } `
                -Verify {
                    param($state)
                    $assigned = @(Get-PSEntraIDGroupLicenseDetail -Identity $group.Id -ErrorAction SilentlyContinue |
                        Where-Object SkuPartNumber -EQ $SkuPartNumber)
                    if ($assigned.Count -eq 0) { return @($false, 'the group does not carry the SKU') }
                    @($true, 'group carries the SKU')
                }

            Test-Scenario -Name 'disable one plan on the group assignment' `
                -Given 'group carries the SKU' `
                -Act {
                    Disable-PSEntraIDGroupLicenseServicePlan -Identity $group.Id -SkuPartNumber $SkuPartNumber `
                        -ServicePlanName $planA.ServicePlanName -Force -Confirm:$false
                } `
                -Verify {
                    param($state)
                    $assigned = @(Get-PSEntraIDGroupLicenseDetail -Identity $group.Id -ErrorAction SilentlyContinue |
                        Where-Object SkuPartNumber -EQ $SkuPartNumber)
                    if ($assigned.Count -eq 0) { return @($false, 'the SKU assignment disappeared') }
                    $disabled = @($assigned[0].ServicePlans | Where-Object ProvisioningStatus -EQ 'Disabled' | Select-Object -ExpandProperty ServicePlanName)
                    if ($disabled -notcontains $planA.ServicePlanName) { return @($false, "$($planA.ServicePlanName) is not disabled on the group") }
                    @($true, "disabled on the group: $($disabled -join ', ')")
                }

            Test-Scenario -Name 'remove the SKU from the group' `
                -Given 'group carries the SKU' `
                -Act { Disable-PSEntraIDGroupLicense -Identity $group.Id -SkuPartNumber $SkuPartNumber -Force -Confirm:$false } `
                -Verify {
                    param($state)
                    $assigned = @(Get-PSEntraIDGroupLicenseDetail -Identity $group.Id -ErrorAction SilentlyContinue |
                        Where-Object SkuPartNumber -EQ $SkuPartNumber)
                    if ($assigned.Count -gt 0) { return @($false, 'the group still carries the SKU') }
                    @($true, 'removed from the group')
                }

            if ($wasMember) {
                Add-PSEntraIDGroupMember -Identity $group.Id -User $userObject.Id -Force -Confirm:$false | Out-Null
                Write-Host '  restored the original group membership' -ForegroundColor DarkGray
            }
        }
    }

    #endregion Group scenarios
}
finally {
    #region Restore -----------------------------------------------------------------

    Write-Head 'Restoring the original licence state'

    $restoreErrors = [System.Collections.Generic.List[string]]::new()
    try {
        $current = Get-UserLicenseState -Upn $UserPrincipalName

        foreach ($sku in $current.Keys) {
            if (-not $originalState.ContainsKey($sku)) {
                Disable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $sku -Force -Confirm:$false | Out-Null
                Write-Host "  removed $sku (not held originally)" -ForegroundColor DarkGray
            }
        }
        foreach ($sku in $originalState.Keys) {
            Enable-PSEntraIDUserLicense -Identity $UserPrincipalName -SkuPartNumber $sku -Force -Confirm:$false | Out-Null
            $wasDisabled = @($originalState[$sku].DisabledPlans)
            if ($wasDisabled.Count -gt 0) {
                Disable-PSEntraIDUserLicenseServicePlan -Identity $UserPrincipalName -SkuPartNumber $sku `
                    -ServicePlanName $wasDisabled -Force -Confirm:$false | Out-Null
            }
            Write-Host "  restored $sku ($($wasDisabled.Count) plan(s) disabled)" -ForegroundColor DarkGray
        }
    }
    catch {
        # Reported, never swallowed: a half-restored test user is something a human has
        # to look at, and it must not hide behind a green summary.
        $restoreErrors.Add($_.Exception.Message)
        Write-Host "  RESTORE FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }

    #endregion Restore

    #region Summary -----------------------------------------------------------------

    Write-Head 'Summary'

    if ($script:results.Count -gt 0) {
        $script:results | Format-Table -AutoSize -Property Name, Result, Detail | Out-Host

        $passed = @($script:results | Where-Object Result -EQ 'Pass').Count
        $failed = @($script:results | Where-Object Result -EQ 'Fail').Count
        $errored = @($script:results | Where-Object Result -EQ 'Error').Count

        Write-Host ("  {0} passed, {1} failed, {2} errored, {3} total" -f $passed, $failed, $errored, $script:results.Count) -ForegroundColor $(if ($failed + $errored -gt 0) { 'Red' } else { 'Green' })
    }
    else { Write-Host '  no scenarios ran' -ForegroundColor Yellow }

    if ($restoreErrors.Count -gt 0) {
        Write-Host "  the test user's licences were NOT fully restored - check it by hand" -ForegroundColor Red
    }

    if ($JsonPath) {
        [pscustomobject]@{
            TenantId      = $TenantId
            UserPrincipalName = $UserPrincipalName
            SkuPartNumber = $SkuPartNumber
            OriginalState = $originalState
            Results       = $script:results
            RestoreErrors = $restoreErrors
        } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $JsonPath -Encoding UTF8
        Write-Host "  results written to $JsonPath" -ForegroundColor DarkGray
    }

    Disconnect-PSMicrosoftEntraID -ErrorAction SilentlyContinue | Out-Null

    #endregion Summary
}
