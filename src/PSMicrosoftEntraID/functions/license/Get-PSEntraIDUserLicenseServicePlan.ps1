function Get-PSEntraIDUserLicenseServicePlan {
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

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com

		Get licenses of user username@contoso.com with service plans

	#>
    [OutputType('PSMicrosoftEntraID.User.License')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateUserIdentity()]
        [string[]]
        [Alias("Id", "UserPrincipalName", "Mail")]
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
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    $aADUser = Get-PSEntraIDUser -Identity $user
                    if (-not([object]::Equals($aADUser, $null))) {
                        $userId = $aADUser.Id
                        Invoke-PSFProtectedCommand -ActionString 'User.LicenseServicePLan.List' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $userId) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
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
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
                    }
                }
            }
            'ServicePlanId' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanId in $ServicePlanId) {
                    Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $itemServicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $query['$filter'] = ('assignedPlans/any(x:servicePlanId eq {0})' -f $itemServicePlanId)
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'ServicePlanName' {
                $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanName in $ServicePlanName) {
                    $singleServicePlan = (Get-PSEntraIDSubscribedSku).Serviceplans | Where-Object -Property servicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique
                    if (-not([object]::Equals($singleServicePlan, $null))) {
                        $query['$filter'] = ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $singleServicePlan.ServicePlanId)
                        Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $singleServicePlan.ServicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name ServicePlanName.Get.Failed) -f $itemServicePlanName)
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
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
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
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
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
                    $query['$Filter'] = 'companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $itemServicePlanId
                    Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $itemServicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
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
                    $singleServicePlan = (Get-PSEntraIDSubscribedSku).Serviceplans | Where-Object -Property ServicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique
                    if (-not([object]::Equals($singleServicePlan, $null))) {
                        $query['$Filter'] = 'companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $singleServicePlan.servicePlanId
                        Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $singleServicePlan.servicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name ServicePlanName.Get.Failed) -f $itemServicePlanName)
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
                    Invoke-RestRequest -Service 'graph' -Path ('users') -Header $header -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues $filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get -Header $header | ConvertFrom-RestUserLicense -ServicePlan
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('users') -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
        }
    }
    end
    {}
}