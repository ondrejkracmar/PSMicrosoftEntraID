function Set-PSAADUserUsageLocation {
    <#
    .SYNOPSIS
        Get the properties of the specified user.

    .DESCRIPTION
        Get the properties of the specified user.

    .PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

    .PARAMETER UsageLocationCode
        Azure Active Directory UsageLocation Code.

    .PARAMETER UsageLocationCountry
        The name of the country corresponding to its usagelocation.

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .EXAMPLE
        PS C:\> Set-PSAADUserUsageLocation -Identity user1@contoso.com -UsageLocationCode GB
		Set usage location for Azure AD user user1@contoso.com


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('PSAzureADDirectory.User')]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentityUsageLocationCode')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCode')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCountry')]
        [ValidateIdentity()]
        [string[]]
        [Alias("Id","UserPrincipalName","Mail")]
        $Identity,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName = 'IdentityUsageLocationCode')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCode,
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCountry')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCountry,
        [switch]
        $EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $usageLocationHashtable = Get-Content -Path( Get-PSFConfigValue -FullName PSAzureADDirectory.Template.AzureADDirectory.UsageLocation) | ConvertFrom-Json | ConvertTo-PSFHashtable
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }

    process {
        foreach ($user in $Identity) {
            $aADUser = Get-PSAADUserLicenseServicePlan -Identity $user
            if (-not ([object]::Equals($aADUser, $null))) {
                $path = ("users/{0}/{1}" -f $aADUser.Id, 'assignLicense')

                switch ($PSCmdlet.ParameterSetName) {
                    'IdentityUsageLocationCode' {
                        $usgaeLocationTarget = $usageLocationCode
                        $body = @{
                            usageLocation = $usageLocationCode
                        }
                    }
                    'IdentityUsageLocationCountry' {
                        $usgaeLocationTarget = ($usageLocationHashtable)[$UsageLocationCountry]
                        $body = @{
                            usageLocation = ($usageLocationHashtable)[$UsageLocationCountry]
                        }
                    }
                }
                Invoke-PSFProtectedCommand -ActionString 'User.UsageLocation' -ActionStringValues $usgaeLocationTarget -Target $aADUser.UserPrincipalName -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Patch)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {}
        }
    }
    end {}
}