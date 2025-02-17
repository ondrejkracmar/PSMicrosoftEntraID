function Disable-PSEntraIDUserLicense {
    <#
	.SYNOPSIS
		Disable user's license.

	.DESCRIPTION
		Disable user's Office 365 subscription.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Users.User object in tenant/directory.

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

    .PARAMETER Force
        The Force switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the disable license action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

	.EXAMPLE
		PS C:\> Disable-PSEntraIDUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK

		Disable license (subscription) ENTERPRISEPACK of user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'InputObjectSkuPartNumber')]
    param ([Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuId')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumber')]
        [PSMicrosoftEntraID.Users.User[]]$InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuId')]
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuId')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuId')]
        [ValidateGuid()]
        [string[]] $SkuId,
        [Parameter(Mandatory = $True, ParameterSetName = 'InputObjectSkuPartNumber')]
        [Parameter(Mandatory = $True, ParameterSetName = 'IdentitySkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string[]] $SkuPartNumber,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch]$PassThru
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else {
            [boolean] $cmdLetVerbose = $false
        }
    }
    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            '\wSkuId' {
                [string[]] $bodySkuId = $SkuId
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    [string] $skuTarget = ($bodySkuId | Join-String -SingleQuote -Separator ',')
                }
                else {
                    [string] $skuTarget = ($bodySkuId | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
            }
            '\wSkuPartNumber' {
                [string[]] $bodySkuId = (Get-PSEntraIDSubscribedSku | Where-Object -Property SkuPartNumber -In -Value $SkuPartNumber).SkuId
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    [string] $skuTarget = ($SkuPartNumber | Join-String -SingleQuote -Separator ',')
                }
                else {
                    [string] $skuTarget = ($SkuPartNumber | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
            }
        }
        [hashtable] $body = @{
            addLicenses    = @()
            removeLicenses = $bodySkuId
        }
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in  $InputObject) {
                    Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {
                        [string] $path = ("users/{0}/{1}" -f $itemInputObject.Id, 'assignLicense')
                        [PSMicrosoftEntraID.Users.LicenseManagement.ServicePlan[]] $servivePlanStatus = $itemInputObject |
                        Get-PSEntraIDUserLicenseDetail |
                        Select-Object -ExpandProperty ServicePLans
                        if (-not ([object]::Equals($servivePlanStatus, $null))) {
                            if ($PassThru.IsPresent) {
                                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                            }
                            else {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                            }
                        }
                    } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity\w' {
                foreach ($user in  $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $skuTarget -Target $user -ScriptBlock {
                        [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                        if (-not ([object]::Equals($aADUser, $null))) {
                            [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                            [PSMicrosoftEntraID.Users.LicenseManagement.ServicePlan[]] $servivePlanStatus = $aADUser |
                            Get-PSEntraIDUserLicenseDetail |
                            Select-Object -ExpandProperty ServicePLans
                            if (-not ([object]::Equals($servivePlanStatus, $null))) {
                                if ($PassThru.IsPresent) {
                                    [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}'-f $path); Body = $body; Headers = $header }
                                }
                                else {
                                    [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                                }
                            }
                        }
                        else {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                            }
                        }
                    } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end
    {}
}
