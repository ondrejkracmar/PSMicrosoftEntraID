BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDGroupAdditionalProperty' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 100 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'assignedLicenses') }
        }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id               = '00000000-0000-0000-0000-000000000010'
                displayName      = 'TestGroup'
                assignedLicenses = @(@{ skuId = 'sku-001' })
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestGroupAdditionalProperty { $InputObject }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup {
            [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }
    }

    Context 'Parameter Validation' {
        It 'Should have InputObject and Identity parameter sets' {
            $command = Get-Command Get-PSEntraIDGroupAdditionalProperty
            $command.ParameterSets.Name | Should -Contain 'InputObject'
            $command.ParameterSets.Name | Should -Contain 'Identity'
        }

        It 'Should have OutputType PSMicrosoftEntraID.Groups.GroupAdditionalProperty' {
            (Get-Command Get-PSEntraIDGroupAdditionalProperty).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Groups.GroupAdditionalProperty'
        }
    }

    Context 'Get additional properties by InputObject' {
        It 'Should call API with groups/{id} path' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupAdditionalProperty -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010'
            }
        }

        It 'Should convert response using ConvertFrom-RestGroupAdditionalProperty' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupAdditionalProperty -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestGroupAdditionalProperty -Times 1
        }
    }

    Context 'Get additional properties by Identity' {
        It 'Should resolve group and call API' {
            Get-PSEntraIDGroupAdditionalProperty -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups/00000000-0000-0000-0000-000000000010'
            }
        }
    }

    Context 'Group not found handling' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $null }
        }

        It 'Should not call API when group is not found' {
            Get-PSEntraIDGroupAdditionalProperty -Identity 'notfound' -EnableException

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Scope It
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            $groupObj = [PSCustomObject]@{
                PSTypeName   = 'PSMicrosoftEntraID.Groups.Group'
                Id           = '00000000-0000-0000-0000-000000000010'
                DisplayName  = 'TestGroup'
                MailNickname = 'testgroup'
            }

            Get-PSEntraIDGroupAdditionalProperty -InputObject $groupObj

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
