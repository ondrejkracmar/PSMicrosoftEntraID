function Get-PSEntraIDLicenseServicePlan {
    <#
	.SYNOPSIS
		Get service plans of license

	.DESCRIPTION
		Get service plans of license

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

	.EXAMPLE
		PS C:\> Get-PSAADLicenseServicePlan -SkuPartNumber ENTERPRISEPACK

		Get service plans of ENTERPRISEPACK license
	#>
    [OutputType('PSAzureADDirectory.License.ServicePlan')]
    [CmdletBinding(DefaultParameterSetName = 'SkuPartNumber')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuId')]
        [ValidateGuid()]
        $SkuId,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SkuPartNumber
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