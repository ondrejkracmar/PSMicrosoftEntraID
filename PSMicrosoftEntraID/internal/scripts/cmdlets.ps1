<#
Registers the cmdlets published by this module.
Necessary for full hybrid module support.
#>
$commonParam = @{
	#HelpFile  = (Resolve-Path "$($script:ModuleRoot)\en-us\PSMicrosoftEntraID.dll-Help.xml")
	Module = $ExecutionContext.SessionState.Module
}

Import-PSFCmdlet @commonParam -Name New-PSEntraIDBatchRequest -Type ([PSMicrosoftEntraID.Commands.NewPSEntraIDBatchRequest])

#Set-Alias -Name Sort-PSFObject -Value Set-PSFObjectOrder -Force -ErrorAction SilentlyContinue