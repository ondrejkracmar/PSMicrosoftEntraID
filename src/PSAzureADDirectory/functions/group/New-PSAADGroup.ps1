function New-PSAADGroup {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'CreateGroup')]
    param(
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DisplayName,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]
        $Description,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string]
        $MailNickName,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]]
        $MailEnabled,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]]
        $IsAssignableToRole,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [System.Nullable[bool]]
        $SecurityEnabled = $true,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string]
        $Classification,
        [Parameter(ParameterSetName = 'CreateGroup', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Unified', 'DynamicMembership')]
        [string[]]
        $GroupTypes,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Public', 'Private', 'HiddenMembership')]
        [string]
        $Visibility,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateIdentity()]
        [string[]]
        $Owners,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateIdentity()]
        [string[]]
        $Members,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string]
        $MembershipRule,
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [string]
        [ValidateSet('On', 'Paused')]
        $MembershipRuleProcessingState,
        [Parameter(ParameterSetName = 'CreateGroupViaJson')]
        [Parameter(ParameterSetName = 'CreateGroup', ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('AllowOnlyMembersToPost', 'HideGroupInOutlook', 'HideGroupInOutlook', 'SubscribeNewGroupMembers', 'WelcomeEmailDisabled')]
        [string[]]
        $ResourceBehaviorOptions,
        [string]
        $JsonRequest
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
        $requestBodyCreateGroupTemplateJSON = '{
            "displayName": "",
            "mailNickname" : "",
            "mailEnabled": true,
            "securityEnabled": true,
            "description": "",
            "visibility": "Public",
            "groupTypes" : []
        }'
    }

    process {
        
        Switch ($PSCmdlet.ParameterSetName) {
            'CreateGroupViaJson' {
                $body = $JsonRequest 
            }
            'CreateGroup' {
                $bodyParameters = $requestBodyCreateGroupTemplateJSON | ConvertFrom-Json | ConvertTo-PSFHashtable
                $bodyParameters['displayName'] = $DisplayName
                if (Test-PSFParameterBinding -Parameter Description) {
                    $bodyParameters['description'] = $Description
                }

                if (Test-PSFParameterBinding -Parameter MailNickName) {
                    $bodyParameters['mailNickName'] = $MailNickName
                }

                if (Test-PSFParameterBinding -Parameter MailEnabled) {
                    $bodyParameters['mailEnabled'] = $MailEnabled
                }

                if (Test-PSFParameterBinding -Parameter Visibility) {
                    $bodyParameters['visibility'] = $Visibility
                }

                if (Test-PSFParameterBinding -Parameter SecurityEnabled) {
                    $bodyParameters['securityEnabled'] = $SecurityEnabled
                }

                if (Test-PSFParameterBinding -Parameter IsAssignableToRole) {
                    $bodyParameters['isAssignableToRole'] = $IsAssignableToRole
                }

                if (Test-PSFParameterBinding -Parameter GroupTypes) {
                    $bodyParameters['groupTypes'] = @($GroupTypes)
                }

                if (Test-PSFParameterBinding -Parameter Owners) {
                    $userIdUriPathList = [System.Collections.ArrayList]::new()
                    foreach ($owner in $Owners) {
                        $userUriPath = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath 'users'
                        $aADUser = Get-PSAADUser -Identity $owner
                        $userIdUriPath = Join-UriPath -Uri $userUriPath -ChildPath $aADUser.Id
                        [void]($userIdUriPathList.Add($userIdUriPath))
                    }
                    $bodyParameters['owners@odata.bind'] = [array]$userIdUriPathList
                }

                if (Test-PSFParameterBinding -Parameter Members) {
                    $userIdUriPathList = [System.Collections.ArrayList]::new()
                    foreach ($member in $Members) {
                        $userUriPath = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath 'users'
                        $aADUser = Get-PSAADUser -Identity $member
                        $userIdUriPath = Join-UriPath -Uri $userUriPath -ChildPath $aADUser.Id
                        [void]($userIdUriPathList.Add($userIdUriPath))
                    }
                    $bodyParameters['members@odata.bind'] = [array]$userIdUriPathList
                }

                if (Test-PSFParameterBinding -Parameter MembershipRule) {
                    $bodyParameters['membershipRule'] = $MembershipRule
                    $bodyParameters['membershipRuleProcessingState'] = 'On'
                    #$bodyParameters['resourceBehaviorOptions'] = 'WelcomeEmailDisabled'
                }

                if (Test-PSFParameterBinding -Parameter MembershipRuleProcessingState) {
                    $bodyParameters['membershipRuleProcessingState'] = $MembershipRuleProcessingState
                }

                if (Test-PSFParameterBinding -Parameter ResourceBehaviorOptions) {
                    $bodyParameters['resourceBehaviorOptions'] = $ResourceBehaviorOptions
                }
                $body = $bodyParameters | ConvertTo-Json
            }
        }

        Invoke-PSFProtectedCommand -ActionString 'Office365Group.New' -ActionStringValues $DisplayName -Target 'Office 365 Groups' $aADUser.UserPrincipalName -ScriptBlock {
            [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post) } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {

    }
}