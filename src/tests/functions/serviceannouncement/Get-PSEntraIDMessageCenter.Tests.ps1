BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Get-PSEntraIDMessageCenter' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 200 } -ParameterFilter { $FullName -like '*MessageCenter.PageSize' }
        Mock -ModuleName $script:ModuleName Get-PSFConfig {
            [PSCustomObject]@{ Value = @('id', 'title', 'services', 'category', 'severity', 'startDateTime', 'lastModifiedDateTime') }
        } -ParameterFilter { $Name -like '*Select.ServiceAnnouncement*' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            @(
                [PSCustomObject]@{ id = 'MC100001'; title = 'Teams Update'; services = @('Microsoft Teams'); category = 'feature'; severity = 'normal'; startDateTime = '2024-01-01T00:00:00Z' },
                [PSCustomObject]@{ id = 'MC100002'; title = 'Exchange Change'; services = @('Exchange Online'); category = 'planForChange'; severity = 'high'; startDateTime = '2024-06-15T00:00:00Z' }
            )
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Office 365' }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestMessageCenter {
            $InputObject | ForEach-Object {
                $msg = [PSMicrosoftEntraID.ServiceAnnouncement.Message]::new()
                $msg.Id = $_.id
                $msg.Title = $_.title
                $msg.Services = [string[]]$_.services
                $msg.Category = $_.category
                $msg.Severity = $_.severity
                $msg.StartDateTime = $_.startDateTime
                $msg
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-TerminatingException { }
    }

    Context 'Parameter Validation' {
        It 'Should have OutputType PSMicrosoftEntraID.MessageCenter.Message' {
            (Get-Command Get-PSEntraIDMessageCenter).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.MessageCenter.Message[]'
        }

        It 'Should have Service parameter with ValidateSet' {
            $param = (Get-Command Get-PSEntraIDMessageCenter).Parameters['Service']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.ValidValues | Should -Contain 'Microsoft Teams'
            $validateSet.ValidValues | Should -Contain 'Exchange Online'
            $validateSet.ValidValues | Should -Contain 'All'
        }

        It 'Should have Category parameter with ValidateSet' {
            $param = (Get-Command Get-PSEntraIDMessageCenter).Parameters['Category']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet.ValidValues | Should -Contain 'feature'
            $validateSet.ValidValues | Should -Contain 'retire'
            $validateSet.ValidValues | Should -Contain 'planForChange'
        }

        It 'Should have Severity parameter with ValidateSet' {
            $param = (Get-Command Get-PSEntraIDMessageCenter).Parameters['Severity']
            $validateSet = $param.Attributes.Where{ $_ -is [ValidateSet] }
            $validateSet.ValidValues | Should -Contain 'normal'
            $validateSet.ValidValues | Should -Contain 'high'
            $validateSet.ValidValues | Should -Contain 'critical'
        }

        It 'Should have PublishedAfter and PublishedBefore datetime parameters' {
            $command = Get-Command Get-PSEntraIDMessageCenter
            $command.Parameters['PublishedAfter'].ParameterType | Should -Be ([datetime])
            $command.Parameters['PublishedBefore'].ParameterType | Should -Be ([datetime])
        }
    }

    Context 'Get messages without filters' {
        It 'Should call API with GET to serviceAnnouncement/messages path' {
            Get-PSEntraIDMessageCenter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'admin/serviceAnnouncement/messages' -and $Method -eq 'Get'
            }
        }

        It 'Should convert response using ConvertFrom-RestMessageCenter' {
            Get-PSEntraIDMessageCenter

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestMessageCenter -Times 1
        }
    }

    Context 'Get messages with Category filter' {
        It 'Should build Graph API filter for category' {
            Get-PSEntraIDMessageCenter -Category 'feature'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -like "*category eq 'feature'*"
            }
        }
    }

    Context 'Get messages with Severity filter' {
        It 'Should build Graph API filter for severity' {
            Get-PSEntraIDMessageCenter -Severity 'high'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -like "*severity eq 'high'*"
            }
        }
    }

    Context 'Get messages with combined filters' {
        It 'Should combine category and severity filters with and' {
            Get-PSEntraIDMessageCenter -Category 'feature' -Severity 'high'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query.'$filter' -like "*category*" -and $Query.'$filter' -like "*severity*" -and $Query.'$filter' -like "* and *"
            }
        }
    }

    Context 'Connection handling' {
        It 'Should assert Entra connection' {
            Get-PSEntraIDMessageCenter

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
