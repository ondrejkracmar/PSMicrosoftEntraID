function Get-PSEntraIDDevice {
    <#
    .SYNOPSIS
        Get the properties of the specified device.

    .DESCRIPTION
        Get the properties of the specified device.

    .PARAMETER Identity
        DisplayName or Id of the device attribute populated in tenant/directory.

    .PARAMETER Filter
        A raw OData $filter for the devices list. The string is passed through
        verbatim - escape caller input before building it.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDDevice -Identity "device-id"

        Get properties of Microsoft Entra ID device.

    .EXAMPLE
        PS C:\> Get-PSEntraIDDevice

        Every device in the directory, with the properties named by
        Settings.GraphApiQuery.Select.Device (extensionAttributes included).

    .NOTES
        Piping into Select-Object -First N logs a warning that is not a failure:

            WARNING: [<cmdlet>] Failed to: ... | The pipeline has been stopped

        The results are correct and complete. Select-Object stops the pipeline once it
        has what it asked for, and the next write throws PipelineStoppedException -
        normal termination, reported as an error only because the write happens inside a
        protected block. Materialise first if the warning is in the way:

            $items = @(<cmdlet> ...)
            $items | Select-Object -First 3

        or filter server-side with -Filter instead of trimming client-side. Not silenced
        on purpose: the only fix that works is to collect the whole result before
        emitting any of it, which would cost streaming on every read.

#>
    [OutputType('PSMicrosoftEntraID.Devices.Device')]
    [CmdletBinding(DefaultParameterSetName = 'List')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'DeviceId')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $listQuery = @{
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Device).Value -join ',')
        }
    }

    process {
        if ($PSCmdlet.ParameterSetName -in @('List', 'Filter')) {
            if ($PSBoundParameters.ContainsKey('Filter')) { $listQuery['$filter'] = $Filter }
            [string] $actionValue = if ($PSBoundParameters.ContainsKey('Filter')) { $Filter } else { '*' }
            $output = Invoke-PSFProtectedCommand -ActionString 'Device.List' -ActionStringValues $actionValue -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                ConvertFrom-RestDevice -InputObject (Invoke-EntraRequest -Service $service -Path 'devices' -Query $listQuery -Method Get -ErrorAction Stop)
            } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
            if (Test-PSFFunctionInterrupt) { return }
            $output
            return
        }
        foreach ($deviceIdentity in $Identity) {
            $output = Invoke-PSFProtectedCommand -ActionString 'Device.Get' -ActionStringValues $deviceIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                # Best-effort: try looking up by displayName, fall back to assuming input is the Id
                [hashtable] $lookupQuery = @{
                    '$top'    = 1
                    '$select' = 'id,displayName'
                }
                $lookupQuery['$Filter'] = ("displayName eq '{0}'" -f (ConvertTo-ODataFilterString -Value $deviceIdentity))

                $deviceMatch = Invoke-EntraRequest -Service $service -Path ('devices') -Query $lookupQuery -Method Get -ErrorAction Stop
                if (-not([object]::Equals($deviceMatch, $null))) {
                    [string] $deviceId = $deviceMatch[0].Id
                }
                else {
                    [string] $deviceId = $deviceIdentity
                }

                $deviceDetails = Invoke-EntraRequest -Service $service -Path ('devices/{0}' -f $deviceId) -Method Get -ErrorAction Stop
                if ([object]::Equals($deviceDetails, $null)) {
                    # Nothing came back, but we know what was asked for - return that much
                    # as the real type rather than a look-alike PSCustomObject.
                    [PSMicrosoftEntraID.Devices.Device]@{
                        Id          = $deviceId
                        DisplayName = $deviceIdentity
                    }
                }
                else {
                    ConvertFrom-RestDevice -InputObject $deviceDetails
                }
            } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false

            if (Test-PSFFunctionInterrupt) { return }
            $output
        }
    }

    end {}
}
