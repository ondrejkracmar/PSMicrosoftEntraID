function Get-GraphApiUriPath {
	<#
	.SYNOPSIS
        Return using Microsoft Graph API version.

	.DESCRIPTION
		Return using Microsoft Graph API version.

	.PARAMETER GraphApiVersion
		Microsoft Graph API version

	.EXAMPLE
		PS C:\> Get-GraphApiUriPath -GraphApiVersion v1.0

		Return url path https://graph.microsoft.com/v1.0

	#>
    [CmdletBinding(DefaultParametersetName="Uri")]
    param(
        [Parameter(ParameterSetName="ApiVersion", Mandatory=$false, Position=0)]
        [ValidateSet('v1.0','beta')]
        [string]$GraphApiVersion
    )

    if(Test-PSFParameterBinding -ParameterName  GraphApiVersion)
    {
        return Join-UriPath -Uri (Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiUrl).Value -ChildPath $GraphApiVersion
    }
    else
    {
        return Join-UriPath -Uri (Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiUrl).Value -ChildPath (Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiVersion).Value
    }
}