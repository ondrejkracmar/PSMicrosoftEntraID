<#
# Example:
Register-PSFTeppScriptblock -Name "PSMicrosoftEntraID.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

Register-PSFTeppScriptblock -Name 'subscribed.skuid' -ScriptBlock { (Get-PSEntraIDLicenseIdentifier | Select-Object -Property SkuId).SkuId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber' -ScriptBlock { (Get-PSEntraIDLicenseIdentifier | Select-Object -Property SkuPartNumber).SkuPartNumber }
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanid' -ScriptBlock { ((Get-PSEntraIDLicenseIdentifier).Serviceplans).ServicePlanId}
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanname' -ScriptBlock { ((Get-PSEntraIDLicenseIdentifier).Serviceplans).ServicePlanName}

Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanid' -ScriptBlock { (Get-PSEntraIDLicenseServicePlan -SkuId $fakeBoundParameter.SkuId | Select-Object -Property ServicePlanId).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanName' -ScriptBlock { (Get-PSEntraIDLicenseServicePlan -SkuId $fakeBoundParameter.SkuId | Select-Object -Property ServicePlanName).ServicePlanName }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanid' -ScriptBlock { (Get-PSEntraIDLicenseServicePlan -SkuPartNumber $fakeBoundParameter.SkuPartNumber | Select-Object -Property ServicePlanId).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanName' -ScriptBlock { (Get-PSEntraIDLicenseServicePlan -SkuPartNumber $fakeBoundParameter.SkuPartNumber | Select-Object -Property ServicePlanName).ServicePlanName }