<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration

#>


$script:ModuleName = 'PSMicrosoftEntraID'

Set-PSFConfig -Module $script:ModuleName -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module $script:ModuleName -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."

# ---- Batch engine and request retry: the one retry layer of the module ------------------------------------------
# Invoke-EntraRequest repeats a failed request (Invoke-EntraRetry, Settings.Request.*), Invoke-EntraParallelBatch a
# failed sub-request (Settings.Batch.*). Nothing above them retries: the cmdlets call Invoke-PSFProtectedCommand
# without -RetryCount. The former Settings.Command.RetryCount and Settings.Command.RetryWaitInSeconds are gone.
# Whole numbers in a range, read invariantly: a value outside it is refused when it is set, not when a run uses it.
Register-PSFConfigValidation -Name 'PSMicrosoftEntraID.timeoutseconds' -ScriptBlock {
	param ($Value)
	$result = [pscustomobject]@{ Success = $true; Value = $null; Message = '' }
	# 4294967 seconds (about 49.7 days) is the longest timeout .NET can arm ([PSMicrosoftEntraID.Http.RequestTimeout]::MaxSeconds).
	[long] $seconds = 0
	if (-not [long]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Integer, [cultureinfo]::InvariantCulture, [ref]$seconds) -or $seconds -lt 0 -or $seconds -gt 4294967) {
		$result.Success = $false
		$result.Message = "The timeout must be a whole number of seconds from 0 (no limit) to 4294967 (about 49.7 days), not '$Value'."
		return $result
	}
	$result.Value = [int]$seconds
	$result
}
Register-PSFConfigValidation -Name 'PSMicrosoftEntraID.batchthrottlelimit' -ScriptBlock {
	param ($Value)
	$result = [pscustomobject]@{ Success = $true; Value = $null; Message = '' }
	[long] $number = 0
	if (-not [long]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Integer, [cultureinfo]::InvariantCulture, [ref]$number) -or $number -lt 1 -or $number -gt 20) {
		$result.Success = $false
		$result.Message = "The batch throttle limit must be a whole number from 1 to 20, not '$Value'."
		return $result
	}
	$result.Value = [int]$number
	$result
}
Register-PSFConfigValidation -Name 'PSMicrosoftEntraID.retrycount' -ScriptBlock {
	param ($Value)
	$result = [pscustomobject]@{ Success = $true; Value = $null; Message = '' }
	[long] $number = 0
	if (-not [long]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Integer, [cultureinfo]::InvariantCulture, [ref]$number) -or $number -lt 0 -or $number -gt 20) {
		$result.Success = $false
		$result.Message = "The retry count must be a whole number from 0 to 20, not '$Value'."
		return $result
	}
	$result.Value = [int]$number
	$result
}
# Graph throttles directory reads per app and tenant, not per mailbox as Exchange does: 4 envelopes of 20 in flight
# is the safe default; more mostly buys more 429 answers.
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Batch.ThrottleLimit' -Value 4 -Initialize -Validation 'PSMicrosoftEntraID.batchthrottlelimit' -Description "Number of Graph `$batch envelopes (20 sub-requests each) the batch engine keeps in flight at the same time, from 1 to 20. Graph throttles directory requests per application and tenant, so raising it mostly raises the number of 429 answers."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Batch.RetryCount' -Value 5 -Initialize -Validation 'PSMicrosoftEntraID.retrycount' -Description "How often a throttled or unavailable batch sub-request (408, 429, 5xx except 501 and 505; a POST only on 429 and 503) is sent again before it is reported as failed, from 0 to 20."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Request.RetryCount' -Value 5 -Initialize -Validation 'PSMicrosoftEntraID.retrycount' -Description "How often Invoke-EntraRetry sends a failed request again (408, 429, 5xx except 501 and 505, no answer; a POST only on 429 and 503), from 0 to 20. The only retry of a single request: Invoke-EntraRequest sends each page at most this many times plus one. Set-PSEntraIDCommandRetry -RetryCount sets it."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Request.TimeoutSeconds' -Value 600 -Initialize -Validation 'PSMicrosoftEntraID.timeoutseconds' -Description "How long one `$batch envelope or one request of Invoke-EntraRequest may take, the whole answer included, in seconds, from 0 (no limit) to 4294967 (about 49.7 days). An envelope without an answer in time comes back as 504 and is retried like an unavailable one; a request is retried like one without an answer (not a POST). Ctrl+C cancels it at any time."

Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultService' -Value $script:_DefaultService -Initialize -Validation 'string' -Description "What service name of Microsoft EntraID."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultServiceEndpoint' -Value 'PSMicrosoftEntraID.Endpoint' -Initialize -Validation 'string' -Description "Default service name for Microsoft Defender for Endpoint requests."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultServiceSecurity' -Value 'PSMicrosoftEntraID.Security' -Initialize -Validation 'string' -Description "Default service name for Microsoft Defender XDR (security.microsoft.com) requests."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultServiceAzure' -Value 'PSMicrosoftEntraID.Azure' -Initialize -Validation 'string' -Description "Default service name for Azure Management requests."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultServiceAzureKeyVault' -Value 'PSMicrosoftEntraID.AzureKeyVault' -Initialize -Validation 'string' -Description "Default service name for Azure Key Vault requests."

Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Authentication.AllowPasswordFlow' -Value $false -Initialize -Validation 'bool' -Description "Whether Connect-PSMicrosoftEntraID -Credential may sign in with a user name and password (the resource owner password credentials flow). Off by default: the flow bypasses multi-factor authentication and Conditional Access, and Microsoft discourages it. When on, every such connect writes a warning. Checked on each sign-in, a renewal of the token included."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.Authentication.BrowserTimeoutSeconds' -Value 300 -Initialize -Validation 'integerpositive' -Description "How long the browser sign-in (Connect-PSMicrosoftEntraID, the default flow) waits for the sign-in to be completed in the browser, in seconds. The local listener is closed when the time is up and the sign-in fails with a timeout. Ctrl+C ends the wait at any time."

Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.PageSize' -Value 100 -Initialize -Validation 'integer' -Description "Value of parameter PageSize invoke rest query."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.MessageCenter.PageSize' -Value 2000 -Initialize -Validation 'integer' -Description "Value of parameter PageSize invoke rest query."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.User' -Value @('id', 'createdDateTime', 'userPrincipalName', 'mail', 'mailNickname', 'proxyAddresses', 'userType', 'accountEnabled', 'givenName', 'surname', 'displayName', 'employeeId', 'jobTitle', 'department', 'officeLocation', 'companyName', 'city', 'postalCode', 'country', 'usageLocation', 'mobilePhone', 'businessPhones', 'faxNumber','otherMails', 'assignedLicenses', 'identities') -Initialize -Validation 'stringarray' -Description "Specifies filter select parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.UserGuest' -Value @('id', 'createdDateTime', 'userPrincipalName', 'mail', 'mailNickname', 'proxyAddresses', 'userType', 'accountEnabled', 'givenName', 'surname', 'displayName', 'employeeId', 'jobTitle', 'department', 'officeLocation', 'companyName', 'city', 'postalCode', 'country', 'usageLocation', 'mobilePhone', 'businessPhones', 'faxNumber','otherMails', 'assignedLicenses', 'identities','ExternalUserState','ExternalUserStateChangeDateTime') -Initialize -Validation 'stringarray' -Description "Specifies filter select parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.SubscribedSku' -Value @('id', 'skuId', 'skuPartNumber', 'appliesTo', 'prepaidUnits', 'consumedUnits', 'servicePlans') -Initialize -Validation 'stringarray' -Description "Specifies filter select parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.UserLicense' -Value @('id', 'userPrincipalName', 'userType', 'accountEnabled', 'displayName', 'mail', 'usageLocation', 'companyName', 'assignedLicenses') -Initialize -Validation 'stringarray' -Description "Specifies filter select parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.Group' -Value @('id', 'createdDateTime', 'mail', 'mailNickname', 'proxyAddresses', 'mailEnabled', 'visibility', 'displayName', 'description', 'groupTypes', 'creationOptions', 'deletedDateTime', 'expirationDateTime', 'isAssignableToRole', 'membershipRule', 'membershipRuleProcessingState', 'renewedDateTime', 'securityEnabled', 'securityIdentifier', 'resourceProvisioningOptions','assignedLabels','assignedLicenses') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
# NO createdDateTime: unlike user and group, the administrativeUnit resource does not
# have one, so Graph answers a $select carrying it with Request_UnsupportedQuery
# ("Invalid property: createdDateTime") and the whole read fails - which is what the AU
# delta leg of a production inventory sync hit. membershipType/-Rule/-ProcessingState ARE
# administrativeUnit properties and describe a dynamic unit, so they join the list.
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.AdministrativeUnit' -Value @('id', 'deletedDateTime', 'displayName', 'description', 'isMemberManagementRestricted', 'visibility', 'membershipType', 'membershipRule', 'membershipRuleProcessingState') -Initialize -Validation 'stringarray' -Description "Specifies select parameter to return a set of properties that are different than the default set for an administrative unit resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.Device' -Value @('id', 'deviceId', 'displayName', 'accountEnabled', 'operatingSystem', 'operatingSystemVersion', 'trustType', 'isManaged', 'isCompliant', 'manufacturer', 'model', 'registrationDateTime', 'approximateLastSignInDateTime', 'extensionAttributes') -Initialize -Validation 'stringarray' -Description "Specifies select parameter to return a set of properties that are different than the default set for a device resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.Contact' -Value @('id','displayName','givenName','surname','jobTitle','mail','mailNickname','companyName','department','businessPhones','mobilePhone','officeLocation','preferredLanguage','proxyAddresses') -Initialize -Validation 'stringarray' -Description "Specifies select parameter for retrieving orgContact properties from Microsoft Graph."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.GroupAdditionalProperty' -Value @('id','mail', 'mailNickname', 'displayName','hideFromAddressLists','hideFromOutlookClients','allowExternalSenders','autoSubscribeNewMembers') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.Organization' -Value @('id', 'displayName', 'tenantType', 'isMultipleDataLocationsForServicesEnabled', 'onPremisesLastSyncDateTime', 'onPremisesSyncEnabled', 'onPremisesSyncStatus', 'partnerTenantType', 'createdDateTime', 'deletedDateTime', 'directorySizeQuota', 'countryLetterCode', 'defaultUsageLocation', 'preferredLanguage', 'street', 'city', 'postalCode', 'state', 'countryLetterCode', 'businessPhones', 'technicalNotificationMails', 'securityComplianceNotificationMails', 'securityComplianceNotificationPhones', 'privacyProfile', 'assignedPlans', 'provisionedPlans', 'verifiedDomains') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.ServiceAnnouncement.Message' -Value @('id', 'title', 'category', 'severity', 'services', 'tags', 'isMajorChange', 'lastModifiedDateTime', 'startDateTime', 'endDateTime', 'actionRequiredByDateTime', 'body', 'viewPoint', 'hasAttachments', 'attachmentsArchive', 'details') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."

Set-PSFConfig -Module $script:ModuleName -Name 'LicenseIdentifiers.CachePath' -Value (Get-PSEntraIDDefaultLicenseIdentifierCachePath) -Initialize -Validation 'string' -Description "User-writable cache path for the license identifier catalog."
Set-PSFConfig -Module $script:ModuleName -Name 'LicenseIdentifiers.SourceUrl' -Value 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv' -Initialize -Validation 'string' -Description "Source URL for refreshing the license identifier catalog."
Set-PSFConfig -Module $script:ModuleName -Name 'LicenseIdentifiers.AutoUpdateOnImport' -Value $false -Initialize -Validation 'bool' -Description "When enabled, module import refreshes the license identifier catalog into the user cache if it is stale."
Set-PSFConfig -Module $script:ModuleName -Name 'LicenseIdentifiers.AutoUpdateIntervalDays' -Value 30 -Initialize -Validation 'integer' -Description "Minimum age in days before the user cache license catalog is refreshed again."

Register-PSEntraIDLicenseIdentifier