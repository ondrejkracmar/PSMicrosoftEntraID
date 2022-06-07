function Get-PSAADUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Get users who are assigned licenses
	
	.DESCRIPTION
		Get users who are assigned licenses with disabled and enabled service plans
	
	.PARAMETER UserPrincipalName
        UserPrincipalName attribute populated in tenant/directory.

    .PARAMETER UserId
        The ID of the user in tenant/directory.
	
	.EXAMPLE
		PS C:\> Get-PSAADUserLicenseServicePlan -UserPrincipalName username@contoso.com

		Get licenses of user username@contoso.com with service plans

	#>
    [OutputType('PSAzureADDirectory.User.License')]
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
        [string]
        $UserPrincipalName,
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
        [string]
        $UserId
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
    