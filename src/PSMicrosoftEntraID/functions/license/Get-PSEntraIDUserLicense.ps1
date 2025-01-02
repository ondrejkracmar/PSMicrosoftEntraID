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
		PS C:\> Get-PSEntraIDUserLicense -Identity username@contoso.com

		Get licenses of user username@contoso.com with service plans

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
        [string[]]$CompanyName,
        [Parameter(Mandatory = $True, ParameterSetName = 'SkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuIdCompanyName')]
        [ValidateGuid()]
        [string[]]$SkuId,
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SkuPartNumberCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$SkuPartNumber,
        [Parameter(Mandatory = $True, ParameterSetName = 'ServicePlanId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePlanIdCompanyName')]
        [ValidateGuid()]
        [string[]]$ServicePlanId,
        [Parameter(Mandatory = $True, ParameterSetName = 'ServicePlanName')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePlanNameCompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ServicePlanName,
        [Parameter(Mandatory = $True, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [switch]$EnableException
    )
    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'SkuId' {
                foreach ($itemSkuId in $SkuId) {
                    $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId
                    Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $itemSkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'SkuPartNumber' {
                foreach ($itemSkuPartNumber in $SkuPartNumber) {
                    $singleSkuPartNumber = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $itemSkuPartNumber
                    if (-not([object]::Equals($singleSkuPartNumber, $null))) {
                        $query['$filter'] = 'assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId
                        Invoke-PSFProtectedCommand -ActionString 'SubscribedSku.Filter' -ActionStringValues ('assignedLicenses/any(x:x/skuId eq {0})' -f $singleSkuPartNumber.SkuId) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose))
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
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
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
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
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
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
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
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
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
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
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
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
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
                    ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues $filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Header $header -Verbose:$($cmdLetVerbose))
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose))
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end
    {}
}