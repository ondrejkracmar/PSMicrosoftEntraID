function Get-PSEntraIDContact {
<#
.SYNOPSIS
    Get the properties of the specified organizational contact.

.DESCRIPTION
    Get the properties of the specified contact from Microsoft Entra ID (Microsoft Graph orgContact entity).
    Requires delegated Graph permission: OrgContact.Read.Al

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
#>
    [OutputType('PSMicrosoftEntraID.Contacts.Contact')]
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
        $cmdLetVerbose = $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($contact in $Identity) {
                    $query['$filter'] = "mail eq '$contact'"
                    Invoke-PSFProtectedCommand -ActionString 'Contact.Get' -ActionStringValues $contact -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                }
            }

            'Name' {
                foreach ($contact in $Name) {
                    $query['$filter'] = "startswith(displayName,'$contact') or startswith(givenName,'$contact') or startswith(surname,'$contact')"
                    Invoke-PSFProtectedCommand -ActionString 'Contact.Name' -ActionStringValues $contact -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop)
                    } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
                }
            }

            'CompanyName' {
                $filterString = "companyName in ({0})" -f ($CompanyName | ForEach-Object { "'$_'" } -join ',')
                $query['$filter'] = $filterString
                Invoke-PSFProtectedCommand -ActionString 'Contact.Filter' -ActionStringValues $CompanyName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Header $header -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
            }

            'Filter' {
                $query['$filter'] = $Filter
                Invoke-PSFProtectedCommand -ActionString 'Contact.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Header $header -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
            }

            'All' {
                Invoke-PSFProtectedCommand -ActionString 'Contact.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    ConvertFrom-RestContact -InputObject (Invoke-EntraRequest -Service $service -Path 'contacts' -Query $query -Method Get -Verbose:$cmdLetVerbose -ErrorAction Stop)
                } -EnableException:$EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $retryCount -RetryWait $retryWait
            }
        }
    }

    end {}
}
