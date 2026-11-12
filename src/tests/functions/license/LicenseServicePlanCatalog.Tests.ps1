BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Enable-*LicenseServicePlan never assigns a SKU it could not read the plans of' -Tag 'Unit' {
    # For a target that does not hold the SKU yet, Enable-* assigns it with every plan
    # disabled except the requested ones - and the list of "every plan" comes from the
    # subscribed SKU catalog. That read ran non-terminating: a failed read (403, 429,
    # 503) only warned, an empty answer was taken at face value, and the licence went
    # out with disabledPlans = [] - every plan enabled. Only the HTTP layer is faked:
    # Get-PSEntraIDSubscribedLicense runs for real, and Invoke-TerminatingException is
    # not mocked, so the command has to stop before anything is POSTed.
    BeforeAll {
        $script:SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:Plan1 = '11111111-1111-1111-1111-111111111111'
        $script:Plan2 = '22222222-2222-2222-2222-222222222222'
        $script:Plan3 = '33333333-3333-3333-3333-333333333333'
        $script:FullCatalog = @(
            [PSCustomObject]@{
                skuId         = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
                skuPartNumber = 'ENTERPRISEPACK'
                servicePlans  = @(
                    [PSCustomObject]@{ servicePlanId = '11111111-1111-1111-1111-111111111111'; servicePlanName = 'EXCHANGE_S_ENTERPRISE' }
                    [PSCustomObject]@{ servicePlanId = '22222222-2222-2222-2222-222222222222'; servicePlanName = 'SHAREPOINTENTERPRISE' }
                    [PSCustomObject]@{ servicePlanId = '33333333-3333-3333-3333-333333333333'; servicePlanName = 'MCOSTANDARD' }
                )
            }
        )
        $script:SkuWithoutPlans = @(
            [PSCustomObject]@{ skuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; skuPartNumber = 'ENTERPRISEPACK'; servicePlans = @() }
        )
        $script:OtherSkuOnly = @(
            [PSCustomObject]@{
                skuId         = 'dddddddd-0000-0000-0000-000000000000'
                skuPartNumber = 'OTHERPACK'
                servicePlans  = @([PSCustomObject]@{ servicePlanId = '44444444-4444-4444-4444-444444444444'; servicePlanName = 'OTHER' })
            }
        )

        # Typed objects, as Get-PSEntraIDUser returns them: piped PSCustomObjects bind by
        # property name to -Identity instead of to -InputObject.
        $script:UserWithoutSku = [PSMicrosoftEntraID.Users.User][PSCustomObject]@{
            Id                = 'aaaaaaaa-0000-0000-0000-000000000001'
            UserPrincipalName = 'user@contoso.com'
            AssignedLicenses  = @()
        }
        $script:GroupWithoutSku = [PSMicrosoftEntraID.Groups.Group][PSCustomObject]@{
            Id               = 'bbbbbbbb-0000-0000-0000-000000000001'
            DisplayName      = 'Group'
            AssignedLicenses = @()
        }

        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        # Get-PSEntraIDSubscribedSku is not an HTTP call: it hands back the PSFramework
        # result cache. The SKU-and-plan validation in begin may read it; it must know the
        # SKU, so that what is tested here is the full-plan-list read in process.
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku {
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
    }

    Context 'The catalog read does not deliver the plans of the SKU' {
        It '<Command> stops before any write when the catalog read fails' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku' }
        ) {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Path -eq 'subscribedSkus') { throw 'Response status code does not indicate success: 503 (Service Unavailable).' }
            }
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly

            { & $Command -InputObject $target -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force -WarningAction SilentlyContinue } |
                Should -Throw -ExpectedMessage "*$($script:SkuId)*"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
        }

        It '<Command> stops before any write when the catalog <Case>' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku'; Case = 'is empty'; Catalog = 'Empty' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku'; Case = 'is empty'; Catalog = 'Empty' }
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku'; Case = 'lists the SKU without plans'; Catalog = 'SkuWithoutPlans' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku'; Case = 'lists the SKU without plans'; Catalog = 'SkuWithoutPlans' }
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku'; Case = 'does not list the SKU'; Catalog = 'OtherSkuOnly' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku'; Case = 'does not list the SKU'; Catalog = 'OtherSkuOnly' }
        ) {
            $script:CatalogResponse = if ($Catalog -eq 'Empty') { @() } else { Get-Variable -Name $Catalog -Scope Script -ValueOnly }
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Path -eq 'subscribedSkus') { return $script:CatalogResponse }
            }
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly

            { & $Command -InputObject $target -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force -WarningAction SilentlyContinue } |
                Should -Throw -ExpectedMessage "*$($script:SkuId)*"
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
        }

        It 'Enable-PSEntraIDUserLicenseServicePlan sends nothing for ANY piped user once the catalog read failed' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Path -eq 'subscribedSkus') { throw 'Response status code does not indicate success: 429 (Too Many Requests).' }
            }
            $secondUser = [PSMicrosoftEntraID.Users.User][PSCustomObject]@{
                Id                = 'aaaaaaaa-0000-0000-0000-000000000002'
                UserPrincipalName = 'user2@contoso.com'
                AssignedLicenses  = @()
            }

            { $script:UserWithoutSku, $secondUser | Enable-PSEntraIDUserLicenseServicePlan -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force -WarningAction SilentlyContinue } |
                Should -Throw
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'Post' }
        }
    }

    Context 'The catalog read delivers the plans' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Path -eq 'subscribedSkus') { return $script:FullCatalog }
            }
        }

        It '<Command> assigns the SKU with every other plan disabled' -TestCases @(
            @{ Command = 'Enable-PSEntraIDUserLicenseServicePlan'; Target = 'UserWithoutSku'; WritePath = 'users/aaaaaaaa-0000-0000-0000-000000000001/assignLicense' }
            @{ Command = 'Enable-PSEntraIDGroupLicenseServicePlan'; Target = 'GroupWithoutSku'; WritePath = 'groups/bbbbbbbb-0000-0000-0000-000000000001/assignLicense' }
        ) {
            $target = Get-Variable -Name $Target -Scope Script -ValueOnly
            $script:ExpectedPath = $WritePath

            & $Command -InputObject $target -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and $Path -eq $script:ExpectedPath -and
                ($Body | ConvertTo-Json -Compress -Depth 5) -match '"disabledPlans":\["22222222-2222-2222-2222-222222222222","33333333-3333-3333-3333-333333333333"\]'
            }
        }

        It 'Enable-PSEntraIDUserLicenseServicePlan reads the catalog once for a pipeline of users without the SKU' {
            $secondUser = [PSMicrosoftEntraID.Users.User][PSCustomObject]@{
                Id                = 'aaaaaaaa-0000-0000-0000-000000000002'
                UserPrincipalName = 'user2@contoso.com'
                AssignedLicenses  = @()
            }

            $script:UserWithoutSku, $secondUser | Enable-PSEntraIDUserLicenseServicePlan -SkuId $script:SkuId -ServicePlanId $script:Plan1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Path -eq 'subscribedSkus' }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'Post' }
        }
    }
}
