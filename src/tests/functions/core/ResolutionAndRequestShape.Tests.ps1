BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Compare-PSEntraIDUserList connection check' -Tag 'Unit' {
    # It asserted a connection to a service called 'graph', which is never registered -
    # the Graph service is 'PSMicrosoftEntraID.Graph' - so the command answered "Not
    # connected" to everyone. Its own tests mocked Assert-EntraConnection away; this one
    # runs the real assertion against a real token table.
    BeforeAll {
        $script:SavedTokens = InModuleScope PSMicrosoftEntraID { $script:_EntraTokens }
        InModuleScope PSMicrosoftEntraID { $script:_EntraTokens = @{ 'PSMicrosoftEntraID.Graph' = $true } }
    }
    AfterAll {
        InModuleScope PSMicrosoftEntraID -Parameters @{ Saved = $script:SavedTokens } { param($Saved) $script:_EntraTokens = $Saved }
    }

    It 'runs when the default Graph service is connected' {
        $result = @(Compare-PSEntraIDUserList -ReferenceIdentity 'a@contoso.com', 'b@contoso.com' -DifferenceIdentity 'b@contoso.com', 'c@contoso.com')

        @($result | Where-Object Crud -EQ 'Create').Identity | Should -Be 'a@contoso.com'
        @($result | Where-Object Crud -EQ 'Delete').Identity | Should -Be 'c@contoso.com'
    }

    It 'still refuses when nothing is connected' {
        InModuleScope PSMicrosoftEntraID { $script:_EntraTokens = @{} }
        try {
            { Compare-PSEntraIDUserList -ReferenceIdentity 'a@contoso.com' -DifferenceIdentity 'b@contoso.com' } | Should -Throw -ExpectedMessage '*PSMicrosoftEntraID.Graph*'
        }
        finally {
            InModuleScope PSMicrosoftEntraID { $script:_EntraTokens = @{ 'PSMicrosoftEntraID.Graph' = $true } }
        }
    }
}

Describe 'Get-PSEntraIDUserMemberOf request shape' -Tag 'Unit' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestGroup { }
        Mock -ModuleName $script:ModuleName Write-PSFMessage { } -ParameterFilter { $Level -eq 'Warning' }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser {
            param($Identity)
            if ($Identity -like 'missing*') { return $null }
            [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Users.User'; Id = 'user-id-001'; UserPrincipalName = $Identity }
        }
    }

    It 'sends ConsistencyLevel: eventual with -Filter' {
        # The header was built and never handed to Invoke-EntraRequest; Graph rejects a
        # memberOf $filter without it.
        Get-PSEntraIDUserMemberOf -Identity 'john@contoso.com' -Filter "startswith(displayName,'IT')"

        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
            $Path -eq 'users/user-id-001/memberOf' -and $Header['ConsistencyLevel'] -eq 'eventual' -and
            $Query['$Filter'] -eq "startswith(displayName,'IT')"
        }
    }

    It 'requests nothing for an identity that does not resolve, and warns' {
        # Was: GET users//memberOf.
        Get-PSEntraIDUserMemberOf -Identity 'missing@contoso.com'

        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        Should -Invoke -ModuleName $script:ModuleName -CommandName Write-PSFMessage -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'Warning' -and $String -eq 'User.Get.Failed' -and $StringValues -contains 'missing@contoso.com'
        }
    }
}

Describe 'Get-PSEntraIDUser resolution order: Id, then userPrincipalName, then mail' -Tag 'Unit' {
    # The mail lookup ran first. When user B's mail equals user A's UPN (a renamed
    # account, a shared alias), asking for A's UPN returned B.
    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { [PSCustomObject]@{ Value = @('id', 'userPrincipalName', 'mail', 'userType') } }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestUserGuest { $InputObject }

        # A: upn shared@contoso.com. B: mail shared@contoso.com.
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            switch ($Path) {
                'users' {
                    if ($Query['$Filter'] -eq "userPrincipalName eq 'shared@contoso.com'") { return [PSCustomObject]@{ id = 'id-A' } }
                    if ($Query['$Filter'] -eq "mail eq 'shared@contoso.com'") { return [PSCustomObject]@{ id = 'id-B' } }
                    if ($Query['$Filter'] -eq "mail eq 'alias@contoso.com'") { return [PSCustomObject]@{ id = 'id-B' } }
                    return $null
                }
                default { return [PSCustomObject]@{ id = ($Path -replace '^users/'); userType = 'Guest' } }
            }
        }
    }

    It '<Command> returns the account whose UPN matches, not the one whose mail does' -TestCases @(
        @{ Command = 'Get-PSEntraIDUser' }
        @{ Command = 'Get-PSEntraIDUserGuest' }
    ) {
        $result = & $Command -Identity 'shared@contoso.com'

        $result.id | Should -Be 'id-A'
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Path -eq 'users/id-A' }
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Path -eq 'users/id-B' }
    }

    It '<Command> falls back to mail when no UPN matches' -TestCases @(
        @{ Command = 'Get-PSEntraIDUser' }
        @{ Command = 'Get-PSEntraIDUserGuest' }
    ) {
        $result = & $Command -Identity 'alias@contoso.com'

        $result.id | Should -Be 'id-B'
    }

    It '<Command> reads an object id directly, without a lookup' -TestCases @(
        @{ Command = 'Get-PSEntraIDUser' }
        @{ Command = 'Get-PSEntraIDUserGuest' }
    ) {
        $id = 'e3305c17-6656-4a6f-946e-56c6c005aef9'
        $result = & $Command -Identity $id

        $result.id | Should -Be $id
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Path -eq 'users' }
    }
}

Describe 'Get-SubscribedLicenseCompletion' -Tag 'Unit' {
    # Its loop variable $servicePlan is the [switch] parameter $ServicePlan - PowerShell
    # variables are case-insensitive - so the first plan was coerced to a switch and the
    # completer threw; Tab then completed nothing.
    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense {
            [PSCustomObject]@{
                SkuId           = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
                SkuPartNumber   = 'ENTERPRISEPACK'
                SkuFriendlyName = 'Office 365 E3'
                ServicePlans    = @(
                    [PSCustomObject]@{ ServicePlanId = '11111111-1111-1111-1111-111111111111'; ServicePlanName = 'EXCHANGE_S_ENTERPRISE'; ServicePlanFriendlyName = 'Exchange Online' }
                    [PSCustomObject]@{ ServicePlanId = '22222222-2222-2222-2222-222222222222'; ServicePlanName = 'SHAREPOINTENTERPRISE'; ServicePlanFriendlyName = 'SharePoint Online' }
                )
            }
        }
    }

    It 'completes service plan names with -ServicePlan' {
        $result = @(InModuleScope PSMicrosoftEntraID { Get-SubscribedLicenseCompletion -ArgumentList @($null, $null, 'EXCH') -ServicePlan })

        $result.Count | Should -Be 1
        $result[0] | Should -BeOfType ([System.Management.Automation.CompletionResult])
        $result[0].CompletionText | Should -Be 'EXCHANGE_S_ENTERPRISE'
    }

    It 'is not attached to the GUID parameter -ServicePlanId, which it would fill with names' {
        $attributes = (Get-Command Enable-PSEntraIDGroupLicenseServicePlan).Parameters['ServicePlanId'].Attributes
        @($attributes | Where-Object { $_ -is [ArgumentCompleter] -and "$($_.ScriptBlock)" -match 'Get-SubscribedLicenseCompletion' }).Count | Should -Be 0
    }
}

Describe 'Get-PSEntraIDGroup escapes the fallback path' -Tag 'Unit' {
    # When no group has the given mailNickName the identity itself goes into the PATH,
    # groups/{0}, and was not escaped: '#' started the URI fragment and '/' or '?' changed
    # the request.
    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { [PSCustomObject]@{ Value = @('id', 'displayName', 'mailNickname') } }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestGroup { $InputObject }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { if ($Path -eq 'groups') { return $null } }
    }

    It 'sends groups/{identity} with the identity escaped' {
        Get-PSEntraIDGroup -Identity 'team#1'

        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Path -eq 'groups/team%231' }
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Path -like 'groups/*#*' }
    }
}
