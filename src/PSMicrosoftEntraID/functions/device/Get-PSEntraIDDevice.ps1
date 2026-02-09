function Get-PSEntraIDDevice {
    <#
    .SYNOPSIS
        Get the properties of the specified device.

    .DESCRIPTION
        Get the properties of the specified device.

    .PARAMETER Identity
        DisplayName or Id of the device attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDDevice -Identity "device-id"

        Get properties of Microsoft Entra ID device.

#>
    [OutputType('PSMicrosoftEntraID.Devices.Device')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'DeviceId')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        foreach ($deviceIdentity in $Identity) {
            $output = Invoke-PSFProtectedCommand -ActionString 'Device.Get' -ActionStringValues $deviceIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                # Best-effort: try looking up by displayName, fall back to assuming input is the Id
                [hashtable] $lookupQuery = @{
                    '$top'    = 1
                    '$select' = 'id,displayName'
                }
                $lookupQuery['$Filter'] = ("displayName eq '{0}'" -f $deviceIdentity)

                $deviceMatch = Invoke-EntraRequest -Service $service -Path ('devices') -Query $lookupQuery -Method Get -ErrorAction Stop
                if (-not([object]::Equals($deviceMatch, $null))) {
                    [string] $deviceId = $deviceMatch[0].Id
                }
                else {
                    [string] $deviceId = $deviceIdentity
                }

                $deviceDetails = Invoke-EntraRequest -Service $service -Path ('devices/{0}' -f $deviceId) -Method Get -ErrorAction Stop
                if ([object]::Equals($deviceDetails, $null)) {
                    [PSCustomObject]@{
                        PSTypeName  = 'PSMicrosoftEntraID.Devices.Device'
                        Id          = $deviceId
                        DisplayName = $deviceIdentity
                    }
                }
                else {
                    if ($deviceDetails.PSObject.TypeNames -notcontains 'PSMicrosoftEntraID.Devices.Device') {
                        $deviceDetails.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Devices.Device')
                    }
                    $deviceDetails
                }
            } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false

            if (Test-PSFFunctionInterrupt) { return }
            $output
        }
    }

    end {}
}
