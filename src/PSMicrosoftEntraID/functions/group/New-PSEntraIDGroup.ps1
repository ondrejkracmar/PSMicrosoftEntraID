function New-PSEntraIDGroup {
    <#
    .SYNOPSIS
        Create new  Microsoft EntraID (Azure AD).

    .DESCRIPTION
        Create new  Microsoft EntraID (Azure AD).

    .PARAMETER Displayname
        The display name for the group.

    .PARAMETER Description
       The description for the group.

    .PARAMETER MailNickname
        The mail alias for the group, unique for Microsoft 365 groups in the organization. Maximum length is 64 characters.

    .PARAMETER MailEnabled
        Specifies whether the group is mail-enabled. Required.

    .PARAMETER IsAssignableToRole
        Indicates whether this group can be assigned to a Microsoft Entra role. Optional.

    .PARAMETER SecurityEnabled
        Specifies whether the group is a security group. Required.

    .PARAMETER Classification
        Describes a classification for the group.

    .PARAMETER GroupTypes
        Specifies the group type and its membership.

    .PARAMETER Visibility
        Specifies the group join policy and group content visibility for groups. Possible values are: Private, Public, or HiddenMembership.

    .PARAMETER Owners
        List of owners of new group.

    .PARAMETER Members
        List of mwmwbrs of new group.

    .PARAMETER MembersmembershipRule
        The rule that determines members for this group if the group is a dynamic group (groupTypes contains DynamicMembership).

    .PARAMETER MembershipRuleProcessingState
        Indicates whether the dynamic membership processing is on or paused. Possible values are On or Paused.

    .PARAMETER ResourceBehaviorOptions
    	Specifies the group behaviors that can be set for a Microsoft 365 group during creation.

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
        PS C:\> New-PSEntraIDUser -DisplayName 'New group' -Description 'Description of new froup'

		Create new  Microsoft EntraID (Azure AD) group
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'CreateGroup')]
    param(
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Displayname,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string] $Description,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $MailNickname,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool] ]$MailEnabled,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]] $IsAssignableToRole,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]] $SecurityEnabled = $true,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string] $Classification,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Unified', 'DynamicMembership')]
        [string[]] $GroupTypes,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Public', 'Private', 'HiddenMembership')]
        [string] $Visibility,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateUserIdentity()]
        [string[]] $Owners,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateUserIdentity()]
        [string[]] $Members,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string] $MembersmembershipRule,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('On', 'Paused')]
        [string] $MembershipRuleProcessingState,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('AllowOnlyMembersToPost', 'HideGroupInOutlook', 'HideGroupInOutlook', 'SubscribeNewGroupMembers', 'WelcomeEmailDisabled')]
        [string[]] $ResourceBehaviorOptions,
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
        [string] $path = 'groups'
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
        Invoke-PSFProtectedCommand -ActionString 'Group.New' -ActionStringValues $Displayname -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            Switch ($PSCmdlet.ParameterSetName) {
                'CreateGroup' {
                    $body['displayName'] = $Displayname
                    $body['mailNickName'] = $MailNickname
                    $body['mailEnabled'] = $MailEnabled
                    $body['securityEnabled'] = $SecurityEnabled
                    $body['groupTypes'] = @($GroupTypes)

                    if ($PSBoundParameters.ContainsKey('Description')) {
                        $body['description'] = $Description
                    }

                    if ($PSBoundParameters.ContainsKey('Visibility')) {
                        $body['visibility'] = $Visibility
                    }

                    if ($PSBoundParameters.ContainsKey('IsAssignableToRole')) {
                        $body['isAssignableToRole'] = $IsAssignableToRole
                    }
                    if (Test-PSFParameterBinding -ParameterName 'Classification') {
                        $body['classification'] = $Classification
                    }

                    if ($PSBoundParameters.ContainsKey('Owners')) {
                        $userIdUriPathList = [System.Collections.ArrayList]::new()
                        foreach ($owner in $Owners) {
                            [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $owner
                            if (-not([object]::Equals($aADUser, $null))) {
                                [void]$userIdUriPathList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                            }
                            $body['owners@odata.bind'] = [array]$userIdUriPathList
                        }
                        foreach ($member in $Members) {
                            [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $member
                            if (-not([object]::Equals($aADUser, $null))) {
                                [void]$userIdUriPathList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                            }
                            $body['members@odata.bind'] = [array]$userIdUriPathList
                        }
                    }
                    if ($PSBoundParameters.ContainsKey('MembersmembershipRule')) {
                        $body['membershipRule'] = $MembersmembershipRule
                        $body['membershipRuleProcessingState'] = 'On'
                        $body['resourceBehaviorOptions'] = 'WelcomeEmailDisabled'
                    }
                    if ($PSBoundParameters.ContainsKey('MembershipRuleProcessingState')) {
                        $body['membershipRuleProcessingState'] = $MembershipRuleProcessingState
                    }
                    if ($PSBoundParameters.ContainsKey('ResourceBehaviorOptions')) {
                        $body['resourceBehaviorOptions'] = $ResourceBehaviorOptions
                    }
                }
            }
            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {

    }
}