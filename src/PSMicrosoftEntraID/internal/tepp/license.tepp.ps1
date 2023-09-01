﻿<#
# Example:
Register-PSFTeppScriptblock -Name "PSMicrosoftEntraID.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

Register-PSFTeppScriptblock -Name 'subscribed.skuid' -ScriptBlock { (Get-PSAADSubscribedSku | Select-Object -Property SkuId).SkuId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber' -ScriptBlock { (Get-PSAADSubscribedSku | Select-Object -Property SkuPartNumber).SkuPartNumber }
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanid' -ScriptBlock { ((Get-PSAADSubscribedSku).Serviceplans).ServicePlanId}
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanname' -ScriptBlock { ((Get-PSAADSubscribedSku).Serviceplans).ServicePlanName}

Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanid' -ScriptBlock { (Get-PSAADLicenseServicePlan -SkuId $fakeBoundParameter.SkuId | Select-Object -Property ServicePlanId).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanName' -ScriptBlock { (Get-PSAADLicenseServicePlan -SkuId $fakeBoundParameter.SkuId | Select-Object -Property ServicePlanName).ServicePlanName }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanid' -ScriptBlock { (Get-PSAADLicenseServicePlan -SkuPartNumber $fakeBoundParameter.SkuPartNumber | Select-Object -Property ServicePlanId).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanName' -ScriptBlock { (Get-PSAADLicenseServicePlan -SkuPartNumber $fakeBoundParameter.SkuPartNumber | Select-Object -Property ServicePlanName).ServicePlanName }