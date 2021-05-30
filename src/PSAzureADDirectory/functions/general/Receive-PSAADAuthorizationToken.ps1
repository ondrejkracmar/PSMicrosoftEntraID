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
                $jwtToken = (Get-PSFConfig -Module PSAzureADDirectory -Name 'Settings.AuthorizationToken').Value  | Get-JWTDetails
                return  $jwtToken                
            }
            else {
                return (Get-PSFConfig -Module PSAzureADDirectory -Name 'Settings.AuthorizationToken').Value
            }
        }
        catch{
            Stop-PSFFunction -Message "Failed to read authorization token token." -ErrorRecord $_
        }
    }
}