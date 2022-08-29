function Get-GraphApiUriPath
<# Joins uri to a child path#>
{
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