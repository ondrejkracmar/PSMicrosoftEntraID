BeforeAll {
    $moduleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$moduleName/$moduleName.psd1" -Force
}

Describe 'Get-PSEntraIDGroupLicense' -Tag 'Unit' {
    BeforeAll {
        function New-TestAssignedLicense {
            param(
                [string] $SkuId,
                [string[]] $DisabledPlans = @()
            )

            [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Groups.AssignedLicense'
                SkuId = [guid]$SkuId
                DisabledPlans = @($DisabledPlans | ForEach-Object { [guid]$_ })
            }
        }

        function New-TestGroup {
            param(
                [string] $Id,
                [string] $DisplayName,
                [string] $Mail,
                [string] $MailNickname,
                [object[]] $AssignedLicenses = @()
            )

            $group = New-Object -TypeName 'PSMicrosoftEntraID.Groups.Group'
            $group.Id = $Id
            $group.DisplayName = $DisplayName
            $group.Mail = $Mail
            $group.MailNickname = $MailNickname
            $group.AssignedLicenses = @($AssignedLicenses)
            $group
        }

        Mock Get-PSFConfigValue -ModuleName PSMicrosoftEntraID {
            param($FullName)
            switch ($FullName) {
                'PSMicrosoftEntraID.Settings.DefaultService' { return 'PSMicrosoftEntraID.Graph' }
                'PSMicrosoftEntraID.Settings.Command.RetryCount' { return 3 }
                'PSMicrosoftEntraID.Settings.Command.RetryWaitInSeconds' { return 5 }
            }
        }

        Mock Assert-EntraConnection -ModuleName PSMicrosoftEntraID { }

        Mock Invoke-PSFProtectedCommand -ModuleName PSMicrosoftEntraID {
            param($ScriptBlock)
            & $ScriptBlock
        }

        Mock Test-PSFFunctionInterrupt -ModuleName PSMicrosoftEntraID { return $false }

        Mock Get-PSEntraIDSubscribedLicense -ModuleName PSMicrosoftEntraID {
            @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
                    SkuId = '11111111-1111-1111-1111-111111111111'
                    SkuPartNumber = 'ENTERPRISEPACK'
                    ServicePlans = @(
                        [PSCustomObject]@{
                            ServicePlanId = '22222222-2222-2222-2222-222222222222'
                            ServicePlanName = 'EXCHANGE_S_ENTERPRISE'
                            ProvisioningStatus = 'Success'
                            AppliesTo = 'User'
                        },
                        [PSCustomObject]@{
                            ServicePlanId = '33333333-3333-3333-3333-333333333333'
                            ServicePlanName = 'SHAREPOINTWAC'
                            ProvisioningStatus = 'Success'
                            AppliesTo = 'User'
                        }
                    )
                }
            )
        }

        Mock Get-PSEntraIDLicenseIdentifier -ModuleName PSMicrosoftEntraID {
            @(
                [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.License.LicenseIdentifier'
                    SkuId = '11111111-1111-1111-1111-111111111111'
                    SkuPartNumber = 'ENTERPRISEPACK'
                    SkuFriendlyName = 'Office 365 E3'
                    ServicePlans = @(
                        [PSCustomObject]@{
                            ServicePlanId = '22222222-2222-2222-2222-222222222222'
                            ServicePlanName = 'EXCHANGE_S_ENTERPRISE'
                            ServicePlanFriendlyName = 'Exchange Online Plan 2'
                        },
                        [PSCustomObject]@{
                            ServicePlanId = '33333333-3333-3333-3333-333333333333'
                            ServicePlanName = 'SHAREPOINTWAC'
                            ServicePlanFriendlyName = 'Office for the Web'
                        }
                    )
                }
            )
        }

        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { return $true } -ParameterFilter { $EnableException -eq $false }
        Mock Stop-PSFFunction -ModuleName PSMicrosoftEntraID { throw [System.Management.Automation.PipelineStoppedException]::new() } -ParameterFilter { $EnableException -eq $true }
    }

    Context 'Parameter Validation' {
        It 'Should have correct parameter sets' {
            $command = Get-Command Get-PSEntraIDGroupLicense
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have correct aliases for Identity parameter' {
            $parameter = (Get-Command Get-PSEntraIDGroupLicense).Parameters['Identity']
            $parameter.Aliases | Should -Contain 'Id'
            $parameter.Aliases | Should -Contain 'GroupId'
            $parameter.Aliases | Should -Contain 'TeamId'
            $parameter.Aliases | Should -Contain 'MailNickName'
        }

        It 'Should have correct output type' {
            $command = Get-Command Get-PSEntraIDGroupLicense
            $command.OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Groups.AssignedLicenseDetail'
        }
    }

    Context 'When using Identity parameter set' {
        BeforeAll {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID {
                param($Identity)
                New-TestGroup -Id 'group-guid-1' -DisplayName 'Licensing Group' -Mail 'licensing@contoso.com' -MailNickname 'licensing-group' -AssignedLicenses @(
                    New-TestAssignedLicense -SkuId '11111111-1111-1111-1111-111111111111' -DisabledPlans @('33333333-3333-3333-3333-333333333333')
                )
            }
        }

        It 'Should resolve group identity and return license detail' {
            $result = Get-PSEntraIDGroupLicense -Identity 'licensing-group'

            $result | Should -Not -BeNullOrEmpty
            $result.GroupDisplayName | Should -Be 'Licensing Group'
            $result.SkuPartNumber | Should -Be 'ENTERPRISEPACK'
            $result.SkuFriendlyName | Should -Be 'Office 365 E3'
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should compute enabled and disabled plan counts' {
            $result = Get-PSEntraIDGroupLicense -Identity 'licensing-group'

            $result.EnabledPlanCount | Should -Be 1
            $result.DisabledPlanCount | Should -Be 1
            $result.TotalPlanCount | Should -Be 2
        }

        It 'Should populate nested service plan status details' {
            $result = Get-PSEntraIDGroupLicense -Identity 'licensing-group'

            $result.ServicePlans | Should -HaveCount 2
            ($result.ServicePlans | Where-Object -Property ServicePlanId -EQ -Value '22222222-2222-2222-2222-222222222222').Status | Should -Be 'Enabled'
            ($result.ServicePlans | Where-Object -Property ServicePlanId -EQ -Value '33333333-3333-3333-3333-333333333333').Status | Should -Be 'Disabled'
            ($result.ServicePlans | Where-Object -Property ServicePlanId -EQ -Value '33333333-3333-3333-3333-333333333333').ServicePlanFriendlyName | Should -Be 'Office for the Web'
        }

        It 'Should return service plan detail objects with expected type name' {
            $result = Get-PSEntraIDGroupLicense -Identity 'licensing-group'

            $result.ServicePlans[0].PSTypeNames | Should -Contain 'PSMicrosoftEntraID.Groups.AssignedLicenseServicePlanDetail'
        }

        It 'Should handle missing group with EnableException' {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID { return $null }
            Mock Invoke-TerminatingException -ModuleName PSMicrosoftEntraID { throw [System.Exception]::new('Group not found') }

            { Get-PSEntraIDGroupLicense -Identity 'missing-group' -EnableException } | Should -Throw
        }
    }

    Context 'When using InputObject parameter set' {
        It 'Should accept pipeline input group objects' {
            $groupObject = New-TestGroup -Id 'group-guid-2' -DisplayName 'Pipeline Group' -Mail 'pipeline@contoso.com' -MailNickname 'pipeline-group' -AssignedLicenses @(
                New-TestAssignedLicense -SkuId '11111111-1111-1111-1111-111111111111'
            )

            $result = $groupObject | Get-PSEntraIDGroupLicense

            $result | Should -Not -BeNullOrEmpty
            $result.GroupDisplayName | Should -Be 'Pipeline Group'
            $result.DisabledPlanCount | Should -Be 0
            $result.EnabledPlanCount | Should -Be 2
        }

        It 'Should refresh input object when AssignedLicenses are not present' {
            Mock Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID {
                New-TestGroup -Id 'group-guid-refresh' -DisplayName 'Refreshed Group' -Mail 'refresh@contoso.com' -MailNickname 'refresh-group' -AssignedLicenses @(
                    New-TestAssignedLicense -SkuId '11111111-1111-1111-1111-111111111111' -DisabledPlans @('33333333-3333-3333-3333-333333333333')
                )
            }

            $groupObject = New-TestGroup -Id 'group-guid-refresh' -DisplayName 'Refreshed Group' -Mail $null -MailNickname $null -AssignedLicenses @()
            $groupObject.AssignedLicenses = $null

            $result = Get-PSEntraIDGroupLicense -InputObject $groupObject

            $result | Should -Not -BeNullOrEmpty
            Should -Invoke Get-PSEntraIDGroup -ModuleName PSMicrosoftEntraID -Times 1 -Scope It
        }

        It 'Should return no output when group has no assigned licenses' {
            $groupObject = New-TestGroup -Id 'group-guid-empty' -DisplayName 'Empty Group' -Mail 'empty@contoso.com' -MailNickname 'empty-group' -AssignedLicenses @()

            $result = Get-PSEntraIDGroupLicense -InputObject $groupObject

            $result | Should -BeNullOrEmpty
        }
    }
}