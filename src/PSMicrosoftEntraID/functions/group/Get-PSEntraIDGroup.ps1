function Get-PSEntraIDGroup {
    <#
        .SYNOPSIS
            Get the properties of the specified group.

        .DESCRIPTION
            Get the properties of the specified group.

        .PARAMETER Identity
            MailnicName, Mail or Id of the group attribute populated in tenant/directory.

        .PARAMETER DisplayName
            DIsplayName of the group attribute populated in tenant/directory.

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
            PS C:\> Get-PSEntraIDGroup -Identity group1

            Get properties of Azure AD group group1


    #>
    [OutputType('PSMicrosoftEntraID.Group')]
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateGroupIdentity()]
        [string[]]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        $Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'DisplayName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DisplayName,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'Filter')]
        [ValidateNotNullOrEmpty()]
        [switch]$AdvancedFilter,
        [Parameter(Mandatory = $True, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()]
        [switch]$All,
        [switch]$EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Identity' {
                foreach ($group in $Identity) {
                    $mailNickNameQuery = @{
                        #'$count'  = 'true'
                        '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
                        '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Group).Value -join ',')
                    }
                    $mailNickNameQuery['$Filter'] = ("mailNickName eq '{0}'" -f $group)

                    Invoke-PSFProtectedCommand -ActionString 'Group.Get' -ActionStringValues $group -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        $mailNickName = Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $mailNickNameQuery -Method Get -ErrorAction Stop | ConvertFrom-RestGroup
                        if (-not([object]::Equals($mailNickName, $null))) {
                            $groupId = $mailNickName[0].Id
                        }
                        else {
                            $groupId = $group
                        }
                        Invoke-RestRequest -Service 'graph' -Path ('groups/{0}' -f $groupId) -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroup
                    } -EnableException $EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'DisplayName' {
                foreach ($group in $DisplayName) {
                    $query['$Filter'] = ("startswith(displayName,'{0}')" -f $group)
                    Invoke-PSFProtectedCommand -ActionString 'Group.Get' -ActionStringValues $group -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroup
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
            'Filter' {
                $query['$Filter'] = $Filter
                Invoke-PSFProtectedCommand -ActionString 'Group.Filter' -ActionStringValues $Filter -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    if ($AdvancedFilter.IsPresent) {
                        $header = @{}
                        $header['ConsistencyLevel'] = 'eventual'
                        Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get -Header $header -ErrorAction Stop | ConvertFrom-RestGroup
                    }
                    else {
                        Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroup
                    }
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            'All' {
                if ($All.IsPresent) {
                    Invoke-PSFProtectedCommand -ActionString 'Group.List' -ActionStringValues 'All' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                        Invoke-RestRequest -Service 'graph' -Path ('groups') -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestGroup
                    } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                    if (Test-PSFFunctionInterrupt) { return }
                }
            }
        }
    }
    end {}
}