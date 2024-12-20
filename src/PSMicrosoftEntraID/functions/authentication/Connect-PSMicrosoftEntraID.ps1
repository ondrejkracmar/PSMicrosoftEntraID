﻿function Connect-PSMicrosoftEntraID {
	<#
	.SYNOPSIS
		Establish a connection to an Entra Service.
	
	.DESCRIPTION
		Establish a connection to an Entra Service.
		Prerequisite before executing any requests / commands.
	
	.PARAMETER ClientID
		ID of the registered/enterprise application used for authentication.
	
	.PARAMETER TenantID
		The ID of the tenant/directory to connect to.
	
	.PARAMETER Scopes
		Any scopes to include in the request.
		Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

	.PARAMETER Browser
		Use an interactive logon in your default browser.
		This is the default logon experience.

	.PARAMETER BrowserMode
		How the browser used for authentication is selected.
		Options:
		+ Auto (default): Automatically use the default browser.
		+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

	.PARAMETER DeviceCode
		Use the Device Code delegate authentication flow.
		This will prompt the user to complete login via browser.
	
	.PARAMETER Certificate
		The Certificate object used to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateThumbprint
		Thumbprint of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificateName
		The name/subject of the certificate to authenticate with.
		The certificate must be stored either in the user or computer certificate store.
		The newest certificate with a private key will be chosen.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePath
		Path to a PFX file containing the certificate to authenticate with.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER CertificatePassword
		Password to use to read a PFX certificate file.
		Only used together with -CertificatePath.
		
		Part of the Application Certificate authentication workflow.
	
	.PARAMETER ClientSecret
		The client secret configured in the registered/enterprise application.
		
		Part of the Client Secret Certificate authentication workflow.

	.PARAMETER Credential
		The username / password to authenticate with.

		Part of the Resource Owner Password Credential (ROPC) workflow.

	.PARAMETER VaultName
		Name of the Azure Key Vault from which to retrieve the certificate or client secret used for the authentication.
		Secrets retrieved from the vault are not cached, on token expiration they will be retrieved from the Vault again.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.

	.PARAMETER SecretName
		Name of the secret to use from the Azure Key Vault specified through the '-VaultName' parameter.
		In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
		or are connected via Connect-AzAccount.

	.PARAMETER Identity
		Log on as the Managed Identity of the current system.
		Only works in environments with managed identities, such as Azure Function Apps or Runbooks.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER AsAzAccount
		Reuse the existing Az.Accounts session to authenticate.
		This is convenient as no further interaction is needed, but also limited in what scopes are available.
		This authentication flow requires the 'Az.Accounts' module to be present, loaded and connected.
		Use 'Connect-AzAccount' to connect first.

	.PARAMETER ShowDialog
		Whether to show an interactive dialog when connecting using the existing Az.Accounts session.
		Defaults to: "auto"

		Options:
		- auto: Shows dialog only if needed.
		- always: Will always show the dialog, forcing interaction.
		- never: Will never show the dialog. Authentication will fail if interaction is required.

	.PARAMETER Service
		The service to connect to.
		Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
		Defaults to: Graph

	.PARAMETER ServiceUrl
		The base url for requests to the service connecting to.
		Overrides the default service url configured with the service settings.

	.PARAMETER Resource
		The resource to authenticate to.
		Used to authenticate to a service without requiring a full service configuration.
		Automatically implies PassThru.
		This token is not registered as a service and cannot be implicitly  used by Invoke-EntraRequest.
		Also provide the "-ServiceUrl" parameter, if you later want to use this token explicitly in Invoke-EntraRequest.

	.PARAMETER MakeDefault
		Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

	.PARAMETER PassThru
		Return the token received for the current connection.

	.PARAMETER Environment
		What environment this service should connect to.
		Defaults to: 'Global'

	.PARAMETER AuthenticationUrl
		The url used for the authentication requests to retrieve tokens.
		Usually determined by service connected to or the "Environment" parameter, but may be overridden in case of need.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID
	
		Establish a connection to the graph API, prompting the user for login on their default browser.

	.EXAMPLE
		PS C:\> connect-EntraService -AsAzAccount

		Establish a connection to the graph API, using the current Az.Accounts session.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -Certificate $cert
	
		Establish a connection to the graph API using the provided certificate.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)
	
		Establish a connection to the graph API using the provided certificate file.
		Prompts you to enter the certificate-file's password first.
	
	.EXAMPLE
		PS C:\> Connect-PSMicrosoftEntraID -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
	
		Establish a connection to Defender for Endpoint using a client secret.
	
	.EXAMPLE
		PS C:\> Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -VaultName myVault -Secretname GraphCert
	
		Establish a connection to the graph API, after retrieving the necessary certificate from the specified Azure Key Vault.
#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
	[CmdletBinding(DefaultParameterSetName = 'Browser')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$ClientID,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Browser')]
		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppCertificate')]
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$TenantID,
		
		[Parameter(ParameterSetName = 'Browser')]
		[Parameter(ParameterSetName = 'DeviceCode')]
		[string[]]
		$Scopes,

		[Parameter(ParameterSetName = 'Browser')]
		[switch]
		$Browser,

		[Parameter(ParameterSetName = 'Browser')]
		[ValidateSet('Auto', 'PrintLink')]
		[string]
		$BrowserMode = 'Auto',

		[Parameter(Mandatory = $true, ParameterSetName = 'DeviceCode')]
		[switch]
		$DeviceCode,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]
		$Certificate,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateThumbprint,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificateName,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[string]
		$CertificatePath,
		
		[Parameter(ParameterSetName = 'AppCertificate')]
		[System.Security.SecureString]
		$CertificatePassword,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'AppSecret')]
		[System.Security.SecureString]
		$ClientSecret,

		[Parameter(Mandatory = $true, ParameterSetName = 'UsernamePassword')]
		[PSCredential]
		$Credential,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$VaultName,

		[Parameter(Mandatory = $true, ParameterSetName = 'KeyVault')]
		[string]
		$SecretName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Identity')]
		[switch]
		$Identity,

		[Parameter(ParameterSetName = 'Identity')]
		[string]
		$IdentityID,

		[Parameter(ParameterSetName = 'Identity')]
		[ValidateSet('ClientID', 'ResourceID', 'PrincipalID')]
		[string]
		$IdentityType = 'ClientID',

		[Parameter(ParameterSetName = 'AzToken')]
		[PSCustomObject]
		$AzToken,

		[Parameter(Mandatory = $true, ParameterSetName = 'AzAccount')]
		[switch]
		$AsAzAccount,

		[Parameter(ParameterSetName = 'AzAccount')]
		[ValidateSet('Auto', 'Always', 'Never')]
		[string]
		$ShowDialog = 'Auto',

		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[ValidateScript({ Assert-ServiceName -Name $_ })]
		[string[]]
		$Service = $script:_DefaultService,

		[string]
		$ServiceUrl,

		[string]
		$Resource,

		[switch]
		$MakeDefault,

		[switch]
		$PassThru,

		[PSMicrosoftEntraID.Environment]
		$Environment,

		[string]
		$AuthenticationUrl
	)
	begin {
		if (-not ([object]::Equals($Service, $null))) {
			Set-PSFConfig -Module $script:ModuleName -Name 'Settings.DefaultService' -Value $Service
			$service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
		}
		$param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Connect-EntraService
	}

	process {
		Connect-EntraService @param -Service $service
		[System.Collections.ArrayList]$licenseIdentifier = Get-PSEntraIDSubscribedSku
		[System.Collections.ArrayList]$subscribedSku = (Get-PSEntraIDSubscribedLicense | Where-Object -Property SkuId -NotIn -Value $licenseIdentifier.SkuId)
		if ([object]::Equals($subscribedSku, $null)) {
			$licenseIdentifier | Set-PSFResultCache
		}
		else {
			[void]$licenseIdentifier.AddRange($subscribedSku)
			$licenseIdentifier | Set-PSFResultCache
		}
	}
	end { }
}