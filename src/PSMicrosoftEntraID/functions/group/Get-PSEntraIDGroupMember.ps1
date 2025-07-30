using namespace PSMicrosoftEntraID.Users
function Get-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Get an owner or member to the team, and to the unified group which backs the team.

    .DESCRIPTION
        This cmdlet get an owner or member of the team, and to the unified group which backs the team.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Groups.Group object in tenant/directory.

    .PARAMETER Identity
        MailNickName or Id of group or team.

    .PARAMETER Owner
        Member type owner.

    .PARAMETER Filter
        Filter expressions of groups in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering groups in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDGroupMember -Identity group1@contoso.com

		Get members of group1@contoso.com

    .EXAMPLE
        PS C:\> Get-PSEntraIDGroupMember -Identity group1@contoso.com -Owner

		Get owners of group1@contoso.com

#>
    [OutputType('PSMicrosoftEntraID.Users.User')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param([Parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Groups.Group[]]$InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'Identity')]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $False, ParameterSetName = 'InputObject')]
        [Parameter(Mandatory = $False, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [switch] $Owner,
        [Parameter(Mandatory = $False, ParameterSetName = 'InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter(Mandatory = $False, ParameterSetName = 'InputObject')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [switch] $AdvancedFilter,
        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        [hashtable] $header = @{}
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.List' -ActionStringValues $itemInputObject.MailnickName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        if ($Owner.IsPresent) {
                            [string] $path = ('groups/{0}/owners' -f $itemInputObject.Id)
                        }
                        else {
                            [string] $path = ('groups/{0}/members' -f $itemInputObject.Id)
                        }
                        if (Test-PSFParameterBinding -ParameterName 'Filter') {
                            $query['$Filter'] = $Filter
                            if ($AdvancedFilter.IsPresent) {
                                $header['ConsistencyLevel'] = 'eventual'
                            }
                        }
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Header $header -Method Get -ErrorAction Stop)
                        if (Test-PSFFunctionInterrupt) { return }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity' {
                foreach ($itemIdentity in $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'GroupMember.List' -ActionStringValues $itemIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        [PSMicrosoftEntraID.Groups.Group] $group = Get-PSEntraIDGroup -Identity $itemIdentity
                        if (-not([object]::Equals($group, $null))) {
                            if ($Owner.IsPresent) {
                                [string] $path = ('groups/{0}/owners' -f $group.Id)
                            }
                            else {
                                [string] $path = ('groups/{0}/members' -f $group.Id)
                            }
                            if (Test-PSFParameterBinding -ParameterName 'Filter') {
                                $query['$Filter'] = $Filter
                                if ($AdvancedFilter.IsPresent) {
                                    $header['ConsistencyLevel'] = 'eventual'
                                }
                            }
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Header $header -Method Get -ErrorAction Stop)
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $itemIdentity)
                            }
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end {

    }
}