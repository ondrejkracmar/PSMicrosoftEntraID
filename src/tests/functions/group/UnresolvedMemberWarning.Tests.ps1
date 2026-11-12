BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Member and owner cmdlets warn about every identity they cannot resolve' -Tag 'Unit' {
    # Without -EnableException an identity that did not resolve used to be skipped in
    # silence: the command "succeeded" and the operator had no way to tell that one of the
    # requested members was never added or removed. Each skip now writes a warning naming
    # the identity, and the identities that did resolve are still processed.
    BeforeAll {
        Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue {
            if ($FullName -like '*DefaultService') { return 'PSMicrosoftEntraID.Graph' }
            if ($FullName -like '*RetryCount') { return 0 }
            if ($FullName -like '*RetryWaitInSeconds') { return 0 }
        }
        Mock -ModuleName PSMicrosoftEntraID Assert-EntraConnection { }
        Mock -ModuleName PSMicrosoftEntraID Get-EntraService {
            [PSCustomObject]@{ ServiceUrl = 'https://graph.microsoft.com/v1.0' }
        }
        Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDGroup {
            param($Identity)
            if ($Identity -like 'missing*') { return $null }
            [PSCustomObject]@{ Id = "id-$Identity"; DisplayName = $Identity }
        }
        Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDUser {
            param($Identity)
            if ($Identity -like 'missing*') { return $null }
            [PSCustomObject]@{ Id = "id-$Identity"; UserPrincipalName = $Identity; Mail = $Identity }
        }
        Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDDevice {
            param($Identity)
            if ($Identity -like 'missing*') { return $null }
            [PSCustomObject]@{ Id = "id-$Identity"; DisplayName = $Identity }
        }
        Mock -ModuleName PSMicrosoftEntraID Get-PSEntraIDAdministrativeUnit {
            param($Identity)
            if ($Identity -like 'missing*') { return $null }
            [PSCustomObject]@{ Id = "id-$Identity"; DisplayName = $Identity }
        }
        Mock -ModuleName PSMicrosoftEntraID Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName PSMicrosoftEntraID Invoke-EntraRequest { }
        Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { } -ParameterFilter { $Level -eq 'Warning' }
    }

    It '<Command> -<Parameter> warns about the unresolved identity and still sends the resolved one' -TestCases @(
        @{ Command = 'Remove-PSEntraIDGroupMember'; Parameter = 'User'; String = 'User.Get.Failed' }
        @{ Command = 'Add-PSEntraIDGroupOwner'; Parameter = 'User'; String = 'User.Get.Failed' }
        @{ Command = 'Remove-PSEntraIDGroupOwner'; Parameter = 'User'; String = 'User.Get.Failed' }
        @{ Command = 'Add-PSEntraIDAdministrativeUnitMember'; Parameter = 'User'; String = 'User.Get.Failed' }
        @{ Command = 'Add-PSEntraIDAdministrativeUnitMember'; Parameter = 'Group'; String = 'Group.Get.Failed' }
        @{ Command = 'Remove-PSEntraIDAdministrativeUnitMember'; Parameter = 'User'; String = 'User.Get.Failed' }
        @{ Command = 'Remove-PSEntraIDAdministrativeUnitMember'; Parameter = 'Group'; String = 'Group.Get.Failed' }
        @{ Command = 'Remove-PSEntraIDAdministrativeUnitMember'; Parameter = 'Device'; String = 'Device.Get.Failed' }
    ) {
        $splat = @{
            Identity   = 'target'
            $Parameter = @('found1@test.com', 'missing1@test.com')
            Force      = $true
        }

        & $Command @splat

        Should -Invoke -ModuleName PSMicrosoftEntraID Write-PSFMessage -ParameterFilter {
            $Level -eq 'Warning' -and $StringValues -contains 'missing1@test.com'
        } -Times 1 -Exactly
        $filter = [scriptblock]::Create(('$Level -eq ''Warning'' -and $String -eq ''{0}''' -f $String))
        Should -Invoke -ModuleName PSMicrosoftEntraID Write-PSFMessage -ParameterFilter $filter -Times 1 -Exactly
        Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 1 -Exactly
    }

    It '<Command> warns when the administrative unit itself does not resolve' -TestCases @(
        @{ Command = 'Add-PSEntraIDAdministrativeUnitMember' }
        @{ Command = 'Remove-PSEntraIDAdministrativeUnitMember' }
    ) {
        & $Command -Identity 'missing-au' -User 'found1@test.com' -Force

        Should -Invoke -ModuleName PSMicrosoftEntraID Write-PSFMessage -ParameterFilter {
            $Level -eq 'Warning' -and $String -eq 'AdministrativeUnit.Get.Failed' -and $StringValues -contains 'missing-au'
        } -Times 1 -Exactly
        Should -Invoke -ModuleName PSMicrosoftEntraID Invoke-EntraRequest -Times 0 -Exactly
    }
}
