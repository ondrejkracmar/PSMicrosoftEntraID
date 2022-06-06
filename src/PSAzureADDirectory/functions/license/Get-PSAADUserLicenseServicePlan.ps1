function Get-PSAADUserLicenseServicePlan {
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
        [string]$UserId
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
            'Userprincipalname' { Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $UserPrincipalName) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan} 
            'UserId' { Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $userId) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan}
        }
    }
    end
    {}
}
    