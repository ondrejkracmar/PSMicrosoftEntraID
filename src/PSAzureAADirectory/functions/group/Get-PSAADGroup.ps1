function Get-PSAADGroup {
    <#
        .SYNOPSIS
            Get the properties of the specified user.

        .DESCRIPTION
            Get the properties of the specified user.

        .PARAMETER Identity
            UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

        .PARAMETER DisplayName
            DIsplayName of the group attribute populated in tenant/directory.

        .PARAMETER Filter
            Filter expressions of accounts in tenant/directory.

        .PARAMETER AdvancedFilter
            Switch advanced filter for filtering accounts in tenant/directory.

        .PARAMETER All
            Return all accounts in tenant/directory.

        .PARAMETER PageSize
            Value of returned result set contains multiple pages of data.

        .EXAMPLE
            PS C:\> Get-PSAADGroup -Identity group1

            Get properties of Azure AD group group1


    #>
    [OutputType('PSAzureADDirectory.Group')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string[]]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'DisplayName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DisplayName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch]$All
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $pageSize = Get-PSFConfigValue -FullName ('{0}.GraphApiQuery.PageSize' -f $script:ModuleName)
        $query = @{
            '$count'  = 'true'
            '$top'    = $pageSize
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',')
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($group in $Identity) {
                    $mailNickNameQuery = @{
                        #'$count'  = 'true'
                        '$top'    = $pageSize
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',')
                    }
                    $mailNickNameQuery['$Filter'] = ("mailNickName eq '{0}'" -f $group)
                    $mailNickName = Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $mailNickNameQuery -Method Get | ConvertFrom-RestGroup
                    if (-not([object]::Equals($mailNickName, $null))) {
                        $groupId = $mailNickName[0].Id                        
                    }
                    else {
                        $groupId = $group
                    }
                    Invoke-RestRequest -Service 'graph' -Path ('groups/{0}' -f $groupId) -Query $query -Method Get | ConvertFrom-RestGroup
                }
            }
            'DisplayName' {
                foreach ($group in $DisplayName) {       
                    $query['$Filter'] = ("startswith(displayName,'{0}')" -f $group)
                    Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get | ConvertFrom-RestGroup
                }
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get -Header $header | ConvertFrom-RestGroup
                }
                else {
                    Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get | ConvertFrom-RestGroup
                }
            }
            'All' {
                if ($All.IsPresent) {
                    Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get | ConvertFrom-RestGroup
                }
            }
        }
    }
    end {}
}