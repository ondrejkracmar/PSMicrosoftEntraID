BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Service-plan cmdlets refuse what they cannot resolve' -Tag 'Unit' {
    # A -ServicePlanName with a typo used to resolve to an EMPTY plan list, silently. For a
    # target that does not hold the SKU yet, Enable-* starts from "every plan disabled" and
    # enables the requested ones - so the typo assigned the licence with every plan
    # disabled: a licence consumed for nothing, and no error. An unknown -SkuPartNumber
    # went the same way with an empty skuId. Invoke-TerminatingException is NOT mocked
    # here: the cmdlet has to stop before anything is sent.
    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }

        $script:SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:Plan1 = '11111111-1111-1111-1111-111111111111'
        $script:Plan2 = '22222222-2222-2222-2222-222222222222'
        $script:Plan3 = '33333333-3333-3333-3333-333333333333'
        $catalog = {
            [PSCustomObject]@{
                SkuId         = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
                SkuPartNumber = 'ENTERPRISEPACK'
                ServicePlans  = @(
                    [PSCustomObject]@{ ServicePlanId = '11111111-1111-1111-1111-111111111111'; ServicePlanName = 'EXCHANGE_S_ENTERPRISE' }
                    [PSCustomObject]@{ ServicePlanId = '22222222-2222-2222-2222-222222222222'; ServicePlanName = 'SHAREPOINTENTERPRISE' }
                    [PSCustomObject]@{ ServicePlanId = '33333333-3333-3333-3333-333333333333'; ServicePlanName = 'MCOSTANDARD' }
                )
            }
        }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku $catalog
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense $catalog

        # Targets that do NOT hold the SKU: the case where an unresolved plan is costly.
        $script:UserWithoutSku = [PSCustomObject]@{
            PSTypeName        = 'PSMicrosoftEntraID.Users.User'
            Id                = 'aaaaaaaa-0000-0000-0000-000000000001'
            UserPrincipalName = 'user@contoso.com'
            AssignedLicenses  = @()
        }
        $script:GroupWithoutSku = [PSCustomObject]@{
            PSTypeName       = 'PSMicrosoftEntraID.Groups.Group'
            Id               = 'bbbbbbbb-0000-0000-0000-000000000001'
            DisplayName      = 'Group'
            AssignedLicenses = @()
        }    }

    Context 'Unresolved input' {
        It '<Command> stops on a service plan name the SKU does not have' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
            @{ Command = 'Disable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Disable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
        ) {
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly
            { & $Command -InputObject $target -SkuId $script:SkuId -ServicePlanName 'EXCHANGE_S_ENTERPRISE', 'EXCHANGE_S_ENTERPRIZE' -Force } |
                Should -Throw -ExpectedMessage '*EXCHANGE_S_ENTERPRIZE*'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It '<Command> stops on a service plan id the SKU does not have' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
            @{ Command = 'Disable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Disable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
        ) {
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly
            { & $Command -InputObject $target -SkuId $script:SkuId -ServicePlanId '99999999-9999-9999-9999-999999999999' -Force } |
                Should -Throw -ExpectedMessage '*99999999-9999-9999-9999-999999999999*'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It '<Command> stops on an unknown SkuPartNumber' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
            @{ Command = 'Disable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Disable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
        ) {
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly
            { & $Command -InputObject $target -SkuPartNumber 'ENTERPRISEPAK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force } |
                Should -Throw -ExpectedMessage '*ENTERPRISEPAK*'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It '<Command> stops on a SkuId the tenant does not subscribe to' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
            @{ Command = 'Disable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Disable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
        ) {
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly
            { & $Command -InputObject $target -SkuId 'dddddddd-0000-0000-0000-000000000000' -ServicePlanId $script:Plan1 -Force } |
                Should -Throw -ExpectedMessage '*dddddddd-0000-0000-0000-000000000000*'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Resolved input still goes out' {
        It 'Enable-PSEntraIDUserLicenseServicePlan by name assigns the SKU with only the other plans disabled' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:UserWithoutSku -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'exchange_s_enterprise' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                ($Body | ConvertTo-Json -Compress -Depth 5) -match ('"disabledPlans":\["{0}","{1}"\]' -f '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')
            }
        }
    }

    Context 'A user object without AssignedLicenses is read again, not taken for "no licence"' {
        # A user from a minimal delta or a custom -Property selection carries no
        # AssignedLicenses at all. Enable-* took that for "does not hold the SKU" and
        # assigned it with every other plan disabled - overwriting the plans the user
        # really had enabled. Disable-* reported the SKU as not assigned and did nothing.
        BeforeAll {
            $script:SparseUser = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = 'aaaaaaaa-0000-0000-0000-000000000002'
                UserPrincipalName = 'sparse@contoso.com'
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser {
                [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = 'aaaaaaaa-0000-0000-0000-000000000002'
                    UserPrincipalName = 'sparse@contoso.com'
                    # Holds the SKU with plans 2 and 3 disabled.
                    AssignedLicenses  = @([PSCustomObject]@{
                            SkuId         = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
                            DisabledPlans = @('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333')
                        })
                }
            }
        }

        It 'Enable-PSEntraIDUserLicenseServicePlan keeps the plans the user has disabled' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:SparseUser -SkuId $script:SkuId -ServicePlanId $script:Plan2 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly -ParameterFilter {
                $Identity -contains 'aaaaaaaa-0000-0000-0000-000000000002'
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'users/aaaaaaaa-0000-0000-0000-000000000002/assignLicense' -and
                ($Body | ConvertTo-Json -Compress -Depth 5) -match '"disabledPlans":\["33333333-3333-3333-3333-333333333333"\]'
            }
        }

        It 'Disable-PSEntraIDUserLicenseServicePlan disables the plan on the SKU the user holds' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:SparseUser -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $json = $Body | ConvertTo-Json -Compress -Depth 5
                ($json -match '11111111-1111-1111-1111-111111111111') -and
                ($json -match '22222222-2222-2222-2222-222222222222') -and
                ($json -match '33333333-3333-3333-3333-333333333333')
            }
        }
    }
}
