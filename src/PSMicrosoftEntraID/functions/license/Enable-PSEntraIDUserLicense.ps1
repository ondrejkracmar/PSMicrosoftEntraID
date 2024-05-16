function Enable-PSEntraIDUserLicenseServicePlan {
    <#
	.SYNOPSIS
		Enable serivce plan of users's sku subscription

	.DESCRIPTION
		Enable serivce plan of users's sku subscription

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

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.



	.EXAMPLE
		PS C:\> Enable-PSEntraIDUserLicenseServicePlan -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK -ServicePlanName @('OFFICESUBSCRIPTION','EXCHANGE_S_ENTERPRISE')

		Enable service plan Office Pro Plus, Exchnage Online  of subcription ENTERPRISEPACK for user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'IdentitySkuPartNumberPlanName')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$Identity,
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuIdServicePlanName')]
        [ValidateGuid()]
        [string]$SkuId,
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumberPlanName')]
        [ValidateNotNullOrEmpty()]
        [string]$SkuPartNumber,
        [switch]$EnableException
    )
    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }
    process {
        foreach ($user in  $Identity) {
            switch -Regex ($PSCmdlet.ParameterSetName) {
                '\wSkuId\w' {
                    $bodySkuId = $SkuId
                    $skuTarget = $SkuId
                    $body = @{

                        addLicenses    = @(
                            @{
                                disabledPlans = @()
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }
                    Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $user -ScriptBlock {
                        $aADUser = Get-PSEntraIDUserLicense -Identity $user
                        if (-not ([object]::Equals($aADUser, $null))) {
                            $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                            [void](Invoke-EntraRequest -Service $service -Path $path -Body $body -Method Post -ErrorAction Stop)
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                            }
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
                '\wSkuPartNumber\w' {
                    $bodySkuId = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -EQ -Value $SkuPartNumber).SkuId
                    $skuTarget = $SkuPartNumber
                    $body = @{

                        addLicenses    = @(
                            @{
                                disabledPlans = @()
                                skuId         = $bodySkuId
                            }
                        )
                        removeLicenses = @()
                    }
                    Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $user -ScriptBlock {
                        $aADUser = Get-PSEntraIDUserLicense-Identity $user
                        if (-not ([object]::Equals($aADUser, $null))) {
                            $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                            [void](Invoke-EntraRequest -Service $service -Path $path -Body $body -Method Post -ErrorAction Stop)
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                            }
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end
    {}
}
