function Set-PSEntraIDAdministrativeUnit {
    <#
    .SYNOPSIS
        Updates the specified properties of an administrative unit.

    .DESCRIPTION
        The `Set-PSEntraIDAdministrativeUnit` cmdlet allows you to modify specific properties of an administrative unit.
        Administrative units provide a way to subdivide your organization and delegate administrative permissions
        to those subdivisions.

    .PARAMETER InputObject
        PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

    .PARAMETER Identity
        DisplayName or Id of the administrative unit attribute populated in tenant/directory.

    .PARAMETER DisplayName
        Specifies the display name of the administrative unit.

    .PARAMETER Description
        Specifies the description of the administrative unit.

    .PARAMETER Visibility
        Controls whether the administrative unit and its members are hidden or public.
        Can be set to HiddenMembership or Public.

    .PARAMETER IsMemberManagementRestricted
        Indicates whether the management of members in this administrative unit is restricted to administrators.

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
        Set-PSEntraIDAdministrativeUnit -Identity "Marketing AU" -DisplayName "Marketing Department" -Description "Updated marketing team administrative unit"

        Update the display name and description of an administrative unit

    .EXAMPLE
        Set-PSEntraIDAdministrativeUnit -Identity "Finance AU" -Visibility "HiddenMembership"

        Set the administrative unit visibility to hidden membership

    .EXAMPLE
        Set-PSEntraIDAdministrativeUnit -Identity "HR AU" -IsMemberManagementRestricted $true

        Restrict member management to administrators only

    .NOTES
        Administrative units provide a way to subdivide your organization and delegate administrative permissions
        to those subdivisions.

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DisplayName,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string] $Description,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('HiddenMembership', 'Public')]
        [string] $Visibility,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]] $IsMemberManagementRestricted,
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
                    [hashtable] $body = @{}
                    foreach ($param in $PSBoundParameters.Keys) {
                        switch ($param) {
                            'DisplayName' { $body['displayName'] = $DisplayName }
                            'Description' { $body['description'] = $Description }
                            'Visibility' { $body['visibility'] = $Visibility }
                            'IsMemberManagementRestricted' { $body['isMemberManagementRestricted'] = $IsMemberManagementRestricted }
                        }
                    }


                    [string] $path = ("directory/administrativeUnits/{0}" -f $itemInputObject.Id)

                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{
                            Method  = 'PATCH'
                            Url     = ('/{0}' -f $path)
                            Body    = $body
                            Headers = $header
                        }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Set' -ActionStringValues $itemInputObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'Identity' {
                foreach ($administrativeUnit in $Identity) {
                    [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $administrativeUnit
                    if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                        [hashtable] $body = @{}

                        foreach ($param in $PSBoundParameters.Keys) {
                            switch ($param) {
                                'DisplayName' { $body['displayName'] = $DisplayName }
                                'Description' { $body['description'] = $Description }
                                'Visibility' { $body['visibility'] = $Visibility }
                                'IsMemberManagementRestricted' { $body['isMemberManagementRestricted'] = $IsMemberManagementRestricted }
                            }
                        }

                        [string] $path = ("directory/administrativeUnits/{0}" -f $aADAdministrativeUnit.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'PATCH'
                                Url     = ('/{0}' -f $path)
                                Body    = $body
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Set' -ActionStringValues $aADAdministrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Set.Failed) -f $administrativeUnit)
                        }
                    }
                }
            }
        }
    }

    end {}
}