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
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

	.EXAMPLE
		PS C:\> Disable-PSEntraIDUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK

		Disable license (subscription) ENTERPRISEPACK of user username@contoso.com

	#>
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'InputObjectSkuPartNumber')]
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
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        # $PSBoundParameters, not $PSCmdlet.ParameterSetName: with pipeline input the
        # set is not resolved until the first object arrives in process, so a switch on
        # it here matches nothing and $bodySkuId stays empty for every piped target.
        # SkuId/SkuPartNumber are never pipeline-bound, so this is decidable in begin.
        if ($PSBoundParameters.ContainsKey('SkuId')) {
            [string[]] $bodySkuId = $SkuId
            [string] $skuTarget = ($bodySkuId | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
        }
        else {
            [System.Collections.Generic.List[string]] $bodySkuIdList = [System.Collections.Generic.List[string]]::new()
            [PSMicrosoftEntraID.License.SubscriptionSku[]] $subscribedSkus = Get-PSEntraIDSubscribedSku
            foreach ($skuPart in $SkuPartNumber) {
                [PSMicrosoftEntraID.License.SubscriptionSku] $matchedSku = @($subscribedSkus | Where-Object { $_.SkuPartNumber -eq $skuPart })[0]
                if ($matchedSku) {
                    $bodySkuIdList.Add($matchedSku.SkuId)
                }
            }
            [string[]] $bodySkuId = $bodySkuIdList.ToArray()
            [string] $skuTarget = ($SkuPartNumber | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
        }
    }
    process {
        [hashtable] $body = @{
            addLicenses    = @()
            removeLicenses = $bodySkuId
        }
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in  $InputObject) {
                    if (-not ([object]::Equals($itemInputObject.AssignedLicenses, $null)) -and $itemInputObject.AssignedLicenses.Count -gt 0) {
                        [string[]] $userSkuIds = $itemInputObject.AssignedLicenses.SkuId
                        [bool] $hasLicenseToRemove = $false
                        foreach ($skuToRemove in $bodySkuId) {
                            if ($userSkuIds -contains $skuToRemove) {
                                $hasLicenseToRemove = $true
                                break
                            }
                        }
                        if ($hasLicenseToRemove) {
                            [string] $path = ("users/{0}/{1}" -f $itemInputObject.Id, 'assignLicense')
                            if ($PassThru.IsPresent) {
                                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                            }
                            else {
                                Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {
                                    [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                        }
                    }
                }
            }
            'Identity\w' {
                foreach ($user in  $Identity) {
                    [PSMicrosoftEntraID.Users.User] $aADUser = Get-PSEntraIDUser -Identity $user
                    if ([object]::Equals($aADUser, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                        }
                    }
                    else {
                        if (-not ([object]::Equals($aADUser.AssignedLicenses, $null)) -and $aADUser.AssignedLicenses.Count -gt 0) {
                        [string[]] $userSkuIds = $aADUser.AssignedLicenses.SkuId
                        [bool] $hasLicenseToRemove = $false
                        foreach ($skuToRemove in $bodySkuId) {
                            if ($userSkuIds -contains $skuToRemove) {
                                $hasLicenseToRemove = $true
                                break
                            }
                        }
                        if ($hasLicenseToRemove) {
                            [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                            if ($PassThru.IsPresent) {
                                [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                            }
                            else {
                                Invoke-PSFProtectedCommand -ActionString 'License.Disable' -ActionStringValues $skuTarget -Target $user -ScriptBlock {
                                    [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                                } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                                if (Test-PSFFunctionInterrupt) { return }
                            }
                        }
                    }
                    }
                }
            }
        }
    }
    end
    {}
}
