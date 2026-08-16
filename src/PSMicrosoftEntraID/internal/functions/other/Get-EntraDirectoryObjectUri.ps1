function Get-EntraDirectoryObjectUri {
    <#
    .SYNOPSIS
        Builds the absolute directoryObjects URI Graph expects in an '@odata.id' binding.

    .DESCRIPTION
        Graph's $ref bindings need a fully qualified URI, and it must point at the cloud
        you are actually connected to. This takes the base from the registered service,
        so a tenant in a sovereign cloud - GCC High on graph.microsoft.us, China on
        microsoftgraph.chinacloudapi.cn - gets its own host instead of the commercial one.

        Six call sites used to hard-code https://graph.microsoft.com/v1.0, which quietly
        pointed those bindings at the wrong cloud for anyone who had re-registered the
        service with Register-EntraService -ServiceUrl.

    .PARAMETER Id
        Object id to bind to.

    .PARAMETER Service
        Registered service name whose ServiceUrl forms the base.

    .EXAMPLE
        PS C:\> Get-EntraDirectoryObjectUri -Id $user.Id -Service $service

        https://graph.microsoft.com/v1.0/directoryObjects/<id>
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Id,

        [Parameter(Mandatory = $true)]
        [string] $Service
    )

    $serviceObject = Get-EntraService -Name $Service
    $base = if ($serviceObject -and $serviceObject.ServiceUrl) { ([string]$serviceObject.ServiceUrl).TrimEnd('/') }
    else {
        # A service that is registered but carries no URL should not silently produce a
        # broken binding; fall back to the documented default and say so.
        Write-PSFMessage -Level Warning -String 'DirectoryObject.NoServiceUrl' -StringValues $Service
        'https://graph.microsoft.com/v1.0'
    }

    '{0}/directoryObjects/{1}' -f $base, $Id
}
