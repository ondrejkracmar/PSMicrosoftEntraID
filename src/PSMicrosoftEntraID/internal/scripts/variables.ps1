$graphCfg = @{
	Name          = 'PSMicrosoftEntraID.Graph'
	ServiceUrl    = 'https://graph.microsoft.com/v1.0'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphCfg

$graphBetaCfg = @{
	Name          = 'PSMicrosoftEntraID.GraphBeta'
	ServiceUrl    = 'https://graph.microsoft.com/beta'
	Resource      = 'https://graph.microsoft.com'
	DefaultScopes = @()
	HelpUrl       = 'https://developer.microsoft.com/en-us/graph/quick-start'
}
Register-EntraService @graphBetaCfg