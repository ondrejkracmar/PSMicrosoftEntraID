BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Enable-PSEntraIDUserLicense' -Tag 'Unit' {

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

        # Mock user
        $script:TestUser = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.User'
            Id = '12345678-1234-1234-1234-123456789012'
            UserPrincipalName = 'user@contoso.com'
            DisplayName = 'Test User'
            UsageLocation = 'US'
            AssignedLicenses = @()
        }

        # Mock subscribed SKUs
        $script:MockSubscribedSku = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
            SkuId = $script:TestSkuId1
            SkuPartNumber = $script:TestSkuPartNumber
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter for InputObjectSkuId parameter set' {
            $param = (Get-Command Enable-PSEntraIDUserLicense).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter for IdentitySkuId parameter set' {
            $param = (Get-Command Enable-PSEntraIDUserLicense).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for SkuId parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicense).Parameters['SkuId']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept string array for SkuPartNumber parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicense).Parameters['SkuPartNumber']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should have PassThru switch parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicense).Parameters['PassThru']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context 'Enable license with InputObject and SkuId' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should enable license for user' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call API with correct path' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "users/$($script:TestUser.Id)/assignLicense"
            }
        }

        It 'Should call API with correct body structure for single license' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses.Count -eq 1 -and
                $Body.addLicenses[0].skuId -eq $script:TestSkuId1 -and
                $Body.addLicenses[0].disabledPlans.Count -eq 0 -and
                $Body.removeLicenses.Count -eq 0
            }
        }

        It 'Should handle multiple SkuIds' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId @($script:TestSkuId1, $script:TestSkuId2) -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Body.addLicenses.Count -eq 2 -and
                $Body.addLicenses[0].skuId -eq $script:TestSkuId1 -and
                $Body.addLicenses[1].skuId -eq $script:TestSkuId2
            }
        }

        It 'Should enable license even if user already has other licenses' {
            $userWithLicense = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.User'
                Id = '12345678-1234-1234-1234-123456789013'
                UserPrincipalName = 'userlic@contoso.com'
                AssignedLicenses = @(
                    [PSCustomObject]@{ SkuId = $script:TestSkuId2; DisabledPlans = @() }
                )
            }

            Enable-PSEntraIDUserLicense -InputObject $userWithLicense -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'Enable license with InputObject and SkuPartNumber' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should enable license using SkuPartNumber' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDSubscribedSku to resolve SkuPartNumber' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedSku -Times 1 -Exactly
        }

        It 'Should call API with resolved SkuId from SkuPartNumber' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].skuId -eq $script:TestSkuId1
            }
        }

        It 'Should handle SkuPartNumber with forward slash' {
            $skuWithSlash = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
                SkuId = $script:TestSkuId2
                SkuPartNumber = 'THREAT_INTELLIGENCE_URL/DOMAIN'
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $skuWithSlash }

            { Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber 'THREAT_INTELLIGENCE_URL/DOMAIN' -Confirm:$false } | Should -Not -Throw
        }

        It 'Should handle multiple SkuPartNumbers' {
            $multipleSkus = @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
                    SkuId = $script:TestSkuId1
                    SkuPartNumber = 'ENTERPRISEPACK'
                }
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
                    SkuId = $script:TestSkuId2
                    SkuPartNumber = 'ENTERPRISEPREMIUM'
                }
            )
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $multipleSkus }

            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber @('ENTERPRISEPACK', 'ENTERPRISEPREMIUM') -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
                $Body.addLicenses.Count -eq 2
            }
        }
    }

    Context 'Enable license with Identity parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should call Get-PSEntraIDUser to retrieve user' {
            Enable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should enable license for retrieved user' {
            Enable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle when user is not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Enable-PSEntraIDUserLicense -Identity 'notfound@contoso.com' -SkuId $script:TestSkuId1 -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }

        It 'Should process multiple identities' {
            Enable-PSEntraIDUserLicense -Identity @('user1@contoso.com', 'user2@contoso.com') -SkuId $script:TestSkuId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 2 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'PassThru parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should return batch request object when PassThru is specified with SkuId' {
            $result = Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'assignLicense'
        }

        It 'Should return batch request object when PassThru is specified with SkuPartNumber' {
            $result = Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Match 'assignLicense'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Identity with SkuPartNumber' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should enable license using Identity and SkuPartNumber' {
            Enable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedSku -Times 1 -Exactly
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should resolve SkuPartNumber to SkuId before enabling' {
            Enable-PSEntraIDUserLicense -Identity 'user@contoso.com' -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].skuId -eq $script:TestSkuId1
            }
        }
    }

    Context 'Pipeline and batch processing' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should accept pipeline input with SkuId' {
            { @($script:TestUser, $script:TestUser) | Enable-PSEntraIDUserLicense -SkuId $script:TestSkuId1 -Confirm:$false } | Should -Not -Throw
        }

        It 'Should accept pipeline input with SkuPartNumber' {
            { @($script:TestUser, $script:TestUser) | Enable-PSEntraIDUserLicense -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Edge cases and error handling' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should use Force switch correctly' {
            Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId $script:TestSkuId1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should handle empty license array' {
            { Enable-PSEntraIDUserLicense -InputObject $script:TestUser -SkuId @() -Confirm:$false } | Should -Throw
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
                    UsageLocation     = 'US'
                    AssignedLicenses  = @()
                }

                Enable-PSEntraIDUserLicense -InputObject $testUser -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -WhatIf

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
                    UsageLocation     = 'US'
                    AssignedLicenses  = @()
                }

                $testUser | Enable-PSEntraIDUserLicense -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -Force -Confirm:$false

                Should -Invoke -CommandName Invoke-PSFProtectedCommand -Times 1
            }
        }
    }
}
