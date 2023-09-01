<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name PSMicrosoftEntraID.alcohol
#>
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserSubscribedSku -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserSubscribedSku -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.serviceplanname'

Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'


Register-PSFTeppArgumentCompleter -Command Set-PSEntraIDUserUsageLocation -Parameter UsageLocationCode -Name 'user.usagelocationcode'
Register-PSFTeppArgumentCompleter -Command Set-PSEntraIDUserUsageLocation -Parameter UsageLocationCountry -Name 'user.usagelocationcountry'