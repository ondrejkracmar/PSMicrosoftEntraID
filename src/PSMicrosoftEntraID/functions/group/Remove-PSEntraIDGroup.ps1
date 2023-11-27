function Remove-PSEntraIDGroup {
    <#
	.SYNOPSIS
		Delete group

	.DESCRIPTION
		Delete Azure AD group
        When deleted, group resources are moved to a temporary container and can be restored within 30 days. After that time, they are permanently deleted.

	.PARAMETER Identity
        groupPrincipalName, Mail or Id of the group attribute populated in tenant/directory.

    .PARAMETER EnableException
        This parameters disables group-friendly warnings and enables the throwing of exceptions. This is less group frien
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
		PS C:\> Remove-PSEntraIDGroup -Identity groupname@contoso.com

		Delete group groupname@contoso.com from Azure AD (Entra ID)

	#>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType()]
    [CmdletBinding(SupportsShouldProcess = $true,
        DefaultParameterSetName = 'Identity')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'Identity')]
        [Alias("Id", "GroupId", "TeamId", "MailNickName")]
        [ValidateGroupIdentity()]
        [string[]]$Identity,
        [switch]$EnableException
    )
    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitIsSeconds' -f $script:ModuleName))
    }

    process {
        foreach ($group in $Identity) {
            $aADGroup = Get-PSEntraIDGroup -Identity $group
            if (-not([object]::Equals($aADGroup, $null))) {
                $path = ("groups/{0}" -f $aADGroup.Id)
                Invoke-PSFProtectedCommand -ActionString 'Group.Delete' -ActionStringValues $aADGroup.MailNickname -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                    [void](Invoke-RestRequest -Service 'graph' -Path $path -Method Delete -ErrorAction Stop)
                } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
                if (Test-PSFFunctionInterrupt) { return }
            }
            else {
                if ($EnableException.IsPresent) {
                    Invoke-TerminatingException -Cmdlet $PSCmdlet -Message ((Get-PSFLocalizedString -Module $script:ModuleName -Name Group.Get.Failed) -f $Identity)
                }
            }
        }
    }

    end
    {}
}
