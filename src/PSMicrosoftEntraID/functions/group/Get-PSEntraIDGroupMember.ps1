function Get-PSEntraIDGroupMember {
    <#
    .SYNOPSIS
        Get an owner or member to the team, and to the unified group which backs the team.

    .DESCRIPTION
        This cmdlet get an owner or member of the team, and to the unified group which backs the team.

    .PARAMETER Identity
        MailNickName or Id of group or team.

    .PARAMETER Owner
        Member type owner.

    .PARAMETER Filter
        Filter expressions of groups in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering groups in tenant/directory.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [OutputType('PSMicrosoftEntraID.User')]
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
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        $header = @{}
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($itemIdentity in $Identity) {
                    $group = Get-PSEntraIDGroup -Identity $itemIdentity
                    if (-not([object]::Equals($group, $null))) {
                        if ($Owner.IsPresent) {
                            $path = ('groups/{0}/owners' -f $group.Id)
                        }
                        else {
                            $path = ('groups/{0}/members' -f $group.Id)
                        }
                        if (Test-PSFParameterBinding -ParameterName 'Filter') {
                            $query['$Filter'] = $Filter
                            if ($AdvancedFilter.IsPresent) {
                                $header['ConsistencyLevel'] = 'eventual'
                            }

                        }
                        Invoke-RestRequest -Service 'graph' -Path $path -Query $query -Header $header -Method Get | ConvertFrom-RestUser
                    }
                }
            }
        }
    }
    end {

    }
}