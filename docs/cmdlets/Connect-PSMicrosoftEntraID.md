---
document type: cmdlet
external help file: PSMicrosoftEntraID-Help.xml
HelpUri: ''
Locale: en-US
Module Name: PSMicrosoftEntraID
ms.date: 10/06/2025
PlatyPS schema version: 2024-05-01
title: Connect-PSMicrosoftEntraID
---

# Connect-PSMicrosoftEntraID

## SYNOPSIS

Establish a connection to an Entra Service.

## SYNTAX

### Browser (Default)

```
Connect-PSMicrosoftEntraID -ClientID <string> [-TenantID <string>] [-Scopes <string[]>] [-Browser]
 [-BrowserMode <string>] [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>]
 [-UseRefreshToken] [-MakeDefault] [-PassThru] [-Environment <Environment>]
 [-AuthenticationUrl <string>] [<CommonParameters>]
```

### Federated

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> [-FallBackAzAccount] [-Federated]
 [-FederationProvider <string>] [-Assertion <string>] [-Service <string[]>] [-ServiceUrl <string>]
 [-Resource <string>] [-MakeDefault] [-PassThru] [-Environment <Environment>]
 [-AuthenticationUrl <string>] [<CommonParameters>]
```

### KeyVault

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> -VaultName <string>
 -SecretName <string[]> [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>]
 [-MakeDefault] [-PassThru] [-Environment <Environment>] [-AuthenticationUrl <string>]
 [<CommonParameters>]
```

### UsernamePassword

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> -Credential <pscredential>
 [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>] [-MakeDefault] [-PassThru]
 [-Environment <Environment>] [-AuthenticationUrl <string>] [<CommonParameters>]
```

### AppSecret

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> -ClientSecret <securestring>
 [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>] [-MakeDefault] [-PassThru]
 [-Environment <Environment>] [-AuthenticationUrl <string>] [<CommonParameters>]
```

### AppCertificate

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> [-Certificate <X509Certificate2>]
 [-CertificateThumbprint <string>] [-CertificateName <string>] [-CertificatePath <string>]
 [-CertificatePassword <securestring>] [-Service <string[]>] [-ServiceUrl <string>]
 [-Resource <string>] [-MakeDefault] [-PassThru] [-Environment <Environment>]
 [-AuthenticationUrl <string>] [<CommonParameters>]
```

### Refresh

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> -RefreshToken <string>
 [-Scopes <string[]>] [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>]
 [-MakeDefault] [-PassThru] [-Environment <Environment>] [-AuthenticationUrl <string>]
 [<CommonParameters>]
```

### DeviceCode

```
Connect-PSMicrosoftEntraID -ClientID <string> -TenantID <string> -DeviceCode [-Scopes <string[]>]
 [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>] [-UseRefreshToken] [-MakeDefault]
 [-PassThru] [-Environment <Environment>] [-AuthenticationUrl <string>] [<CommonParameters>]
```

### RefreshObject

```
Connect-PSMicrosoftEntraID -RefreshTokenObject <EntraToken> [-Scopes <string[]>]
 [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>] [-MakeDefault] [-PassThru]
 [-Environment <Environment>] [-AuthenticationUrl <string>] [<CommonParameters>]
```

### Identity

```
Connect-PSMicrosoftEntraID -Identity [-IdentityID <string>] [-IdentityType <string>]
 [-FallBackAzAccount] [-Service <string[]>] [-ServiceUrl <string>] [-Resource <string>]
 [-MakeDefault] [-PassThru] [-Environment <Environment>] [-AuthenticationUrl <string>]
 [<CommonParameters>]
```

### AzAccount

```
Connect-PSMicrosoftEntraID -AsAzAccount [-ShowDialog <string>] [-Service <string[]>]
 [-ServiceUrl <string>] [-Resource <string>] [-MakeDefault] [-PassThru] [-Environment <Environment>]
 [-AuthenticationUrl <string>] [<CommonParameters>]
```

### AzToken

```
Connect-PSMicrosoftEntraID [-AzToken <psobject>] [-Service <string[]>] [-ServiceUrl <string>]
 [-Resource <string>] [-MakeDefault] [-PassThru] [-Environment <Environment>]
 [-AuthenticationUrl <string>] [<CommonParameters>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Establish a connection to an Entra Service.
Prerequisite before executing any requests / commands.

## EXAMPLES

### EXAMPLE 1

Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID

Establish a connection to the graph API, prompting the user for login on their default browser.

### EXAMPLE 2

Connect-PSMicrosoftEntraID -AsAzAccount

Establish a connection to the graph API, using the current Az.Accounts session.

### EXAMPLE 3

Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -Certificate $cert

Establish a connection to the graph API using the provided certificate.

### EXAMPLE 4

Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -CertificatePath C:\secrets\certs\mde.pfx -CertificatePassword (Read-Host -AsSecureString)

Establish a connection to the graph API using the provided certificate file.
Prompts you to enter the certificate-file's password first.

### EXAMPLE 5

Connect-PSMicrosoftEntraID -Service Endpoint -ClientID $clientID -TenantID $tenantID -ClientSecret $secret

Establish a connection to Defender for Endpoint using a client secret.

### EXAMPLE 6

Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -VaultName myVault -Secretname GraphCert

Establish a connection to the graph API, after retrieving the necessary certificate from the specified Azure Key Vault.

## PARAMETERS

### -AsAzAccount

Reuse the existing Az.Accounts session to authenticate.
This is convenient as no further interaction is needed, but also limited in what scopes are available.
This authentication flow requires the 'Az.Accounts' module to be present, loaded and connected.
Use 'Connect-AzAccount' to connect first.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzAccount
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Assertion

The credentials from the federated identity provider to use in an Federated Credentials authentication flow.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -AuthenticationUrl

The url used for the authentication requests to retrieve tokens.
Usually determined by service connected to or the "Environment" parameter, but may be overridden in case of need.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -AzToken

{{ Fill AzToken Description }}

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzToken
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Browser

Use an interactive logon in your default browser.
This is the default logon experience.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Browser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -BrowserMode

How the browser used for authentication is selected.
Options:
+ Auto (default): Automatically use the default browser.
+ PrintLink: The link to open is printed on console and user selects which browser to paste it into (must be used on the same machine)

```yaml
Type: System.String
DefaultValue: Auto
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Browser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Certificate

The Certificate object used to authenticate with.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.Security.Cryptography.X509Certificates.X509Certificate2
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppCertificate
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CertificateName

The name/subject of the certificate to authenticate with.
The certificate must be stored either in the user or computer certificate store.
The newest certificate with a private key will be chosen.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppCertificate
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CertificatePassword

Password to use to read a PFX certificate file.
Only used together with -CertificatePath.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppCertificate
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CertificatePath

Path to a PFX file containing the certificate to authenticate with.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppCertificate
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -CertificateThumbprint

Thumbprint of the certificate to authenticate with.
The certificate must be stored either in the user or computer certificate store.

Part of the Application Certificate authentication workflow.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppCertificate
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ClientID

ID of the registered/enterprise application used for authentication.

Supports providing special labels as "ID":
+ Azure: Resolves to the actual ID of the first party app used by Connect-AzAccount
+ Graph: Resolves to the actual ID of the first party app used by Connect-MgGraph

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: KeyVault
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: UsernamePassword
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AppSecret
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AppCertificate
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Refresh
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: DeviceCode
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Browser
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ClientSecret

The client secret configured in the registered/enterprise application.

Part of the Client Secret Certificate authentication workflow.

```yaml
Type: System.Security.SecureString
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AppSecret
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Credential

The username / password to authenticate with.

Part of the Resource Owner Password Credential (ROPC) workflow.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: UsernamePassword
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -DeviceCode

Use the Device Code delegate authentication flow.
This will prompt the user to complete login via browser.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DeviceCode
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Environment

What environment this service should connect to.
Defaults to: 'Global'

```yaml
Type: PSMicrosoftEntraID.Environment
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -FallBackAzAccount

When logon as Managed Identity fails, try logging in as current AzAccount.
This is intended to allow easier local testing of code intended for an MSI environment, such as an Azure Function App.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Identity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Federated

Use federated credentials to authenticate.
This authentication flow is specific to a given environment and can for example enable a Github Action in a specific repository on a specific branch to authenticate, without needing to provide (and manage) a credential.
Some setup is required.

By default, this command is going to check all provided configurations ("Federation Providers") registered to PSMicrosoftEntraID and use the first that applies.
Use "PSMicrosoftEntraID" to pick a specific one to use.
Use "-Assertion" to handle the federated identity provider outside of PSMicrosoftEntraID and simply provide the result for logon.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -FederationProvider

The name of the Federation Provider to use.
Overrides the automatic selection.
Federation Providers are an PSMicrosoftEntraID concept and used to automatically do what is needed to access and use a Federated Credential, based on its environment.
See the documentation on Register-EntraFederationProvider for more details.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Identity

Log on as the Managed Identity of the current system.
Only works in environments with managed identities, such as Azure Function Apps or Runbooks.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IdentityID

ID of the User-Managed Identity to connect as.
https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IdentityType

Type of the User-Managed Identity.

```yaml
Type: System.String
DefaultValue: ClientID
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Identity
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -MakeDefault

Makes this service the new default service for all subsequent Connect-EntraService & Invoke-EntraRequest calls.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PassThru

Return the token received for the current connection.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RefreshToken

Use an already existing RefreshToken to authenticate.
Can be used to connect to multiple services using a single interactive delegate auth flow.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Refresh
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -RefreshTokenObject

Use the full token object of a delegate session with a refresh token, to authenticate to another service with this object.
Can be used to connect to multiple services using a single interactive delegate auth flow.

```yaml
Type: EntraToken
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: RefreshObject
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Resource

The resource to authenticate to.
Used to authenticate to a service without requiring a full service configuration.
Automatically implies PassThru.
This token is not registered as a service and cannot be implicitly  used by Invoke-EntraRequest.
Also provide the "-ServiceUrl" parameter, if you later want to use this token explicitly in Invoke-EntraRequest.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Scopes

Any scopes to include in the request.
Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: RefreshObject
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Refresh
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: DeviceCode
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Browser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -SecretName

Name of the secret to use from the Azure Key Vault specified through the '-VaultName' parameter.
In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
or are connected via Connect-AzAccount.
Supports specifying _multiple_ secret names, in which case the first one that works will be used.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: KeyVault
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Service

The service to connect to.
Individual commands using Invoke-EntraRequest specify the service to use and thus identify the token needed.
Defaults to: Graph

```yaml
Type: System.String[]
DefaultValue: $script:_DefaultService
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServiceUrl

The base url for requests to the service connecting to.
Overrides the default service url configured with the service settings.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ShowDialog

Whether to show an interactive dialog when connecting using the existing Az.Accounts session.
Defaults to: "auto"

Options:
- auto: Shows dialog only if needed.
- always: Will always show the dialog, forcing interaction.
- never: Will never show the dialog.
Authentication will fail if interaction is required.

```yaml
Type: System.String
DefaultValue: Auto
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: AzAccount
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TenantID

The ID of the tenant/directory to connect to.

```yaml
Type: System.String
DefaultValue: organizations
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Federated
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: KeyVault
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: UsernamePassword
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AppSecret
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: AppCertificate
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Refresh
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: DeviceCode
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Browser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UseRefreshToken

Use a refresh token if available.
Only applicable when connecting using a delegate authentication flow.
If specified, it will look to reuse an existing refresh token for that same client ID & tenant ID, if present,
making the authentication process non-interactive.
By default, it would always do the fully interactive authentication flow via Browser.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: DeviceCode
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
- Name: Browser
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -VaultName

Name of the Azure Key Vault from which to retrieve the certificate or client secret used for the authentication.
Secrets retrieved from the vault are not cached, on token expiration they will be retrieved from the Vault again.
In order for this flow to work, please ensure that you either have an active AzureKeyVault service connection,
or are connected via Connect-AzAccount.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: KeyVault
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

{{ Fill in the related links here }}

