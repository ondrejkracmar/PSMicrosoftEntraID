function Get-GraphAPIVersion {
    <#
	.SYNOPSIS
        Return using Microsoft Graph API version.

	.DESCRIPTION
		Return using Microsoft Graph API version.

	.EXAMPLE
		PS C:\> Get-GraphAPIVersion

		Return url path v1.0

	#>
    [CmdletBinding()]
    param(
    )

    return (Get-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiVersion').Value

}