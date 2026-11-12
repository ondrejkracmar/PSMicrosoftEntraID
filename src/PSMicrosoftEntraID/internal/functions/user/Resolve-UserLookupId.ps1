function Resolve-UserLookupId {
    <#
    .SYNOPSIS
        Resolves a user identity to the value read from users/{0}: object id, then userPrincipalName, then mail.

    .DESCRIPTION
        An object id is returned as it is. Anything else is looked up by userPrincipalName
        first and by mail only when no UPN matches; when neither matches, the identity
        itself is returned so the direct read reports the failure.

        The order matters: the mail lookup used to run first, and when user B's mail equals
        user A's userPrincipalName (a renamed account, a shared alias) a request for A
        returned B.

        Errors are not handled here: the caller runs this inside its protected command.

    .PARAMETER Identity
        Object id, userPrincipalName or mail of the user.

    .PARAMETER Service
        The Entra service to query.

    .EXAMPLE
        PS C:\> $userId = Resolve-UserLookupId -Identity 'john@contoso.com' -Service $service

        Returns the object id of the user whose UPN, or else whose mail, is john@contoso.com.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string] $Identity,
        [Parameter(Mandatory = $true)]
        [string] $Service
    )

    if ($Identity -match '^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$') {
        return $Identity.Trim('{', '}')
    }
    foreach ($propertyName in 'userPrincipalName', 'mail') {
        [hashtable] $lookupQuery = @{
            '$select' = 'id'
            '$Filter' = ("{0} eq '{1}'" -f $propertyName, (ConvertTo-ODataFilterString -Value $Identity))
        }
        $match = @(Invoke-EntraRequest -Service $Service -Path 'users' -Query $lookupQuery -Method Get -ErrorAction Stop | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace($_.id) })[0]
        if (-not [object]::Equals($match, $null)) {
            return [string] $match.id
        }
    }
    $Identity
}
