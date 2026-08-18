function Get-PSEntraIDContact {
    <#
.SYNOPSIS
    Get the properties of the specified organizational contact.

.DESCRIPTION
    Get the properties of the specified contact from Microsoft Entra ID (Microsoft Graph orgContact entity).
    Requires delegated Graph permission: OrgContact.Read.Alll

.PARAMETER Identity
    Mail or Id of the contact.

.PARAMETER Name
    DisplayName, GivenName, or Surname of the contact.

.PARAMETER CompanyName
    Filter by company name.

.PARAMETER Filter
    Raw filter expression for Graph API.

.PARAMETER All
    Get all contacts in directory.

.PARAMETER EnableException
    Enables exception throwing for error handling in scripts.

.EXAMPLE
    Get-PSEntraIDContact -Identity "contact1@contoso.com"

    Returns the contact whose mail or id matches "contact1@contoso.com".
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
    [OutputType('PSMicrosoftEntraID.Contacts.Contact')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters consumed inside Where-Object script blocks or reserved as part of the public parameter surface.')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "Mail")]
        [string[]] $Identity,

        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [string[]] $Name,

        [Parameter(Mandatory = $true, ParameterSetName = 'CompanyName')]
        [string[]] $CompanyName,

        [Parameter(Mandatory = $true, ParameterSetName = 'Filter')]
        [string] $Filter,

        [Parameter(Mandatory = $true, ParameterSetName = 'All')]
        [switch] $All,

        [Parameter()]
        [switch] $EnableException
    )

    begin {
        $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet

        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Contact).Value -join ',')
        }

        $header = @{ 'ConsistencyLevel' = 'eventual' }
        $retryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $retryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($contact in $Identity) {
                    # Escape: -Identity is a free string, so an apostrophe in a name
                    # (O'Brien) breaks the filter, and worse can be used to rewrite it.
                    # Every other filter in the module goes through this helper.
                    $query['$filter'] = "mail eq '{0}'" -f (ConvertTo-ODataFilterString -Value $contact)
                    Invoke-PSFProtectedCommand -ActionString 'Contact.Get' -ActionStringValues $contact -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }

            'Name' {
                foreach ($contact in $Name) {
                    $contactEscaped = ConvertTo-ODataFilterString -Value $contact
                    $query['$filter'] = "startswith(displayName,'{0}') or startswith(givenName,'{0}') or startswith(surname,'{0}')" -f $contactEscaped
                    Invoke-PSFProtectedCommand -ActionString 'Contact.Name' -ActionStringValues $contact -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }

            'CompanyName' {
                $filterString = "companyName in ({0})" -f ($CompanyName | ForEach-Object { "'{0}'" -f (ConvertTo-ODataFilterString -Value $_) } | Join-String -Separator ',')
                $query['$filter'] = $filterString
                Invoke-PSFProtectedCommand -ActionString 'Contact.Filter' -ActionStringValues $CompanyName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Header $header -Method Get -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                if (Test-PSFFunctionInterrupt) { return }
            }

            'Filter' {
                $query['$filter'] = $Filter
                Invoke-PSFProtectedCommand -ActionString 'Contact.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Header $header -Method Get -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                if (Test-PSFFunctionInterrupt) { return }
            }

            'All' {
                Invoke-PSFProtectedCommand -ActionString 'Contact.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
        }
    }

    end {}
}
