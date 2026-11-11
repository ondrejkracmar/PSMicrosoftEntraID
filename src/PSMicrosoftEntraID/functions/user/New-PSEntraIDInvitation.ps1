function New-PSEntraIDInvitation {
    <#
    .SYNOPSIS
        Create a new invitation of the specified user.

    .DESCRIPTION
        Create a new invitation of the specified user.

    .PARAMETER InvitedUserEmailAddress
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER InvitedUserDisplayName
        DisplayName, GivenName, Surname of the user attribute populated in tenant/directory.

    .PARAMETER InviteRedirectUrl
        The URL that the user will be redirected to after redemption.

    .PARAMETER SendInvitationMessage
        Switch if send invitation message

    .PARAMETER InviteMessage
        The invitation message

    .PARAMETER MessageLanguage
        Language of invite message.

    .PARAMETER CCRecipient
        Name and mail of CC recipients

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly, but allows catching exceptions in calling scripts.

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
        When specified, the cmdlet will not execute the action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> New-PSEntraIDInvitation -InvitedUserEmailAddress user1@contoso.com -InvitedUserDisplayName 'Displayname' -InviteRedirectUrl 'https://url'

		Create new  of EntraID guest user user1@contoso.com


#>
    [OutputType('PSMicrosoftEntraID.Users.Invitations.Invitation', [PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'UserEmailAddress')]
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
        [switch] $SendInvitationMessage,
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
        [switch] $Force,
        [Parameter()]
        [switch]$PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = 'invitations'
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        # Keys bound on the command line; everything else in $PSBoundParameters was bound
        # by the current pipeline record and is dropped after it (docs/internal/conventions.md).
        [string[]] $commandLineParameter = @($PSBoundParameters.Keys)
    }

    process {
        try {
            [hashtable] $body = @{}
            # Per record: created once in begin, the list collected every earlier record's CC
            # recipients and copied them onto each later invitation.
            [System.Collections.Generic.List[object]] $cCRecipientList = [System.Collections.Generic.List[object]]::new()
            $body['invitedUserEmailAddress'] = $InvitedUserEmailAddress

            if ($PSBoundParameters.ContainsKey('InvitedUserDisplayName')) {
                $body['invitedUserDisplayName'] = $InvitedUserDisplayName
            }

            if ($PSBoundParameters.ContainsKey('InviteRedirectUrl')) {
                $body['inviteRedirectUrl'] = $InviteRedirectUrl
            }

            if ($PSBoundParameters.ContainsKey('SendInvitationMessage')) {
                $body['sendInvitationMessage'] = [bool] $SendInvitationMessage
            }
            else {
                $body['sendInvitationMessage'] = $false
            }

            if ($PSBoundParameters.ContainsKey('MessageLanguage')) {
                $body['messageLanguage'] = $MessageLanguage
            }
            else {
                $body['messageLanguage'] = $null
            }

            if ($PSBoundParameters.ContainsKey('CCRecipient')) {
                foreach ($itemCCRecipient in $CCRecipient) {
                    [void] $cCRecipientList.Add($itemCCRecipient)
                }
            }

            $body['invitedUserMessageInfo'] = @{
                messageLanguage       = $MessageLanguage
                ccRecipients          = $cCRecipientList
                customizedMessageBody = $InviteMessage
            }
            if ($PassThru.IsPresent) {
                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
            }
            else {
                Invoke-PSFProtectedCommand -ActionString 'User.Invitation' -ActionStringValues $InvitedUserEmailAddress -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestInvitation -InputObject (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
        finally {
            Clear-PipelineBoundParameter -BoundParameters $PSBoundParameters -CommandLineParameter $commandLineParameter
        }
    }
    end {}
}
