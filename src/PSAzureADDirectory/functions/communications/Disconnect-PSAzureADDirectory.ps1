function Disconnect-PSAzureADDirectory {
    [CmdletBinding(DefaultParametersetName = "Token")]    
    param()
    
    process {
        Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.AuthorizationToken' -Value 'None' -Hidden
    }
}       
