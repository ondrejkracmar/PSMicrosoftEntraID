BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Import here rather than relying on whichever test file happened to run first:
    # Pester executes every file in ONE runspace, so an ambient import made these
    # tests pass alone and fail in a full run with
    #   RuntimeException: No modules named 'PSMicrosoftEntraID' are currently loaded.
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
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

    Context 'Wire format' {
        # Every other test here asserts on $Body as a PowerShell OBJECT:
        #
        #   $Body.addLicenses[0].disabledPlans -contains $planId
        #
        # -contains is true for a scalar as well as for an array, so an assertion like
        # that passes whether disabledPlans is ["x"] or "x". Graph answers the second
        # question, not the first:
        #
        #   Request_BadRequest: An unexpected 'PrimitiveValue' node was found when
        #   reading from the JSON reader. A 'StartArray' node was expected.
        #
        # A live tenant produced exactly that, repeatedly, for a single service plan -
        # while the same call with every plan of the SKU succeeded. These tests look at
        # the JSON, serialised the way Invoke-EntraRequest serialises it, so the shape
        # that actually leaves the machine is pinned rather than inferred.
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }

            # The body is serialised inside -ParameterFilter, which runs in the same
            # scope as the mock. Handing it out through a $script: variable does not
            # work: the mock body and the test body are different scopes, and the read
            # comes back $null - which reads exactly like "no request was made".
            $script:BodyJson = { $Body | ConvertTo-Json -Compress -Depth 99 }
        }

        It 'sends disabledPlans as an array for ONE plan by id' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                ($Body | ConvertTo-Json -Compress -Depth 99) -match '"disabledPlans":\['
            } -Because 'Graph rejects a scalar with "a StartArray node was expected"'
        }

        It 'sends disabledPlans as an array for ONE plan by name' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuPartNumber $script:TestSkuPartNumber -ServicePlanName $script:TestServicePlanName1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                ($Body | ConvertTo-Json -Compress -Depth 99) -match '"disabledPlans":\['
            }
        }

        It 'sends addLicenses and removeLicenses as arrays' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $json = $Body | ConvertTo-Json -Compress -Depth 99
                ($json -match '"addLicenses":\[\{') -and ($json -match '"removeLicenses":\[')
            }
        }

        It 'writes the JSON it produced to the console, so a failure names the shape' {
            # A file, not a variable: it is the one channel that crosses the mock
            # boundary reliably.
            $capturePath = Join-Path ([System.IO.Path]::GetTempPath()) 'psentraid-wire-format.json'
            if (Test-Path -LiteralPath $capturePath) { Remove-Item -LiteralPath $capturePath -Force }

            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $Body | ConvertTo-Json -Compress -Depth 99 |
                    Set-Content -LiteralPath (Join-Path ([System.IO.Path]::GetTempPath()) 'psentraid-wire-format.json')
            }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Force

            Test-Path -LiteralPath $capturePath | Should -BeTrue -Because 'the cmdlet has to make a request at all'
            $json = Get-Content -LiteralPath $capturePath -Raw
            Write-Host "      JSON sent: $json" -ForegroundColor DarkGray
            Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue
            $json | Should -Match '"disabledPlans":\['
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

        It 'reads existing state from AssignedLicenses, never licenseDetails' {
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            # licenseDetails' provisioningStatus trails the assignment by seconds to
            # minutes, so a plan disabled a moment ago read as enabled and the next call
            # silently re-enabled it - verified against a live tenant. The merge source
            # is assignedLicenses.disabledPlans, which this cmdlet's own write sets and
            # which is visible immediately. This asserts the laggy read is GONE.
            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDUserLicenseDetail -Times 0 -Exactly
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
            # The already-disabled plan is expressed where the cmdlet now reads it:
            # assignedLicenses.disabledPlans. This is the ADD-not-replace regression a
            # live tenant caught - two disables in a row kept only the second, because
            # the first was read from provisioningStatus, which had not caught up yet.
            $userWithDisabled = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = $script:TestUser.Id
                UserPrincipalName = $script:TestUser.UserPrincipalName
                AssignedLicenses  = @(
                    [PSCustomObject]@{
                        SkuId         = $script:TestSkuId
                        DisabledPlans = @($script:TestServicePlanId1)
                    }
                )
            }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $userWithDisabled -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId2 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId1 -and
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId2
            }
        }

        It 'warns and sends nothing when the user does not hold the SKU' {
            Mock -ModuleName $script:ModuleName Write-PSFMessage { }
            $userWithoutSku = [PSCustomObject]@{
                PSTypeName        = 'PSMicrosoftEntraID.Users.User'
                Id                = $script:TestUser.Id
                UserPrincipalName = $script:TestUser.UserPrincipalName
                AssignedLicenses  = @()
            }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $userWithoutSku -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            # Silence here reads as success and it is not - same convention as the
            # group cmdlets and finding #7.
            Should -Invoke -ModuleName $script:ModuleName -CommandName Write-PSFMessage -ParameterFilter {
                $String -eq 'License.Sku.NotAssigned'
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
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

            # One request per piped user; state comes off each object's own
            # AssignedLicenses, so no extra reads happen at all.
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
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

        It 'still disables when licenseDetails has not caught up yet' {
            # The live-tenant regression, pinned. licenseDetails trails the assignment,
            # so a user whose SKU was assigned a moment ago has an assignedLicenses
            # entry and NO licence detail. The old code read its state from the detail
            # and treated this exact situation as "nothing to do". Holding the SKU is
            # what matters, and the user does.
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $null }

            Disable-PSEntraIDUserLicenseServicePlan -InputObject $script:TestUser -SkuId $script:TestSkuId -ServicePlanId $script:TestServicePlanId1 -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.addLicenses[0].disabledPlans -contains $script:TestServicePlanId1
            } -Times 1 -Exactly
        }
    }

    Context 'Disable service plan with Identity, SkuPartNumber, and ServicePlanName (IdentitySkuPartNumberPlanName)' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUser { $script:TestUser }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDUserLicenseDetail { $script:MockLicenseDetail }
            Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedSku { $script:MockSubscribedSku }
        }

        It 'Should disable service plan using Identity with SkuPartNumber and ServicePlanName' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should resolve user via Get-PSEntraIDUser' {
            Disable-PSEntraIDUserLicenseServicePlan -Identity 'testuser@domain.com' -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuId 'c7df2760-2c81-4ef7-b578-5b5392b571df' -ServicePlanName 'EXCHANGE_S_ENTERPRISE' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force

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
            Disable-PSEntraIDUserLicenseServicePlan -InputObject $inputObj -SkuPartNumber 'ENTERPRISEPACK' -ServicePlanId 'a23b959c-7ce8-4e57-9140-b90eb88a9e97' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }
    }
}
