function Get-PSEntraIDAdministrativeUnitMember {
    <#
    .SYNOPSIS
        Get members of an administrative unit.

    .DESCRIPTION
        This cmdlet gets members of an administrative unit. Administrative units can contain users, groups, and devices as members.

    .PARAMETER InputObject
        PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit object in tenant/directory.

    .PARAMETER Identity
        DisplayName or Id of the administrative unit.

    .PARAMETER Filter
        Filter expressions for members in the administrative unit.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering members in the administrative unit.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDAdministrativeUnitMember -Identity "Marketing AU"

        Get members of administrative unit "Marketing AU"

    .EXAMPLE
        PS C:\> Get-PSEntraIDAdministrativeUnit -DisplayName "Finance AU" | Get-PSEntraIDAdministrativeUnitMember

        Get members of administrative unit "Finance AU" using pipeline

    .EXAMPLE
        PS C:\> Get-PSEntraIDAdministrativeUnitMember -Identity "HR AU" -Filter "displayName startswith 'John'"

        Get members of administrative unit "HR AU" where display name starts with 'John'

    .NOTES
        Piping into Select-Object -First N logs a warning that is not a failure:

            WARNING: [<cmdlet>] Failed to: ... | The pipeline has been stopped

        The results are correct and complete. Select-Object stops the pipeline once it
        has what it asked for, and the next write throws PipelineStoppedException -
        normal termination, reported as an error only because the write happens inside a
        protected block. Materialise first if the warning is in the way:

            $items = @(<cmdlet> ...)
            $items | Select-Object -First 3

        or filter server-side with -Filter instead of trimming client-side. Not silenced
        on purpose: the only fix that works is to collect the whole result before
        emitting any of it, which would cost streaming on every read.

#>
    [OutputType('PSMicrosoftEntraID.Users.User')]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ParameterSetName = 'InputObject')]
        [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit[]]$InputObject,
        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'Identity')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,
        [Parameter(Mandatory = $False, ParameterSetName = 'InputObject')]
        [Parameter(Mandatory = $False, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter(Mandatory = $False, ParameterSetName = 'InputObject')]
        [Parameter(Mandatory = $False, ParameterSetName = 'Identity')]
        [switch] $AdvancedFilter,
        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = 'directory/administrativeUnits'
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'InputObject' {
                foreach ($administrativeUnit in $InputObject) {
                    if ($PSBoundParameters.ContainsKey('Filter')) {
                        $query['$filter'] = $Filter
                    }
                    if ($AdvancedFilter.IsPresent) {
                        [hashtable] $header = @{}
                        $header['ConsistencyLevel'] = 'eventual'
                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.List' -ActionStringValues $administrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('{0}/{1}/members' -f $path, $administrativeUnit.Id) -Query $query -Method Get -Header $header -ErrorAction Stop)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.List' -ActionStringValues $administrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('{0}/{1}/members' -f $path, $administrativeUnit.Id) -Query $query -Method Get -ErrorAction Stop)
                        } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    }
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Identity' {
                foreach ($administrativeUnit in $Identity) {
                    [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit] $aADAdministrativeUnit = Get-PSEntraIDAdministrativeUnit -Identity $administrativeUnit
                    if ([object]::Equals($aADAdministrativeUnit, $null)) {
                        if ($EnableException.IsPresent) {
                            Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name AdministrativeUnit.Get.Failed) -f $administrativeUnit)
                        }
                    }
                    else {
                        if ($PSBoundParameters.ContainsKey('Filter')) {
                            $query['$filter'] = $Filter
                        }

                        if ($AdvancedFilter.IsPresent) {
                            [hashtable] $header = @{}
                            $header['ConsistencyLevel'] = 'eventual'
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.List' -ActionStringValues $aADAdministrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('{0}/{1}/members' -f $path, $aADAdministrativeUnit.Id) -Query $query -Method Get -Header $header -ErrorAction Stop)
                            } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        }
                        else {
                            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnitMember.List' -ActionStringValues $aADAdministrativeUnit.DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                                ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('{0}/{1}/members' -f $path, $aADAdministrativeUnit.Id) -Query $query -Method Get -ErrorAction Stop)
                            } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                        }
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
        }
    }

    end {}
}
