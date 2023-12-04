﻿function Set-PSEntraIDUserUsageLocation {
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

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .EXAMPLE
        PS C:\>Set-PSEntraIDUserUsageLocation -Identity user1@contoso.com -UsageLocationCode GB

		Set usage location for Azure AD user user1@contoso.com


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType(('PSMicrosoftEntraID.User'))]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'IdentityUsageLocationCode')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCode')]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'IdentityUsageLocationCountry')]
        [Alias("Id", "UserPrincipalName", "Mail")]
        [ValidateUserIdentity()]
        [string[]]$Identity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'IdentityUsageLocationCode')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCode,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'IdentityUsageLocationCountry')]
        [ValidateNotNullOrEmpty()]
        [string]$UsageLocationCountry,
        [switch]$EnableException
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $usageLocationTemplate = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'aadtemplate' -ChildPath 'UsageLocation.json' )
        $usageLocationHashtable = Get-Content -Path $usageLocationTemplate | ConvertFrom-Json | ConvertTo-PSFHashtable
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
    }

    process {
        foreach ($user in $Identity) {
            $aADUser = Get-PSEntraIDUserLicenseServicePlan -Identity $user
            if (-not ([object]::Equals($aADUser, $null))) {
                $path = ("users/{0}" -f $aADUser.Id)
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
                    [void](Invoke-RestRequest -Service 'graph' -Path $path -Body $body -Method Patch -ErrorAction Stop)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue #-RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {
                if ($EnableException.IsPresent) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name User.Get.Failed) -f $user)
                }
            }
        }
    }
    end {}
}