function New-PSEntraIDTeppUsageLocationCompletionItem {
	param (
		[Parameter(Mandatory)]
		[string] $Text,

		[Parameter(Mandatory)]
		[string] $ToolTip
	)

	@{
		Text = $Text
		ToolTip = $ToolTip
	}
}

Register-PSFTeppScriptblock -Name 'user.usagelocationcode' -ScriptBlock {
	foreach ($country in (Get-PSEntraIDUsageLocation).Keys) {
		New-PSEntraIDTeppUsageLocationCompletionItem -Text (Get-PSEntraIDUsageLocation)[$country] -ToolTip $country
	}
}
Register-PSFTeppScriptblock -Name 'user.usagelocationcountry' -ScriptBlock {
	foreach ($country in (Get-PSEntraIDUsageLocation).Keys) {
		New-PSEntraIDTeppUsageLocationCompletionItem -Text $country -ToolTip (Get-PSEntraIDUsageLocation)[$country]
	}
}