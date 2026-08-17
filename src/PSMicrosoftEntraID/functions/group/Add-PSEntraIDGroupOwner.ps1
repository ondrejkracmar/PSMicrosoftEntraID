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
            PS C:\> Add-PSEntraIDGroupOwner -Identity group1 -User user1,user2

            Add owners user1,user2 to Azure group group1
#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'IdentityInputObject')]
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
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        [PSMicrosoftEntraID.Groups.Group] $group = Get-PSEntraIDGroup -Identity $Identity
        if ([object]::Equals($group, $null)) {
            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
        }
    }

    process {
        [System.Collections.Generic.List[object]] $ownerUrlList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $ownerObjectIdList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $ownerUserPrincipalNameList = [System.Collections.Generic.List[object]]::new()
        [System.Collections.Generic.List[object]] $ownerMailList = [System.Collections.Generic.List[object]]::new()
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
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                        }
                    }
                    else {
                        [void] $ownerUrlList.Add(('{0}/users/{1}' -f (Get-EntraService -Name $service).ServiceUrl, $aADUser.Id))
                        [void] $ownerObjectIdList.Add($aADUser.Id)
                        [void] $ownerUserPrincipalNameList.Add($aADUser.UserPrincipalName)
                        [void] $ownerMailList.Add($aADUser.Mail)
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
                $userActionString = ($requestHash.UserPrincipalName | ForEach-Object { "{0}" -f $_ }) -join ','
                Invoke-PSFProtectedCommand -ActionString 'GroupOwner.Add' -ActionStringValues $userActionString -Target $group.DisplayName -ScriptBlock {
                    [void](Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method $method -ErrorAction Stop)
                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            }
            if (Test-PSFFunctionInterrupt) { return }
        }
    }
    end {

    }
}
