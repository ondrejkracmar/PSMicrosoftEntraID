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
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>] [-Browser] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### DeviceCode
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>] [-DeviceCode] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AppCertificate
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 [-Certificate <X509Certificate2>] [-CertificateThumbprint <String>] [-CertificateName <String>]
 [-CertificatePath <String>] [-CertificatePassword <SecureString>] [-PassThru]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### AppSecret
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 -ClientSecret <SecureString> [-PassThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### UsernamePassword
```
Connect-PSMicrosoftEntraID -ClientID <String> -TenantID <String> [-Scopes <String[]>]
 -Credential <PSCredential> [-PassThru] [-ProgressAction <ActionPreference>] [<CommonParameters>]
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
Connect-PSMicrosoftEntraID -ClientID $clientID -TenantID $tenantID -ClientSecret $secret
```

Establish a connection using a client secret.

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
Parameter Sets: (All)
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

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

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
Parameter Sets: (All)
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
