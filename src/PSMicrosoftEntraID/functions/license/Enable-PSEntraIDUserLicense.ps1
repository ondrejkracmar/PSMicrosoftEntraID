function Enable-PSEntraIDUserLicense {
    <#
	.SYNOPSIS
		Enable user license of users's sku subscription.

	.DESCRIPTION
		Enable user license of users's sku subscription.

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
        When specified, the cmdlet will not execute the action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

	.EXAMPLE
		PS C:\> Enable-PSEntraIDUserLicense -Identity username@contoso.com -SkuPartNumber ENTERPRISEPACK

		Enable license ENTERPRISEPACK for user username@contoso.com

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'InputObjectSkuPartNumber')]
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
        [ArgumentCompleter({ Get-SubscribedLicenseCompletion $args })]
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
        [bool] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        switch -Regex ($PSCmdlet.ParameterSetName) {
            '\wSkuId' {
                [string[]] $bodySkuId = $SkuId
                [string] $skuTarget = ($bodySkuId | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
                [System.Collections.Generic.List[object]] $addLicensesList = [System.Collections.Generic.List[object]]::new()
                foreach ($skuIdItem in $bodySkuId) {
                    [void] $addLicensesList.Add(@{
                        disabledPlans = @()
                        skuId         = $skuIdItem
                    })
                }
                [hashtable] $body = @{
                    addLicenses    = $addLicensesList.ToArray()
                    removeLicenses = @()
                }
            }
            '\wSkuPartNumber' {
                [System.Collections.Generic.List[string]] $bodySkuIdList = [System.Collections.Generic.List[string]]::new()
                [PSMicrosoftEntraID.License.SubscriptionSku[]] $subscribedSkus = Get-PSEntraIDSubscribedSku
                foreach ($skuPart in $SkuPartNumber) {
                    [PSMicrosoftEntraID.License.SubscriptionSku] $matchedSku = $subscribedSkus | Where-Object { $_.SkuPartNumber -eq $skuPart } | Select-Object -First 1
                    if ($matchedSku) {
                        $bodySkuIdList.Add($matchedSku.SkuId)
                    }
                }
                [string[]] $bodySkuId = $bodySkuIdList.ToArray()
                [string] $skuTarget = ($SkuPartNumber | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
                [System.Collections.Generic.List[object]] $addLicensesList = [System.Collections.Generic.List[object]]::new()
                foreach ($skuIdItem in $bodySkuId) {
                    [void] $addLicensesList.Add(@{
                        disabledPlans = @()
                        skuId         = $skuIdItem
                    })
                }
                [hashtable] $body = @{
                    addLicenses    = $addLicensesList.ToArray()
                    removeLicenses = @()
                }
            }
        }
    }
    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in  $InputObject) {
                    [string] $path = ("users/{0}/{1}" -f $itemInputObject.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $itemInputObject.UserPrincipalName -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
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
                        [string] $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $user -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                    }
                }
            }
        }
    }
    end
    {}
}
