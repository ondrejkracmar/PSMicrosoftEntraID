function Get-PSAADGroupMember {
    <#
    .SYNOPSIS
        Get an owner or member to the team, and to the unified group which backs the team.

    .DESCRIPTION
        This cmdlet get an owner or member of the team, and to the unified group which backs the team.

    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER Owner
        Member type owner

    .EXAMPLE
        PS C:\> Get-PSAADUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [OutputType('PSAzureADDirectory.User')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string[]]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $False, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Owner,
        [Parameter(Mandatory = $false, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 999)]
        [int]
        $PageSize = 100
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = $PageSize
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($itemIdentity in $Identity) {
                    $group = Get-PSAADGroup -Identity $itemIdentity
                    if (-not([object]::Equals($group, $null))) {
                        if ($Owner.IsPresent) {
                            $path = ('groups/{0}/owners' -f $group.Id)
                        }
                        else {
                            $path = ('groups/{0}/members' -f $group.Id)
                        }
                        Invoke-RestRequest -Service 'graph' -Path $path -Query $query -Method Get | ConvertFrom-RestUser
                    }
                }
            }
        }
    }
    end {

    }
}