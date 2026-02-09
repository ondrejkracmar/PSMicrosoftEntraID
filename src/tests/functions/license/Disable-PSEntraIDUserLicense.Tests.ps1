BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }

    # Module is already imported by pester.ps1
    # No need to import again as it causes path issues
}

Describe 'Disable-PSEntraIDUserLicense' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        
        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'User not found' } -ParameterFilter { $Name -eq 'User.Get.Failed' }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }

        # Mock license data
        $script:TestSkuId1 = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:TestSkuId2 = '6fd2c87f-b296-42f0-b197-1e91e994b900'
        $script:TestSkuPartNumber = 'ENTERPRISEPACK'

        # Mock user with licenses
        $script:TestUser = [PSCustomObject]@{
            Id                = '12345678-1234-1234-1234-123456789012'
            UserPrincipalName = 'user@contoso.com'
            DisplayName       = 'Test User'
            AssignedLicenses  = @(
                [PSCustomObject]@{
                    SkuId         = $script:TestSkuId1
                    DisabledPlans = @()
                }
            )
        }

        # Mock user without licenses
        $script:TestUserNoLicense = [PSCustomObject]@{
            Id                = '12345678-1234-1234-1234-123456789013'
            UserPrincipalName = 'usernolic@contoso.com'
            DisplayName       = 'Test User No License'
            AssignedLicenses  = @()
        }

        # Mock subscribed SKUs
        $script:MockSubscribedSku = [PSCustomObject]@{
            SkuId         = $script:TestSkuId1
            SkuPartNumber = $script:TestSkuPartNumber
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter for InputObjectSkuId parameter set' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter for IdentitySkuId parameter set' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for SkuId parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['SkuId']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept string array for SkuPartNumber parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['SkuPartNumber']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Disable license with InputObject and SkuId' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable license when user has the license' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should not call API when user does not have the license' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUserNoLicense -SkuId $script:TestSkuId2 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should call API with correct path' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "users/$($script:TestUser.Id)/assignLicense"
            }
        }

        It 'Should call API with correct body structure' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.removeLicenses -contains $script:TestSkuId1 -and
                $Body.addLicenses.Count -eq 0
            }
        }

        It 'Should handle multiple SkuIds' {
            $userWithMultipleLicenses = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'user@contoso.com'
                AssignedLicenses  = @(
                    [PSCustomObject]@{ SkuId = $script:TestSkuId1; DisabledPlans = @() }
                    [PSCustomObject]@{ SkuId = $script:TestSkuId2; DisabledPlans = @() }
                )
            }

            Disable-PSEntraIDUserLicense -InputObject $userWithMultipleLicenses -SkuId @($script:TestSkuId1, $script:TestSkuId2) -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Body.removeLicenses.Count -eq 2
            }
        }
    }

    Context 'Disable license with InputObject and SkuPartNumber' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable license when user has the license' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDSubscribedSku to resolve SkuPartNumber' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedSku -Times 1 -Exactly
        }

        It 'Should handle SkuPartNumber with forward slash' {
            $skuWithSlash = [PSCustomObject]@{
                PSTypeName    = 'PSMicrosoftEntraID.License.SubscriptionSku'
                SkuId         = $script:TestSkuId2
                SkuPartNumber = 'THREAT_INTELLIGENCE_URL/DOMAIN'
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $skuWithSlash }

            $userWithSlashLicense = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '12345678-1234-1234-1234-123456789014'
                UserPrincipalName = 'userslash@contoso.com'
                AssignedLicenses  = @(
                    [PSCustomObject]@{ SkuId = $script:TestSkuId2; DisabledPlans = @() }
                )
            }

            { Disable-PSEntraIDUserLicense -InputObject $userWithSlashLicense -SkuPartNumber 'THREAT_INTELLIGENCE_URL/DOMAIN' -Confirm:$false } | Should -Not -Throw
        }

        It 'Should handle multiple SkuPartNumbers' {
            $multipleSkus = @(
                [PSCustomObject]@{
                    SkuId         = $script:TestSkuId1
                    SkuPartNumber = 'ENTERPRISEPACK'
                }
                [PSCustomObject]@{
                    SkuId         = $script:TestSkuId2
                    SkuPartNumber = 'ENTERPRISEPREMIUM'
                }
            )
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $multipleSkus }

            $userWithMultipleLicenses = [PSCustomObject]@{
                Id                = '12345678-1234-1234-1234-123456789016'
                UserPrincipalName = 'usermulti@contoso.com'
                AssignedLicenses  = @(
                    [PSCustomObject]@{ SkuId = $script:TestSkuId1; DisabledPlans = @() }
                    [PSCustomObject]@{ SkuId = $script:TestSkuId2; DisabledPlans = @() }
                )
            }

            Disable-PSEntraIDUserLicense -InputObject $userWithMultipleLicenses -SkuPartNumber @('ENTERPRISEPACK', 'ENTERPRISEPREMIUM') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Body.removeLicenses.Count -eq 2
            }
        }
    }

    Context 'Disable license with Identity parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should call Get-PSEntraIDUser to retrieve user' {
            Disable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should disable license when user has the license' {
            Disable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle when user is not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Disable-PSEntraIDUserLicense -Identity 'notfound@contoso.com' -SkuId $script:TestSkuId1 -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }

        It 'Should process multiple identities' {
            Disable-PSEntraIDUserLicense -Identity @('user1@contoso.com', 'user2@contoso.com') -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 2 -Exactly
        }
    }

    Context 'PassThru parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should return batch request object when PassThru is specified with SkuId' {
            $result = Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'assignLicense'
        }

        It 'Should return batch request object when PassThru is specified with SkuPartNumber' {
            $result = Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'assignLicense'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Pipeline and batch processing' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should have ValueFromPipeline attribute on InputObject parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicense).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should accept pipeline input with SkuId' {
            { @($script:TestUser, $script:TestUser) | Disable-PSEntraIDUserLicense -SkuId $script:TestSkuId1 -Confirm:$false } | Should -Not -Throw
        }

        It 'Should accept pipeline input with SkuPartNumber' {
            { @($script:TestUser, $script:TestUser) | Disable-PSEntraIDUserLicense -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Identity with SkuPartNumber' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable license using Identity and SkuPartNumber' {
            Disable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedSku -Times 1 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should resolve SkuPartNumber to SkuId before disabling' {
            Disable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.removeLicenses -contains $script:TestSkuId1
            }
        }
    }

    Context 'Edge cases and error handling' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
        }

        It 'Should handle user with null AssignedLicenses' {
            $userNullLicenses = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = '12345678-1234-1234-1234-123456789015'
                UserPrincipalName = 'usernull@contoso.com'
                AssignedLicenses  = $null
            }

            Disable-PSEntraIDUserLicense -InputObject $userNullLicenses -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }

        It 'Should handle empty SkuId array' {
            { Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId @() -Confirm:$false } | Should -Throw
        }

        It 'Should use Force switch correctly' {
            Disable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }
    }

    Context 'WhatIf support' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
        }

        It 'Should not invoke Invoke-EntraRequest when -WhatIf is specified' {
            InModuleScope $script:ModuleName {
                $testUser = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = '12345678-1234-1234-1234-123456789012'
                    UserPrincipalName = 'user@contoso.com'
                    AssignedLicenses  = @(
                        [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                    )
                }

                Disable-PSEntraIDUserLicense -InputObject $testUser -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -WhatIf

                Should -Invoke -CommandName Invoke-EntraRequest -Times 0
            }
        }
    }

    Context 'Pipeline input with Invoke-PSFProtectedCommand' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should accept pipeline input and call Invoke-PSFProtectedCommand' {
            InModuleScope $script:ModuleName {
                $testUser = [PSCustomObject]@{
                    PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                    Id                = '12345678-1234-1234-1234-123456789012'
                    UserPrincipalName = 'user@contoso.com'
                    AssignedLicenses  = @(
                        [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                    )
                }

                $testUser | Disable-PSEntraIDUserLicense -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }
}
