function Enable-PSEntraIDGroupLicense {
    <#
    .SYNOPSIS
        Enable a license on a group.

    .DESCRIPTION
        Assign a subscribed SKU license to a Microsoft 365 group.

    .PARAMETER InputObject
        PSMicrosoftEntraID.Groups.Group object in tenant/directory.

    .PARAMETER Identity
        MailNickName or Id of the group.

    .PARAMETER SkuId
        Office 365 product GUID of the subscribedSku to assign.

    .PARAMETER SkuPartNumber
        Friendly name of the subscribedSku product to assign.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        This is less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch suppresses the confirmation prompt before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to stop processing before any changes are made
        and prompt you to acknowledge each action before it continues.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> Enable-PSEntraIDGroupLicense -Identity group1 -SkuPartNumber ENTERPRISEPACK

        Enable license ENTERPRISEPACK on group group1.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType([PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'InputObjectSkuPartNumber')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuId')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObjectSkuPartNumber')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuId')]
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuId')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuId')]
        [ValidateGuid()]
        [string[]] $SkuId,
        [ArgumentCompleter({ Get-SubscribedLicenseCompletion $args })]
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObjectSkuPartNumber')]
        [Parameter(Mandatory = $true, ParameterSetName = 'IdentitySkuPartNumber')]
        [ValidateNotNullOrEmpty()]
        [string[]] $SkuPartNumber,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{ 'Content-Type' = 'application/json' }
        [bool] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm

        switch -Regex ($PSCmdlet.ParameterSetName) {
            '\wSkuId' {
                [string[]] $bodySkuId = $SkuId
                [string] $skuTarget = ($bodySkuId | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            }
            '\wSkuPartNumber' {
                [System.Collections.Generic.List[string]] $bodySkuIdList = [System.Collections.Generic.List[string]]::new()
                [object[]] $subscribedLicenses = @(Get-PSEntraIDSubscribedLicense -EnableException:$EnableException)
                foreach ($skuPart in $SkuPartNumber) {
                    [object] $matchedSku = $subscribedLicenses | Where-Object { $_.SkuPartNumber -eq $skuPart } | Select-Object -First 1
                    if ($matchedSku) {
                        $bodySkuIdList.Add($matchedSku.SkuId)
                    }
                    else {
                        [string] $message = (Get-PSFLocalizedString -Module $script:ModuleName -Name SubscribedSku.SkuPartNumber.NotFound) -f $skuPart
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message $message
                        }
                        else {
                            Write-PSFMessage -Level Warning -Message $message
                        }
                    }
                }
                [string[]] $bodySkuId = $bodySkuIdList.ToArray()
                [string] $skuTarget = ($SkuPartNumber | ForEach-Object { "'{0}'" -f $_ } | Join-String -Separator ',')
            }
        }

        [System.Collections.ArrayList] $addLicensesList = [System.Collections.ArrayList]::new()
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

    process {
        switch -Regex ($PSCmdlet.ParameterSetName) {
            'InputObject\w' {
                foreach ($itemInputObject in $InputObject) {
                    [string] $path = ('groups/{0}/{1}' -f $itemInputObject.Id, 'assignLicense')
                    if ($PassThru.IsPresent) {
                        [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                    }
                    else {
                        $groupTarget = if (-not [string]::IsNullOrWhiteSpace($itemInputObject.DisplayName)) { $itemInputObject.DisplayName } else { $itemInputObject.Id }
                        Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $groupTarget -ScriptBlock {
                            [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                        } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
            'Identity\w' {
                foreach ($group in $Identity) {
                    [PSMicrosoftEntraID.Groups.Group] $aADGroup = Get-PSEntraIDGroup -Identity $group
                    if ([object]::Equals($aADGroup, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $group)
                        }
                    }
                    else {
                        [string] $path = ('groups/{0}/{1}' -f $aADGroup.Id, 'assignLicense')
                        if ($PassThru.IsPresent) {
                            [PSMicrosoftEntraID.Batch.Request]@{ Method = 'POST'; Url = ('/{0}' -f $path); Body = $body; Headers = $header }
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'License.Enable' -ActionStringValues $skuTarget -Target $group -ScriptBlock {
                                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)
                            } -EnableException $EnableException -Confirm:$($cmdLetConfirm) -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                            if (Test-PSFFunctionInterrupt) { return }
                        }
                    }
                }
            }
        }
    }
}