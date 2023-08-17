function Get-PSADGroup {
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateIdentity()]
        [string]
        [Alias("Id", "MailNickName", "Mail")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'DisplayName')]
        [ValidateNotNullOrEmpty()]
        $DisplayName,
        [Parameter(Mandatory = $false, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Public", "Private")]
        [string]$Visibility,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch]$All,
        [Parameter(Mandatory = $false, ParameterSetName = 'Name')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 999)]
        [int]
        [Alias("Top")]
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
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        '$count'  = 'true'
                        '$top'    = $PageSize
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    $userMail = Invoke-RestRequest -Service 'graph' -Path ('users') -Query $mailQuery -Method Get | ConvertFrom-RestUser
                    if (-not([object]::Equals($userMail, $null))) {
                        $user = $userMail[0].Id
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUser
                    }
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