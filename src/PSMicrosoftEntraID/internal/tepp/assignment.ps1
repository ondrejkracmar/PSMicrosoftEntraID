<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name PSMicrosoftEntraID.alcohol
#>


Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter ServicePlanId -Name 'subscribed.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Get-PSEntraIDUserLicense -Parameter ServicePlanName -Name 'subscribed.serviceplanname'

Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSEntraIDGroupLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Set-PSEntraIDUserUsageLocation -Parameter UsageLocationCode -Name 'user.usagelocationcode'
Register-PSFTeppArgumentCompleter -Command Set-PSEntraIDUserUsageLocation -Parameter UsageLocationCountry -Name 'user.usagelocationcountry'