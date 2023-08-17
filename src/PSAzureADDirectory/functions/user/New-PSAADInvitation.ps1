#New-MgInvitation -InvitedUserDisplayName "John Doe" -InvitedUserEmailAddress John@contoso.com -InviteRedirectUrl "https://myapplications.microsoft.com" -SendInvitationMessage:$true
#Update-MgUser -UserId <GuestUserUPN> -UserType Member -UserPrincipalName <NewUPN> -UsageLocation <UsageLocation>
#Update-MgUser -UserId cmoris_fabrikam.com#EXT#@contoso.com -UserType member -UserPrincipalName "cmoris@contoso.com" -UsageLocation US


function New-PSAADInvitation {
    <#
    .SYNOPSIS
        Get the properties of the specified user.

    .DESCRIPTION
        Get the properties of the specified user.

    .PARAMETER InvitedUserEmailAddress
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER InvitedUserDisplayNameName
        DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

    .PARAMETER InviteRedirectUrl
        CompanyName of the user attribute populated in tenant/directory.

    .PARAMETER MessageLanguage
        Return disabled accounts in tenant/directory.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

    .PARAMETER All
        Return all accounts in tenant/directory.

    .PARAMETER PageSize
        Value of returned result set contains multiple pages of data.

    .EXAMPLE
        PS C:\> Get-PSAADUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [CmdletBinding(DefaultParameterSetName = 'UserEmailAddres')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [ValidateEmailAddres()]
        [string]
        [Alias("UserEmailAddress", "EmailAddres", "Mail")]
        $InvitedUserEmailAddress,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("UserDisplayNameName", "DisplayNameName", "Name")]
        [ValidateNotNullOrEmpty()]
        [string]$InvitedUserDisplayNameName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("RedirectUrl", "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$InviteRedirectUrl,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [ValidateNotNullOrEmpty()]
        [string]$SendInvitationMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("Language")]
        [string]$MessageLanguage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("Message")]
        [string]$CustomizedMessage
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }

    process {
        # Set Variables
        #Guest Details
        $GuestUserName = "Michael Seidl (GMAIL)"
        $GuestUserMail = "seidlmichael82@gmail.com"

        #Send Invitation CC to this USer
        $CCRecipientName = "Michael Seidl"
        $CCRecipientMail = "michael@techguy.at"

        #Add Personal Text do Invite Mail
        $InviteMessage = "You have been invited to join the Tenant au2mator.com"
        $InviteRedirectURL = "https://au2mator.com" #URL where the USer is redirected after Invite Acceptance

        #Auth MS Graph API and Get Header

        $path = 'invitations'
        $body = @{}

        $body['invitedUserEmailAddress'] = $InvitedUserEmailAddress

        if (Test-PSFParameterBinding "InvitedUserDisplayNameName")
        {
            $body['invitedUserDisplayName'] = $InvitedUserDisplayNameName
        }

        if (Test-PSFParameterBinding "InviteRedirectUrl")
        {
            $body['inviteRedirectUrl'] = $InviteRedirectUrl
        }

        if (Test-PSFParameterBinding "SendInvitationMessage")
        {
            $body['sendInvitationMessage'] = $SendInvitationMessage
        }
        else{
            $body['sendInvitationMessage'] = $false
        }

        if (Test-PSFParameterBinding "Language")
        {
            $body['messageLanguage'] = $Language
        }
        else{
            $body['messageLanguage'] = $null
        }
        $body['invitedUserMessageInfo'] = @(
            @{
                disabledPlans = $bodyDisabledServicePlans
                skuId         = $bodySkuId
            }
        )
        

        Invoke-PSFProtectedCommand -ActionString 'User.Invitation' -ActionStringValues $InvitedUserEmailAddress -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post)
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }

    $URL = "https://graph.microsoft.com/v1.0/invitations"
    $Method = "POST"
    $body = @"
{
    "invitedUserEmailAddress":"$GuestUserMail",
    "inviteRedirectUrl":"$InviteRedirectURL",
    "invitedUserDisplayName":"$GuestUserName",
    "sendInvitationMessage": true,
    "invitedUserMessageInfo": {
        "messageLanguage": null,
        "ccRecipients": [
             {
                "emailAddress": {
                    "name": "$CCRecipientName",
                    "address": "$CCRecipientMail"
                 }
             }
        ],
        "customizedMessageBody": "$InviteMessage"
     }
}
"@


}
end {}
}