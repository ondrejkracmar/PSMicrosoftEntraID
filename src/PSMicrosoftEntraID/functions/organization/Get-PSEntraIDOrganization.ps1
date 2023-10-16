function Get-PSEntraIDOrganization {
    <#
	.SYNOPSIS
		Get the properties and relationships of the currently authenticated organization.

	.DESCRIPTION
		Get the properties and relationships of the currently authenticated organization.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

	.EXAMPLE
		PS C:\> Get-PSEntraIDOrganization

		Get collection of EntraID organization

	#>
    [OutputType('PSMicrosoftEntraID.Organization')]
    [CmdletBinding()]
    param (
        [switch]$EnableException
    )
    begin {
        Assert-RestConnection -Service graph -Cmdlet $PSCmdlet
        $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Organization).Value -join ',')
        }
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
    }
    process {
        Invoke-PSFProtectedCommand -ActionString 'Organization.Get' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            Invoke-RestRequest -Service 'graph' -Path organization -Query $query -Method Get -ErrorAction Stop | ConvertFrom-RestOrganization
        } -EnableException $EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait
    }
    end
    {}
}