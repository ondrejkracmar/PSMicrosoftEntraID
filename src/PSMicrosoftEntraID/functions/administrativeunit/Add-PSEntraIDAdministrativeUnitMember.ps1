function Add-PSEntraIDAdministrativeUnitMember {
    <#
    .SYNOPSIS
        Add a member to an administrative unit.

    .DESCRIPTION
        Add a member to an administrative unit. Administrative units can contain users, groups, and devices as members.

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
        When specified, the cmdlet will not execute the add member action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> Add-PSEntraIDAdministrativeUnitMember -Identity "Marketing AU" -User "user1@contoso.com","user2@contoso.com"

        Add users to administrative unit "Marketing AU"

    .EXAMPLE
        PS C:\> Add-PSEntraIDAdministrativeUnitMember -Identity "Finance AU" -Group "Finance-Team"

        Add a group to administrative unit "Finance AU"

    .EXAMPLE
        PS C:\> Get-PSEntraIDAdministrativeUnit -DisplayName "HR AU" | Add-PSEntraIDAdministrativeUnitMember -User "hr-manager@contoso.com"

        Add a user to administrative unit "HR AU" using pipeline

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentityUser')]
    param(
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityUser')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityGroup')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityDevice')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityInputObject')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityInputObjectGroup')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentityInputObjectDevice')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string] $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObjectGroup')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObjectGroup,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObjectDevice')]
        [PSObject[]] $InputObjectDevice,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'IdentityUser')]
        [ValidateNotNullOrEmpty()]
        [string[]] $User,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'IdentityGroup')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Group,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'IdentityDevice')]
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
            'IdentityInputObject$' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($userObject in $InputObject) {
                        [hashtable] $body = @{
                            '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $userObject.Id
                        }
                        [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'POST'
                                Url     = ('/{0}' -f $pathWithRef)
                                Body    = $body
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $userObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                }
            }
            'IdentityInputObjectGroup$' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($groupObject in $InputObjectGroup) {
                        [hashtable] $body = @{
                            '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $groupObject.Id
                        }
                        [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'POST'
                                Url     = ('/{0}' -f $pathWithRef)
                                Body    = $body
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $groupObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                }
            }
            'IdentityInputObjectDevice$' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    foreach ($deviceObject in $InputObjectDevice) {
                        [hashtable] $body = @{
                            '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $deviceObject.Id
                        }
                        [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{
                                Method  = 'POST'
                                Url     = ('/{0}' -f $pathWithRef)
                                Body    = $body
                                Headers = $header
                            }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $deviceObject.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                }
            }
            'Identity\w+' {
                [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $Identity
                if (-not ([object]::Equals($aADAdministrativeUnit, $null))) {
                    switch -Regex ($PSCmdlet.ParameterSetName) {
                        '\wUser$' {
                            foreach ($userIdentity in $User) {
                                [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $userIdentity
                                if (-not ([object]::Equals($aADUser, $null))) {
                                    [hashtable] $body = @{
                                        '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $aADUser.Id
                                    }
                                    [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                                    if ($PassThru.IsPresent) {
                                        [PSMicrosoftEntraID.Batch.Request]@{
                                            Method  = 'POST'
                                            Url     = ('/{0}' -f $pathWithRef)
                                            Body    = $body
                                            Headers = $header
                                        }
                                    }
                                    else {
                                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $aADUser.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                            [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
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
                        '\wGroup$' {
                            foreach ($groupIdentity in $Group) {
                                [PSMicrosoftEntraID.Groups.Group] $aADGroup = Get-PSEntraIDGroup -Identity $groupIdentity
                                if (-not ([object]::Equals($aADGroup, $null))) {
                                    [hashtable] $body = @{
                                        '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $aADGroup.Id
                                    }
                                    [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                                    if ($PassThru.IsPresent) {
                                        [PSMicrosoftEntraID.Batch.Request]@{
                                            Method  = 'POST'
                                            Url     = ('/{0}' -f $pathWithRef)
                                            Body    = $body
                                            Headers = $header
                                        }
                                    }
                                    else {
                                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $aADGroup.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                            [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
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
                        '\wDevice$' {
                            foreach ($deviceIdentity in $Device) {
                                # Note: Device cmdlets would need to be implemented separately
                                # For now, we'll use the device ID directly
                                [hashtable] $body = @{
                                    '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/{0}" -f $deviceIdentity
                                }
                                [string] $pathWithRef = ("{0}/{1}/members/`$ref" -f $path, $aADAdministrativeUnit.Id)

                                if ($PassThru.IsPresent) {
                                    [PSMicrosoftEntraID.Batch.Request]@{
                                        Method  = 'POST'
                                        Url     = ('/{0}' -f $pathWithRef)
                                        Body    = $body
                                        Headers = $header
                                    }
                                }
                                else {
                                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.Add' -ActionStringValues $deviceIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                        [void] (Invoke-EntraRequest -Service $service -Path $pathWithRef -Header $header -Body $body -Method Post -ErrorAction Stop)
                                    } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                    if (Test-PSFFunctionInterrupt) { return }
                                }
                            }
                        }
                    }
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $Identity)
                    }
                }
            }
        }
    }
    end {}
}