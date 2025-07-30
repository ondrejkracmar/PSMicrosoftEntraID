function Disconnect-PSMicrosoftEntraID {
	<#
	.SYNOPSIS
		Disconnect from an Microsoft EntraID Service.

	.DESCRIPTION
		Disconnect from an Microsoft EntraID Service.

	.PARAMETER Service
		The service for which to retrieve the token.
		Defaults to: Default Service

	.EXAMPLE
		PS C:\> Disconnect-PSMicrosoftEntraID


	#>
	[CmdletBinding()]
	param (
		[Parameter()]
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string] $Service = $script:_DefaultService
	)
	begin {
		if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
			[boolean] $cmdLetVerbose = $true
		}
		else {
			[boolean] $cmdLetVerbose = $false
		}
	}
	process {
		if ($cmdLetVerbose) {
			Clear-PSFResultCache
			Write-Verbose  ((Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Disconnect) -f $Service)
		}
		$script:_EntraTokens[$Service] = $null
	}
}