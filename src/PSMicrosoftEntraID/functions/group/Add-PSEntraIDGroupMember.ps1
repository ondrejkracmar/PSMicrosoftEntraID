function Add-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Add a member to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a member to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

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
            PS C:\> Add-PSEntraIDGroupMember -Identity group1 -User user1,user2

            Add member to Azure AD group group1
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [ValidateGroupIdentity()]
        [string]$Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$User,
        [switch]$EnableException,
        [switch]$Force
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        $nextLoop = 20
        $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool]$cmdLetConfirm = $false
        }
        else {
            [bool]$cmdLetConfirm = $true
        }
    }

    process {
        $memberUrlList = [System.Collections.ArrayList]::new()
        $memberObjectIdList = [System.Collections.ArrayList]::new()
        $memberUserPrincipalNameList = [System.Collections.ArrayList]::new()
        $memberMailList = [System.Collections.ArrayList]::new()
        Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues ((($User | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $Identity -ScriptBlock {
            $group = Get-PSEntraIDGroup -Identity $Identity
            if (-not([object]::Equals($group, $null))) {
                if ($User.count -eq 1) {
                    $aADUser = Get-PSEntraIDUser -Identity $User
                    if (-not([object]::Equals($aADUser, $null))) {
                        [void]$memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                        [void]$memberObjectIdList.Add($aADUser.Id)
                        [void]$memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                        [void]$memberMailList.Add($aADUser.Mail)
                        $requestHash = @{
                            ObjectId          = $memberObjectIdList
                            UserPrincipalName = $memberUserPrincipalNameList
                            Mail              = $memberMailList
                            Role              = 'Member'
                            UrlPath           = ('groups/{0}/members/$ref' -f $group.Id)
                            Method            = 'Post'
                            MemberUrlList     = $memberUrlList
                        }
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $User)
                        }
                    }
                }
                else {
                    foreach ($itemUser in $User) {
                        $aADUser = Get-PSEntraIDUser -Identity $itemUser
                        if (-not([object]::Equals($aADUser, $null))) {
                            [void]$memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                            [void]$memberObjectIdList.Add($aADUser.Id)
                            [void]$memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                            [void]$memberMailList.Add($aADUser.Mail)
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                            }
                        }
                    }
                    $requestHash = @{
                        ObjectId          = $memberObjectIdList
                        UserPrincipalName = $memberUserPrincipalNameList
                        Mail              = $memberMailList
                        Role              = 'Member'
                        UrlPath           = ('groups/{0}' -f $group.Id)
                        Method            = 'Patch'
                        MemberUrlList     = $memberUrlList
                    }
                }
                if ($requestHash.ObjectId.Count -gt 1) {
                    $bodyList = $requestHash.MemberUrlList | Step-Array -Size $nextLoop
                    foreach ($bodyItem in $bodyList) {
                        $body = @{
                            'members@odata.bind' = @($bodyItem)
                        }
                        try {
                            [void](Invoke-EntraRequest -Service $service -Path $requestHash.UrlPath -Header $header -Body $body -Method $requestHash.Method -ErrorAction Stop)
                        }
                        catch {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Add.Failed) -f $Identity)
                            }
                        }
                    }
                }
                else {
                    foreach ($memberUrl in $requestHash.MemberUrlList) {
                        $body = @{
                            '@odata.id' = $memberUrl
                        }
                        try {
                            [void](Invoke-EntraRequest -Service $service -Path $requestHash.UrlPath -Header $header -Body $body -Method $requestHash.Method -ErrorAction Stop)
                        }
                        catch {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupMember.Add.Failed) -f $Identity)
                            }
                        }
                    }
                }
            }
            else {
                if ($EnableException.IsPresent) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
                }
            }
        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue #-RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end {

    }
}
