function Connect-ServiceIdentity {
	<#
	.SYNOPSIS
		Connect as the current Managed Identity.

	.DESCRIPTION
		Connect as the current Managed Identity.
		Only works from within an Azure environment with a managed identity:

		+ App Service, Azure Functions, Azure Automation runbooks and Container Apps: the platform sets
		  IDENTITY_ENDPOINT and IDENTITY_HEADER; the token comes from that endpoint, with the header (a secret of the
		  platform) as X-IDENTITY-HEADER.
		+ Azure VM and VM scale set: no such variables are set; the token comes from the instance metadata service
		  (IMDS) at 169.254.169.254, with the header Metadata: true. A probe of at most 2 seconds checks first that the
		  service answers, so outside Azure the sign-in fails fast instead of waiting. IMDS answers 404 while the
		  identity is still being assigned, 410 while it is updating and 429 or 5xx when it is busy: those are retried
		  after 1, 2, 4, 8 and 16 seconds, within 90 seconds in all, as Microsoft advises.

		Azure Arc (IDENTITY_ENDPOINT with IMDS_ENDPOINT, a challenge file instead of a header) is not supported.
		Each token request waits at most 30 seconds for its answer. The environment of the process is read, never
		written: the earlier version set IDENTITY_ENDPOINT on a VM and then still required IDENTITY_HEADER, which a
		VM never has - so it never worked there, and left the variables behind for every later command.

		Ported from PSExchangeOnline (review finding M6, 2026-10-20).

	.PARAMETER Resource
		The resource to get a token for.

	.PARAMETER IdentityID
		ID of the User-Managed Identity to connect as.

	.PARAMETER IdentityType
		Type of the User-Managed Identity.

	.PARAMETER Cmdlet
		The $PSCmdlet of the calling command.
		If specified, errors are triggered in the caller's context.

	.EXAMPLE
		PS C:\> Connect-ServiceIdentity -Resource 'https://vault.azure.net'

		Connect as the current managed identity, retrieving a token for the Azure Key Vault.

	.LINK
		https://learn.microsoft.com/en-us/azure/app-service/overview-managed-identity

	.LINK
		https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-to-use-vm-token
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Resource,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityID,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$IdentityType,

		$Cmdlet = $PSCmdlet
	)
	process {
		if ($env:IDENTITY_ENDPOINT -and $env:IDENTITY_HEADER) {
			# App Service / Azure Functions
			[string] $apiVersion = $env:IDENTITY_API_VERSION
			if (-not $apiVersion) { $apiVersion = '2019-08-01' }
			[string] $url = '{0}?resource={1}&api-version={2}' -f $env:IDENTITY_ENDPOINT, [uri]::EscapeDataString($Resource), $apiVersion
			$labels = @{ ClientID = 'client_id'; ResourceID = 'mi_res_id'; PrincipalID = 'principal_id' }
			$headers = @{ 'X-IDENTITY-HEADER' = $env:IDENTITY_HEADER }
			$noProxy = $false
		}
		else {
			# Azure VM: the instance metadata service. A short wait: outside Azure nothing answers on that address, and
			# the probe must not hang the sign-in.
			try {
				$vmMetadata = Invoke-RestMethod -Method GET -Headers @{ Metadata = 'true' } -NoProxy -TimeoutSec $script:_InstanceMetadataProbeSeconds -Uri "$script:_InstanceMetadataUrl/metadata/instance?api-version=2021-02-01" -ErrorAction Stop
			}
			catch { $vmMetadata = $null }
			if ($vmMetadata.compute.azEnvironment -notlike '*Azure*') {
				Invoke-TerminatingException -Cmdlet $Cmdlet -Message (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.ManagedIdentity.NotFound') -Category ConnectionError
			}
			[string] $url = '{0}/metadata/identity/oauth2/token?api-version=2018-02-01&resource={1}' -f $script:_InstanceMetadataUrl, [uri]::EscapeDataString($Resource)
			$labels = @{ ClientID = 'client_id'; ResourceID = 'msi_res_id'; PrincipalID = 'object_id' }
			$headers = @{ Metadata = 'true' }
			$noProxy = $true
		}
		if ($IdentityID) {
			[string] $label = $labels[$IdentityType]
			if (-not $label) { $label = $labels.ClientID }
			$url = '{0}&{1}={2}' -f $url, $label, [uri]::EscapeDataString($IdentityID)
		}

		# Only IMDS is retried (Microsoft's guidance for it); the App Service endpoint answers or fails at once.
		[int[]] $waits = if ($noProxy) { 1, 2, 4, 8, 16 } else { @() }
		$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
		[int] $attempt = 0
		while ($true) {
			try {
				Write-PSFMessage -Level Verbose -String 'Identity.ManagedIdentity.Request' -StringValues (Get-EntraLogUri -Uri $url)
				$authResponse = Invoke-RestMethod -Method GET -Uri $url -Headers $headers -NoProxy:$noProxy -TimeoutSec 30 -ErrorAction Stop
				break
			}
			catch {
				[int] $status = 0
				if ($_.Exception.Response -and $_.Exception.Response.StatusCode) { $status = [int]$_.Exception.Response.StatusCode }
				[bool] $retry = ($status -in @(404, 410, 429) -or $status -ge 500) -and $attempt -lt $waits.Count
				if ($retry -and ($elapsed.Elapsed.TotalSeconds + $waits[$attempt]) -gt 90) { $retry = $false }
				if (-not $retry) {
					Invoke-TerminatingException -Cmdlet $Cmdlet -Message ((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Identity.ManagedIdentity.Failed') -f $_.Exception.Message) -ErrorRecord $_
				}
				Write-PSFMessage -Level Verbose -String 'Identity.ManagedIdentity.Retry' -StringValues $status, $waits[$attempt]
				Start-Sleep -Seconds $waits[$attempt]
				$attempt++
			}
		}

		Read-AuthResponse -AuthResponse $authResponse
	}
}
