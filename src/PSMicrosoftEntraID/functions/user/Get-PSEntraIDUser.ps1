function Get-PSEntraIDUser {
    <#
    .SYNOPSIS
        Get the properties of the specified user.

    .DESCRIPTION
        Get the properties of the specified user.

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER Name
        DIsplayName, GivenName, SureName of the user attribute populated in tenant/directory.

    .PARAMETER CompanyName
        CompanyName of the user attribute populated in tenant/directory.

    .PARAMETER Disabled
        Return disabled accounts in tenant/directory.

    .PARAMETER Filter
        Filter expressions of accounts in tenant/directory.

    .PARAMETER AdvancedFilter
        Switch advanced filter for filtering accounts in tenant/directory.

    .PARAMETER All
        Return all accounts in tenant/directory.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .EXAMPLE
        PS C:\> Get-PSEntraIDUser -Identity user1@contoso.com

		Get properties of Azure AD user user1@contoso.com

#>
    [OutputType('PSMicrosoftEntraID.Users.User')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]] $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Name,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CompanyName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $CompanyName,
        [Parameter(Mandatory = $false, ParameterSetName = 'CompanyName')]
        [Parameter(Mandatory = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch] $Disabled,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string] $Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch] $AdvancedFilter,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
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
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else{
            [boolean] $cmdLetVerbose =  $false
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($user in $Identity) {
                    [hashtable] $mailQuery = @{
                        #'$count'  = 'true'
                        '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.User).Value -join ',')
                    }
                    $mailQuery['$Filter'] = ("mail eq '{0}'" -f $user)
                    Invoke-PSFProtectedCommand -ActionString 'User.Get' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        [PSMicrosoftEntraID.Users.User[]] $userMail = ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $mailQuery -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        if (-not([object]::Equals($userMail, $null))) {
                            [string] $userId = $userMail[0].Id

                        }
                        else {
                            [string] $userId = $user
                        }
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users/{0}' -f $userId) -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                }
            }
            'Name' {
                foreach ($user in $Name) {
                    $query['$Filter'] = ("startswith(displayName,'{0}') or startswith(givenName,'{0}') or startswith(surName,'{0}')" -f $User)
                    Invoke-PSFProtectedCommand -ActionString 'User.Name' -ActionStringValues $user -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Filter' {
                $query['$Filter'] = $Filter
                if ($AdvancedFilter.IsPresent) {
                    [hashtable] $header = @{}
                    $header['ConsistencyLevel'] = 'eventual'
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Header $header -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
                else {
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'CompanyName' {
                [hashtable] $header = @{}
                $header['ConsistencyLevel'] = 'eventual'
                if (Test-PSFPowerShell -PSMinVersion 7.0) {
                    [string] $companyNameList = ($CompanyName | Join-String -SingleQuote -Separator ',')
                }
                else {
                    [string] $companyNameList = ($CompanyName | ForEach-Object { "'{0}'" -f $_ }) -join ','
                }
                if ($Disabled.IsPresent) {
                    $query['$Filter'] = 'companyName in ({0}) and accountEnabled eq false' -f $companyNameList
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues ('companyName in ({0}) and accountEnabled eq false' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
                else {
                    $query['$Filter'] = 'companyName in ({0})' -f $companyNameList
                    Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues ('companyName in ({0})' -f $companyNameList) -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'All' {
                if ($All.IsPresent) {
                    if ($Disabled.IsPresent) {
                        [hashtable] $header = @{}
                        $header['ConsistencyLevel'] = 'eventual'
                        $query['$Filter'] = "accountEnabled eq false"
                        Invoke-PSFProtectedCommand -ActionString 'User.Filter' -ActionStringValues 'accountEnabled eq false' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Header $header -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    }
                    else {
                        Invoke-PSFProtectedCommand -ActionString 'User.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                            ConvertFrom-RestUser -InputObject (Invoke-EntraRequest -Service $service -Path ('users') -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop)
                        } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                        if (Test-PSFFunctionInterrupt) { return }
                    }
                }
            }
        }
    }
    end {}
}