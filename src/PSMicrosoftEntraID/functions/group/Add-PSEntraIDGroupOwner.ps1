﻿function Add-PSEntraIDGroupOwner {
    <#
    .SYNOPSIS
        Add a owner to a security or Microsoft 365 group.

    .DESCRIPTION
        Add a owner to a security or Microsoft 365 group.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

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

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the disable license action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
            PS C:\> Add-PSEntraIDGroupOwner -Identity group1 -User user1,user2

            Add owners user1,user2 to Azure group group1
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentityInputObject')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUser')]
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
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
        [PSMicrosoftEntraID.Groups.Group] $group = Get-PSEntraIDGroup -Identity $Identity
        if ([object]::Equals($group, $null)) {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
        }
    }

    process {
        [System.Collections.ArrayList] $ownerUrlList = [System.Collections.ArrayList]::new()
        [System.Collections.ArrayList] $ownerObjectIdList = [System.Collections.ArrayList]::new()
        [System.Collections.ArrayList] $ownerUserPrincipalNameList = [System.Collections.ArrayList]::new()
        [System.Collections.ArrayList] $ownerMailList = [System.Collections.ArrayList]::new()
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityUser' {
                [string] $userActionString = ($User | ForEach-Object { "{0}" -f $_ }) -join ','
            }
            'IdentityInputObject' {
                [string] $userActionString = ($InputObject.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
            }
        }
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityInputObject' {
                foreach ($itemInputObject in $InputObject) {
                    [void] $ownerUrlList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $itemInputObject.Id))
                    [void] $ownerObjectIdList.Add($itemInputObject.Id)
                    [void] $ownerUserPrincipalNameList.Add($itemInputObject.UserPrincipalName)
                    [void] $ownerMailList.Add($itemInputObject.Mail)
                }
            }
            'IdentityUser' {
                foreach ($itemUser in $User) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $itemUser
                    if (-not([object]::Equals($aADUser, $null))) {
                        [void] $ownerUrlList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                        [void] $ownerObjectIdList.Add($aADUser.Id)
                        [void] $ownerUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                        [void] $ownerMailList.Add($aADUser.Mail)
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                        }
                    }
                }
            }
        }
        [hashtable] $requestHash = @{
            ObjectId          = $ownerObjectIdList
            UserPrincipalName = $ownerUserPrincipalNameList
            Mail              = $ownerMailList
            Role              = 'Owner'
            UrlPath           = ('groups/{0}/owners/$ref' -f $group.Id)
            Method            = 'POST'
            OwnerUrlList      = $ownerUrlList
        }
        foreach ($ownerUrl in $requestHash.OwnerUrlList) {
            [hashtable] $body = @{
                '@odata.id' = $ownerUrl
            }
            $path = $requestHash.UrlPath
            $method = $requestHash.Method
            if ($PassThru.IsPresent) {
                [PSMicrosoftEntraID.Batch.Request]@{ Method = $method; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
            }
            else {
                $userActionString = ($questHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
                Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Add' -ActionStringValues $userActionString -Target $group.DisplayName -ScriptBlock {
                    [void](Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method $method -ErrorAction Stop)
                } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            }
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
    end {

    }
}
