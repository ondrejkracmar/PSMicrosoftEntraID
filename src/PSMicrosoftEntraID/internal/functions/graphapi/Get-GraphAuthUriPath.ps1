function Get-GraphAuthUriPath {
    <#
	.SYNOPSIS
        Return using Microsoft Graph authorization API version.

	.DESCRIPTION
		Return using Microsoft Graph authorization API version.

	.EXAMPLE
		PS C:\> Get-Get-GraphAuthUriPath

		Return url path https://login.microsoftonline.com

	#>
    [CmdletBinding()]
    param(
    )

    return (Get-PSFConfig -Module $script:ModuleName -Name 'Settings.AuthUrl').Value

}