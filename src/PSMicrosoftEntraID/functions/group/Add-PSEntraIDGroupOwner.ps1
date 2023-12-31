﻿function Add-PSEntraIDGroupOwner {
    <#
    .SYNOPSIS
        Add a owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a owner to a security or Microsoft 365 group.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER User
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Role
        user's role (Member or Owner)

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .EXAMPLE
            PS C:\> Add-PSEntraIDGroupOwner -Identity group1 -User user1,user2

            Add owners user1,user2 to Azure group group1
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
    }

    process {
        $ownerUrlList = [System.Collections.ArrayList]::new()
        $memberObjectIdList = [System.Collections.ArrayList]::new()
        $memberUserPrincipalNameList = [System.Collections.ArrayList]::new()
        $memberMailList = [System.Collections.ArrayList]::new()
        $group = Get-PSEntraIDGroup -Identity $Identity
        if (-not([object]::Equals($group, $null))) {
            foreach ($itemUser in $User) {
                $aADUser = Get-PSEntraIDUser -Identity $itemUser
                if (-not([object]::Equals($aADUser, $null))) {
                    [void]$ownerUrlList.Add(('{0}/users/{1}' -f (Get-GraphApiUriPath), $aADUser.Id))
                    [void]$memberObjectIdList.Add($aADUser.Id)
                    [void]$memberUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                    [void]$memberMailList.Add($aADUser.Mail)
                }
            }
            $requestHash = @{
                ObjectId          = $memberObjectIdList
                UserPrincipalName = $memberUserPrincipalNameList
                Mail              = $memberMailList
                Role              = 'Owner'
                UrlPath           = ('groups/{0}/owners/$ref' -f $group.Id)
                Metohd            = 'Post'
                MemberUrlList     = $memberUrlList
            }
            foreach ($ownerUrl in $requestHash.$ownerUrlList) {
                $body = @{
                    '@odata.id' = $ownerUrl
                }
                Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Add' -ActionStringValues ((($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ',')) -Target $group.MailNickName -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $requestHash.UrlPath -Body $body -Method $requestHash.Method -ErrorAction Stop)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
        else {
            if ($EnableException.IsPresent) {
                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
            }
        }
    }
    end {

    }
}
