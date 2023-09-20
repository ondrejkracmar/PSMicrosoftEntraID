function Get-PSEntraIDUser {
    <#
    .SYNOPSIS
        Get the properties of the specified user.

    .DESCRIPTION
        Get the properties of the specified user.

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Name
        DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

    .PARAMETER CompanyName
        CompanyName of the user attribute populated in tenant/directory.

    .PARAMETER Disabled
        Return disabled accounts in tenant/directory.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

    .PARAMETER All
        Return all accounts in tenant/directory.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com

#>
    [OutputType('PSMicrosoftEntraID.User')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("Id", "UserPrincipalName", "Mail")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$CompanyName,
        [Parameter(Mandatory = $false, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch]$Disabled,
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
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        #'$count'  = 'true'
                        '$top'    = $pageSize
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    $userMail = Invoke-RestRequest -Service 'graph' -Path ('users') -Query $mailQuery -Method Get | ConvertFrom-RestUser
                    if (-not([object]::Equals($userMail, $null))) {
                        $userId = $userMail[0].Id

                    }
                    else{
                        $userId = $user
                    }
                    Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $userId) -Query $query -Method Get | ConvertFrom-RestUser
                }
            }
            'Name' {
                foreach ($user in $Name) {
                    $query['$Filter'] = ("startswith(displayName,'{0}') or startswith(givenName,'{0}') or startswith(surName,'{0}')" -f $User)
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUser
                }
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get -Header $header | ConvertFrom-RestUser
                }
                else {
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUser
                }
            }
            'CompanyName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                if ($Disabled.IsPresent) {
                    $query['$Filter'] = 'companyName in ({0}) and accountEnabled eq false' -f $companyNameList
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUser
                }
                else {
                    $query['$Filter'] = 'companyName in ({0})' -f $companyNameList
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUser
                }
            }
            'All' {
                if ($All.IsPresent) {
                    if ($Disabled.IsPresent) {
                        $header = @{}
                        $header['ConsistencyLevel'] = 'eventual'
                        $query['$Filter'] = "accountEnabled eq false"
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUser
                    }
                    else {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUser
                    }
                }
            }
        }
    }
    end {}
}