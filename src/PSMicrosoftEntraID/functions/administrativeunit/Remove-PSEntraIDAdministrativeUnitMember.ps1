function Remove-PSEntraIDAdministrativeUnitMember {
    <#
    .SYNOPSIS
        Remove a member from an administrative unit.

    .DESCRIPTION
        Remove a member from an administrative unit. This cmdlet can remove users, groups, and devices from administrative units.

    .PARAMETER InputObject
        PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

    .PARAMETER InputObjectUser
        User object(s) to remove from the administrative unit.

    .PARAMETER InputObjectGroup
        Group object(s) to remove from the administrative unit.

    .PARAMETER InputObjectDevice
        Device object(s) to remove from the administrative unit.

    .PARAMETER Identity
        DisplayName or Id of the administrative unit.

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Group
        DisplayName, MailNickName or Id of the group attribute populated in tenant/directory.

    .PARAMETER Device
        DisplayName or Id of the device attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

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
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'IdentityInputObjectUser')]
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
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
    }

    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'IdentityInputObjectUser' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'IdentityInputObjectGroup' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'IdentityInputObjectDevice' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                        } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'IdentityUser' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $userIdentity)
                        }
                    }
                }
            }
            'IdentityGroup' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $groupIdentity)
                        }
                    }
                }
            }
            'IdentityDevice' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if ([object]::Equals($aADAdministrativeUnit, $null)) {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                    return
                }
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
                            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Device.Get.Failed) -f $deviceIdentity)
                        }
                    }
                }
            }
        }
    }

    end {}
}
