function Get-PSEntraIDGroupLicenseDetail {
    <#
        .SYNOPSIS
            Return details for licenses that are assigned to a group.

        .DESCRIPTION
            Return details for licenses that are assigned to a group.

        .PARAMETER InputObject
            PSMicrosoftEntraID.Groups.Group object in tenant/directory.

        .PARAMETER Identity
            MailNickname, Mail or Id of the group attribute populated in tenant/directory.

        .PARAMETER EnableException
            This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
            but allows catching exceptions in calling scripts.

        .EXAMPLE
            PS C:\> Get-PSEntraIDGroupLicenseDetail -Identity licensing-group

            Get Office 365 subscriptions with their service plans of specific group
    #>
    [OutputType('PSMicrosoftEntraID.Groups.LicenseManagement.SubscriptionSku')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param ([Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.Groups.Group[]] $InputObject,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias('Id', 'GroupId', 'TeamId', 'MailNickName')]
        [ValidateGroupIdentity()]
        [string[]] $Identity,
        [Parameter()]
        [switch] $EnableException
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($itemInputObject in $InputObject) {
                    $groupObject = $itemInputObject
                    if ((-not $itemInputObject.PSObject.Properties['AssignedLicenses'] -or [object]::Equals($itemInputObject.AssignedLicenses, $null)) -and -not [string]::IsNullOrWhiteSpace($itemInputObject.Id)) {
                        $groupObject = Get-PSEntraIDGroup -Identity $itemInputObject.Id -EnableException:$EnableException
                    }

                    if ([object]::Equals($groupObject, $null) -or [object]::Equals($groupObject.AssignedLicenses, $null) -or $groupObject.AssignedLicenses.Count -eq 0) {
                        continue
                    }

                    foreach ($assignedLicense in @($groupObject.AssignedLicenses)) {
                        if ($null -eq $assignedLicense) {
                            continue
                        }
                        ConvertFrom-GroupLicenseDetailSubscriptionSku -LicenseDetail $assignedLicense
                    }
                }
            }
            'Identity' {
                foreach ($group in $Identity) {
                    $groupObject = Get-PSEntraIDGroup -Identity $group -EnableException:$EnableException

                    if ([object]::Equals($groupObject, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $group)
                        }
                        continue
                    }

                    if ([object]::Equals($groupObject.AssignedLicenses, $null) -or $groupObject.AssignedLicenses.Count -eq 0) {
                        continue
                    }

                    foreach ($assignedLicense in @($groupObject.AssignedLicenses)) {
                        if ($null -eq $assignedLicense) {
                            continue
                        }
                        ConvertFrom-GroupLicenseDetailSubscriptionSku -LicenseDetail $assignedLicense
                    }
                }
            }
        }
    }

    end {}
}