function Get-PSAADUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Get users who are assigned licenses

	.DESCRIPTION
		Get users who are assigned licenses with disabled and enabled service plans

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER CompanyName
        CompanyName of the user attribute populated in tenant/directory.

    .PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of SubscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of SubscribedSku.

    .PARAMETER ServicePLanId
		Office 365 product GUID is identified using a GUID of ServicePlan.

    .PARAMETER ServicePLanName
        Friendly name Office 365 product of ServicePlanName.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

    .PARAMETER PageSize
        Value of returned result set contains multiple pages of data.

	.EXAMPLE
		PS C:\> Get-PSAADUserLicenseServicePlan -Identity username@contoso.com

		Get licenses of user username@contoso.com with service plans

	#>
    [OutputType('PSAzureADDirectory.User.License')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("Id","UserPrincipalName","Mail")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ServicePlanIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ServicePlanNameCompanyName')]
        [string[]]
        $CompanyName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string[]]
        $SkuId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SkuPartNumber,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'ServicePlanId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'ServicePlanIdCompanyName')]
        [ValidateGuid()]
        [string[]]
        $ServicePlanId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'ServicePlanName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'ServicePlanNameCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServicePlanName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [Parameter(Mandatory = $false, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePlanId')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePlanName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuPartNumberCompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePlanIdCompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePlanNameCompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
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
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserLicense).Value -join ',')
        }
        Get-PSAADSubscribedSku | Set-PSFResultCache

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
                    if ([object]::Equals($userMail, $null)) {
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    }
                    else {
                        $user = $userMail[0].id
                        Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    }
                }
            }
            'SkuId' {
                foreach ($itemSkuId in $SkuId) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    }
                }
            }
            'ServicePlanId' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanId in $ServicePlanId) {
                    $query['$filter'] = ('assignedPlans/any(x:servicePlanId eq {0})' -f $itemServicePlanId)
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                }
            }
            'ServicePlanName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanName in $ServicePlanName) {
                    $singleServicePlan = (Get-PSAADSubscribedSku).Serviceplans | Where-Object -Property servicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique
                    if (-not([object]::Equals($singleServicePlan, $null))) {
                        $query['$filter'] = ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $singleServicePlan.ServicePlanId)
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
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
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
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
                    $singleSkuPartNumber = Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$Filter'] = "companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})" -f $companyNameList, $singleSkuPartNumber.SkuId
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    }
                }
            }
            'ServicePlanIdCompanyName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                foreach ($itemServicePlanId in $ServicePlanId) {
                    $query['$Filter'] = "companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})" -f $companyNameList, $itemServicePlanId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                }
            }
            'ServicePlanNameCompanyName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                foreach ($itemServicePlanName in $ServicePlanName) {
                    $singleServicePlan = (Get-PSAADSubscribedSku).Serviceplans | Where-Object -Property ServicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique
                    if (-not([object]::Equals($singleServicePlan, $null))) {
                        $query['$Filter'] = "companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})" -f $companyNameList, $singleServicePlan.servicePlanId
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
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
                Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get -Header $header | ConvertFrom-RestUserLicense -ServicePlan
                }
                else {
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                }
            }
        }
    }
    end
    {}
}