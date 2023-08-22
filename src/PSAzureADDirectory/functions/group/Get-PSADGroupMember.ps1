function Get-PSADGroupMember {
    <#
    .SYNOPSIS
        Get an owner or member to the team, and to the unified group which backs the team.
              
    .DESCRIPTION
        This cmdlet get an owner or member of the team, and to the unified group which backs the team.
              
    .PARAMETER Identity
        MailNickName or Id of group or team

    .PARAMETER Role
        Type of role user (user or Member)
    
    .EXAMPLE
        PS C:\> Get-PSAADUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com


#>
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param(
        [Parameter(ParameterSetName = 'AddMember', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string[]]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $False, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Role')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Member', 'Owner')]
        [string]
        $Role,
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Role')]
        [switch]$All,
        [Parameter(Mandatory = $false, ParameterSetName = 'Role')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 999)]
        [int]
        [Alias("Top")]
        $PageSize = 100

    )
	
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
    }
	
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($group in $Identity) {
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    $userMail = Invoke-RestRequest -Service 'graph' -Path ('users') -Query $mailQuery -Method Get | ConvertFrom-RestGroup
                    if (-not([object]::Equals($userMail, $null))) {
                        $user = $userMail[0].Id
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestGroup
                    }
                }
            }
        }
        if (Test-PSFFunctionInterrupt) { return }
	    
        $graphApiParameters['Uri'] = Join-UriPath -Uri $url -ChildPath "$($GroupId)/members"
        if (Test-PSFParameterBinding -Parameter Role) {
            if ($Role -eq 'Owners') {
                $graphApiParameters['Filter'] = "(roles/Any(x:x eq 'owner'))"
            }
        }

        if (Test-PSFParameterBinding -Parameter All) {
            $graphApiParameters['All'] = $true
        }

        if (Test-PSFParameterBinding -Parameter PageSize) {
            $graphApiParameters['Top'] = $PageSize
        }
        Invoke-GraphApiQuery @graphApiParameters

    }
    end {
	
    }
}