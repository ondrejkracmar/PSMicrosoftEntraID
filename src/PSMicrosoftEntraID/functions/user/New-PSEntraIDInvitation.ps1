function New-PSEntraIDInvitation {
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


    .EXAMPLE
        PS C:\> New-PSEntraIDInvitation -InvitedUserEmailAddress user1@contoso.com -InvitedUserDisplayName 'Displayname' -InviteRedirectUrl 'https://url'

		Create new  of EntraID guest user user1@contoso.com


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'UserEmailAddres')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("UserEmailAddress", "EmailAddres", "Mail", "UserPrincipalName", "InvitedUserPrincipalName")]
        [ValidateMailAddress()]
        [string] $InvitedUserEmailAddress,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("UserDisplayNameName", "DisplayNameName", "Name")]
        [ValidateNotNullOrEmpty()]
        [string] $InvitedUserDisplayName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("RedirectUrl", "Url")]
        [ValidateNotNullOrEmpty()]
        [string] $InviteRedirectUrl,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [ValidateNotNullOrEmpty()]
        [bool] $SendInvitationMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("Message")]
        [ValidateNotNullOrEmpty()]
        [string] $InviteMessage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [Alias("Language")]
        [string] $MessageLanguage,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserEmailAddress')]
        [psobject[]] $CCRecipient,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = 'invitations'
        [System.Collections.ArrayList] $cCRecipientList = [System.Collections.ArrayList]::New()
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else {
            [boolean] $cmdLetVerbose = $false
        }
    }

    process {
        [hashtable] $body = @{}
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
                [void] $cCRecipientList.Add($itemCCRecipient)
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
            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {}
}