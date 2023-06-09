function Get-GraphApiUriPath {
	<#
	.SYNOPSIS
        Retrun using Microsoft Graph API version.

	.DESCRIPTION
		Retrun using Microsoft Graph API version.

	.PARAMETER GraphApiVersion
		The rest response representing a license

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