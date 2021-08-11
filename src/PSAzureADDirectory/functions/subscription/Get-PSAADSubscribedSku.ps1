function Get-PSAADSubscribedSku {
    [CmdletBinding(DefaultParameterSetName = 'SkuId',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        
    )
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "subscribedSkus"
            $authorizationToken = Get-PSAADAuthorizationToken
            $property = (Get-PSFConfig -Module PSAzureADDirectory -Name Settings.GraphApiQuery.Select.SubscribedSku).Value
        }
        catch {
            Stop-PSFFunction -String 'StringAssemblyError' -StringValues $url -ErrorRecord $_
        }
    }
    process {        
        if (Test-PSFFunctionInterrupt) { return }
        $graphApiParameters = @{
            Method             = 'Get'
            AuthorizationToken = "Bearer $authorizationToken"
            Uri                = $url
            Select = $property -join ","
        }    
        $subscribedSkuResult = Invoke-GraphApiQuery @graphApiParameters
        $subscribedSkuResult | Select-PSFObject -Property $property -ExcludeProperty '@odata*' -TypeName "PSAzureADDirectory.SubscribedSku"
    }  
    end
    {}
}
