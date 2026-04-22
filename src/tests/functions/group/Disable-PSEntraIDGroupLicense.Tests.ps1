BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Disable-PSEntraIDGroupLicense' -Tag 'Unit' {
    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup { $script:TestGroup }
        $script:TestSkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:TestGroup = [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = '12345678-1234-1234-1234-123456789012'; DisplayName = 'Test Group'; MailNickname = 'test-group'; AssignedLicenses = @([PSCustomObject]@{ SkuId = $script:TestSkuId; DisabledPlans = @() }) }
    }

    It 'Should remove assigned license by SkuId' {
        Disable-PSEntraIDGroupLicense -InputObject $script:TestGroup -SkuId $script:TestSkuId -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Body.addLicenses.Count -eq 0 -and $Body.removeLicenses[0] -eq $script:TestSkuId }
    }

    It 'Should not invoke request when license is not assigned' {
        $group = [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = '12345678-1234-1234-1234-123456789012'; DisplayName = 'Test Group'; AssignedLicenses = @() }
        Disable-PSEntraIDGroupLicense -InputObject $group -SkuId $script:TestSkuId -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
    }
}