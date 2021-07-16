function Get-PSAADSubscribedSkus {
    [CmdletBinding(DefaultParameterSetName = 'SkuId',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        
    )
    begin
    {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "subscribedSkus"
            $authorizationToken = Receive-PSAADAuthorizationToken
        }
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }
    }
    process {        
        if (Test-PSFFunctionInterrupt) { return }
        try
        {
            $graphApiParameters=@{
                Method = 'Get'
                AuthorizationToken = "Bearer $authorizationToken"
                Uri = $url 
            }
            
            Invoke-GraphApiQuery @graphApiParameters
            
        }
        catch {
			Stop-PSFFunction -String 'FailedGetSubscribedSkus' -StringValues $graphApiParameters['Uri'] -Target $graphApiParameters['Uri'] -SilentlyContinue -ErrorRecord $_ -Tag GraphApi,Get
		}
        Write-PSFMessage -Level InternalComment -String 'QueryCommandOutput' -StringValues $graphApiParameters['Uri'] -Target $graphApiParameters['Uri'] -Tag GraphApi,Get -Data $graphApiParameters
    }  
    end
    {}
}
