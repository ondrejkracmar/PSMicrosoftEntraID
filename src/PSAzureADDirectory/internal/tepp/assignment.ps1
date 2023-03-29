<#
# Example:
Register-PSFTeppArgumentCompleter -Command Get-Alcohol -Parameter Type -Name PSAzureADDirectory.alcohol
#>
Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Get-PSAADLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSAADLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'
Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Get-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.serviceplanname'

Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'

Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicense -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Disable-PSAADUserLicense -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'


Register-PSFTeppArgumentCompleter -Command Set-PSAADUserUsageLocation -Parameter UsageLocationCode -Name 'user.usagelocationcode'
Register-PSFTeppArgumentCompleter -Command Set-PSAADUserUsageLocation -Parameter UsageLocationCountry -Name 'user.usagelocationcountry'