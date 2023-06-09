﻿function Get-PSAADUserSubscribedSku {
    <#
	.SYNOPSIS
		Get users who are assigned licenses

	.DESCRIPTION
		Get users who are assigned licenses

    .PARAMETER ComanyName
        CompanyName of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

    .PARAMETER PageSize
        Value of returned result set contains multiple pages of data.

	.EXAMPLE
		PS C:\> Get-PSAADUserLicense -Identity username@contoso.com

		Get licenses of user username@contoso.com

	.EXAMPLE
		PS C:\> Get-PSAADUserSubscribedSku -SkuPartNumber ENTERPRISEPACK

		Get userse with ENTERPRISEPACK subscription
	#>
    [OutputType('PSAzureADDirectory.User.SubscribedSku')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [string[]]
        $CompanyName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string]
        $SkuId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SkuPartNumber,
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuPartNumberCompanyName')]
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
            'SkuId' {
                $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $SkuId
                Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserSubscribedSku -SkuId $SkuId
            }
            'SkuPartNumber' {
                $singleSkuPartNumber = Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber
                if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserSubscribedSku -SkuId $singleSkuPartNumber.SkuId
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
                
                $query['$Filter'] = "companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})" -f $companyNameList, $SkuId
                Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserSubscribedSku -SkuId $SkuId
                
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
                $singleSkuPartNumber = Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber
                if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                    $query['$Filter'] = "companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1}) " -f $companyNameList, $singleSkuPartNumber.SkuId
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserSubscribedSku -SkuId $singleSkuPartNumber.SkuId
                }
            }
        }
    }
    end
    {}
}