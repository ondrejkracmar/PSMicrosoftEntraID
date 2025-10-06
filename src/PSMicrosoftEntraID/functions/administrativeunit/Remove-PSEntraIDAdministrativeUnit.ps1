function Remove-PSEntraIDAdministrativeUnit {
    <#
	.SYNOPSIS
		Delete administrative unit

	.DESCRIPTION
		Delete administrative unit from Microsoft Entra ID (Azure AD).
        When deleted, administrative unit resources are moved to a temporary container and can be restored within 30 days.
        After that time, they are permanently deleted.

    .PARAMETER InputObject
        PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

    .PARAMETER Identity
        DisplayName or Id of the administrative unit attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the delete action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

	.EXAMPLE
		PS C:\> Remove-PSEntraIDAdministrativeUnit -Identity "Marketing AU"

		Delete administrative unit "Marketing AU" from Microsoft Entra ID

	.EXAMPLE
		PS C:\> Get-PSEntraIDAdministrativeUnit -DisplayName "Old Department" | Remove-PSEntraIDAdministrativeUnit

		Delete administrative unit by piping from Get cmdlet

    .NOTES
        Administrative units provide a way to subdivide your organization and delegate administrative permissions
        to those subdivisions. When deleted, they can be restored within 30 days.

	#>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSTypeName('PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit')]
        [object[]] $InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,
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
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    [string] $path = ("directory/administrativeUnits/{0}" -f $itemInputObject.Id)

                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{
                            Method  = 'DELETE'
                            Url     = ('/{0}' -f $path)
                            Headers = $header
                        }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Remove' -ActionStringValues $itemInputObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Method Delete -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'Identity' {
                foreach ($administrativeUnit in $Identity) {
                    [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $administrativeUnit
                    if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                        [string] $path = ("directory/administrativeUnits/{0}" -f $aADAdministrativeUnit.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'DELETE'
                                Url     = ('/{0}' -f $path)
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Remove' -ActionStringValues $aADAdministrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Method Delete -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Remove.Failed) -f $administrativeUnit)
                        }
                    }
                }
            }
        }
    }

    end {}
}