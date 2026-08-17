function New-PSEntraIDAdministrativeUnit {
    <#
    .SYNOPSIS
        Create new administrative unit in Microsoft Entra ID (Azure AD).

    .DESCRIPTION
        Create new administrative unit in Microsoft Entra ID (Azure AD). Administrative units restrict permissions
        in a role to any portion of your organization that you define.

    .PARAMETER DisplayName
        The display name for the administrative unit.

    .PARAMETER Description
        The description for the administrative unit.

    .PARAMETER Visibility
        Controls whether the administrative unit and its members are hidden or public.
        Can be set to HiddenMembership or Public. If not set, the default behavior is Public.

    .PARAMETER IsMemberManagementRestricted
        Indicates whether the management of members in this administrative unit is restricted to administrators.
        Default is false.

    .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        Suppresses the confirmation prompt, for unattended use.

        An explicitly bound -Confirm wins over it, whatever its value: -Confirm:$true
        prompts even with -Force present. The two are therefore alternatives rather
        than a pair - passing both says nothing the second one does not already say.

        Without either, whether the command prompts is left to its ConfirmImpact and
        the session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Bound explicitly it wins over -Force, whatever its value - so -Confirm:$true
        prompts even alongside -Force, and the two are alternatives rather than a pair.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .PARAMETER PassThru
        When specified, the cmdlet will not execute the delete action but will instead
        return a `PSMicrosoftEntraID.Batch.Request` object for batch processing.

    .EXAMPLE
        PS C:\> New-PSEntraIDAdministrativeUnit -DisplayName "Marketing Department" -Description "Marketing team administrative unit"

        Create a new administrative unit for the Marketing Department

    .EXAMPLE
        PS C:\> New-PSEntraIDAdministrativeUnit -DisplayName "Finance AU" -Description "Finance administrative unit" -Visibility "HiddenMembership"

        Create a new administrative unit with hidden membership

    .NOTES
        Administrative units provide a way to subdivide your organization and delegate administrative permissions
        to those subdivisions.

    #>
    [OutputType('PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit', [PSMicrosoftEntraID.Batch.Request])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DisplayName,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string] $Description,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('HiddenMembership', 'Public')]
        [string] $Visibility,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [bool] $IsMemberManagementRestricted = $false,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force,
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [System.TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))
        [hashtable] $header = @{
            'Content-Type' = 'application/json'
        }
        [hashtable] $cmdLetConfirm = Resolve-PSEntraIDConfirmPreference -BoundParameters $PSBoundParameters -Force:$Force -Confirm:$Confirm
        [string] $path = "directory/administrativeUnits"
    }

    process {
        [hashtable] $body = @{
            'displayName'                  = $DisplayName
            'isMemberManagementRestricted' = $IsMemberManagementRestricted
        }

        if ($PSBoundParameters.ContainsKey('Description')) {
            $body['description'] = $Description
        }

        if ($PSBoundParameters.ContainsKey('Visibility')) {
            $body['visibility'] = $Visibility
        }


        if ($PassThru.IsPresent) {
            [PSMicrosoftEntraID.Batch.Request]@{
                Method  = 'POST'
                Url     = ('/{0}' -f $path)
                Body    = $body
                Headers = $header
            }
        }
        else {
            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Create' -ActionStringValues $DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                [void] (Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop)

            } -EnableException:$EnableException @cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    end {}
}
