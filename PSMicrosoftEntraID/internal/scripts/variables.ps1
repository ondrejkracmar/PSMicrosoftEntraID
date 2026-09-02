# Available Tokens
$script:_EntraTokens = @{}

# Endpoint Configuration for Requests
$script:_EntraEndpoints = @{}

# Plugins for automatic processing of Federated Authentication in the correct context
$script:_FederationProviders = @{}

# The default service to connect to
$script:_DefaultService = 'PSMicrosoftEntraID.Graph'

# The resource identifying Graph-based services - the license cache is only warmed for these
$script:_GraphResource = 'https://graph.microsoft.com'

# Maps the registered resource of a service to the configuration setting holding the
# default service of that family. Connect-PSMicrosoftEntraID updates the setting of
# each family it connects to; cmdlets read the setting of the family they belong to.
$script:_ServiceDefaultConfig = @{
	'https://graph.microsoft.com'              = 'Settings.DefaultService'
	'https://api.securitycenter.microsoft.com' = 'Settings.DefaultServiceEndpoint'
	'https://security.microsoft.com/mtp/'      = 'Settings.DefaultServiceSecurity'
	'https://management.core.windows.net/'     = 'Settings.DefaultServiceAzure'
	'https://vault.azure.net'                  = 'Settings.DefaultServiceAzureKeyVault'
}