function Remove-PSEntraIDAdministrativeUnitMember {
    <#
    .SYNOPSIS
        Remove a member from an administrative unit.

    .DESCRIPTION
        Remove a member from an administrative unit. This cmdlet can remove users, groups, and devices from administrative units.

    .PARAMETER InputObject
        PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

    .PARAMETER Identity
        DisplayName or Id of the administrative unit.

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Group
        DisplayName, MailNickName or Id of the group attribute populated in tenant/directory.

    .PARAMETER Device
        DisplayName or Id of the device attribute populated in tenant/directory.

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
        When specified, the cmdlet will not execute the remove member action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> Remove-PSEntraIDAdministrativeUnitMember -Identity "Marketing AU" -User "user1@contoso.com","user2@contoso.com"

        Remove users from administrative unit "Marketing AU"

    .EXAMPLE
        PS C:\> Remove-PSEntraIDAdministrativeUnitMember -Identity "Finance AU" -Group "Finance-Team"

        Remove a group from administrative unit "Finance AU"

    .EXAMPLE
        PS C:\> Get-PSEntraIDAdministrativeUnit -DisplayName "HR AU" | Remove-PSEntraIDAdministrativeUnitMember -User "former-employee@contoso.com"

        Remove a user from administrative unit "HR AU" using pipeline

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentityInputObjectUser')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityUser')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityGroup')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityDevice')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityInputObjectUser')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityInputObjectGroup')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityInputObjectDevice')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string] $Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObjectUser')]
        [PSMicrosoftEntraID.Users.User[]] $InputObjectUser,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObjectGroup')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObjectGroup,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObjectDevice')]
        [PSTypeName('PSMicrosoftEntraID.Devices.Device')]
        [object[]] $InputObjectDevice,
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityUser')]
        [ValidateNotNullOrEmpty()]
        [string[]] $User,
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityGroup')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Group,
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityDevice')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Device,
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
        [string] $path = 'directory/administrativeUnits'
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
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'IdentityInputObjectUser' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($userObject in $InputObjectUser) {
                        [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $userObject.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'DELETE'
                                Url     = ('/{0}' -f $pathWithRef)
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $userObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
            'IdentityInputObjectGroup' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($groupObject in $InputObjectGroup) {
                        [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $groupObject.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'DELETE'
                                Url     = ('/{0}' -f $pathWithRef)
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $groupObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
            'IdentityInputObjectDevice' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($deviceObject in $InputObjectDevice) {
                        [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $deviceObject.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'DELETE'
                                Url     = ('/{0}' -f $pathWithRef)
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $deviceObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
            'Identity\w+' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    switch -Regex ($PSCmdlet.ParameterSetName) {
                        'IdentityUser' {
                            foreach ($userIdentity in $User) {
                                [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $userIdentity
                                if (-not ([object]::Equals($aADUser, $null))) {
                                    [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $aADUser.Id)

                                    if ($PassThru.IsPresent) {
                                        [PSMicrosoftEntraID.Batch.Request]@{
                                            Method  = 'DELETE'
                                            Url     = ('/{0}' -f $pathWithRef)
                                            Headers = $header
                                        }
                                    }
                                    else {
                                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $aADUser.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                            [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                        if (Test-PSFFunctionInterrupt) { return }
                                    }
                                }
                            }
                        }
                        'IdentityGroup' {
                            foreach ($groupIdentity in $Group) {
                                [PSMicrosoftEntraID.Groups.Group] $aADGroup = Get-PSEntraIDGroup -Identity $groupIdentity
                                if (-not ([object]::Equals($aADGroup, $null))) {
                                    [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $aADGroup.Id)

                                    if ($PassThru.IsPresent) {
                                        [PSMicrosoftEntraID.Batch.Request]@{
                                            Method  = 'DELETE'
                                            Url     = ('/{0}' -f $pathWithRef)
                                            Headers = $header
                                        }
                                    }
                                    else {
                                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $aADGroup.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                            [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                        if (Test-PSFFunctionInterrupt) { return }
                                    }
                                }
                            }
                        }
                        'IdentityDevice' {
                            foreach ($deviceIdentity in $Device) {
                                [PSObject] $aADDevice = Get-PSEntraIDDevice -Identity $deviceIdentity
                                if (-not ([object]::Equals($aADDevice, $null))) {
                                    [string] $pathWithRef = ("{0}/{1}/members/{2}/`$ref" -f $path, $aADAdministrativeUnit.Id, $aADDevice.Id)

                                    if ($PassThru.IsPresent) {
                                        [PSMicrosoftEntraID.Batch.Request]@{
                                            Method  = 'DELETE'
                                            Url     = ('/{0}' -f $pathWithRef)
                                            Headers = $header
                                        }
                                    }
                                    else {
                                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Delete' -ActionStringValues $aADDevice.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                            [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Method Delete -ErrorAction Stop)
                                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                        if (Test-PSFFunctionInterrupt) { return }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    end {}
}