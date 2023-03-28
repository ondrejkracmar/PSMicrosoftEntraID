
$usageLocationHashTable = Get-UserUsageLocation
$usageLocationHashTable
Register-PSFTeppScriptblock -Name 'usagelocation.usagelocationcode' -ScriptBlock { $usageLocationHashTable.Values }
Register-PSFTeppScriptblock -Name 'usagelocation.usagelocationcountry' -ScriptBlock { $usageLocationHashTable.Keys }