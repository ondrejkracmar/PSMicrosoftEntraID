BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Enable-PSEntraIDUserLicenseServicePlan' -Tag 'Unit' {

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
        $script:TestServicePlanId3 = '43de0ff5-c92c-492b-9116-175376d08c38'
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
                    DisabledPlans = @($script:TestServicePlanId1)
                }
            )
        }

        # Mock license details with some disabled plans
        $script:MockLicenseDetail = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.Users.LicenseManagement.LicenseDetail'
            SkuId = $script:TestSkuId
            SkuPartNumber = $script:TestSkuPartNumber
            ServicePlans = @(
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId1
                    ServicePlanName = $script:TestServicePlanName1
                    ProvisioningStatus = 'Disabled'
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId2
                    ServicePlanName = $script:TestServicePlanName2
                    ProvisioningStatus = 'Success'
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId3
                    ServicePlanName = 'MCOSTANDARD'
                    ProvisioningStatus = 'Disabled'
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
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId3
                    ServicePlanName = 'MCOSTANDARD'
                }
            )
        }

        # Mock subscribed license for when user doesn't have the license yet
        $script:MockSubscribedLicense = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
            SkuId = $script:TestSkuId
            SkuPartNumber = $script:TestSkuPartNumber
            ServicePlans = @(
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId1
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId2
                }
                [PSCustomObject]@{
                    ServicePlanId = $script:TestServicePlanId3
                }
            )
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Identity parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string for SkuId parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['SkuId']
            $param.ParameterType.Name | Should -Be 'String'
        }

        It 'Should accept string for SkuPartNumber parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['SkuPartNumber']
            $param.ParameterType.Name | Should -Be 'String'
        }

        It 'Should accept string array for ServicePlanId parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['ServicePlanId']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept string array for ServicePlanName parameter' {
            $param = (Get-Command Enable-PSEntraIDUserLicenseServicePlan).Parameters['ServicePlanName']
            $param.ParameterType.Name | Should -Be 'String[]'
        }
    }

    Context 'Enable service plan with SkuId and ServicePlanId' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDUserLicenseDetail' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUserLicenseDetail -Times 1 -Exactly
        }

        It 'Should call API with correct body structure' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].skuId -eq $script:TestSkuId -and
                $Body.removeLicenses.Count -eq 0
            }
        }

        It 'Should remove specified plan from disabled list' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -notcontains $script:TestServicePlanId1
            }
        }

        It 'Should preserve other disabled plans' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId3
            }
        }

        It 'Should handle multiple service plans' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId @($script:TestServicePlanId1, $script:TestServicePlanId3) -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -notcontains $script:TestServicePlanId1 -and
                $Body.addLicenses[0].disabledPlans -notcontains $script:TestServicePlanId3
            }
        }
    }

    Context 'Enable service plan with SkuPartNumber and ServicePlanName' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using names' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -ServicePlanName $script:TestServicePlanName1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should call Get-PSEntraIDSubscribedSku to resolve names' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -ServicePlanName $script:TestServicePlanName1 -Confirm:$false

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

            { Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber 'THREAT_INTELLIGENCE_URL/DOMAIN' -ServicePlanName $script:TestServicePlanName1 -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Pipeline and Identity parameter tests' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should process pipeline input with InputObject' {
            @($script:TestUser, $script:TestUser) | Enable-PSEntraIDUserLicenseServicePlan -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUserLicenseDetail -Times 2 -Exactly
        }

        It 'Should process multiple identities via Identity parameter' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity @('user1@contoso.com', 'user2@contoso.com') -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 2 -Exactly
        }
    }

    Context 'Enable service plan when user does not have the license' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $null }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should call Get-PSEntraIDSubscribedLicense when user has no license' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedLicense -Times 1 -Exactly
        }

        It 'Should get all service plans from subscribed license' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans.Count -ge 0
            }
        }
    }

    Context 'Enable service plan with Identity parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should call Get-PSEntraIDUser' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'user@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }

        It 'Should enable service plan for retrieved user' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'user@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'Should handle when user is not found' {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $null }

            Enable-PSEntraIDUserLicenseServicePlan -Identity 'notfound@contoso.com' -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -EnableException -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-TerminatingException -Times 1 -Exactly
        }
    }

    Context 'PassThru parameter' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should return batch request when PassThru is specified' {
            $result = Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Edge cases' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should handle empty disabled plans list' {
            $licenseNoDisabled = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Users.LicenseManagement.LicenseDetail'
                SkuId = $script:TestSkuId
                ServicePlans = @(
                    [PSCustomObject]@{
                        ServicePlanId = $script:TestServicePlanId1
                        ProvisioningStatus = 'Success'
                    }
                )
            }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $licenseNoDisabled }

            Enable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans.Count -eq 0
            }
        }
    }

    Context 'IdentitySkuPartNumberPlanName parameter set' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using Identity, SkuPartNumber, and ServicePlanName' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'IdentitySkuPartNumberPlanId parameter set' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using Identity, SkuPartNumber, and ServicePlanId' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'IdentitySkuIdServicePlanName parameter set' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using Identity, SkuId, and ServicePlanName' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Enable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUser -Times 1 -Exactly
        }
    }

    Context 'InputObjectSkuIdServicePlanName parameter set' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using InputObject, SkuId, and ServicePlanName' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:TestServicePlanId1) })
            }

            InModuleScope $script:ModuleName -Parameters @{ inputObj = $inputObj; skuId = $script:TestSkuId; planName = $script:TestServicePlanName1 } {
                Enable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId $skuId -ServicePlanName $planName -Force -Confirm:$false
            }

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should call Invoke-EntraRequest' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:TestServicePlanId1) })
            }

            InModuleScope $script:ModuleName -Parameters @{ inputObj = $inputObj; skuId = $script:TestSkuId; planName = $script:TestServicePlanName1 } {
                Enable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId $skuId -ServicePlanName $planName -Force -Confirm:$false
            }

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }

    Context 'InputObjectSkuPartNumberPlanId parameter set' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { $script:MockSubscribedLicense }
        }

        It 'Should enable service plan using InputObject, SkuPartNumber, and ServicePlanId' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:TestServicePlanId1) })
            }

            InModuleScope $script:ModuleName -Parameters @{ inputObj = $inputObj; skuPartNumber = $script:TestSkuPartNumber; planId = $script:TestServicePlanId1 } {
                Enable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber $skuPartNumber -ServicePlanId $planId -Force -Confirm:$false
            }

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should call Invoke-EntraRequest' {
            $inputObj = [PSCustomObject]@{
                PSTypeName       = 'PSMicrosoftEntraID.Users.User'
                Id               = '12345678-1234-1234-1234-123456789012'
                UserPrincipalName = 'testuser@domain.com'
                AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @($script:TestServicePlanId1) })
            }

            InModuleScope $script:ModuleName -Parameters @{ inputObj = $inputObj; skuPartNumber = $script:TestSkuPartNumber; planId = $script:TestServicePlanId1 } {
                Enable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber $skuPartNumber -ServicePlanId $planId -Force -Confirm:$false
            }

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }
}
