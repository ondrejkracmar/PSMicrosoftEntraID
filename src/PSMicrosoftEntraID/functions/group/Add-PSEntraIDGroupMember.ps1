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
        # Everything a record sends is built here from nothing: state left over from the
        # previous pipeline record used to be sent again when this one did not resolve.
        [System.Collections.Generic.List[object]] $memberList = [System.Collections.Generic.List[object]]::new()
        switch ($PSCmdlet.ParameterSetName) {
            'IdentityInputObject' {
                foreach ($itemInputObject in $InputObject) {
                    [void] $memberList.Add([PSCustomObject]@{ Id = $itemInputObject.Id; UserPrincipalName = $itemInputObject.UserPrincipalName })
                }
            }
            'IdentityUser' {
                foreach ($itemUser in $User) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $itemUser
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $itemUser)
                        }
                        Write-PSFMessage -Level Warning -String 'User.Get.Failed' -StringValues $itemUser
                        continue
                    }
                    [void] $memberList.Add([PSCustomObject]@{ Id = $aADUser.Id; UserPrincipalName = $aADUser.UserPrincipalName })
                }
            }
        }
        if ($memberList.Count -eq 0) { return }

        # The endpoint follows the number of members that RESOLVED, not the number asked
        # for: one goes to members/$ref, more go to the group in chunks of $nextLoop.
        [string] $serviceUrl = (Get-EntraService -Name $service).ServiceUrl
        [System.Collections.Generic.List[hashtable]] $requestList = [System.Collections.Generic.List[hashtable]]::new()
        if ($memberList.Count -eq 1) {
            [void] $requestList.Add(@{
                    Path    = ('groups/{0}/members/$ref' -f $group.Id)
                    Method  = 'POST'
                    Body    = @{ '@odata.id' = ('{0}/directoryObjects/{1}' -f $serviceUrl, $memberList[0].Id) }
                    Members = $memberList[0].UserPrincipalName
                })
        }
        else {
            # @() collects the chunks; a [string[]] cast here joined each chunk into one string.
            foreach ($chunk in @($memberList | Step-Array -Size $nextLoop)) {
                [string[]] $chunkUrlList = @($chunk | ForEach-Object { '{0}/directoryObjects/{1}' -f $serviceUrl, $_.Id })
                [void] $requestList.Add(@{
                        Path    = ('groups/{0}' -f $group.Id)
                        Method  = 'PATCH'
                        Body    = @{ 'members@odata.bind' = $chunkUrlList }
                        Members = ($chunk.UserPrincipalName -join ',')
                    })
            }
        }

        foreach ($request in $requestList) {
            if ($PassThru.IsPresent) {
                [PSMicrosoftEntraID.Batch.Request]@{ Method = $request.Method; Url = ('/{0}' -f $request.Path); Body = $request.Body; Headers = $header }
            }
            else {
                Invoke-PSFProtectedCommand -ActionString 'GroupMember.Add' -ActionStringValues $request.Members -Target $group.DisplayName -ScriptBlock {
                    [void] (Invoke-EntraRequest -Service $service -Path $request.Path -Header $header -Body $request.Body -Method $request.Method -ErrorAction Stop)
                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
    }
    end {

    }
}
