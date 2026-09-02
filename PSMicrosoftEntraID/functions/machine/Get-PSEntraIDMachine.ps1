function Get-PSEntraIDMachine {
    <#
    .SYNOPSIS
        Get machines onboarded to Microsoft Defender for Endpoint.

    .DESCRIPTION
        Reads the Defender for Endpoint machines API (service family Endpoint,
        Settings.DefaultServiceEndpoint - connect with
        Connect-PSMicrosoftEntraID -Service PSMicrosoftEntraID.Endpoint).

        Without parameters, every machine is returned. The MDE machine id is a
        hash issued by Defender and exists only there; the bridge to the
        directory is AadDeviceId, which equals the DeviceId of the Entra ID
        device object returned by Get-PSEntraIDDevice. Note that AadDeviceId is
        NOT unique among machine records - a re-onboarded device leaves its old
        record behind - so -DeviceId may return several records; inspect
        MergedIntoMachineId, IsExcluded, OnboardingStatus and LastSeen to pick
        the live one.

    .PARAMETER Identity
        The MDE machine id (the hash issued by Defender for Endpoint).

    .PARAMETER DeviceId
        The Entra ID device GUID (aadDeviceId) - server-side filter for the
        machine records of a directory device.

    .PARAMETER Filter
        A raw OData $filter for the machines list. The MDE API supports $filter
        on computerDnsName, id, version, deviceValue, aadDeviceId, machineTags,
        lastSeen, exposureLevel, onboardingStatus, lastIpAddress, healthStatus,
        osPlatform, riskScore and rbacGroupId. The string is passed through
        verbatim - escape caller input before building it.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDMachine

        Every machine onboarded to Defender for Endpoint.

    .EXAMPLE
        PS C:\> Get-PSEntraIDDevice -Identity 'IT3C-JB-SEP2MDE' | ForEach-Object { Get-PSEntraIDMachine -DeviceId $_.DeviceId }

        The MDE machine record(s) of a directory device.

    .EXAMPLE
        PS C:\> Get-PSEntraIDMachine -Filter "healthStatus eq 'Active'"

        Machines whose sensor currently reports.
#>
    [OutputType('PSMicrosoftEntraID.DefenderEndpoint.Machine')]
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'MachineId')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'DeviceId')]
        [Alias('AadDeviceId')]
        [guid[]] $DeviceId,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultServiceEndpoint' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($machineIdentity in $Identity) {
                    $output = Invoke-PSFProtectedCommand -ActionString 'Machine.Get' -ActionStringValues $machineIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestMachine -InputObject (Invoke-EntraRequest -Service $service -Path ('machines/{0}' -f $machineIdentity) -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $output
                }
            }
            'DeviceId' {
                foreach ($deviceIdItem in $DeviceId) {
                    # A GUID cannot smuggle OData syntax, so it is safe to inline - and the
                    # MDE API wants it unquoted, unlike Graph.
                    [hashtable] $query = @{ '$filter' = ('aadDeviceId eq {0}' -f $deviceIdItem.Guid) }
                    $output = Invoke-PSFProtectedCommand -ActionString 'Machine.Get' -ActionStringValues $deviceIdItem -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestMachine -InputObject (Invoke-EntraRequest -Service $service -Path 'machines' -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $output
                }
            }
            'Filter' {
                [hashtable] $query = @{ '$filter' = $Filter }
                $output = Invoke-PSFProtectedCommand -ActionString 'Machine.List' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestMachine -InputObject (Invoke-EntraRequest -Service $service -Path 'machines' -Query $query -Method Get -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                if (Test-PSFFunctionInterrupt) { return }
                $output
            }
            'List' {
                $output = Invoke-PSFProtectedCommand -ActionString 'Machine.List' -ActionStringValues '*' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestMachine -InputObject (Invoke-EntraRequest -Service $service -Path 'machines' -Method Get -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                if (Test-PSFFunctionInterrupt) { return }
                $output
            }
        }
    }

    end {}
}
