﻿function New-PSEntraIDInvitation {
    <#
    .SYNOPSIS
        Get the properties of the specified user.

    .DESCRIPTION
        Get the properties of the specified user.

    .PARAMETER InvitedUserEmailAddress
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER InvitedUserDisplayName
        DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

    .PARAMETER InviteRedirectUrl
        The URL that the user will be redirected to after redemption.

    .PARAMETER SendInvitationMessage
        Switch if senf invitation message

    .PARAMETER InviteMessage
        The invitation message

    .PARAMETER MessageLanguage
        Langueage of invite message.

    .PARAMETER CCRecipient
        Name and mail of CC recipients

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.


    .EXAMPLE
        PS C:\> Get-PSEntraIDUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'UserEmailAddres')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("UserEmailAddress", "EmailAddres", "Mail", "UserPrincipalName", "InvitedUserPrincipalName")]
        [ValidateMailAddress()]
        [string]$InvitedUserEmailAddress,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("UserDisplayNameName", "DisplayNameName", "Name")]
        [ValidateNotNullOrEmpty()]
        [string]$InvitedUserDisplayName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("RedirectUrl", "Url")]
        [ValidateNotNullOrEmpty()]
        [string]$InviteRedirectUrl,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [ValidateNotNullOrEmpty()]
        [bool]$SendInvitationMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("Message")]
        [ValidateNotNullOrEmpty()]
        [string]$InviteMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("Language")]
        [string]$MessageLanguage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [psobject[]]$CCRecipient,
        [switch]$EnableException
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        $path = 'invitations'
        $cCRecipientList = [System.Collections.ArrayList]::New()
        $header = @{
            'Content-Type' = 'application/json'
        }
    }

    process {
        $body = @{}
        $body['invitedUserEmailAddress'] = $InvitedUserEmailAddress

        if (Test-PSFParameterBinding -ParameterName 'InvitedUserDisplayName') {
            $body['invitedUserDisplayName'] = $InvitedUserDisplayName
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

        $body['invitedUserMessageInfo'] = @{
            messageLanguage       = $MessageLanguage
            ccRecipients          = $cCRecipientList
            customizedMessageBody = $InviteMessage
        }

        Invoke-PSFProtectedCommand -ActionString 'User.Invitation' -ActionStringValues $InvitedUserEmailAddress -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            [void](Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {}
}