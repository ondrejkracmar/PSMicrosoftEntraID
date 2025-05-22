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
        [Parameter()]
        [switch] $EnableException
    )
    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [hashtable] $query = @{
            '$count'  = 'true'
            '$top'    = Get-PSFConfigValue -FullName ('{0}.Settings.GraphApiQuery.PageSize' -f $script:ModuleName)
            '$select' = ((Get-PSFConfig -Module $script:ModuleName -Name Settings.GraphApiQuery.Select.Organization).Value -join ',')
        }
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Verbose')) {
            [boolean] $cmdLetVerbose = $true
        }
        else {
            [boolean] $cmdLetVerbose = $false
        }
    }
    process {
        Invoke-PSFProtectedCommand -ActionString 'Organization.Get' -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            [string] $jsonString = Invoke-EntraRequest -Service $service -Path organization -Query $query -Method Get -Verbose:$($cmdLetVerbose) -ErrorAction Stop | ConvertTo-Json -Depth 4
            [byte[]] $byteArray = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
            [System.IO.MemoryStream] $stream = [System.IO.MemoryStream]::new($byteArray)
            [System.Runtime.Serialization.Json.DataContractJsonSerializer] $serializer = [System.Runtime.Serialization.Json.DataContractJsonSerializer]::new([PSMicrosoftEntraID.Organization.OrganizationDetail])
            $serializer.ReadObject($stream)
        } -EnableException $EnableException -Continue -PSCmdlet $PSCmdlet -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }
    end
    {}
}