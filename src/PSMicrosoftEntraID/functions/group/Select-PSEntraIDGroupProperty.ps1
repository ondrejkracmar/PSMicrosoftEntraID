using namespace PSMicrosoftEntraID.Users
function Select-PSEntraIDGroupProperty {
    <#
    .SYNOPSIS
        Get the properties and relationships of a group or the team, and to the unified group which backs the team.

    .DESCRIPTION
        This cmdlet gets properties and relationships of a group or the team, and to the unified group which backs the team.

    .PARAMETER Identity
        MailNickName or Id of group or team.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Select-PSEntraIDGroupProperty -Identity group1@contoso.com

		Get the properties and relationships of a group group1@contoso.com

#>
    [OutputType('PSMicrosoftEntraID.Groups.Group')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [ValidateGroupIdentity()]
        [string[]]$Identity,
        [switch]$EnableException
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',') + ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.GroupProperty).Value -join ',')
        }
        $header = @{}
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($itemIdentity in $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'Group.Select' -ActionStringValues $itemIdentity -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $group = Get-PSEntraIDGroup -Identity $itemIdentity
                        if (-not([object]::Equals($group, $null))) {
                            $path = ('groups/{0}' -f $group.Id)
                            ConvertFrom-RestGroup -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Header $header -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $itemIdentity)
                            }
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end {

    }
}