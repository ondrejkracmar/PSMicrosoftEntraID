function Get-PSAADUserLicense {
    [CmdletBinding(DefaultParameterSetName = 'UserPrincipalName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserPrincipalName')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                If ($_ -match '@') {
                    $True
                }
                else {
                    $false
                }
            })]
        [string]$UserPrincipalName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'UserId')]
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
        [string]$SkuPartNumber,
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuPartNumber')]
        [Parameter(Mandatory = $false, ParameterSetName = 'SkuId')]
        [ValidateNotNullOrEmpty()]
        [ValidateRange(1, 999)]
        [int]$PageSize = 100
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserLicense).Value -join ',')
        }
        Get-PSAADSubscribedSku | Set-PSFResultCache -DisableCache $true
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Userprincipalname' { Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $UserPrincipalName) -Query $query -Method Get | ConvertFrom-RestUserLicense } 
            'UserId' { Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $userId) -Query $query -Method Get | ConvertFrom-RestUserLicense }
            'SkuId' {
                $query['$count'] = 'true'
                $query['$top'] = $PageSize
                $query['$filter'] = ('assignedLicenses/any(x:x/skuId eq {0})' -f $SkuId)
                Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get | ConvertFrom-RestUserLicense
            }
            'SkuPartNumber' {
                $query['$count'] = 'true'
                $query['$top'] = $PageSize
                $SkuId = (Get-PSAADSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
                $query['$filter'] = ('assignedLicenses/any(x:x/skuId eq {0})' -f $SkuId)
                Invoke-RestRequest -Service 'graph' -Path users -Query $query -Method Get | ConvertFrom-RestUserLicense
            }
        }
    }
    end
    {}
}
    