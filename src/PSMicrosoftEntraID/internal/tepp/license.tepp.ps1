<#
# Example:
Register-PSFTeppScriptblock -Name "PSMicrosoftEntraID.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

Register-PSFTeppScriptblock -Name 'subscribed.skuid' -ScriptBlock { (Get-PSEntraIDSubscribedLicense | Select-Object -Property SkuId -Unique).SkuId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber' -ScriptBlock { (Get-PSEntraIDSubscribedLicense | Select-Object -Property SkuPartNumber -Unique).SkuPartNumber }
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanid' -ScriptBlock { ((Get-PSEntraIDSubscribedLicense).Serviceplans | Select-Object -Property ServicePlanId -Unique).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanname' -ScriptBlock { ((Get-PSEntraIDSubscribedLicense).Serviceplans | Select-Object -Property ServicePlanName -Unique).ServicePlanName }

Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanid' -ScriptBlock {((Get-PSEntraIDSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ).ServicePlans | Select-Object -Property ServicePlanId -Unique).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanName' -ScriptBlock {((Get-PSEntraIDSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ).ServicePlans | Select-Object -Property ServicePlanName -Unique).ServicePlanName }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanid' -ScriptBlock {((Get-PSEntraIDSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ).ServicePlans | Select-Object -Property ServicePlanId -Unique).ServicePlanId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanName' -ScriptBlock { ((Get-PSEntraIDSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ).ServicePlans | Select-Object -Property ServicePlanName -Unique).ServicePlanName }