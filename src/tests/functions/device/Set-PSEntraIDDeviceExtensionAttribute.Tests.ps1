BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Set-PSEntraIDDeviceExtensionAttribute' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Resolve-PSEntraIDConfirmPreference { @{ Confirm = $false } }
    }

    Context 'Parameter validation' {
        It 'Should refuse an attribute name outside extensionAttribute1..15' {
            { Set-PSEntraIDDeviceExtensionAttribute -Identity 'obj' -AttributeName 'extensionAttribute16' -Value 'x' -Force } | Should -Throw
            { Set-PSEntraIDDeviceExtensionAttribute -Identity 'obj' -AttributeName 'displayName' -Value 'x' -Force } | Should -Throw
        }
    }

    Context 'Wire format' {
        It 'Should PATCH the nested extensionAttributes body' {
            Set-PSEntraIDDeviceExtensionAttribute -Identity '7c06cd31-7c30-4f3b-a5c3-444cd8dd63ac' -AttributeName 'extensionAttribute10' -Value 'vip' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'devices/7c06cd31-7c30-4f3b-a5c3-444cd8dd63ac' -and
                $Method -eq 'Patch' -and
                (($Body | ConvertTo-Json -Compress -Depth 5) -match '"extensionAttributes":\{"extensionAttribute10":"vip"\}')
            } -Times 1
        }

        It 'Should address the device by deviceId without an object-id lookup' {
            Set-PSEntraIDDeviceExtensionAttribute -DeviceId '6c1fc0eb-7fae-3992-70cf-d632a1b69569' -AttributeName 'extensionAttribute10' -Value 'vip' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "devices(deviceId='6c1fc0eb-7fae-3992-70cf-d632a1b69569')"
            } -Times 1
        }

        It 'Should clear with null, not with an empty string' {
            Set-PSEntraIDDeviceExtensionAttribute -Identity 'obj-id' -AttributeName 'extensionAttribute10' -Value '' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                (($Body | ConvertTo-Json -Compress -Depth 5) -match '"extensionAttribute10":null')
            } -Times 1
        }
    }

    Context 'Batch composition' {
        It 'Should emit a Batch.Request with PassThru and execute nothing' {
            $request = Set-PSEntraIDDeviceExtensionAttribute -Identity 'obj-id' -AttributeName 'extensionAttribute10' -Value 'vip' -Force -PassThru

            $request | Should -BeOfType [PSMicrosoftEntraID.Batch.Request]
            $request.Method | Should -Be 'PATCH'
            $request.Url | Should -Be '/devices/obj-id'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0
        }
    }
}
