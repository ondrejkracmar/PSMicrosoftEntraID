function Add-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Add a member to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a member to a security or Microsoft 365 group.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

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
            PS C:\> Add-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Add member to Azure AD group group1
#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'IdentityInputObject')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityInputObject')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentityUser')]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [ValidateGroupIdentity()]
        [string] $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [PSMicrosoftEntraID.Users.User[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUser')]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $User,
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
        [int] $nextLoop = 20
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        [PSMicrosoftEntraID.Groups.Group] $group = Get-PSEntraIDGroup -Identity $Identity
        if ([object]::Equals($group, $null)) {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
        }
    }

    process {
        [System.Collections.Generic.List[object]] $memberUrlList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $memberObjectIdList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $memberUserPrincipalNameList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $memberMailList = [System.Collections.Generic.List[object]]::new()

        switch ($PSCmdlet.ParameterSetName) {
            'IdentityInputObject' {
                if ($InputObject.Count -eq 1) {
                    [void] $memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $InputObject.Id))
                    [void] $memberObjectIdList.Add($InputObject.Id)
                    [void] $memberUserPrincipalNameList.Add($InputObject.UserPrincipalName)
                    [void] $memberMailList.Add($InputObject.Mail)
                    [hashtable] $requestHash = @{
                        ObjectId          = $memberObjectIdList
                        UserPrincipalName = $memberUserPrincipalNameList
                        Mail              = $memberMailList
                        Role              = 'Member'
                        UrlPath           = ('groups/{0}/members/$ref' -f $group.Id)
                        Method            = 'POST'
                        MemberUrlList     = $memberUrlList
                    }
                }
                else {
                    foreach ($itemInputObject in $InputObject) {
                        [void]$memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $itemInputObject.Id))
                        [void]$memberObjectIdList.Add($itemInputObject.Id)
                        [void]$memberUserPrincipalNameList.Add($itemInputObject.UserPrincipalName)
                        [void]$memberMailList.Add($itemInputObject.Mail)
                    }
                    [hashtable] $requestHash = @{
                        ObjectId          = $memberObjectIdList
                        UserPrincipalName = $memberUserPrincipalNameList
                        Mail              = $memberMailList
                        Role              = 'Member'
                        UrlPath           = ('groups/{0}' -f $group.Id)
                        Method            = 'PATCH'
                        MemberUrlList     = $memberUrlList
                    }
                }
            }
            'IdentityUser' {
                if ($User.Count -eq 1) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $User
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $User)
                        }
                    }
                    else {
                        [void] $memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                        [void] $memberObjectIdList.Add($aADUser.Id)
                        [void] $memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                        [void] $memberMailList.Add($aADUser.Mail)
                        [hashtable] $requestHash = @{
                            ObjectId          = $memberObjectIdList
                            UserPrincipalName = $memberUserPrincipalNameList
                            Mail              = $memberMailList
                            Role              = 'Member'
                            UrlPath           = ('groups/{0}/members/$ref' -f $group.Id)
                            Method            = 'POST'
                            MemberUrlList     = $memberUrlList
                        }
                    }
                }
                else {
                    foreach ($itemUser in $User) {
                        [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $itemUser
                        if ([object]::Equals($aADUser, $null)) {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                            }
                        }
                        else {
                            [void] $memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                            [void] $memberObjectIdList.Add($aADUser.Id)
                            [void] $memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                            [void] $memberMailList.Add($aADUser.Mail)
                        }
                    }
                    $requestHash = @{
                        ObjectId          = $memberObjectIdList
                        UserPrincipalName = $memberUserPrincipalNameList
                        Mail              = $memberMailList
                        Role              = 'Member'
                        UrlPath           = ('groups/{0}' -f $group.Id)
                        Method            = 'PATCH'
                        MemberUrlList     = $memberUrlList
                    }
                }
            }
        }
        if ($requestHash.ObjectId.Count -gt 1) {
            [string[]] $bodyList = $requestHash.MemberUrlList | Step-Array -Size $nextLoop
            foreach ($bodyItem in $bodyList) {
                [hashtable] $body = @{
                    'members@odata.bind' = @($bodyItem)
                }
                $path = $requestHash.UrlPath
                $method = $requestHash.Method
                if ($PassThru.IsPresent) {
                    [PSMicrosoftEntraID.Batch.Request]@{ Method = $method; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                }
                else {
                    $userActionString = ($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues $userActionString -Target $group.DisplayName -ScriptBlock {
                        [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method $requestHash.Method -ErrorAction Stop)
                    } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
        else {
            foreach ($memberUrl in $requestHash.MemberUrlList) {
                [hashtable] $body = @{
                    '@odata.id' = $memberUrl
                }
                $path = $requestHash.UrlPath
                $method = $requestHash.Method
                if ($PassThru.IsPresent) {
                    [PSMicrosoftEntraID.Batch.Request]@{ Method = $method; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                }
                else {
                    $userActionString = ($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues $userActionString -Target $group.DisplayName -ScriptBlock {
                        [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method $requestHash.Method -ErrorAction Stop)
                    } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }

                }
            }
        }
    }
    end {

    }
}
