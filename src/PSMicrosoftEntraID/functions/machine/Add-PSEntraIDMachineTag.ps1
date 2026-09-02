function Add-PSEntraIDMachineTag {
    <#
    .SYNOPSIS
        Add a tag to a Microsoft Defender for Endpoint machine.

    .DESCRIPTION
        Adds a machine tag via the MDE machines API (POST /machines/{id}/tags,
        service family Endpoint). Requires the WindowsDefenderATP permission
        Machine.ReadWrite.All (application) or Machine.ReadWrite (delegated,
        plus the MDE role permission 'Manage security setting').

        The tags API is rate limited to 100 calls per minute and 1,500 calls
        per hour - throttled requests are retried by the request layer, but
        large bulk runs should pace themselves.

    .PARAMETER InputObject
        Machine object(s) as returned by Get-PSEntraIDMachine.

    .PARAMETER MachineId
        The MDE machine id(s) (the hash issued by Defender for Endpoint).

    .PARAMETER Tag
        The tag value(s) to add.

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
        Returns the updated machine object(s) the API reports back.

    .EXAMPLE
        PS C:\> Get-PSEntraIDMachine -DeviceId $device.DeviceId | Add-PSEntraIDMachineTag -Tag 'vip'

        Tags every MDE machine record of the device.
#>
    [OutputType('PSMicrosoftEntraID.DefenderEndpoint.Machine')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'InputObject')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.DefenderEndpoint.Machine[]] $InputObject,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'MachineId')]
        [Alias('Id')]
        [ValidateNotNullOrEmpty()]
        [string[]] $MachineId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]] $Tag,

        [Parameter()]
        [switch] $EnableException,

        [Parameter()]
        [switch] $Force,

        [Parameter()]
        [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultServiceEndpoint' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    }

    process {
        [string[]] $machineIdList = switch ($PSCmdlet.ParameterSetName) {
            'InputObject' { $InputObject.Id }
            'MachineId' { $MachineId }
        }
        foreach ($machineIdItem in $machineIdList) {
            foreach ($tagItem in $Tag) {
                [hashtable] $body = @{ Value = $tagItem; Action = 'Add' }
                $response = Invoke-PSFProtectedCommand -ActionString 'MachineTag.Add' -ActionStringValues $tagItem, $machineIdItem -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    Invoke-EntraRequest -Service $service -Path ('machines/{0}/tags' -f $machineIdItem) -Header $header -Body $body -Method Post -ErrorAction Stop
                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
                if ($PassThru.IsPresent -and -not ([object]::Equals($response, $null))) {
                    ConvertFrom-RestMachine -InputObject $response
                }
            }
        }
    }

    end {}
}
