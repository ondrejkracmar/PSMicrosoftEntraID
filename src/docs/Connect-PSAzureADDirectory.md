---
external help file: PSAzureADDirectory-help.xml
Module Name: PSAzureADDirectory
online version:
schema: 2.0.0
---

# Connect-PSAzureADDirectory

## SYNOPSIS
Connect to the Azure AD object via Microsoft Graph API

## SYNTAX

### UsernamePassword
```
Connect-PSAzureADDirectory -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 -Credential <PSCredential> [<CommonParameters>]
```

### AppSecret
```
Connect-PSAzureADDirectory -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 -ClientSecret <SecureString> [<CommonParameters>]
```

### AppCertificate
```
Connect-PSAzureADDirectory -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 [-Certificate <X509Certificate2>] [-CertificateThumbprint <String>] [-CertificateName <String>]
 [-CertificatePath <String>] [-CertificatePassword <SecureString>] [<CommonParameters>]
```

### DeviceCode
```
Connect-PSAzureADDirectory -ClientID <String> -TenantID <String> [-Scopes <String[]>] [-DeviceCode]
 [<CommonParameters>]
```

### LegacyToken
```
Connect-PSAzureADDirectory [-Scopes <String[]>] -Token <SecureString> [<CommonParameters>]
```

## DESCRIPTION
Connect to the Azure AD object via Microsoft Graph API

## EXAMPLES

### EXAMPLE 1
```
Connect-PSAzureADDirectory -ClientID $clientID -TenantID $tenantID -TenantName contoso -Certificate $cert
```

Connect to the specified tenant using a certificate

### EXAMPLE 2
```
Connect-PSAzureADDirectory -ClientID $clientID -TenantID $tenantID -TenantName contoso -DeviceCode
```

Connect to the specified tenant using the DeviceCode flow

## PARAMETERS

### -ClientID
ID of the registered/enterprise application used for authentication.

```yaml
Type: String
Parameter Sets: UsernamePassword, AppSecret, AppCertificate, DeviceCode
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantID
The ID of the tenant/directory to connect to.

```yaml
Type: String
Parameter Sets: UsernamePassword, AppSecret, AppCertificate, DeviceCode
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scopes
Any scopes to include in the request.
Only used for interactive/delegate workflows, ignored for Certificate based authentication or when using Client Secrets.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeviceCode
Use the Device Code delegate authentication flow.
This will prompt the user to complete login via browser.

```yaml
Type: SwitchParameter
Parameter Sets: DeviceCode
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Certificate
The Certificate object used to authenticate with.

Part of the Application Certificate authentication workflow.

```yaml
Type: X509Certificate2
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
Type: String
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
Type: String
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
Type: String
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
Type: SecureString
Parameter Sets: AppCertificate
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientSecret
The client secret configured in the registered/enterprise application.

Part of the Client Secret Certificate authentication workflow.

```yaml
Type: SecureString
Parameter Sets: AppSecret
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The credentials to use to authenticate as a user.

Part of the Username and Password delegate authentication workflow.
Note: This workflow only works with cloud-only accounts and requires scopes to be pre-approved.

```yaml
Type: PSCredential
Parameter Sets: UsernamePassword
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Token
A legacy token used to authorize API access.
These tokens are deprecated and should be avoided, but not every migration can be accomplished instantaneously...

```yaml
Type: SecureString
Parameter Sets: LegacyToken
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
