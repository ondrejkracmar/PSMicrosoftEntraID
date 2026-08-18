function New-EntraIdentityFilter {
    <#
    .SYNOPSIS
        Builds the OData clause that filters users on their identities collection.

    .DESCRIPTION
        Composes the lambda Microsoft Graph expects for the identities collection:

            identities/any(i:i/issuer eq '<issuer>' and i/issuerAssignedId eq '<id>')

        Every value goes through ConvertTo-ODataFilterString, so an apostrophe in an
        issuer or a sign-in name cannot break out of the string literal.

        Graph does not support the full cross product here, and the unsupported shapes
        fail by returning nothing rather than by erroring - which reads exactly like
        "no such guest". This function therefore refuses the one shape Graph documents
        as unsupported, and warns about the one that only works for four issuers.

    .PARAMETER Cmdlet
        The $PSCmdlet of the calling command, so a rejected filter terminates in the
        caller's context rather than here.

    .PARAMETER Issuer
        The issuer to match - the home organization's domain for a B2B guest, or a
        provider such as google.com. Required: Graph supports issuerAssignedId and
        signInType only in combination with it.

    .PARAMETER IssuerAssignedId
        The identifier the issuer assigned to the user, typically their sign-in name at
        the home organization.

    .PARAMETER SignInType
        The sign-in type to match, such as federated, userName or emailAddress.
        userPrincipalName is rejected - Graph documents it as unsupported for filtering.

    .EXAMPLE
        PS C:\> New-EntraIdentityFilter -Cmdlet $PSCmdlet -Issuer 'contoso.com' -IssuerAssignedId 'j.smith@contoso.com'

        identities/any(i:i/issuer eq 'contoso.com' and i/issuerAssignedId eq 'j.smith@contoso.com')

    .EXAMPLE
        PS C:\> New-EntraIdentityFilter -Cmdlet $PSCmdlet -Issuer 'google.com'

        identities/any(i:i/issuer eq 'google.com')

        One of the four issuers Graph will match on its own.

    .NOTES
        Internal helper. See
        https://learn.microsoft.com/en-us/graph/api/resources/objectidentity
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds a filter string in memory. The New verb names what it returns; nothing local or remote is changed, so there is nothing to confirm.')]
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Issuer,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $IssuerAssignedId,

        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $SignInType
    )

    # Graph: "Filtering for entries with a signInType of userPrincipalName isn't
    # supported. You can filter on the userPrincipalName property on the user object
    # instead." Left to Graph this returns an empty set, not an error.
    if ($SignInType -and $SignInType -eq 'userPrincipalName') {
        Invoke-TerminatingException -Cmdlet $Cmdlet -Category InvalidArgument -Message (
            Get-PSFLocalizedString -Module $script:ModuleName -Name 'User.Identity.SignInType.Unsupported'
        )
    }

    # Graph: filtering on issuer alone works for these four only. Anything else needs
    # issuerAssignedId as well, and silently matches nothing without it.
    $issuerAloneSupported = @('google.com', 'facebook.com', 'mail', 'phone')
    if (-not $IssuerAssignedId -and $Issuer -notin $issuerAloneSupported) {
        Write-PSFMessage -Level Warning -String 'User.Identity.Issuer.Alone' -StringValues $Issuer, ($issuerAloneSupported -join ', ')
    }

    $clauses = @("i/issuer eq '{0}'" -f (ConvertTo-ODataFilterString -Value $Issuer))

    if ($IssuerAssignedId) {
        $clauses += "i/issuerAssignedId eq '{0}'" -f (ConvertTo-ODataFilterString -Value $IssuerAssignedId)
    }

    if ($SignInType) {
        $clauses += "i/signInType eq '{0}'" -f (ConvertTo-ODataFilterString -Value $SignInType)
    }

    return 'identities/any(i:{0})' -f ($clauses -join ' and ')
}
