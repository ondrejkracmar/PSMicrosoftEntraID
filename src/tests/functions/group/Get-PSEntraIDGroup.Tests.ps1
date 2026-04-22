BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDGroup' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 100 } -ParameterFilter { $FullName -like '*PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'displayName', 'mailNickname', 'mail') }
        } -ParameterFilter { $Name -like '*Select.Group' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id              = '00000000-0000-0000-0000-000000000010'
                displayName     = 'TestGroup'
                mailNickname    = 'testgroup'
                mail            = 'testgroup@contoso.com'
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestGroup { $InputObject }
    }

    Context 'Parameter Validation' {
        It 'Should have Identity, DisplayName, Filter, and All parameter sets' {
            $command = Get-Command Get-PSEntraIDGroup
            $command.ParameterSets.Name | Should -Contain 'Identity'
            $command.ParameterSets.Name | Should -Contain 'DisplayName'
            $command.ParameterSets.Name | Should -Contain 'Filter'
            $command.ParameterSets.Name | Should -Contain 'All'
        }

        It 'Should have OutputType PSMicrosoftEntraID.Groups.Group' {
            (Get-Command Get-PSEntraIDGroup).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Groups.Group'
        }

        It 'Should have mandatory Identity parameter with aliases' {
            $param = (Get-Command Get-PSEntraIDGroup).Parameters['Identity']
            $param.Aliases | Should -Contain 'Id'
            $param.Aliases | Should -Contain 'GroupId'
            $param.Aliases | Should -Contain 'MailNickName'
        }

        It 'Should accept pipeline input for Identity' {
            $param = (Get-Command Get-PSEntraIDGroup).Parameters['Identity']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }
    }

    Context 'Get group by Identity' {
        It 'Should call API with mailNickName query then by Id' {
            Get-PSEntraIDGroup -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly
        }

        It 'Should query mailNickName filter first' {
            Get-PSEntraIDGroup -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -like "mailNickName eq*"
            }
        }

        It 'Should convert response using ConvertFrom-RestGroup' {
            Get-PSEntraIDGroup -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestGroup -Times 2
        }
    }

    Context 'Get group by DisplayName' {
        It 'Should query with startswith displayName filter' {
            Get-PSEntraIDGroup -DisplayName 'Test'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -like "startswith(displayName*"
            }
        }
    }

    Context 'Get group by Filter' {
        It 'Should pass custom filter to query' {
            Get-PSEntraIDGroup -Filter "mailEnabled eq true"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$Filter' -eq "mailEnabled eq true"
            }
        }

        It 'Should add ConsistencyLevel header with AdvancedFilter' {
            Get-PSEntraIDGroup -Filter "mailEnabled eq true" -AdvancedFilter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.ConsistencyLevel -eq 'eventual'
            }
        }
    }

    Context 'Get all groups' {
        It 'Should call API for all groups' {
            Get-PSEntraIDGroup -All

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'groups'
            }
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            Get-PSEntraIDGroup -Identity 'testgroup'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
