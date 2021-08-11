function Request-PSAADAuthorizationToken { 
    <# 
    .SYNOPSIS 
        Create new team using JSON template.

    .DESCRIPTION
        Create new team using JSON template

    .PARAMETER TenantId 
        Id of Office 365 tenant 

    .PARAMETER TenantName 
        Name  of Office 365 tenant 

    .PARAMETER Clientd 
        Id of delegation application for Graph API (Teams) of Azure AD (Office 365)  

    .PARAMETER ClientSecret 
        Client secret of delegation application 
#> 

    [CmdletBinding(DefaultParameterSetName = 'Token', 
        SupportsShouldProcess = $false, 
        PositionalBinding = $true, 
        ConfirmImpact = 'Medium')] 
    param ( 
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $false, 
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 0, 
            ParameterSetName = 'Token')] 
        [ValidateNotNullOrEmpty()] 

        [string]$TenantId, 
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $false, 
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 1, 
            ParameterSetName = 'Token')] 
        [ValidateNotNullOrEmpty()] 
        [string]$TenantName, 
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $false, 
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 2, 
            ParameterSetName = 'Token')] 
        [ValidateNotNullOrEmpty()] 
        [string]$ClientId, 
        [Parameter(Mandatory = $true,  
            ValueFromPipeline = $false, 
            ValueFromPipelineByPropertyName = $false, 
            ValueFromRemainingArguments = $false, 
            Position = 3, 
            ParameterSetName = 'Token')] 
        [ValidateNotNullOrEmpty()] 
        [string]$ClientSecret 

    ) 
    begin { 
        $loginURL = (Get-PSFConfigValue -Name PSAzureADDirectory.Settings.AuthUrl)   
        $scope = "https://graph.microsoft.com/.default"
        $tenantdomain = '{0}.{1}' -f $TenantName, 'onmicrosoft.com' 
    } 

    process {
        $body = @{grant_type = "client_credentials"; scope = $scope; client_id = $clientID; client_secret = $ClientSecret } 
        $oauth = Invoke-RestMethod -Method Post -Uri ('{0}/{1}/{2}' -f $loginURL, $tenantdomain, 'oauth2/v2.0/token') -Body $body 
        return $oauth.access_token
    } 
    end { 

    }
}