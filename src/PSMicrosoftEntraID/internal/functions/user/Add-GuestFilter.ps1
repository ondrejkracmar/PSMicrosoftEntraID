function Add-GuestFilter {
    <#
    .SYNOPSIS
        Ensures that the filter includes the condition "userType eq 'Guest'".

    .DESCRIPTION
        This function checks if the provided OData filter string already contains
        the condition "userType eq 'Guest'". If not, it appends the condition with
        a logical AND. If no filter string is provided, it simply returns
        "userType eq 'Guest'".

    .PARAMETER CurrentFilter
        The existing OData filter string. This may be null or empty.

    .EXAMPLE
        PS C:\> Add-GuestFilter -CurrentFilter "accountEnabled eq false"
        (accountEnabled eq false) and userType eq 'Guest'

        If the filter string does not contain userType eq 'Guest', it gets appended.

    .EXAMPLE
        PS C:\> Add-GuestFilter
        userType eq 'Guest'

        If no filter string is provided, the function just returns userType eq 'Guest'.

    .NOTES
        Author: Your Name
        Last Updated: 2025-03-06
    #>
    param(
        [string] $CurrentFilter
    )

    if ([string]::IsNullOrEmpty($CurrentFilter)) {
        return "userType eq 'Guest'"
    }
    else {
        if ($CurrentFilter -notmatch "userType\s+eq\s+'Guest'") {
            return "($CurrentFilter) and userType eq 'Guest'"
        }
        else {
            return $CurrentFilter
        }
    }
}
