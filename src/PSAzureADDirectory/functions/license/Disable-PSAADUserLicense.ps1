function Disable-PSAADUserLicense {
    <#
	.SYNOPSIS
		Disable user's license

	.DESCRIPTION
		Disable user's Office 365 subscription

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

	.PARAMETER SkuId
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER SkuPartNumber
        Friendly name Office 365 product of subscribedSku.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.


	.EXAMPLE
		PS C:\> Disable-PSAADUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK

		Disable license (subscription) ENTERPRISEPACK of user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentitySkuPartNumber')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [ValidateIdentity()]
        [string[]]
        [Alias("Id","UserPrincipalName","Mail")]
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
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }
    process {
        foreach ($user in  $Identity) {
            $aADUser = Get-PSAADUserLicenseServicePlan -Identity $user
            if (-not ([object]::Equals($aADUser, $null))) {
                $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')

                switch -Regex ($PSCmdlet.ParameterSetName) {
                    '\wSkuId' {
                        [string[]]$bodySkuId = $SkuId
                        if (Test-PSFPowerShell -PSMinVersion 7.0) {
                            $skuTarget = ($SkuId | Join-String -SingleQuote -Separator ',')
                        }
                        else {
                            $skuTarget = ($SkuId | ForEach-Object { "'{0}'" -f $_ }) -join ','
                        }
                    }
                    '\wSkuPartNumber' {
                        [string[]]$bodySkuId = (Get-PSFResultCache | Where-Object -Property SkuPartNumber -In -Value $SkuPartNumber).SkuId
                        if (Test-PSFPowerShell -PSMinVersion 7.0) {
                            $skuTarget = ($SkuPartNumber | Join-String -SingleQuote -Separator ',')
                        }
                        else {
                            $skuTarget = ($SkuPartNumber | ForEach-Object { "'{0}'" -f $_ }) -join ','
                        }
                    }
                }
                $body = @{

                    addLicenses    = @(
                    )
                    removeLicenses = $bodySkuId
                }
                Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $skuTarget -Target $aADUser.UserPrincipalName -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Post)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {}
        }
    }
    end
    {}
}
