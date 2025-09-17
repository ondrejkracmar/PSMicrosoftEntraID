function Set-PSEntraIDUser {
    <#
.SYNOPSIS
    Updates the specified properties of one or more Microsoft Entra ID (Azure AD) users.

.DESCRIPTION
    The `Set-PSEntraIDUser` cmdlet allows you to modify specific properties of Microsoft Entra ID (Azure AD) users.
    Supports both direct identity and pipeline object input.
    Only parameters specified in the call are updated. All others are ignored.

.PARAMETER InputObject
    User object(s) as returned by Get-PSEntraIDUser.

.PARAMETER Identity
    One or more user UPNs, Ids, or Mails.

.PARAMETER DisplayName
    Specifies the display name of the user.

.PARAMETER GivenName
    Specifies the given name (first name) of the user.

.PARAMETER Surname
    Specifies the surname (last name) of the user.

.PARAMETER JobTitle
    Specifies the job title of the user.

.PARAMETER Department
    Specifies the department of the user.

.PARAMETER CompanyName
    Specifies the company name of the user.

.PARAMETER OfficeLocation
    Specifies the office location of the user.

.PARAMETER City
    Specifies the city of the user.

.PARAMETER PostalCode
    Specifies the postal code of the user.

.PARAMETER State
    Specifies the state or province of the user.

.PARAMETER Country
    Specifies the country of the user.

.PARAMETER MobilePhone
    Specifies the user's mobile phone number.

.PARAMETER BusinessPhones
    Specifies an array of business phone numbers for the user.

.PARAMETER UsageLocation
    Specifies the location where the user intends to use Microsoft 365 services.

.PARAMETER PreferredLanguage
    Specifies the user's preferred language (RFC 3066 code).

.PARAMETER AccountEnabled
    Enables or disables the user account.

.PARAMETER Password
    Specifies a new password (as SecureString).

.PARAMETER ForceChangePasswordNextSignIn
    Specifies whether the user must change password at next sign-in.

.PARAMETER ForceChangePasswordNextSignInWithMfa
    Specifies whether the user must change password at next sign-in using MFA.

.PARAMETER EnableException
    This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
    dly, but allows catching exceptions in calling scripts.

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
    When specified, the cmdlet will not execute the disable license action but will instead
    return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

.EXAMPLE
    Set-PSEntraIDUser -Identity "john.doe@contoso.com" -JobTitle "Manager"

.EXAMPLE
    Get-PSEntraIDUser -Filter "department eq 'IT'" | Set-PSEntraIDUser -UsageLocation "CZ" -Department "IT"
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'InputObjectUpdateUser')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectUpdateUser')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [ValidateUserIdentity()]
        [Alias('Id', 'UserPrincipalName')]
        [string[]] $Identity,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $Mail,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $DisplayName,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ParameterSetName = 'IdentityUpdateUser')]
        [string] $GivenName,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $Surname,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $JobTitle,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $Department,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ParameterSetName = 'IdentityUpdateUser')]
        [string] $CompanyName,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $OfficeLocation,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $City,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $PostalCode,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $State,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $Country,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $MobilePhone,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string[]] $BusinessPhones,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $UsageLocation,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [string] $PreferredLanguage,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [bool] $AccountEnabled,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [SecureString] $Password,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [bool] $ForceChangePasswordNextSignIn,
        [Parameter(ParameterSetName = 'InputObjectUpdateUser')]
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUpdateUser')]
        [bool] $ForceChangePasswordNextSignInWithMfa,
        [Parameter()] [switch] $EnableException,
        [Parameter()] [switch] $Force,
        [Parameter()] [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObjectUpdateUser' {
                foreach ($itemInputObject in $InputObject) {
                    [hashtable] $body = @{}
                    if ($PSBoundParameters.ContainsKey('Mail')) { $body['mail'] = $Mail }
                    if ($PSBoundParameters.ContainsKey('DisplayName')) { $body['displayName'] = $DisplayName }
                    if ($PSBoundParameters.ContainsKey('GivenName')) { $body['givenName'] = $GivenName }
                    if ($PSBoundParameters.ContainsKey('Surname')) { $body['surname'] = $Surname }
                    if ($PSBoundParameters.ContainsKey('JobTitle')) { $body['jobTitle'] = $JobTitle }
                    if ($PSBoundParameters.ContainsKey('Department')) { $body['department'] = $Department }
                    if ($PSBoundParameters.ContainsKey('CompanyName')) { $body['companyName'] = $CompanyName }
                    if ($PSBoundParameters.ContainsKey('OfficeLocation')) { $body['officeLocation'] = $OfficeLocation }
                    if ($PSBoundParameters.ContainsKey('City')) { $body['city'] = $City }
                    if ($PSBoundParameters.ContainsKey('PostalCode')) { $body['postalCode'] = $PostalCode }
                    if ($PSBoundParameters.ContainsKey('State')) { $body['state'] = $State }
                    if ($PSBoundParameters.ContainsKey('Country')) { $body['country'] = $Country }
                    if ($PSBoundParameters.ContainsKey('MobilePhone')) { $body['mobilePhone'] = $MobilePhone }
                    if ($PSBoundParameters.ContainsKey('BusinessPhones')) { $body['businessPhones'] = $BusinessPhones }
                    if ($PSBoundParameters.ContainsKey('UsageLocation')) { $body['usageLocation'] = $UsageLocation }
                    if ($PSBoundParameters.ContainsKey('PreferredLanguage')) { $body['preferredLanguage'] = $PreferredLanguage }
                    if ($PSBoundParameters.ContainsKey('AccountEnabled')) { $body['accountEnabled'] = $AccountEnabled }
                    if ($PSBoundParameters.ContainsKey('Password')) {
                        $body['passwordProfile'] = @{ password = ($Password | ConvertFrom-SecureString -AsPlainText) }
                        if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignIn')) {
                            $body['passwordProfile']['forceChangePasswordNextSignIn'] = $ForceChangePasswordNextSignIn
                        }
                        if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignInWithMfa')) {
                            $body['passwordProfile']['forceChangePasswordNextSignInWithMfa'] = $ForceChangePasswordNextSignInWithMfa
                        }
                    }
                    [string] $path = ("users/{0}" -f $itemInputObject.Id)
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'PATCH'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'User.Set' -ActionStringValues $itemInputObject.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
                        } -EnableException:$EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'IdentityUpdateUser' {
                foreach ($user in $Identity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if (-not ([object]::Equals($aADUser, $null))) {
                        [hashtable] $body = @{}
                        if ($PSBoundParameters.ContainsKey('Mail')) { $body['mail'] = $Mail }
                        if ($PSBoundParameters.ContainsKey('DisplayName')) { $body['displayName'] = $DisplayName }
                        if ($PSBoundParameters.ContainsKey('GivenName')) { $body['givenName'] = $GivenName }
                        if ($PSBoundParameters.ContainsKey('Surname')) { $body['surname'] = $Surname }
                        if ($PSBoundParameters.ContainsKey('JobTitle')) { $body['jobTitle'] = $JobTitle }
                        if ($PSBoundParameters.ContainsKey('Department')) { $body['department'] = $Department }
                        if ($PSBoundParameters.ContainsKey('CompanyName')) { $body['companyName'] = $CompanyName }
                        if ($PSBoundParameters.ContainsKey('OfficeLocation')) { $body['officeLocation'] = $OfficeLocation }
                        if ($PSBoundParameters.ContainsKey('City')) { $body['city'] = $City }
                        if ($PSBoundParameters.ContainsKey('PostalCode')) { $body['postalCode'] = $PostalCode }
                        if ($PSBoundParameters.ContainsKey('State')) { $body['state'] = $State }
                        if ($PSBoundParameters.ContainsKey('Country')) { $body['country'] = $Country }
                        if ($PSBoundParameters.ContainsKey('MobilePhone')) { $body['mobilePhone'] = $MobilePhone }
                        if ($PSBoundParameters.ContainsKey('BusinessPhones')) { $body['businessPhones'] = $BusinessPhones }
                        if ($PSBoundParameters.ContainsKey('UsageLocation')) { $body['usageLocation'] = $UsageLocation }
                        if ($PSBoundParameters.ContainsKey('PreferredLanguage')) { $body['preferredLanguage'] = $PreferredLanguage }
                        if ($PSBoundParameters.ContainsKey('AccountEnabled')) { $body['accountEnabled'] = $AccountEnabled }
                        if ($PSBoundParameters.ContainsKey('Password')) {
                            $body['passwordProfile'] = @{ password = ($Password | ConvertFrom-SecureString -AsPlainText) }
                            if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignIn')) {
                                $body['passwordProfile']['forceChangePasswordNextSignIn'] = $ForceChangePasswordNextSignIn
                            }
                            if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignInWithMfa')) {
                                $body['passwordProfile']['forceChangePasswordNextSignInWithMfa'] = $ForceChangePasswordNextSignInWithMfa
                            }
                        }
                        [string] $path = ("users/{0}" -f $aADUser.Id)
                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'PATCH'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'User.Set' -ActionStringValues $aADUser.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -ErrorAction Stop)
                            } -EnableException:$EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $User)
                        }
                    }
                }
            }
        }
    }
    end {}
}
