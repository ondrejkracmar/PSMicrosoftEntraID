function Receive-PSAADAuthorizationToken
{
    [CmdletBinding(DefaultParametersetName="Token")]    
    param(

            [switch]
            $AuthorizationTokenDetail
        )
 
    process
    {
        try{
            if(Test-PSFParameterBinding -ParameterName AuthorizationTokenDetail)
            {
                $jwtToken = (Get-PSFConfig -Module $Env:ModuleName -Name 'Settings.AuthorizationToken')  | Get-JWTDetails
                return  $jwtToken                
            }
            else {
                return (Get-PSFConfigValue -Module $Env:ModuleName -Name 'Settings.AuthorizationToken')
            }
        }
        catch{
            Stop-PSFFunction -Message "Failed to read authorization token token." -ErrorRecord $_
        }
    }
}