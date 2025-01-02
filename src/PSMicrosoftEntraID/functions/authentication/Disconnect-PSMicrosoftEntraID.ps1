﻿function Disconnect-PSMicrosoftEntraID {
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
		[ArgumentCompleter({ Get-ServiceCompletion $args })]
		[string]
		$Service = $script:_DefaultService
	)
	begin{
		if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean]$cmdLetVerbose = $true
        }
        else{
            [boolean]$cmdLetVerbose =  $false
        }
	}
	process {
		if($cmdLetVerbose){
			Write-Verbose  ((Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Disconnect) -f $Service)
		}
		$script:_EntraTokens[$Service] = $null
	}
}