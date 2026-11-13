class EntraToken {
	#region Token Data
	[string]$AccessToken
	[System.DateTime]$ValidAfter
	[System.DateTime]$ValidUntil
	[string[]]$Scopes
	[string]$RefreshToken
	[string]$Audience
	[string]$Issuer
	[PSObject]$TokenData
	#endregion Token Data

	#region Connection Data
	[string]$Service
	[string]$Type
	[string]$ClientID
	[string]$TenantID
	[string]$ServiceUrl
	[string]$AuthenticationUrl
	[Hashtable]$Header = @{}
	[Hashtable]$Query = @{}
	[bool]$RawOnly

	[string]$IdentityID
	[string]$IdentityType

	# Workflow: Browser
	[string]$RedirectUri

	# Workflow: Client Secret
	[System.Security.SecureString]$ClientSecret

	# Workflow: Certificate
	[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate

	# Workflow: Username & Password
	[PSCredential]$Credential

	# Workflow: Key Vault
	[string]$VaultName
	[string]$SecretName

	# Workflow: Az.Accounts
	[string]$ShowDialog

	# Workflow: AzToken - whether the token came from Get-AzAccessToken, which can be asked again (Request-ServiceAzToken)
	[bool]$AzTokenRenewable

	# Workflow: Federated
	# A [PSMicrosoftEntraID.FederationProvider]. Typed [object]: PowerShell resolves the types of a class when it
	# PARSES the file, and the compiled module is one .psm1 parsed before bin/assembly.ps1 has loaded the library -
	# a library type here made the built module fail to import ("Unable to find type").
	[object]$FederationProvider

	# Workflow: Custom Token
	[scriptblock]$HeaderCode
	[hashtable]$Data = @{}

	#endregion Connection Data

	#region Constructors
	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [Securestring]$ClientSecret, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ClientSecret = $ClientSecret
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'ClientSecret'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [object]$Provider, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		# [object] for the parse-time reason above; the type is still enforced, at run time.
		if ($null -eq $Provider -or $Provider.GetType().FullName -ne 'PSMicrosoftEntraID.FederationProvider') {
			throw [System.ArgumentException]::new('Provider must be a [PSMicrosoftEntraID.FederationProvider].', 'Provider')
		}
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.FederationProvider = $Provider
		$this.Type = 'Federated'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Certificate = $Certificate
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'Certificate'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [pscredential]$Credential, [string]$ServiceUrl, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.Credential = $Credential
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'UsernamePassword'
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [string]$ServiceUrl, [bool]$IsDeviceCode, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		if ($IsDeviceCode) { $this.Type = 'DeviceCode' }
		else { $this.Type = 'Browser' }
	}

	EntraToken([string]$Service, [string]$ClientID, [string]$TenantID, [string]$ServiceUrl, [string]$VaultName, [string]$SecretName, [string]$AuthenticationUrl) {
		$this.Service = $Service
		$this.ClientID = $ClientID
		$this.TenantID = $TenantID
		$this.ServiceUrl = $ServiceUrl
		$this.VaultName = $VaultName
		$this.SecretName = $SecretName
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = 'KeyVault'
	}

	EntraToken([string]$Service, [string] $AccessToken, [string]$TenantID, [string]$IdentityID, [string[]] $Scopes, [string]$ServiceUrl, [string]$AuthenticationUrl, [string]$IdentityType) {
		$this.Service = $Service
		$this.AccessToken = $AccessToken
		$this.TenantID = $TenantID
		$this.Scopes = $Scopes
		$this.ServiceUrl = $ServiceUrl
		$this.AuthenticationUrl = $AuthenticationUrl
		$this.Type = $IdentityType

		if ($IdentityID) {
			$this.IdentityID = $IdentityID
		}
	}

	EntraToken([string]$Service, [string]$ServiceUrl, [string]$IdentityID, [string]$IdentityType) {
		$this.Service = $Service
		$this.ServiceUrl = $ServiceUrl
		$this.Type = 'Identity'

		if ($IdentityID) {
			$this.IdentityID = $IdentityID
			$this.IdentityType = $IdentityType
		}
	}

	EntraToken([string]$Service, [string]$ServiceUrl, [string]$ShowDialog) {
		$this.Service = $Service
		$this.ServiceUrl = $ServiceUrl
		$this.ShowDialog = $ShowDialog
		$this.Type = 'AzAccount'
	}

	# Empty Constructor for Import-EntraToken
	EntraToken() {}
	#endregion Constructors

	# The claims of a JWT: its payload, base64url without padding, as UTF-8 JSON (a name claim can hold any character;
	# ASCII turned them into '?').
	static [PSObject]ReadTokenData([string]$Token) {
		$tokenPayload = $Token.Split(".")[1].Replace('-', '+').Replace('_', '/')
		while ($tokenPayload.Length % 4) { $tokenPayload += "=" }
		$bytes = [System.Convert]::FromBase64String($tokenPayload)
		return ([System.Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json)
	}

	[void]SetTokenMetadata([PSObject] $AuthToken) {
		$this.AccessToken = $AuthToken.AccessToken
		$this.ValidAfter = $AuthToken.ValidAfter
		$this.ValidUntil = $AuthToken.ValidUntil
		$this.Scopes = $AuthToken.Scopes
		if ($AuthToken.RefreshToken) { $this.RefreshToken = $AuthToken.RefreshToken }

		$localData = [EntraToken]::ReadTokenData($AuthToken.AccessToken)

		if ($localData.roles) { $this.Scopes = $localData.roles }
		elseif ($localData.scp) { $this.Scopes = $localData.scp -split " " }

		$this.Audience = $localData.aud
		$this.Issuer = $localData.iss
		$this.TokenData = $localData
		$this.TenantID = $localData.tid
	}

	[hashtable]GetHeader() {
		if ($this.HeaderCode) {
			$newHeader = $this.Header.Clone()
			$results = @(& $this.HeaderCode $this)[0]
			foreach ($pair in $results.GetEnumerator()) {
				$newHeader[$pair.Key] = $pair.Value
			}
			return $newHeader
		}

		if ($this.ValidUntil -lt (Get-Date).AddMinutes(5)) {
			$this.RenewToken()
		}

		$currentHeader = @{}
		if ($this.Header.Count -gt 0) {
			$currentHeader = $this.Header.Clone()
		}
		$currentHeader.Authorization = "Bearer $($this.AccessToken)"

		return $currentHeader
	}

	[void]RenewToken() {
		$defaultParam = @{
			TenantID          = $this.TenantID
			ClientID          = $this.ClientID
			Resource          = $this.Audience
			AuthenticationUrl = $this.AuthenticationUrl
		}
		switch ($this.Type) {
			Certificate {
				$result = Connect-ServiceCertificate @defaultParam -Certificate $this.Certificate
				$this.SetTokenMetadata($result)
			}
			ClientSecret {
				$result = Connect-ServiceClientSecret @defaultParam -ClientSecret $this.ClientSecret
				$this.SetTokenMetadata($result)
			}
			UsernamePassword {
				$result = Connect-ServicePassword @defaultParam -Credential $this.Credential
				$this.SetTokenMetadata($result)
			}
			DeviceCode {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceDeviceCode @defaultParam
				$this.SetTokenMetadata($result)
			}
			Browser {
				if ($this.RefreshToken) {
					Connect-ServiceRefreshToken -Token $this
					return
				}

				$result = Connect-ServiceBrowser @defaultParam -SelectAccount -RedirectUri $this.RedirectUri
				$this.SetTokenMetadata($result)
			}
			Refresh {
				Connect-ServiceRefreshToken -Token $this
			}
			KeyVault {
				$secret = Get-VaultSecret -VaultName $this.VaultName -SecretName $this.SecretName
				$result = switch ($secret.Type) {
					Certificate { Connect-ServiceCertificate @defaultParam -Certificate $secret.Certificate }
					ClientSecret { Connect-ServiceClientSecret @defaultParam -ClientSecret $secret.ClientSecret }
				}
				$this.SetTokenMetadata($result)
			}
			Identity {
				$result = Connect-ServiceIdentity -Resource $this.Audience -IdentityID $this.IdentityID -IdentityType $this.IdentityType
				$this.SetTokenMetadata($result)
			}
			AzAccount {
				$result = Connect-ServiceAzure -Resource $this.Audience -ShowDialog $this.ShowDialog
				$this.SetTokenMetadata($result)
			}
			AzToken {
				# Get-AzAccessToken is asked again; any other source cannot be renewed and fails with a clear message.
				$result = Request-ServiceAzToken -Token $this
				$this.SetTokenMetadata($result)
			}
			Federated {
				$result, $provider = Connect-ServiceFederated @defaultParam -Provider $this.FederationProvider.Name -Assertion $this.FederationProvider.Assertion
				$this.SetTokenMetadata($result)
			}
		}
	}
}