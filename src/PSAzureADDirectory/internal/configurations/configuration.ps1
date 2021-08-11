<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'PSOffice365Reports' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.GraphApiVersion' -Value "beta" -Initialize -Validation 'string' -Description "What version of Graph API module is useing."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.GraphApiUrl' -Value "https://graph.microsoft.com" -Initialize -Validation 'string' -Description "What url of Graph API module is useing."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.AuthUrl' -Value "https://login.microsoftonline.com" -Initialize -Validation 'string' -Description "What url authentication of Graph API module is useing."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.InvokeRestMethodRetryCount' -Value 2 -Initialize -Validation 'integer' -Description "Specifies how many times PowerShell retries a connection when a failure code between 400 and 599, inclusive or 304 is received."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.InvokeRestMethodRetryTimeSec' -Value 5 -Initialize -Validation 'integer' -Description "Specifies how many times PowerShell retries a connection when a failure code between 400 and 599, inclusive or 304 is received."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.ContentType' -Value 'application/json' -Initialize -Validation 'string' -Description "Specifies post content type of rest method."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.AcceptType' -Value 'application/json' -Initialize -Validation 'string' -Description "Specifies header accept type of rest method."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.AuthorizationToken' -Value '' -Initialize -Validation 'string' -Description "Specifies the last authorization token of GRAPH APU to Office 65 Teams."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.GraphApiQuery.Format' -Value 'json' -Initialize -Validation 'string' -Description "Specifies the media format of the items returned from Microsoft Graph."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.GraphApiQuery.Select.User' -Value @('id', 'createdDateTime','userPrincipalName','mail','mailNickname','proxyAddresses','userType','accountEnabled','givenName','surname','displayName','employeeId','jobTitle','department','companyName','city','postalCode','country','preferredLanguage','usageLocation','mobilePhone','businessPhones','faxNumber') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."
Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.GraphApiQuery.Select.AssignedLicenses' -Value @('id', 'userPrincipalName','mail','accountEnabled','givenName','surname','displayName','jobTitle','department','companyName','city','postalCode','country','usageLocation','mobilePhone','businessPhones','faxNumber','assignedLicenses','assignedPlans','provisionedPlans') -Initialize -Validation 'stringarray' -Description "Specifies uery parameter to return a set of properties that are different than the default set for an individual resource or a collection of resources."