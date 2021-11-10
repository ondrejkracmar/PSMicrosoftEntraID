function Connect-PSAzureADDirectory {
    [CmdletBinding(DefaultParametersetName = "Token")]    
    param(
        [Parameter(ParameterSetName = "AuthorizationToken", Mandatory = $true)]
        [string]$AuthorizationToken,
        [Parameter(ParameterSetName = 'Application', Mandatory = $true)]
        [string]$TenantName,
        [Parameter(ParameterSetName = 'Application', Mandatory = $true)]
        [string]$TenantId,
        [Parameter(ParameterSetName = 'Application', Mandatory = $true)]
        [string]$ClientId,
        [Parameter(ParameterSetName = 'Application', Mandatory = $true)]
        [string]$ClientSecret)
    
    process {
        Switch ($PSCmdlet.ParameterSetName) {
            'AuthorizationToken' {                               
                $accessToken = $AuthorizationToken
            }
            'Application' {
                try{
                    $accessToken = Request-PSAADAuthorizationToken -TenantName $TenantName -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
                }
                catch{
                    $PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]'Failed to authenticate.'), $null, 0, $null))
                }
            }
        }
        Set-PSFConfig -Module 'PSAzureADDirectory' -Name 'Settings.AuthorizationToken' -Value $accessToken -Hidden
    }
}       
