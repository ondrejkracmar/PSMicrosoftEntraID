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
            PS C:\> Add-PSADGroupMember -Identity group1 -User user1,user2

            Add member to Azure AD group group1
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(ParameterSetName = 'UserIdentity', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("UserId", "UserPrincipalName", "Mail")]
        $User,
        [switch]
        $EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
        $nextLoop = 20
    }

    process {
        $memberUrlList = [System.Collections.ArrayList]::new()
        $memberObjectIdList = [System.Collections.ArrayList]::new()
        $memberUserPrincipalNameList = [System.Collections.ArrayList]::new()
        $memberMailList = [System.Collections.ArrayList]::new()
        $group = Get-PSEntraIDGroup -Identity $Identity
        if (-not([object]::Equals($group, $null))) {
            if ($User.count -eq 1) {
                $aADUser = Get-PSEntraIDUser -Identity $User
                [void]$memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-GraphApiUriPath), $aADUser.Id))
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
                foreach ($itemUser in $User) {
                    $aADUser = Get-PSEntraIDUser -Identity $itemUser
                    if (-not([object]::Equals($aADUser, $null))) {
                        [void]$memberUrlList.Add(('{0}/directoryObjects/{1}' -f (Get-GraphApiUriPath), $aADUser.Id))
                        [void]$memberObjectIdList.Add($aADUser.Id)
                        [void]$memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                        [void]$memberMailList.Add($aADUser.Mail)
                    }
                }
                $requestHash = @{
                    ObjectId          = $memberObjectIdList
                    UserPrincipalName = $memberUserPrincipalNameList
                    Mail              = $memberMailList
                    Role              = 'Member'
                    UrlPath           = ('groups/{0}/members/$ref' -f $group.Id)
                    Method            = 'Patch'
                    MemberUrlList     = $memberUrlList
                }
            }
            if ($requestHash.ObjectId.Count -gt 1) {
                $bodyList = $requestHash.Body | Step-Array -Size $nextLoop
                foreach ($bodyItem in $bodyList) {
                    $body = @{
                        'members@odata.bind' = $bodyItem
                    }
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues ((($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $group.MailNickName -ScriptBlock {
                        [void](Invoke-RestRequest -Service 'graph' -Path $requestHash.UrlPath -Body $body -Method $requestHash.Method)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            else {
                foreach ($memberUrl in $requestHash.MemberUrlList) {
                    $body = @{
                        '@odata.id' = $memberUrl
                    }
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues ((($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $group.MailNickName -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path $requestHash.UrlPath -Body $body -Method $requestHash.Method
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }

            }
        }
    }
    end {

    }
}
