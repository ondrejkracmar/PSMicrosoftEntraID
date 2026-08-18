Register-PSFTeppScriptblock -Mode Full -Name 'user.usagelocationcode' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($country in (Get-PSEntraIDUsageLocation).Keys) {
		New-PSEntraIDTeppCompletionItem -Text (Get-PSEntraIDUsageLocation)[$country] -ToolTip $country
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'user.usagelocationcountry' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($country in (Get-PSEntraIDUsageLocation).Keys) {
		New-PSEntraIDTeppCompletionItem -Text $country -ToolTip (Get-PSEntraIDUsageLocation)[$country]
	}
}