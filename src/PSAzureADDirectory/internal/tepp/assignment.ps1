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

Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter SkuId -Name 'subscribed.skuid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter SkuPartNumber -Name 'subscribed.skupartnumber'

Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skuid.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skuid.serviceplanName'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanId -Name 'subscribed.skupartnumber.serviceplanid'
Register-PSFTeppArgumentCompleter -Command Enable-PSAADUserLicenseServicePlan -Parameter ServicePlanName -Name 'subscribed.skupartnumber.serviceplanName'
