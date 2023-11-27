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

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDLicenseServicePlan -SkuPartNumber ENTERPRISEPACK

		Get service plans of ENTERPRISEPACK license
	#>
    [OutputType('PSMicrosoftEntraID.License.ServicePlan')]
    [CmdletBinding(DefaultParameterSetName = 'SkuPartNumber')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuId')]
        [ValidateGuid()]
        [string]$SkuId,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'SkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber,
        [switch]$EnableException
    )
    begin {
        Assert-RestConnection -Service graph -Cmdlet $PSCmdlet
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'SkuId' {
                $subscribedSku = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuId -EQ -Value $SkuId
                if (-not([object]::Equals($subscribedSku, $null))) {
                    $subscribedSku.ServicePlans | ConvertFrom-RestServicePlan
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $SkuId)
                    }
                }
            }
            'SkuPartNumber' {
                $subscribedSku = Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber
                if (-not([object]::Equals($subscribedSku, $null))) {
                    $subscribedSku.ServicePlans | ConvertFrom-RestServicePlan
                }
                else {
                    if ($EnableException.IsPresent) {
                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.Get.Failed) -f $SkuPartNumber)
                    }
                }
            }
        }
    }
    end
    {}
}