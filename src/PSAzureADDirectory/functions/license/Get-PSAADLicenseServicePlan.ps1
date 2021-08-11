function Get-PSAADLicenseServicePlan {
    [CmdletBinding(DefaultParameterSetName = 'SkuId',
        SupportsShouldProcess = $false,
        PositionalBinding = $true,
        ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } 
                catch {
                    $false
                }
            })]
        [string]$UserId,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 1,
            ParameterSetName = 'SkuId')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                try {
                    [System.Guid]::Parse($_) | Out-Null
                    $true
                } 
                catch {
                    $false
                }
            })]
        [string]$SkuId,
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 1,
            ParameterSetName = 'SkuId')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber
    )
    begin {
        try {
            $url = Join-UriPath -Uri (Get-GraphApiUriPath) -ChildPath "users"
            $authorizationToken = Get-PSAADAuthorizationToken
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
            Uri                = Join-UriPath -Uri $url -ChildPath ("{0}/{1}" -f $UserId, 'licenseDetails')
        }
        if (Test-PSFParameterBinding -Parameter SkuId) {
            Invoke-GraphApiQuery @graphApiParameters | Where-Object { $_.SkuId -eq $SkuId }
        }
        elseif (Test-PSFParameterBinding -Parameter SkuId) {
            Invoke-GraphApiQuery @graphApiParameters | Where-Object { $_.SkuPartNumber -eq $SkuPartNumber }
        }
        else {
            Invoke-GraphApiQuery @graphApiParameters
        }
    }  
    end
    {}
}
