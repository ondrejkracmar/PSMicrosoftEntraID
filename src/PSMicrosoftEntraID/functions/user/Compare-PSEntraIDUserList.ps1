function  Compare-PSEntraIDUserList {
    <#
    .SYNOPSIS
        Compare two list user of user.

    .DESCRIPTION
        Compare two list user of user.

    .PARAMETER ReferenceIdentity
        Reference list of users

    .PARAMETER DifferenceIdentity
        Difference list of users

    .EXAMPLE
            PS C:\> Compare-PSEntraIDUserList -ReferenceIdentity $UserList1 -DifferenceIdentity $UserList2

            Remove memebr to Azure AD group group1


#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [OutputType('System.Collections.ArrayList')]
    [CmdletBinding(DefaultParameterSetName = 'UserIdentity')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [string[]] $ReferenceIdentity,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ParameterSetName = 'UserIdentity')]
        [ValidateUserIdentity()]
        [string[]] $DifferenceIdentity
    )

    begin {
        Assert-RestConnection -Service 'graph' -Cmdlet $PSCmdlet
        [System.Collections.ArrayList] $changeUserList = [System.Collections.ArrayList]::New()
    }

    process {
        [System.Object[]] $compareUserList = Compare-Object -ReferenceObject $ReferenceIdentity -DifferenceObject $DifferenceIdentity -IncludeEqual
        foreach ($compareUser in $compareUserList) {
            switch ($compareUser.SideIndicator) {
                '=>' {
                    [pscustomobject] $changeUser = [pscustomobject]@{
                        Crud     = 'Delete'
                        Identity = $compareUser.InputObject
                    }
                    [void] ($changeUserList.Add($changeUser))
                }
                '<=' {
                    [pscustomobject] $changeUser = [pscustomobject]@{
                        Crud     = 'Create'
                        Identity = $compareUser.InputObject
                    }
                    [void]($changeUserList.Add($changeUser))
                }
            }
        }
        $changeUserList
    }
    end {}
}