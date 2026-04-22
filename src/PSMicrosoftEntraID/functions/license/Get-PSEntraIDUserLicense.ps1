function Get-PSEntraIDUserLicense {
    <#
	.SYNOPSIS
		Get users who are assigned licenses

	.DESCRIPTION
		Get users who are assigned licenses with disabled and enabled service plans

    .PARAMETER CompanyName
        CompanyName of the user attribute populated in tenant/directory.

    .PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of SubscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of SubscribedSku.

    .PARAMETER ServicePlanId
		Office 365 product GUID is identified using a GUID of ServicePlan.

    .PARAMETER ServicePlanName
        Friendly name Office 365 product of ServicePlanName.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDUserLicense -SkuPartNumber ENTERPRISEPACK

		Get users with license ENTERPRISEPACK and their service plans

	#>
    [OutputType('PSMicrosoftEntraID.Users.User')]
    [CmdletBinding(DefaultParameterSetName = 'CompanyName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ServicePlanIdCompanyName')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ServicePlanNameCompanyName')]
        [Alias("Company")]
        [string[]] $CompanyName,
        [Parameter(Mandatory = $True, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string[]] $SkuId,
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $SkuPartNumber,
        [Parameter(Mandatory = $True, ParameterSetName = 'ServicePlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePlanIdCompanyName')]
        [ValidateGuid()]
        [string[]] $ServicePlanId,
        [Parameter(Mandatory = $True, ParameterSetName = 'ServicePlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePlanNameCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $ServicePlanName,
        [Parameter(Mandatory = $True, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch] $AdvancedFilter,
        [Parameter()]
        [switch] $EnableException
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'SkuId' {
                foreach ($itemSkuId in $SkuId) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId
                    $result = Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -Value $itemSkuPartNumber -EQ).SkuId
                    if (-not [string]::IsNullOrWhiteSpace($singleSkuPartNumber)) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber
                        $result = Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                        $result
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
                    }
                }
            }
            'ServicePlanId' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanId in $ServicePlanId) {
                    $result = Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $itemServicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $query['$filter'] = ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $itemServicePlanId)
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'ServicePlanName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                foreach ($itemServicePlanName in $ServicePlanName) {
                    $singleServicePlan = ((Get-PSEntraIDSubscribedSku).Serviceplans | Where-Object -Property servicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique).ServicePlanId
                    if (-not [string]::IsNullOrWhiteSpace($singleServicePlan)) {
                        $query['$filter'] = ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $singleServicePlan)
                        $result = Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('assignedPlans/any(x:x/servicePlanId eq {0})' -f $singleServicePlan) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                        $result
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name ServicePlanName.Get.Failed) -f $itemServicePlanName)
                        }
                    }
                }
            }
            'SkuIdCompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                foreach ($itemSkuId in $SkuId) {
                    $query['$Filter'] = 'companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $itemSkuId
                    $result = Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $itemSkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'SkuPartNumberCompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber).SkuId
                    if (-not [string]::IsNullOrWhiteSpace($singleSkuPartNumber)) {
                        $query['$Filter'] = 'companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $singleSkuPartNumber
                        $result = Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('companyName in ({0}) and assignedLicenses/any(x:x/skuId eq {1})' -f $companyNameList, $singleSkuPartNumber) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                        $result
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $itemSkuPartNumber)
                        }
                    }
                }
            }
            'ServicePlanIdCompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                foreach ($itemServicePlanId in $ServicePlanId) {
                    $query['$Filter'] = 'companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $itemServicePlanId
                    $result = Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $itemServicePlanId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
            'ServicePlanNameCompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                foreach ($itemServicePlanName in $ServicePlanName) {
                    $singleServicePlan = ((Get-PSEntraIDSubscribedSku).Serviceplans | Where-Object -Property ServicePlanName -EQ -Value $itemServicePlanName | Select-Object -Unique).ServicePlanId
                    if (-not [string]::IsNullOrWhiteSpace($singleServicePlan)) {
                        $query['$Filter'] = 'companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $singleServicePlan
                        $result = Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0}) and assignedPlans/any(x:x/servicePlanId eq {1})' -f $companyNameList, $singleServicePlan) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        if (Test-PSFFunctionInterrupt) { return }
                        $result
                    }
                    else {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name ServicePlanName.Get.Failed) -f $itemServicePlanName)
                        }
                    }
                }
            }
            'CompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                $query['$Filter'] = 'companyName in ({0})' -f $companyNameList
                $result = Invoke-PSFProtectedCommand -ActionString 'ServicePlan.Filter' -ActionStringValues ('companyName in ({0})' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                if (Test-PSFFunctionInterrupt) { return }
                $result
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    [hashtable] $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    $result = Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues $filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Header $header)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
                else {
                    $result = Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                    $result
                }
            }
        }
    }
    end
    {}
}