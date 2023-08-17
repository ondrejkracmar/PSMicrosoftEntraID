﻿function Remove-PSAADUser {
    <#
	.SYNOPSIS
		Delete user

	.DESCRIPTION
		Delete Azure AD user
        When deleted, user resources are moved to a temporary container and can be restored within 30 days. After that time, they are permanently deleted.

	.PARAMETER Identity
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

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
		PS C:\> Remove-PSAADUser -Identity username@contoso.com

		Delete user user username@contoso.com from Azure AD (Entra ID)

	#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [ValidateIdentity()]
        [string[]]
        [Alias("Id", "UserPrincipalName", "Mail")]
        $Identity
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryCount'
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName 'PSAzureADDirectory.Settings.Command.RetryWaitIsSeconds')
    }

    process {
        foreach ($user in $Identity) {
            $aADUser = Get-PSAADUser -Identity $user
            $path = ("users/{0}" -f $aADUser.Id)
            Invoke-PSFProtectedCommand -ActionString 'User.Delete' -ActionStringValues $aADUser.UserPrincipalName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                [void](Invoke-RestRequest -Service 'graph' -Path $path -Method Delete)
            } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    end
    {}
}