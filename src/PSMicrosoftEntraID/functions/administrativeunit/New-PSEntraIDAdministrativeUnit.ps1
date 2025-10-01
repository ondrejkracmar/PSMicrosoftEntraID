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
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user friendly,
        but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Force
        The Force switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Force switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

    .PARAMETER Confirm
        The Confirm switch instructs the command to which it is applied to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        When you use the Confirm switch, you can step through changes to objects to make sure that changes are made only to the specific objects that you want to change.
        This functionality is useful when you apply changes to many objects and want precise control over the operation of the Shell.
        A confirmation prompt is displayed for each object before the Shell modifies the object.

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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit')]
    [CmdletBinding(SupportsShouldProcess = $true)]
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
    }

    process {
        [hashtable] $body = @{
            'displayName' = $DisplayName
            'isMemberManagementRestricted' = $IsMemberManagementRestricted
        }

        if ($PSBoundParameters.ContainsKey('Description')) {
            $body['description'] = $Description
        }

        if ($PSBoundParameters.ContainsKey('Visibility')) {
            $body['visibility'] = $Visibility
        }

        [string] $path = "administrativeUnits"
        
        if ($PassThru.IsPresent) {
            [PSMicrosoftEntraID.Batch.Request]@{ 
                Method = 'POST'
                Url = ('/{0}' -f $path)
                Body = $body
                Headers = $header 
            }
        }
        else {
            Invoke-PSFProtectedCommand -ActionString 'AdministrativeUnit.Create' -ActionStringValues $DisplayName -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
                $result = Invoke-EntraRequest -Service $service -Path $path -Header $header -Body $body -Method Post -ErrorAction Stop
                $result
            } -EnableException $EnableException -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
            if (Test-PSFFunctionInterrupt) { return }
        }
    }

    end {}
}
