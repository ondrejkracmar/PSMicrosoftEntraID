<#
# Example:
Register-PSFTeppScriptblock -Name "PSAzureADDirectory.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

Register-PSFTeppScriptblock -Name 'subscribed.skuid' -ScriptBlock { (Get-PSAADSubscribedSku | Select-Object -Property SkuId).SkuId }
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber' -ScriptBlock { (Get-PSAADSubscribedSku | Select-Object -Property SkuPartNumber).SkuPartNumber }
