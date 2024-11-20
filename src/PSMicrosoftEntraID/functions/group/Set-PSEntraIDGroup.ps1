function Set-PSEntraIDGroup {
    <#
    .SYNOPSIS
        Updates the specified properties of a Microsoft 365 Group.

    .DESCRIPTION
        The `Set-PSntraIDGroup` cmdlet allows you to modify specific properties of a Microsoft 365 Group.
        Some properties can be updated together, while others require separate calls. Additionally, certain
        properties are read-only and can only be retrieved, not modified..

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER DisplayName
        Specifies the display name of the group. This can be updated in conjunction with other group settings.

    .PARAMETER Description
        Specifies the description of the group. This can be updated with other properties.

    .PARAMETER MailNickname
        Sets the mail alias (nickname) of the group. This can be updated along with other modifiable properties.

    .PARAMETER Visibility
        Defines the visibility of the group. Accepted values are `Public` and `Private`. This parameter can be updated in conjunction with other properties.

    .PARAMETER AllowExternalSenders
        Specifies whether external users can send messages to the group.
        Note: This parameter must be set in a separate call and cannot be combined with other properties in a single `PATCH` request.

    .PARAMETER AutoSubscribeNewMembers
        Indicates whether new members are automatically subscribed to receive email notifications.
        Note: This parameter must be updated in a separate call from other properties.

    .PARAMETER HideFromAddressLists
        Hides the group from global address lists.
        Note: This parameter must be updated in a separate call from other properties.

    .PARAMETER HideFromOutlookClients
        Hides the group from Outlook clients.
        Note: This parameter must be updated in a separate call from other properties.

    .PARAMETER SecurityEnabled
        Sets whether the group is security-enabled. This is often used with dynamic groups and can be updated along with other modifiable properties.

    .PARAMETER GroupTypes
        Specifies the type of the group. For Microsoft 365 groups, use `Unified`. This can be combined with other parameters in the same update request.

    .PARAMETER MembershipRule
        Defines the membership rule for a dynamic group. This parameter is specific to dynamic groups and should be used with `MembershipRuleProcessingState`.

    .PARAMETER MembershipRuleProcessingState
        Sets the processing state of the membership rule. Accepted values are `On`, `Paused`, and `Off`. This should be used with `MembershipRule` and is specific to dynamic groups.

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
        Set-PSntraIDGroup -GroupId "mailnickname1" -DisplayName "New Group Name" -Description "Updated group description" -Visibility "Private"

    .EXAMPLE
        Set-PSntraIDGroup -GroupId "mailnickname@domain.com" -AllowExternalSenders $true

    .EXAMPLE
        Set-PSntraIDGroup -GroupId "mailnickname1" -MembershipRule "(user.department -eq 'Sales')" -MembershipRuleProcessingState "On"

    .NOTES
        - Properties like `AllowExternalSenders`, `AutoSubscribeNewMembers`, `HideFromAddressLists`, and `HideFromOutlookClients` must each be set in separate requests.
        - Use `Set-PSntraIDGroup` to retrieve read-only properties such as `isSubscribedByMail` and `unseenCount`.

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'UodtaeGroupCommon')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AllowExternalSenders')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AutoSubscribeNewMembers')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'HideFromAddressLists')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'HideFromOutlookClients')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeDynamicGroup')]
        [Alias("Id", "GroupId", "TeamId")]
        [ValidateGroupIdentity()]
        [string[]]$Identity,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [ValidateNotNullOrEmpty()]
        [string]$Displayname,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [string]$Description,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [string]$MailNickname,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [ValidateSet('Unified', 'DynamicMembership')]
        [string[]]$GroupTypes,
        [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeGroupCommon')]
        [ValidateSet('Public', 'Private', 'HiddenMembership')]
        [string]$Visibility,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AllowExternalSenders')]
        [System.Nullable[bool]]$AllowExternalSenders,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'AutoSubscribeNewMembers')]
        [System.Nullable[bool]]$AutoSubscribeNewMembers,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'HideFromAddressLists')]
        [System.Nullable[bool]]$HideFromAddressLists,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'HideFromOutlookClients')]
        [System.Nullable[bool]]$HideFromOutlookClients,
        [Parameter(Mandatory = $true , ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeDynamicGroup')]
        [string]$MembershipRule,
        [Parameter(Mandatory = $true , ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UodtaeDynamicGroup')]
        [ValidateSet('On', 'Paused', 'Off')]
        [string]$MembershipRuleProcessingState,
        [switch]$EnableException,
        [switch]$Force
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool]$cmdLetConfirm = $false
        }
        else {
            [bool]$cmdLetConfirm = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }

    process {
        foreach ($group in $Identity) {
            $aADGroup = Get-PSEntraIDGroup -Identity $group
            if (-not ([object]::Equals($aADGroup, $null))) {
                $path = ("groups/{0}" -f $aADGroup.Id)
                $body = @{}
                switch ($PSCmdlet.ParameterSetName) {
                    'UodtaeGroupCommon' {
                        if ($PSBoundParameters.ContainsKey('Displayname')) {
                            $body['displayName'] = $Displayname
                        }
                        if ($PSBoundParameters.ContainsKey('Description')) {
                            $body['description'] = $Description
                        }
                        if ($PSBoundParameters.ContainsKey('MailNickname')) {
                            $body['mailNickName'] = $MailNickname
                        }
                        if ($PSBoundParameters.ContainsKey('GroupTypes')) {
                            $body['groupTypes'] = @($GroupTypes)
                        }
                        if ($PSBoundParameters.ContainsKey('Visibility')) {
                            $body['visibility'] = $Visibility
                        }
                    }
                    'AllowExternalSenders' {
                        $body['allowExternalSenders'] = $AllowExternalSenders
                    }
                    'AutoSubscribeNewMembers' {
                        $body['autoSubscribeNewMembers'] = $AutoSubscribeNewMembers
                    }
                    'HideFromAddressLists' {
                        $body['hideFromAddressLists'] = $HideFromAddressLists
                    }
                    'HideFromOutlookClients' {
                        $body['hideFromOutlookClients'] = $HideFromOutlookClients
                    }
                    'UodtaeDynamicGroup' {
                        $body['membershipRule'] = $MembershipRule
                        $body['membershipRuleProcessingState'] = $MembershipRuleProcessingState
                    }
                }
                Invoke-PSFProtectedCommand -ActionString 'Group.Set' -ActionStringValues $aADGroup.MailNickname -Target (Get-PSFLocalizedString -Module $script:ModuleName) -ScriptBlock {
                    [void](Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Patch -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue #-RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {
                if ($EnableException.IsPresent) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Set.Failed) -f $user)
                }
            }
        }
    }
    end {}
}