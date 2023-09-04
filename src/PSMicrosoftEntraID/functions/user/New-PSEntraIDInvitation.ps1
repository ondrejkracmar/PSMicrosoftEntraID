function New-PSEntraIDInvitation {
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
        PS C:\> Get-PSEntraIDUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [CmdletBinding(DefaultParameterSetName = 'UserEmailAddres')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [ValidateEmailAddres()]
        [string]
        [Alias("UserEmailAddress", "EmailAddres", "Mail")]
        $InvitedUserEmailAddress,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("UserDisplayNameName", "DisplayNameName", "Name")]
        [ValidateNotNullOrEmpty()]
        [string]$InvitedUserDisplayNameName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("RedirectUrl", "Url")]
        [ValidateNotNullOrEmpty()]
        [bool]$InviteRedirectUrl,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [ValidateNotNullOrEmpty()]
        [string]$SendInvitationMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("Message")]
        [ValidateNotNullOrEmpty()]
        [string]$InviteMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [Alias("Language")]
        [string]$MessageLanguage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddres')]
        [psobject[]]$CCRecipient,
        [switch]
        $EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds') -f $script:ModuleName)
        $path = 'invitations'
        $cCRecipientList = [System.Collections.ArrayList]::New()
    }

    process {

        $body = @{}

        $body['invitedUserEmailAddress'] = $InvitedUserEmailAddress

        if (Test-PSFParameterBinding -ParameterName 'InvitedUserDisplayNameName') {
            $body['invitedUserDisplayName'] = $InvitedUserDisplayNameName
        }

        if (Test-PSFParameterBinding -ParameterName 'InviteRedirectUrl') {
            $body['inviteRedirectUrl'] = $InviteRedirectUrl
        }

        if (Test-PSFParameterBinding -ParameterName 'SendInvitationMessage') {
            $body['sendInvitationMessage'] = $SendInvitationMessage
        }
        else {
            $body['sendInvitationMessage'] = $false
        }

        if (Test-PSFParameterBinding -ParameterName 'Language') {
            $body['messageLanguage'] = $Language
        }
        else {
            $body['messageLanguage'] = $null
        }

        if (Test-PSFParameterBinding -ParameterName 'CCRecipient') {
            foreach ($itemCCRecipient in $CCRecipient) {
                [void]$cCRecipientList.Add($itemCCRecipient)
            }
        }

        if (Test-PSFParameterBinding -ParameterName CustomizedMessage) {

        }

        $body['invitedUserMessageInfo'] = @(
            messageLanguage = $MessageLanguage
            ccRecipients = $cCRecipientList
            customizedMessageBody = $InviteMessage
        )

        Invoke-PSFProtectedCommand -ActionString 'User.Invitation' -ActionStringValues $InvitedUserEmailAddress -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post)
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {}
}