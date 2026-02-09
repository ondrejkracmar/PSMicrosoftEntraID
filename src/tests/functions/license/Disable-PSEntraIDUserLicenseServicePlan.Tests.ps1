BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Disable-PSEntraIDUserLicenseServicePlan' -Tag 'Unit' {

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
        $script:TestSkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:TestSkuPartNumber = 'ENTERPRISEPACK'
        $script:TestServicePlanId1 = 'a23b959c-7ce8-4e57-9140-b90eb88a9e97'
        $script:TestServicePlanId2 = '9aaf7827-d63c-4b61-89c3-182f06f82e5c'
        $script:TestServicePlanName1 = 'EXCHANGE_S_ENTERPRISE'
        $script:TestServicePlanName2 = 'SHAREPOINTENTERPRISE'

        # Mock user with license
        $script:TestUser = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.User'
            Id = '12345678-1234-1234-1234-123456789012'
            UserPrincipalName = 'user@contoso.com'
            DisplayName = 'Test User'
            AssignedLicenses = @(
                [PSCustomObject]@{
                    SkuId = $script:TestSkuId
                    DisabledPlans = @()
                }
            )
        }

        # Mock license details
        $script:MockLicenseDetail = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.LicenseManagement.LicenseDetail'
            SkuId = $script:TestSkuId
            SkuPartNumber = $script:TestSkuPartNumber
            ServicePlans = @(
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId1
                    ServicePlanName = $script:TestServicePlanName1
                    ProvisioningStatus = 'Success'
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId2
                    ServicePlanName = $script:TestServicePlanName2
                    ProvisioningStatus = 'Success'
                }
            )
        }

        # Mock subscribed SKU
        $script:MockSubscribedSku = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
            SkuId = $script:TestSkuId
            SkuPartNumber = $script:TestSkuPartNumber
            ServicePlans = @(
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId1
                    ServicePlanName = $script:TestServicePlanName1
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId2
                    ServicePlanName = $script:TestServicePlanName2
                }
            )
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string for SkuId parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['SkuId']
            $param.ParameterType.Name | Should -Be 'String'
        }

        It 'Should accept string for SkuPartNumber parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['SkuPartNumber']
            $param.ParameterType.Name | Should -Be 'String'
        }

        It 'Should accept string array for ServicePlanId parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['ServicePlanId']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept string array for ServicePlanName parameter' {
            $param = (Get-Command Disable-PSEntraIDUserLicenseServicePlan).Parameters['ServicePlanName']
            $param.ParameterType.Name | Should -Be 'String[]'
        }
    }

    Context 'Disable service plan with SkuId and ServicePlanId' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDUserLicenseDetail' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUserLicenseDetail -Times 1 -Exactly
        }

        It 'Should call API with correct body structure' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId1 -and
                $Body.addLicenses[0].skuId -eq $script:TestSkuId -and
                $Body.removeLicenses.Count -eq 0
            }
        }

        It 'Should handle multiple service plans' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId @($script:TestServicePlanId1, $script:TestServicePlanId2) -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans.Count -eq 2
            }
        }

        It 'Should preserve existing disabled plans' {
            $licenseWithDisabled = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.LicenseManagement.LicenseDetail'
                SkuId = $script:TestSkuId
                ServicePlans = @(
                    [PSCustomObject]@{
                        ServicePlanId = $script:TestServicePlanId1
                        ProvisioningStatus = 'Disabled'
                    }
                    [PSCustomObject]@{
                        ServicePlanId = $script:TestServicePlanId2
                        ProvisioningStatus = 'Success'
                    }
                )
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $licenseWithDisabled }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId2 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId1 -and
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId2
            }
        }
    }

    Context 'Disable service plan with SkuPartNumber and ServicePlanName' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using names' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -ServicePlanName $script:TestServicePlanName1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDSubscribedSku to resolve names' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -ServicePlanName $script:TestServicePlanName1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedSku -Times 2 -Exactly
        }

        It 'Should handle SkuPartNumber with forward slash' {
            $skuWithSlash = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSku'
                SkuId = $script:TestSkuId
                SkuPartNumber = 'THREAT_INTELLIGENCE_URL/DOMAIN'
                ServicePlans = @(
                    [PSCustomObject]@{
                        ServicePlanId = $script:TestServicePlanId1
                        ServicePlanName = $script:TestServicePlanName1
                    }
                )
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $skuWithSlash }

            { Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber 'THREAT_INTELLIGENCE_URL/DOMAIN' -ServicePlanName $script:TestServicePlanName1 -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Pipeline and Identity parameter tests' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should process pipeline input with InputObject' {
            @($script:TestUser, $script:TestUser) | Disable-PSEntraIDUserLicenseServicePlan -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUserLicenseDetail -Times 2 -Exactly
        }

        It 'Should process multiple identities via Identity parameter' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity @('user1@contoso.com', 'user2@contoso.com') -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 2 -Exactly
        }
    }

    Context 'Disable service plan with Identity parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should call Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'user@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should disable service plan for retrieved user' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'user@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle when user is not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Disable-PSEntraIDUserLicenseServicePlan -Identity 'notfound@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'PassThru parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should return batch request when PassThru is specified' {
            $result = Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Edge cases' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should not call API when user has no license details' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $null }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Disable service plan with Identity, SkuPartNumber, and ServicePlanName (IdentitySkuPartNumberPlanName)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using Identity with SkuPartNumber and ServicePlanName' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'Disable service plan with Identity, SkuPartNumber, and ServicePlanId (IdentitySkuPartNumberPlanId)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using Identity with SkuPartNumber and ServicePlanId' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'Disable service plan with Identity, SkuId, and ServicePlanName (IdentitySkuIdServicePlanName)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using Identity with SkuId and ServicePlanName' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'Disable service plan with InputObject, SkuId, and ServicePlanName (InputObjectSkuIdServicePlanName)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using InputObject with SkuId and ServicePlanName' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @(
                    [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                )
            }
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should call Invoke-EntraRequest' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @(
                    [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                )
            }
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'Disable service plan with InputObject, SkuPartNumber, and ServicePlanId (InputObjectSkuPartNumberPlanId)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using InputObject with SkuPartNumber and ServicePlanId' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @(
                    [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                )
            }
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should call Invoke-EntraRequest' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @(
                    [PSCustomObject]@{ SkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'; DisabledPlans = @() }
                )
            }
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }
}
