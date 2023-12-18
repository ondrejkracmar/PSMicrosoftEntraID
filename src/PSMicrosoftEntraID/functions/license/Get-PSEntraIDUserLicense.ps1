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

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

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
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$Identity,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [Alias("Company")]
        [string[]]$CompanyName,
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string[]]$SkuId,
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuPartNumber,
        [Parameter(Mandatory = $True, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [switch]$EnableException
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserLicense).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $aADUser = Get-PSEntraIDUser -Identity $user
                    if (-not([object]::Equals($aADUser, $null))) {
                        $userId = $aADUser.Id
                        Invoke-PSFProtectedCommand -ActionString 'User.License.List' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $userId) -Query $query -Method Get | ConvertFrom-RestUserLicense
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                }
            }
            'SkuId' {
                foreach ($itemSkuId in $SkuId) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId
                    Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
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
                    $query['$Filter'] = 'companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $itemSkuId
                    Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $itemSkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
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
                        $query['$Filter'] = 'companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $singleSkuPartNumber.SkuId
                        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $singleSkuPartNumber.SkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
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
                $query['$Filter'] = 'companyName in ({0})' -f $companyNameList
                Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0})' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues $filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get -Header $header | ConvertFrom-RestUserLicense
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
        }
    }
    end
    {}
}
