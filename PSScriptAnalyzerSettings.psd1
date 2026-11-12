@{
	# CodexVault default PSScriptAnalyzer profile
	IncludeDefaultRules = $true
	Severity            = @('Error', 'Warning')

	ExcludeRules = @(
		# Plural nouns are established in several shipped cmdlet names
		'PSUseSingularNouns'
	)

	Rules = @{
		PSAvoidUsingCmdletAliases  = @{ Enable = $true }
		PSAvoidUsingWriteHost      = @{ Enable = $true }
		PSAvoidUsingInvokeExpression = @{ Enable = $true }
		PSAvoidUsingPlainTextForPassword = @{ Enable = $true }
		PSAvoidUsingConvertToSecureStringWithPlainText = @{ Enable = $true }
		PSUseShouldProcessForStateChangingFunctions = @{ Enable = $true }
	}
}
