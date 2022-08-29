function Disable-PSAADUserLicense {
    <#
	.SYNOPSIS
		Disable user's license 
	
	.DESCRIPTION
		Disable user's Office 365 subscription  
	
	.PARAMETER Identity
        UserPrincipalName or Id of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

	.EXAMPLE
		PS C:\> Disable-PSAADUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK

		Disable license (subscription) ENTERPRISEPACK of user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentitySkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [ValidateIdentity()]
        [string[]]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuId')]
        [ValidateGuid()]
        [string[]]
        $SkuId,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SkuPartNumber,
        [switch]
        $EnableException
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        Get-PSAADSubscribedSku | Set-PSFResultCache
    }
    process {
        foreach ($user in  $Identity) {
            switch -Regex ($PSCmdlet.ParameterSetName) {
                'Identity\w' {
                    $userLicenseDetail = Get-PSAADUserLicenseServicePlan -Identity $user
                    $path = ("users/{0}/{1}" -f $user, 'assignLicense')
                }
                '\wSkuId' {
                    [string[]]$bodySkuId = $SkuId
                }
                '\wSkuPartNumber' {
                    [string[]]$bodySkuId = (Get-PSFResultCache | Where-Object -Property SkuPartNumber -in -Value $SkuPartNumber).SkuId
                }
            }
            $body = @{
                            
                addLicenses    = @(
                )
                removeLicenses = $bodySkuId
            }            
            Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $Identity -Target $Identity -ScriptBlock {
               $disableLicense = Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post
            } -EnableException $EnableException -PSCmdlet $PSCmdlet
            $disableLicense  | ConvertFrom-RestUser
        }
    }
    end
    {}
}
