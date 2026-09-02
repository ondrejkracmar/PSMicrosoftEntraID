function Set-PSEntraIDDeviceExtensionAttribute {
    <#
    .SYNOPSIS
        Set or clear one extension attribute of an Entra ID device.

    .DESCRIPTION
        PATCHes the extensionAttributes property of a directory device object
        (Graph: Update device). extensionAttributes is the one device property
        an app-only caller may update - Device.ReadWrite.All suffices - and the
        property dynamic device group rules can target
        (device.extensionAttribute1..15).

        The device can be addressed three ways: by piped device object, by the
        directory object id, or by the device GUID (DeviceId - the same value
        Defender for Endpoint reports as aadDeviceId), which Graph accepts
        directly as devices(deviceId='...') without an object-id lookup.

    .PARAMETER InputObject
        Device object(s) as returned by Get-PSEntraIDDevice.

    .PARAMETER Identity
        The directory object id(s) of the device (device.id).

    .PARAMETER DeviceId
        The device GUID(s) (device.deviceId / MDE aadDeviceId).

    .PARAMETER AttributeName
        Which attribute to write: extensionAttribute1 through extensionAttribute15.

    .PARAMETER Value
        The value to set. An empty or null value CLEARS the attribute (Graph
        clears with null; an empty string would be stored literally otherwise).

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER Force
        The Force switch instructs the command to which object the specific query is applied without asking for confirmation.

    .PARAMETER PassThru
        Instead of executing the request, return a PSMicrosoftEntraID.Batch.Request
        for New-PSEntraIDBatchRequest / Invoke-PSEntraIDBatchRequest.

    .EXAMPLE
        PS C:\> Set-PSEntraIDDeviceExtensionAttribute -DeviceId $machine.AadDeviceId -AttributeName extensionAttribute10 -Value 'vip'

        Writes the value into extensionAttribute10 of the device matched by its GUID.

    .EXAMPLE
        PS C:\> Get-PSEntraIDDevice -Identity 'IT3C-JB-SEP2MDE' | Set-PSEntraIDDeviceExtensionAttribute -AttributeName extensionAttribute10 -Value ''

        Clears extensionAttribute10 on the device.
#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'InputObject')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Devices.Device[]] $InputObject,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,

        [Parameter(Mandatory = $true, ParameterSetName = 'DeviceId')]
        [Alias('AadDeviceId')]
        [guid[]] $DeviceId,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^extensionAttribute([1-9]|1[0-5])$')]
        [string] $AttributeName,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $Value,

        [Parameter()]
        [switch] $EnableException,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        # Graph clears an extension attribute with null - an empty string would be
        # stored literally and a dynamic group rule would then match ''.
        $attributeValue = if ([string]::IsNullOrEmpty($Value)) { $null } else { $Value }
        [hashtable] $body = @{ extensionAttributes = @{ $AttributeName = $attributeValue } }
    }

    process {
        [string[]] $pathList = switch ($PSCmdlet.ParameterSetName) {
            'InputObject' { foreach ($item in $InputObject) { 'devices/{0}' -f $item.Id } }
            'Identity' { foreach ($item in $Identity) { 'devices/{0}' -f $item } }
            'DeviceId' { foreach ($item in $DeviceId) { "devices(deviceId='{0}')" -f $item.Guid } }
        }
        foreach ($path in $pathList) {
            if ($PassThru.IsPresent) {
                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'PATCH'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
            }
            else {
                Invoke-PSFProtectedCommand -ActionString 'Device.ExtensionAttribute.Set' -ActionStringValues $AttributeName, $path -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
    }

    end {}
}
