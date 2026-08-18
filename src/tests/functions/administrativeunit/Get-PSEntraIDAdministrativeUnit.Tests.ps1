BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Import here rather than relying on whichever test file happened to run first:
    # Pester executes every file in ONE runspace, so an ambient import made these
    # tests pass alone and fail in a full run with
    #   RuntimeException: No modules named 'PSMicrosoftEntraID' are currently loaded.
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Get-PSEntraIDAdministrativeUnit' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig { 
            [PSCustomObject]@{ Value = @('id', 'displayName', 'description') }
        } -ParameterFilter { $Name -eq 'Settings.GraphApiQuery.Select.AdministrativeUnit' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { 
            [PSCustomObject]@{
                value = @($script:MockAU)
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestAdministrativeUnit { $InputObject.value }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }

        # Mock administrative unit data
        $script:MockAU = [PSCustomObject]@{
            PSTypeName = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
            Id = '12345678-1234-1234-1234-123456789012'
            DisplayName = 'Marketing AU'
            Description = 'Marketing Department Administrative Unit'
            Visibility = 'Public'
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory Identity parameter for Identity parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory DisplayName parameter for DisplayName parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['DisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory Filter parameter for Filter parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Filter']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory All parameter for All parameter set' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['All']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept string array for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.ParameterType.Name | Should -Be 'String[]'
        }

        It 'Should accept pipeline input for Identity parameter' {
            $param = (Get-Command Get-PSEntraIDAdministrativeUnit).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'Get administrative unit by Identity' {
        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits/12345678-1234-1234-1234-123456789012'
            }
        }

        It 'Should return administrative unit object' {
            $result = Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be $script:MockAU.Id
        }

        It 'Should handle multiple identities' {
            # GUIDs on purpose: a non-GUID identity legitimately costs an extra
            # resolution request, which is covered in its own context below.
            Get-PSEntraIDAdministrativeUnit -Identity @('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should process pipeline input' {
            @('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222') | Get-PSEntraIDAdministrativeUnit

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Identity resolves a display name' {
        # -Identity documents "DisplayName or Id", but only an id may travel in the URL
        # path - Graph answers 400 'Invalid object identifier' for a name, always. Found
        # by the live scenario: the unit was created, then unreadable for 90 seconds of
        # deterministic 400s. Every other administrative-unit cmdlet resolves through
        # this one, so a name-blind Get made the whole family GUID-only.

        It 'a display name goes through an exact filter first, then the resolved id path' {
            Get-PSEntraIDAdministrativeUnit -Identity 'Marketing AU'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits' -and $Query.'$filter' -eq "displayName eq 'Marketing AU'"
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits/12345678-1234-1234-1234-123456789012'
            }
        }

        It 'a GUID never pays for the resolution request' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly
        }

        It 'an unresolved name falls back to the escaped raw identity in the path' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Query -and $Query.ContainsKey('$filter')) { return $null }
                [PSCustomObject]@{ value = @($script:MockAU) }
            }

            Get-PSEntraIDAdministrativeUnit -Identity 'No Such AU'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits/No%20Such%20AU'
            }
        }
    }

    Context 'Get administrative unit by DisplayName' {
        It 'Should call API with filter query' {
            Get-PSEntraIDAdministrativeUnit -DisplayName 'Marketing'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "startswith(displayName,'Marketing')"
            }
        }

        It 'Should handle multiple display names' {
            Get-PSEntraIDAdministrativeUnit -DisplayName @('Marketing', 'Finance')

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }
    }

    Context 'Get administrative unit with Filter' {
        It 'Should call API with custom filter' {
            Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -eq "displayName eq 'Marketing AU'"
            }
        }

        It 'Should use ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnit -Filter "startswith(displayName,'M')" -AdvancedFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }

        It 'Should not use ConsistencyLevel header without AdvancedFilter' {
            Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $null -eq $Header -or $null -eq $Header.ConsistencyLevel
            }
        }
    }

    Context 'Get all administrative units' {
        It 'Should call API with correct path' {
            Get-PSEntraIDAdministrativeUnit -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'directory/administrativeUnits'
            }
        }

        It 'Should include count and top parameters' {
            Get-PSEntraIDAdministrativeUnit -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$count' -eq 'true' -and $Query.'$top' -eq 999
            }
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }

        It 'Should use Invoke-PSFProtectedCommand for retries' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1 -Exactly
        }

        It 'Should convert response using ConvertFrom-RestAdministrativeUnit' {
            Get-PSEntraIDAdministrativeUnit -Identity '12345678-1234-1234-1234-123456789012'

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestAdministrativeUnit -Times 1 -Exactly
        }
    }
}
