function Get-PSAADUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Get users who are assigned licenses
	
	.DESCRIPTION
		Get users who are assigned licenses with disabled and enabled service plans
	
	.PARAMETER Identity
        UserPrincipalName or Id of the user attribute populated in tenant/directory.

    .PARAMETER UserId
        The ID of the user in tenant/directory.
	
	.EXAMPLE
		PS C:\> Get-PSAADUserLicenseServicePlan -UserPrincipalName username@contoso.com

		Get licenses of user username@contoso.com with service plans

	#>
    [OutputType('PSAzureADDirectory.User.License')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateIdentity()]
        [string[]]
        $Identity
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.UserLicense).Value -join ',')
        }
        Get-PSAADSubscribedSku | Set-PSFResultCache
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' { 
                foreach ($user in $Identity) {
                    Invoke-RestRequest -Service 'graph' -Path ('users/{0}' -f $user) -Query $query -Method Get | ConvertFrom-RestUserLicense -ServicePlan
                } 
            }
        }
    }
    end
    {}
}
    