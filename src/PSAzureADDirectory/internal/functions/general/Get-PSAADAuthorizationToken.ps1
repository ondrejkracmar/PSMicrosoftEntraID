
function Get-PSAADAuthorizationToken
{
    [CmdletBinding(DefaultParametersetName="Token")]    
    param()
 
    process
    {
        return (Get-PSFConfig -Module PSAzureADDirectory -Name 'Settings.AuthorizationToken' -force).Value
    }
}