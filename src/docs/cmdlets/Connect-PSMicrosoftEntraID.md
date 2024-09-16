---
external help file: PSMicrosoftEntraID-help.xml
Module Name: PSMicrosoftEntraID
online version:
schema: 2.0.0
---

# Connect-PSMicrosoftEntraID

## SYNOPSIS
Establish a connection to an Entra Service.

## SYNTAX

### Browser (Default)
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>] [-Browser]
 [-BrowserMode <String>] [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault]
 [-PassThru] [<CommonParameters>]
```

### KeyVault
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> -VaultName <String> -SecretName <String>
 [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault] [-PassThru]
 [<CommonParameters>]
```

### UsernamePassword
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> -Credential <PSCredential>
 [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault] [-PassThru]
 [<CommonParameters>]
```

### AppSecret
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> -ClientSecret <SecureString>
 [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault] [-PassThru]
 [<CommonParameters>]
```

### AppCertificate
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Certificate <X509Certificate2>]
 [-CertificateThumbprint <String>] [-CertificateName <String>] [-CertificatePath <String>]
 [-CertificatePassword <SecureString>] [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>]
 [-MakeDefault] [-PassThru] [<CommonParameters>]
```

### DeviceCode
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>] [-DeviceCode]
 [-Service <String[]>] [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault] [-PassThru]
 [<CommonParameters>]
```

### Identity
```
Connect-PSMicrosoftEntraID [-Identity] [-IdentityID <String>] [-IdentityType <String>] [-Service <String[]>]
 [-ServiceUrl <String>] [-Resource <String>] [-MakeDefault] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Establish a connection to an Entra Service.
Prerequisite before executing any requests / commands.

## EXAMPLES

### EXAMPLE 1
```
Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID
```

Establish a connection to the graph API, prompting the user for login on their default browser.

### EXAMPLE 2
```
Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -Certificate $cert
```

Establish a connection to the graph API using the provided certificate.

### EXAMPLE 3
```
Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)
```

Establish a connection to the graph API using the provided certificate file.
Prompts you to enter the certificate-file's password first.

### EXAMPLE 4
```
Connect-PSMicrosoftEntraID -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
```

Establish a connection to Defender for Endpoint using a client secret.

### EXAMPLE 5
```
Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -VaultName myVault -Secretname GraphCert
```

Establish a connection to the graph API, after retrieving the necessary certificate from the specified Azure Key Vault.

## PARAMETERS

### -Browser
Use an interactive logon in your default browser.
This is the default logon experience.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Browser
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -BrowserMode
How the browser used for authentication is selected.
Options:
+ Auto (default): Automatically use the default browser.
+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

```yaml
Type: System.String
Parameter Sets: Browser
Aliases:

Required: False
Position: Named
Default value: Auto
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
The Certificate object used to authenticate with.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.Security.Cryptography.X509Certificates.X509Certificate2
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateName
The name/subject of the certificate to authenticate with.
The certificate must be stored either in the user or computer certificate store.
The newest certificate with a private key will be chosen.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePassword
Password to use to read a PFX certificate file.
Only used together with -CertificatePath.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.Security.SecureString
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificatePath
Path to a PFX file containing the certificate to authenticate with.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateThumbprint
Thumbprint of the certificate to authenticate with.
The certificate must be stored either in the user or computer certificate store.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientID
ID of the registered/enterprise application used for authentication.

```yaml
Type: System.String
Parameter Sets: Browser, KeyVault, UsernamePassword, AppSecret, AppCertificate, DeviceCode
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
The client secret configured in the registered/enterprise application.

Part of the Client Secret Certificate authentication workflow.

```yaml
Type: System.Security.SecureString
Parameter Sets: AppSecret
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The username / password to authenticate with.

Part of the Resource Owner Password Credential (ROPC) workflow.

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: UsernamePassword
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceCode
Use the Device Code delegate authentication flow.
This will prompt the user to complete login via browser.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: DeviceCode
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Identity
Log on as the Managed Identity of the current system.
Only works in environments with managed identities, such as Azure Function Apps or Runbooks.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: Identity
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityID
ID of the User-Managed Identity to connect as.
https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

```yaml
Type: System.String
Parameter Sets: Identity
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityType
Type of the User-Managed Identity.

```yaml
Type: System.String
Parameter Sets: Identity
Aliases:

Required: False
Position: Named
Default value: ClientID
Accept pipeline input: False
Accept wildcard characters: False
```

### -MakeDefault
Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the token received for the current connection.

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Resource
The resource to authenticate to.
Used to authenticate to a service without requiring a full service configuration.
Automatically implies PassThru.
This token is not registered as a service and cannot be implicitly  used by Invoke-EntraRequest.
Also provide the "-ServiceUrl" parameter, if you later want to use this token explicitly in Invoke-EntraRequest.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scopes
Any scopes to include in the request.
Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

```yaml
Type: System.String[]
Parameter Sets: Browser, DeviceCode
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SecretName
Name of the secret to use from the Azure Key Vault specified through the '-VaultName' parameter.
In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
or are connected via Connect-AzAccount.

```yaml
Type: System.String
Parameter Sets: KeyVault
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Service
The service to connect to.
Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
Defaults to: Graph

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $script:_DefaultService
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServiceUrl
The base url for requests to the service connecting to.
Overrides the default service url configured with the service settings.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantID
The ID of the tenant/directory to connect to.

```yaml
Type: System.String
Parameter Sets: Browser, KeyVault, UsernamePassword, AppSecret, AppCertificate, DeviceCode
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -VaultName
Name of the Azure Key Vault from which to retrieve the certificate or client secret used for the authentication.
Secrets retrieved from the vault are not cached, on token expiration they will be retrieved from the Vault again.
In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
or are connected via Connect-AzAccount.

```yaml
Type: System.String
Parameter Sets: KeyVault
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
