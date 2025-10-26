function New-PSEntraIDUser {
    <#
.SYNOPSIS
    Creates a new user in Microsoft Entra ID (Azure AD).

.DESCRIPTION
    Provisions a new user object with configurable properties like name, contact info,
    job details, and password using Microsoft Graph API.

.PARAMETER DisplayName
    Full name of the user.

.PARAMETER GivenName
    First name.

.PARAMETER Surname
    Last name.

.PARAMETER UserPrincipalName
    User sign-in name (e.g. john.doe@contoso.com).

.PARAMETER MailNickname
    User alias.

.PARAMETER Password
    Initial password as SecureString.

.PARAMETER ForceChangePasswordNextSignIn
    If set, user must change password on first login.

.PARAMETER ForceChangePasswordNextSignInWithMfa
    If set, user must change password on first login with MFA.

.PARAMETER AccountEnabled
    Whether the account is enabled. Default: $true

.PARAMETER UsageLocation
    ISO country code (e.g. CZ, US).

.PARAMETER JobTitle
    Job title of the user.

.PARAMETER Department
    Department name.

.PARAMETER CompanyName
    Company name.

.PARAMETER OfficeLocation
    Office location.

.PARAMETER City
    City of residence.

.PARAMETER PostalCode
    Postal code.

.PARAMETER Country
    Country name.

.PARAMETER State
    State or province.

.PARAMETER MobilePhone
    Mobile phone number.

.PARAMETER BusinessPhones
    Business phone numbers.

.PARAMETER Mail
    Primary email address of the user.
.PARAMETER ProxyAddresses

    Array of proxy email addresses for the user.
.PARAMETER FaxNumber
    Fax number associated with the user.
    
.PARAMETER OtherMails
    List of other email addresses for the user.

.PARAMETER PreferredLanguage
    Default language (e.g. en-US, cs-CZ).

.PARAMETER EmployeeId
    Employee ID.

.PARAMETER EmployeeType
    Employee type (e.g. full-time, contractor).

.PARAMETER EnableException
    Enables throwing of terminating errors.

.PARAMETER PassThru
    Outputs the created user object.

.PARAMETER Confirm
    Prompts for confirmation.

.PARAMETER WhatIf
    Simulates the command.

.EXAMPLE
    Import-Csv users.csv | New-PSEntraIDUser

.EXAMPLE
    New-PSEntraIDUser -DisplayName "John Doe" -UserPrincipalName "john.doe@contoso.com" -MailNickname "jdoe" -Password (Read-Host -AsSecureString "Enter password")
#>
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'CreateUser')]
    param (
        [Parameter(ParameterSetName = 'CreateUser', Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $DisplayName,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $GivenName,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $Surname,
        [Parameter(ParameterSetName = 'CreateUser', Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $UserPrincipalName,
        [Parameter(ParameterSetName = 'CreateUser', Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [string] $MailNickname,
        [Parameter(ParameterSetName = 'CreateUser', Mandatory = $true, ValueFromPipelineByPropertyName = $true)] [SecureString] $Password,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [bool] $ForceChangePasswordNextSignIn = $true,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [bool] $ForceChangePasswordNextSignInWithMfa = $false,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $Mail,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [bool] $AccountEnabled = $true,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $UsageLocation,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $JobTitle,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $Department,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $CompanyName,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $OfficeLocation,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $City,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $PostalCode,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $Country,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $State,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $MobilePhone,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string[]] $BusinessPhones,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string[]] $ProxyAddresses,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $FaxNumber,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $EmployeeId,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string[]] $OtherMails,
        [Parameter(ParameterSetName = 'CreateUser', ValueFromPipelineByPropertyName = $true)] [string] $PreferredLanguage,
        [Parameter()] [switch] $PassThru
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
    }

    process {
        [hashtable] $body = @{}
        [hashtable] $passwordProfile = @{}
        Switch ($PSCmdlet.ParameterSetName) {
            'CreateUser' {

                $passwordProfile = @{ password = ($Password | ConvertFrom-SecureString -AsPlainText) }
                if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignIn')) {
                    $passwordProfile['forceChangePasswordNextSignIn'] = $ForceChangePasswordNextSignIn
                }
                if ($PSBoundParameters.ContainsKey('ForceChangePasswordNextSignInWithMfa')) {
                    $passwordProfile['forceChangePasswordNextSignInWithMfa'] = $ForceChangePasswordNextSignInWithMfa
                }

                $body = @{
                    accountEnabled    = $AccountEnabled
                    displayName       = $DisplayName
                    mailNickname      = $MailNickname
                    userPrincipalName = $UserPrincipalName
                    passwordProfile   = $passwordProfile
                }

                if ($PSBoundParameters.ContainsKey('Mail')) { $body['mail'] = $Mail }
                if ($PSBoundParameters.ContainsKey('GivenName')) { $body['givenName'] = $GivenName }
                if ($PSBoundParameters.ContainsKey('Surname')) { $body['surname'] = $Surname }
                if ($PSBoundParameters.ContainsKey('UsageLocation')) { $body['usageLocation'] = $UsageLocation }
                if ($PSBoundParameters.ContainsKey('JobTitle')) { $body['jobTitle'] = $JobTitle }
                if ($PSBoundParameters.ContainsKey('Department')) { $body['department'] = $Department }
                if ($PSBoundParameters.ContainsKey('CompanyName')) { $body['companyName'] = $CompanyName }
                if ($PSBoundParameters.ContainsKey('OfficeLocation')) { $body['officeLocation'] = $OfficeLocation }
                if ($PSBoundParameters.ContainsKey('City')) { $body['city'] = $City }
                if ($PSBoundParameters.ContainsKey('PostalCode')) { $body['postalCode'] = $PostalCode }
                if ($PSBoundParameters.ContainsKey('Country')) { $body['country'] = $Country }
                if ($PSBoundParameters.ContainsKey('State')) { $body['state'] = $State }
                if ($PSBoundParameters.ContainsKey('MobilePhone')) { $body['mobilePhone'] = $MobilePhone }
                if ($PSBoundParameters.ContainsKey('BusinessPhones')) { $body['businessPhones'] = $BusinessPhones }
                if ($PSBoundParameters.ContainsKey('ProxyAddresses')) { $body['proxyAddresses'] = $ProxyAddresses }
                if ($PSBoundParameters.ContainsKey('UserPrincipalName')) { $body['userPrincipalName'] = $UserPrincipalName }
                if ($PSBoundParameters.ContainsKey('MailNickname')) { $body['mailNickname'] = $MailNickname }
                if ($PSBoundParameters.ContainsKey('FaxNumber')) { $body['faxNumber'] = $FaxNumber }
                if ($PSBoundParameters.ContainsKey('OtherMails')) { $body['otherMails'] = $OtherMails }
                if ($PSBoundParameters.ContainsKey('PreferredLanguage')) { $body['preferredLanguage'] = $PreferredLanguage }
                if ($PSBoundParameters.ContainsKey('EmployeeId')) { $body['employeeId'] = $EmployeeId }
                if ($PSBoundParameters.ContainsKey('EmployeeType')) { $body['employeeType'] = $EmployeeType }
            }
        }

        if ($PassThru) {
            return [PSMicrosoftEntraID.Batch.Request]@{
                Method  = 'POST'
                Url     = '/users'
                Body    = $body
                Headers = $header
            }
        }
        else {
            Invoke-PSFProtectedCommand -ActionString 'User.New' -ActionStringValues $UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                [void] (Invoke-EntraRequest -Service $service -Path 'users' -Header $header -Body $body -Method Post -ErrorAction Stop)
            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    end {}
}
