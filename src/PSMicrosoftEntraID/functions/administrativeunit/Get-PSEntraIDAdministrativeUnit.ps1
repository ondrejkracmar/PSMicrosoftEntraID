function Get-PSEntraIDAdministrativeUnit {
    <#
        .SYNOPSIS
            Get the properties of the specified administrative unit.

        .DESCRIPTION
            Get the properties of the specified administrative unit.

        .PARAMETER Identity
            DisplayName or Id of the administrative unit attribute populated in tenant/directory.

        .PARAMETER DisplayName
            DisplayName of the administrative unit attribute populated in tenant/directory.

        .PARAMETER Filter
            Filter expressions of administrative units in tenant/directory.

        .PARAMETER AdvancedFilter
            Switch advanced filter for filtering administrative units in tenant/directory.

        .PARAMETER All
            Return all administrative units in tenant/directory.

        .PARAMETER EnableException
            This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
            but allows catching exceptions in calling scripts.

        .EXAMPLE
            PS C:\> Get-PSEntraIDAdministrativeUnit -Identity "Marketing AU"

            Get properties of administrative unit "Marketing AU"

        .EXAMPLE
            PS C:\> Get-PSEntraIDAdministrativeUnit -All

            Get all administrative units in the tenant

        .EXAMPLE
            PS C:\> Get-PSEntraIDAdministrativeUnit -Filter "displayName eq 'Marketing AU'"

            Get administrative units using OData filter

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
    [OutputType('PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "AdministrativeUnitId")]
        [ValidateNotNullOrEmpty()]
        [string[]] $Identity,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'DisplayName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $DisplayName,
        [Parameter(Mandatory = $True, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter(Mandatory = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch] $AdvancedFilter,
        [Parameter(Mandatory = $True, ParameterSetName = 'All')]
        [switch] $All,
        [Parameter()]
        [switch] $EnableException
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.AdministrativeUnit).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [string] $path = 'directory/administrativeUnits'
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($administrativeUnit in $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Get' -ActionStringValues $administrativeUnit -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        # -Identity promises "DisplayName or Id", but only an id may go
                        # into the URL path - Graph answers 400 'Invalid object
                        # identifier' for anything else, deterministically. A name is
                        # resolved to its id first, the way Get-PSEntraIDUser resolves a
                        # mail address. Every other administrative-unit cmdlet resolves
                        # its -Identity through this one, so before this fix the whole
                        # family only ever worked with GUIDs.
                        if ($administrativeUnit -as [guid]) {
                            [string] $administrativeUnitId = $administrativeUnit
                        }
                        else {
                            [hashtable] $nameQuery = @{
                                '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                                '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.AdministrativeUnit).Value -join ',')
                                '$filter' = ("displayName eq '{0}'" -f (ConvertTo-ODataFilterString -Value $administrativeUnit))
                            }
                            [PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit[]] $unitByName = ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $nameQuery -Method Get -ErrorAction Stop)
                            # Null AND empty: an empty result binds as a zero-length
                            # array, which is not null - indexing it under StrictMode
                            # throws instead of falling back.
                            if (-not([object]::Equals($unitByName, $null)) -and $unitByName.Length -gt 0) {
                                [string] $administrativeUnitId = $unitByName[0].Id
                            }
                            else {
                                [string] $administrativeUnitId = $administrativeUnit
                            }
                        }
                        # Escaped because the fallback above can put caller input into
                        # the URL path - see the same rule in Get-PSEntraIDUser.
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path ('{0}/{1}' -f $path, [uri]::EscapeDataString($administrativeUnitId)) -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'DisplayName' {
                foreach ($name in $DisplayName) {
                    $query['$filter'] = ("startswith(displayName,'{0}')" -f (ConvertTo-ODataFilterString -Value $name))
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Get' -ActionStringValues $name -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Filter' {
                $query['$filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    [hashtable] $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Method Get -Header $header -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                }
                if (Test-PSFFunctionInterrupt) { return }
            }
            'All' {
                if ($All.IsPresent) {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path $path -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }

    end {}
}
