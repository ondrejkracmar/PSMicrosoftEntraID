<#
# Example:
Register-PSFTeppScriptblock -Name "PSMicrosoftEntraID.alcohol" -ScriptBlock { 'Beer','Mead','Whiskey','Wine','Vodka','Rum (3y)', 'Rum (5y)', 'Rum (7y)' }
#>

function Get-PSEntraIDTeppSubscribedLicense {
	# TEPP completion runs synchronously on every Tab keystroke and must work
	# both online and offline. Prefer the cached catalog (Get-PSEntraIDSubscribedSku),
	# fall back to the live tenant call only if the cache is empty AND a live
	# session is available.
	[object[]] $cached = @(Get-PSEntraIDSubscribedSku)
	if ($cached.Count -gt 0) {
		return $cached
	}

	try {
		[object[]] @(Get-PSEntraIDSubscribedLicense -ErrorAction Stop)
	}
	catch {
		@()
	}
}

function Get-PSEntraIDTeppSubscribedServicePlan {
	param (
		[object[]] $SubscribedLicense
	)

	if ($null -eq $SubscribedLicense -or $SubscribedLicense.Count -eq 0) {
		return
	}

	foreach ($license in $SubscribedLicense) {
		foreach ($servicePlan in @($license.ServicePlans)) {
			[pscustomobject] @{
				SkuId                  = $license.SkuId
				SkuPartNumber          = $license.SkuPartNumber
				SkuFriendlyName        = $license.SkuFriendlyName
				ServicePlanId          = $servicePlan.ServicePlanId
				ServicePlanName        = $servicePlan.ServicePlanName
				ServicePlanFriendlyName = $servicePlan.ServicePlanFriendlyName
			}
		}
	}
}

function New-PSEntraIDTeppCompletionItem {
	param (
		[Parameter(Mandatory)]
		[string] $Text,

		[string] $ToolTip
	)

	# Emits a real CompletionResult. A hashtable does NOT work: PSFramework's Simple
	# mode expects plain strings and Full mode expects CompletionResult, so a hashtable
	# matches nothing and PowerShell silently falls back to completing FILE PATHS -
	# which is what "tab completion does not work" looked like from the outside.
	#
	# Filtering is ours to do. A registered completer's output is NOT filtered by
	# PowerShell (verified: typing 'DEVELOPER' still returned all 616 SKUs), so match
	# against the word being typed. It lives in the completer scriptblock one scope up.
	$word = Get-Variable -Name 'wordToComplete' -Scope 1 -ValueOnly -ErrorAction Ignore
	if (-not [string]::IsNullOrEmpty($word)) {
		$bare = $word.Trim("'", '"')
		if ($Text -notlike "$bare*") { return }
	}

	# Drop whatever the tooltip repeats from the value itself - for -SkuPartNumber the
	# part number is already the thing being completed. Done here rather than in the
	# tooltip builders because the same tooltip serves -SkuId, where the value is a GUID
	# and the part number is the useful part.
	if (-not [string]::IsNullOrWhiteSpace($ToolTip)) {
		$ToolTip = (@($ToolTip -split ' \| ') | Where-Object { $_ -ne $Text }) -join ' | '
	}
	if ([string]::IsNullOrWhiteSpace($ToolTip)) { $ToolTip = $Text }

	# Values with spaces must go back quoted or the command line breaks apart.
	$completionText = if ($Text -match '\s') { "'{0}'" -f ($Text -replace "'", "''") } else { $Text }

	[System.Management.Automation.CompletionResult]::new($completionText, $Text, 'ParameterValue', $ToolTip)
}

function Get-PSEntraIDTeppSkuToolTip {
	param (
		[Parameter(Mandatory)]
		[object] $License
	)

	$toolTipParts = @($License.SkuFriendlyName, $License.SkuPartNumber) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
	($toolTipParts | Select-Object -Unique) -join ' | '
}

function Get-PSEntraIDTeppServicePlanToolTip {
	param (
		[Parameter(Mandatory)]
		[object] $ServicePlan
	)

	$toolTipParts = @($ServicePlan.ServicePlanFriendlyName, $ServicePlan.ServicePlanName, $ServicePlan.SkuFriendlyName, $ServicePlan.SkuPartNumber) |
		Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
	($toolTipParts | Select-Object -Unique) -join ' | '
}

Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skuid' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($license in (Get-PSEntraIDTeppSubscribedLicense | Select-Object -Property SkuId, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $license.SkuId -ToolTip (Get-PSEntraIDTeppSkuToolTip -License $license)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skupartnumber' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($license in (Get-PSEntraIDTeppSubscribedLicense | Select-Object -Property SkuPartNumber, SkuFriendlyName -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $license.SkuPartNumber -ToolTip (Get-PSEntraIDTeppSkuToolTip -License $license)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.serviceplanid' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense (Get-PSEntraIDTeppSubscribedLicense) | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.serviceplanname' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense (Get-PSEntraIDTeppSubscribedLicense) | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}

Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skuid.serviceplanid' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skuid.serviceplanName' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skupartnumber.serviceplanid' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Mode Full -Name 'subscribed.skupartnumber.serviceplanName' -ScriptBlock {
	param ($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)

	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}