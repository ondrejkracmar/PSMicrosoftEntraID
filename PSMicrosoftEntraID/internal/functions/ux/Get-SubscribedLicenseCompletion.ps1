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
				foreach ($servicePlan in @($subscribedLicense.ServicePlans)) {
					if ($null -eq $servicePlan) { continue }
					if ($servicePlan.ServicePlanName -notlike "$($wordToComplete)*") { continue }

					$text = if ($servicePlan.ServicePlanName -notmatch '\s') { $servicePlan.ServicePlanName } else { "'$($servicePlan.ServicePlanName)'" }
					[System.Management.Automation.CompletionResult]::new(
						$text,
						$text,
						'ParameterValue',
						$servicePlan.ServicePlanFriendlyName
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