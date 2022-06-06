function Get-PSAADLicenseServicePlan {
    [OutputType('PSAzureADDirectory.License.ServicePlan')]
    [CmdletBinding(DefaultParameterSetName = 'SkuPartNumber')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuId')]
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
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber
    )
    begin {        
        Assert-RestConnection -Service graph -Cmdlet $PSCmdlet
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'SkuId' {
                (Get-PSAADSubscribedSku | Where-Object -Property SkuId -EQ -Value $SkuId).ServicePlans | ConvertFrom-RestServicePlan
            }
            'SkuPartNumber' {
                (Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).ServicePlans | ConvertFrom-RestServicePlan
            }
        }
    }  
    end
    {}
}