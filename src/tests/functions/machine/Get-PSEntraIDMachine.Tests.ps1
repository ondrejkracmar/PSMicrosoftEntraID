BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Get-PSEntraIDMachine' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true; 'PSMicrosoftEntraID.Endpoint' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Endpoint' } -ParameterFilter { $FullName -like '*DefaultServiceEndpoint' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{
                id          = '1e5bc9d7e413ddd7902c2932e418702b84d0cc07'
                computerDnsName = 'it3c-jb-sep2mde-2'
                aadDeviceId = '6c1fc0eb-7fae-3992-70cf-d632a1b69569'
                machineTags = @('test tag 1', 'test tag 2')
            }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
    }

    Context 'Parameter validation' {
        It 'Should declare the Machine output type' {
            (Get-Command Get-PSEntraIDMachine).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.DefenderEndpoint.Machine'
        }
        It 'Should refuse a non-GUID DeviceId' {
            { Get-PSEntraIDMachine -DeviceId 'not-a-guid' } | Should -Throw
        }
    }

    Context 'Service selection' {
        It 'Should read the Endpoint family default service' {
            Get-PSEntraIDMachine

            Should -Invoke -ModuleName $script:ModuleName -CommandName Get-PSFConfigValue -ParameterFilter {
                $FullName -like '*DefaultServiceEndpoint'
            } -Times 1
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Endpoint'
            } -Times 1
        }
    }

    Context 'Request shapes' {
        It 'Should list machines without a query' {
            Get-PSEntraIDMachine

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'machines'
            } -Times 1
        }

        It 'Should get a machine by its id' {
            Get-PSEntraIDMachine -Identity '1e5bc9d7e413ddd7902c2932e418702b84d0cc07'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'machines/1e5bc9d7e413ddd7902c2932e418702b84d0cc07'
            } -Times 1
        }

        It 'Should filter by aadDeviceId unquoted' {
            Get-PSEntraIDMachine -DeviceId '6c1fc0eb-7fae-3992-70cf-d632a1b69569'

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query['$filter'] -eq 'aadDeviceId eq 6c1fc0eb-7fae-3992-70cf-d632a1b69569'
            } -Times 1
        }

        It 'Should pass a raw filter through verbatim' {
            Get-PSEntraIDMachine -Filter "healthStatus eq 'Active'"

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Query['$filter'] -eq "healthStatus eq 'Active'"
            } -Times 1
        }
    }

    Context 'Typed output' {
        It 'Should return the strongly typed machine' {
            $machine = Get-PSEntraIDMachine -Identity '1e5bc9d7e413ddd7902c2932e418702b84d0cc07'
            $machine | Should -BeOfType [PSMicrosoftEntraID.DefenderEndpoint.Machine]
            $machine.AadDeviceId | Should -Be '6c1fc0eb-7fae-3992-70cf-d632a1b69569'
            $machine.MachineTags | Should -Contain 'test tag 1'
        }
    }
}

Describe 'Add-PSEntraIDMachineTag / Remove-PSEntraIDMachineTag' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Endpoint' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Endpoint' } -ParameterFilter { $FullName -like '*DefaultServiceEndpoint' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest { [PSCustomObject]@{ id = 'hashA'; machineTags = @('vip') } }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Resolve-PSEntraIDConfirmPreference { @{ Confirm = $false } }
    }

    Context 'Wire format' {
        It 'Add: Should POST Value/Action=Add to the tags path' {
            Add-PSEntraIDMachineTag -MachineId 'hashA' -Tag 'vip' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'machines/hashA/tags' -and
                $Method -eq 'Post' -and
                (($Body | ConvertTo-Json -Compress) -match '"Value":"vip"') -and
                (($Body | ConvertTo-Json -Compress) -match '"Action":"Add"')
            } -Times 1
        }

        It 'Remove: Should POST Value/Action=Remove to the tags path' {
            Remove-PSEntraIDMachineTag -MachineId 'hashA' -Tag 'vip' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq 'machines/hashA/tags' -and
                (($Body | ConvertTo-Json -Compress) -match '"Action":"Remove"')
            } -Times 1
        }

        It 'Should issue one request per machine x tag pair' {
            Add-PSEntraIDMachineTag -MachineId 'hashA', 'hashB' -Tag 'one', 'two' -Force

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 4 -Exactly
        }

        It 'Should return the updated machine only with PassThru' {
            $silent = Add-PSEntraIDMachineTag -MachineId 'hashA' -Tag 'vip' -Force
            $silent | Should -BeNullOrEmpty

            $machine = Add-PSEntraIDMachineTag -MachineId 'hashA' -Tag 'vip' -Force -PassThru
            $machine | Should -BeOfType [PSMicrosoftEntraID.DefenderEndpoint.Machine]
        }
    }
}
