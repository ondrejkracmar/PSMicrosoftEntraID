BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Enable-PSEntraIDGroupLicense' -Tag 'Unit' {
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
        $script:TestGroup = [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = '12345678-1234-1234-1234-123456789012'; DisplayName = 'Test Group'; MailNickname = 'test-group'; AssignedLicenses = @() }
        $script:TestSkuId = 'c7df2760-2c81-4ef7-b578-5b5392b571df'
        $script:TestSkuPartNumber = 'ENTERPRISEPACK'
        Mock -ModuleName $script:ModuleName Get-PSEntraIDSubscribedLicense { [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'; SkuId = $script:TestSkuId; SkuPartNumber = $script:TestSkuPartNumber } }
    }

    It 'Should assign license by SkuId' {
        Enable-PSEntraIDGroupLicense -InputObject $script:TestGroup -SkuId $script:TestSkuId -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter { $Path -eq "groups/$($script:TestGroup.Id)/assignLicense" -and $Body.addLicenses[0].skuId -eq $script:TestSkuId -and $Body.removeLicenses.Count -eq 0 }
    }

    It 'Should resolve SkuPartNumber' {
        Enable-PSEntraIDGroupLicense -Identity 'test-group' -SkuPartNumber $script:TestSkuPartNumber -Confirm:$false
        Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDSubscribedLicense -Times 1 -Exactly
        Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSEntraIDGroup -Times 1 -Exactly
    }

    It 'Should return batch request when PassThru is specified' {
        $result = Enable-PSEntraIDGroupLicense -InputObject $script:TestGroup -SkuId $script:TestSkuId -PassThru
        $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
        $result.Url | Should -Be "/groups/$($script:TestGroup.Id)/assignLicense"
    }
}