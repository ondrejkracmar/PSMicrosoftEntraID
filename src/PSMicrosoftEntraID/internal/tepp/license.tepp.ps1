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

	if ([string]::IsNullOrWhiteSpace($ToolTip)) {
		$ToolTip = $Text
	}

	@{
		Text = $Text
		ToolTip = $ToolTip
	}
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

Register-PSFTeppScriptblock -Name 'subscribed.skuid' -ScriptBlock {
	foreach ($license in (Get-PSEntraIDTeppSubscribedLicense | Select-Object -Property SkuId, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $license.SkuId -ToolTip (Get-PSEntraIDTeppSkuToolTip -License $license)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber' -ScriptBlock {
	foreach ($license in (Get-PSEntraIDTeppSubscribedLicense | Select-Object -Property SkuPartNumber, SkuFriendlyName -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $license.SkuPartNumber -ToolTip (Get-PSEntraIDTeppSkuToolTip -License $license)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanid' -ScriptBlock {
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense (Get-PSEntraIDTeppSubscribedLicense) | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.serviceplanname' -ScriptBlock {
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense (Get-PSEntraIDTeppSubscribedLicense) | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}

Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanid' -ScriptBlock {
	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.skuid.serviceplanName' -ScriptBlock {
	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuId -Value $fakeBoundParameter.SkuId -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanid' -ScriptBlock {
	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanId, ServicePlanFriendlyName, ServicePlanName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanId -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}
Register-PSFTeppScriptblock -Name 'subscribed.skupartnumber.serviceplanName' -ScriptBlock {
	[object[]] $subscribedLicense = @(Get-PSEntraIDTeppSubscribedLicense | Where-Object -Property SkuPartNumber -Value $fakeBoundParameter.SkuPartNumber -EQ)
	foreach ($servicePlan in (Get-PSEntraIDTeppSubscribedServicePlan -SubscribedLicense $subscribedLicense | Select-Object -Property ServicePlanName, ServicePlanFriendlyName, SkuFriendlyName, SkuPartNumber -Unique)) {
		New-PSEntraIDTeppCompletionItem -Text $servicePlan.ServicePlanName -ToolTip (Get-PSEntraIDTeppServicePlanToolTip -ServicePlan $servicePlan)
	}
}