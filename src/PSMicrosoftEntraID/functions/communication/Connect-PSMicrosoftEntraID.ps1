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

	.PARAMETER PassThru
		Return the token received for the current connection.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID
	
		Establish a connection to the graph API, prompting the user for login on their default browser.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -Certificate $cert
	
		Establish a connection to the graph API using the provided certificate.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)
	
		Establish a connection to the graph API using the provided certificate file.
		Prompts you to enter the certificate-file's password first.
	
	.EXAMPLE
		PS C:\> Connect-EntraService -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
	
		Establish a connection to Defender for Endpoint using a client secret.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[CmdletBinding(DefaultParameterSetName = 'Browser')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$ClientID,
		[Parameter(Mandatory = $true)]
		[string]
		$TenantID,
		[string[]]
		$Scopes,
		[Parameter(ParameterSetName = 'Browser')]
		[switch]
		$Browser,
		[Parameter(ParameterSetName = 'DeviceCode')]
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
		[switch]
		$PassThru
	)

	begin {
		$service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
		$param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Connect-EntraService
	}

	process {
		Connect-EntraService @param -Service $service
	}
	end { }
}