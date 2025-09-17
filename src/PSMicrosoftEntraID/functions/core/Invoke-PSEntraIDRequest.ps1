function Invoke-PSEntraIDRequest {
    <#
    .SYNOPSIS
        Executes a web request against an Entra-based service.

    .DESCRIPTION
        Executes a web request against an Entra-based service.
        Handles authentication details once connected using Connect-EntraService.

    .PARAMETER Path
        The relative path of the endpoint to query.
        For example, to retrieve Microsoft Graph users, use "users".
        To access details on a specific Defender for Endpoint machine, use "machines/{id}".

    .PARAMETER Body
        The body content to include in the request.

    .PARAMETER Query
        The query parameters to append to the request URL.
        Typically used for filtering or additional request parameters.

    .PARAMETER Method
        The HTTP method to use (e.g., GET, POST, PUT, DELETE).
        Defaults to "GET".

    .PARAMETER RequiredScopes
        The authentication scopes required for the request.
        Used for documentation purposes only.

    .PARAMETER Header
        Additional headers to include in the request, beyond authentication and content-type.

    .PARAMETER Service
        The service to execute the request against.
        Determines the API base URL.
        Defaults to "Graph".

    .PARAMETER SerializationDepth
        Specifies how deeply to serialize the request body when converting it to JSON.
        Defaults to 99.

    .PARAMETER Token
        A token object created and maintained by this module.
        If specified, overrides the -Service parameter.

    .PARAMETER NoPaging
        If specified, disables automatic paging of result sets.
        By default, the cmdlet retrieves all available pages of results.

    .PARAMETER Raw
        If specified, returns the raw API response without additional processing.

        .PARAMETER EnableException
        This parameter disables user-friendly warnings and enables the throwing of exceptions.
        Less user friendly, but allows catching exceptions in calling scripts.

    .PARAMETER Force
        The Force switch instructs the command to stop processing before any changes are made
        and prompt for confirmation (depending on your logic in the code).
        When used, you can step through changes to ensure only specific objects are modified.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        The Confirm switch instructs the command to stop processing before any changes are made.
        The command then prompts you to acknowledge each action before it continues.
        This functionality is useful when you apply changes to many objects
        and want precise control over the operation of the Shell.

    .EXAMPLE
        PS C:\> Invoke-PSEntraIDRequest -Path 'alerts' -RequiredScopes 'Alert.Read'

        Returns a list of Defender alerts.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    [OutputType([pscustomobject])]
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Path,
        [Parameter()]
        [object]  # <- DOPLNĚNO: protože Body může být jakýkoliv objekt (pscustomobject, string, apod.)
        $Body,
        [Parameter()]
        [hashtable]
        $Query = @{},
        [Parameter()]
        [string]
        $Method = 'GET',
        [Parameter()]
        [string[]]
        $RequiredScopes,
        [Parameter()]
        [hashtable]
        $Header = @{},
        [Parameter()]
        [ArgumentCompleter({ Get-ServiceCompletion $args })]
        [ValidateScript({ Assert-ServiceName -Name $_ -IncludeTokens })]
        [string]
        $Service = $script:_DefaultService,
        [Parameter()]
        [ValidateRange(1, 666)]
        [int]
        $SerializationDepth = 99,
        [Parameter()]
        [EntraToken]
        $Token,
        [Parameter()]
        [switch]
        $NoPaging,
        [Parameter()]
        [switch]
        $Raw,
        [Parameter()]
        [switch] $EnableException,
        [Parameter()]
        [switch] $Force
    )

    begin {
        [string] $service = Get-PSFConfigValue -FullName ('{0}.Settings.DefaultService' -f $script:ModuleName)
        Assert-EntraConnection -Service $service -Cmdlet $PSCmdlet
        $param = $PSBoundParameters | ConvertTo-PSFHashtable -ReferenceCommand Invoke-EntraRequest
        [int] $commandRetryCount = Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryCount' -f $script:ModuleName)
        [TimeSpan] $commandRetryWait = New-TimeSpan -Seconds (Get-PSFConfigValue -FullName ('{0}.Settings.Command.RetryWaitInSeconds' -f $script:ModuleName))

        if ($Force.IsPresent -and (-not $Confirm.IsPresent)) {
            [bool] $cmdLetConfirm = $false
        }
        else {
            [bool] $cmdLetConfirm = $true
        }
    }

    process {
        Invoke-PSFProtectedCommand -ActionString 'Request.Invoke' -ActionStringValues $Path -Target (Get-PSFLocalizedString -Module $script:ModuleName -Name Identity.Platform) -ScriptBlock {
            Invoke-EntraRequest @param -Service $service -ErrorAction Stop
        } -EnableException $EnableException -Confirm:$cmdLetConfirm -PSCmdlet $PSCmdlet -Continue -RetryCount $commandRetryCount -RetryWait $commandRetryWait
        if (Test-PSFFunctionInterrupt) { return }
    }

    end {

    }
}
