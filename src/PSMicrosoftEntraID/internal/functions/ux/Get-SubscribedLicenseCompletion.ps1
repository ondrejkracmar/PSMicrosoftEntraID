function global:Get-SubscribedLicenseCompletion {
	<#
	.SYNOPSIS
		Returns completion values for subscribed licenses.

	.DESCRIPTION
		Returns completion values for subscribed licenses.
		Use this command in argument completers.

	.PARAMETER ArgumentList
		The arguments an argument completer receives.
		The third item will be the word to complete.

	.PARAMETER ServicePlan
		Returns service plan completion values instead of SKU completion values.

	.EXAMPLE
		PS C:\> Get-SubscribedLicenseCompletion -ArgumentList $args

		Returns the values to complete for subscribed SKU part numbers.
	#>
	[OutputType([System.Management.Automation.CompletionResult])]
	[CmdletBinding()]
	param (
		$ArgumentList,
		[switch] $ServicePlan
	)

	process {
		$wordToComplete = $ArgumentList[2].Trim("'`"")
		[object[]] $subscribedLicenses = @(Get-PSEntraIDSubscribedLicense)

		foreach ($subscribedLicense in $subscribedLicenses) {
			if ($null -eq $subscribedLicense) { continue }

			if ($ServicePlan.IsPresent) {
				# NOT $servicePlan: variables are case-insensitive, so that is the [switch]
				# parameter $ServicePlan, and assigning a plan to it threw.
				foreach ($planItem in @($subscribedLicense.ServicePlans)) {
					if ($null -eq $planItem) { continue }
					if ($planItem.ServicePlanName -notlike "$($wordToComplete)*") { continue }

					$text = if ($planItem.ServicePlanName -notmatch '\s') { $planItem.ServicePlanName } else { "'$($planItem.ServicePlanName)'" }
					[System.Management.Automation.CompletionResult]::new(
						$text,
						$text,
						'ParameterValue',
						$planItem.ServicePlanFriendlyName
					)
				}
				continue
			}

			if ($subscribedLicense.SkuPartNumber -notlike "$($wordToComplete)*") { continue }

			$text = if ($subscribedLicense.SkuPartNumber -notmatch '\s') { $subscribedLicense.SkuPartNumber } else { "'$($subscribedLicense.SkuPartNumber)'" }
			[System.Management.Automation.CompletionResult]::new(
				$text,
				$text,
				'ParameterValue',
				$subscribedLicense.SkuFriendlyName
			)
		}
	}
}
$ExecutionContext.InvokeCommand.GetCommand("Get-SubscribedLicenseCompletion","Function").Visibility = 'Private'