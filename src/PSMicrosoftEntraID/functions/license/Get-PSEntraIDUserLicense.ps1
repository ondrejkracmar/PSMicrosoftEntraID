function Get-PSEntraIDUserLicense {
    <#
	.SYNOPSIS
		Get users who are assigned licenses

	.DESCRIPTION
		Get users who are assigned licenses

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER CompanyName
        CompanyName of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicense -Identity username@contoso.com

		Get licenses of user username@contoso.com

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicense -SkuPartNumber ENTERPRISEPACK

		Get userse with ENTERPRISEPACK licenses
	#>
    [OutputType('PSMicrosoftEntraID.User.License')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("Id","UserPrincipalName","Mail")]
        $Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [string[]]
        $CompanyName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string[]]
        $SkuId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SkuPartNumber,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $pageSize = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
        $query = @{
            '$count'  = 'true'
            '$top'    = $pageSize
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserLicense).Value -join ',')
        }
        Get-PSEntraIDSubscribedSku | Set-PSFResultCache
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $mailQuery = @{
                        '$count'  = 'true'
                        '$top'    = $pageSize
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    $userMail = Invoke-RestRequest -Service 'graph' -Path ('users') -Query $mailQuery -Method Get | ConvertFrom-RestUser
                    if ([object]::Equals($userMail, $null)) {
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUserLicense
                    }
                    else {
                        $user = $userMail[0].id
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUserLicense
                    }
                }
            }
            'SkuId' {
                foreach ($itemSkuId in $SkuId) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                    }
                }
            }
            'SkuIdCompanyName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                foreach ($itemSkuId in $SkuId) {
                    $query['$Filter'] = "companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})" -f $companyNameList, $itemSkuId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
                }

            }
            'SkuPartNumberCompanyName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$Filter'] = "companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1}) " -f $companyNameList, $singleSkuPartNumber.SkuId
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
                    }
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
                $query['$Filter'] = "companyName in ({0})" -f $companyNameList
                Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get -Header $header | ConvertFrom-RestUserLicense
                }
                else {
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                }
            }
        }
    }
    end
    {}
}
