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
            This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
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
            '$count' = 'true'
            '$top'   = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($administrativeUnit in $Identity) {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Get' -ActionStringValues $administrativeUnit -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        try {
                            # Try direct lookup by ID first
                            ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path ('administrativeUnits/{0}' -f $administrativeUnit) -Query $query -Method Get -ErrorAction Stop)
                        }
                        catch {
                            if ($_.Exception.Response.StatusCode -eq 404) {
                                # Try to find by displayName if direct lookup failed
                                [hashtable] $displayNameQuery = @{
                                    '$filter' = "displayName eq '{0}'" -f $administrativeUnit.Replace("'", "''")
                                    '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                                }
                                $result = Invoke-EntraRequest -Service $service -Path 'administrativeUnits' -Query $displayNameQuery -Method Get -ErrorAction Stop
                                if ($result.value.Count -eq 0) {
                                    if ($EnableException.IsPresent) {
                                        Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ("Administrative unit '{0}' not found" -f $administrativeUnit)
                                    }
                                }
                                else {
                                    ConvertFrom-RestAdministrativeUnit -InputObject $result.value
                                }
                            }
                            else {
                                throw
                            }
                        }
                    } -EnableException $EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'DisplayName' {
                foreach ($name in $DisplayName) {
                    $query['$filter'] = "displayName eq '{0}'" -f $name.Replace("'", "''")
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Get' -ActionStringValues $name -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $result = Invoke-EntraRequest -Service $service -Path 'administrativeUnits' -Query $query -Method Get -ErrorAction Stop
                        if ($result.value.Count -eq 0) {
                            if ($EnableException.IsPresent) {
                                Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ("Administrative unit with display name '{0}' not found" -f $name)
                            }
                        }
                        else {
                            ConvertFrom-RestAdministrativeUnit -InputObject $result.value
                        }
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Filter' {
                $query['$filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    [hashtable] $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path 'administrativeUnits' -Query $query -Method Get -Header $header -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path 'administrativeUnits' -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                }
                if (Test-PSFFunctionInterrupt) { return }
            }
            'All' {
                if ($All.IsPresent) {
                    Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestAdministrativeUnit -InputObject (Invoke-EntraRequest -Service $service -Path 'administrativeUnits' -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait -WhatIf:$false
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }

    end {}
}
