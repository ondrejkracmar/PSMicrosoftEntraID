function Add-PSEntraIDGroupOwner {
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
        [string]$Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'IdentityInputObject')]
        [PSMicrosoftEntraID.Users.User[]]$InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUser')]
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
        $ownerUrlList = [System.Collections.ArrayList]::new()
        $ownerObjectIdList = [System.Collections.ArrayList]::new()
        $ownerUserPrincipalNameList = [System.Collections.ArrayList]::new()
        $ownerMailList = [System.Collections.ArrayList]::new()
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityUser' {
                $userActionString = ($User | ForEach-Object { "{0}" -f $_ }) -join ','
            }
            'IdentityInputObject' {
                $userActionString = ($InputObject.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
            }
        }
        Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Add' -ActionStringValues $userActionString -Target $Identity -ScriptBlock {
            $group = Get-PSEntraIDGroup -Identity $Identity
            if (-not([object]::Equals($group, $null))) {
                switch ($PSCmdlet.ParameterSetName) {
                    'IdentityInputObject' {
                        foreach ($itemInputObject in $InputObject) {
                            [void]$ownerUrlList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $itemInputObject.Id))
                            [void]$ownerObjectIdList.Add($itemInputObject.Id)
                            [void]$ownerUserPrincipalNameList.Add($itemInputObject.UserPrincipalName)
                            [void]$ownerMailList.Add($itemInputObject.Mail)
                        }
                    }
                    'IdentityUser' {
                        foreach ($itemUser in $User) {
                            $aADUser = Get-PSEntraIDUser -Identity $itemUser
                            if (-not([object]::Equals($aADUser, $null))) {
                                [void]$ownerUrlList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                                [void]$ownerObjectIdList.Add($aADUser.Id)
                                [void]$ownerUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                                [void]$ownerMailList.Add($aADUser.Mail)
                            }
                            else {
                                if ($EnableException.IsPresent) {
                                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                                }
                            }
                        }
                    }
                }
                $requestHash = @{
                    ObjectId          = $ownerObjectIdList
                    UserPrincipalName = $ownerUserPrincipalNameList
                    Mail              = $ownerMailList
                    Role              = 'Owner'
                    UrlPath           = ('groups/{0}/owners/$ref' -f $group.Id)
                    Method            = 'Post'
                    OwnerUrlList      = $ownerUrlList
                }
                foreach ($ownerUrl in $requestHash.OwnerUrlList) {
                    $body = @{
                        '@odata.id' = $ownerUrl
                    }
                    try {
                        [void](Invoke-EntraRequest -Service $service -Path $requestHash.UrlPath -Header $header -Body $body -Method $requestHash.Method -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    }
                    catch {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name GroupOwner.Add.Failed) -f $Identity)
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
