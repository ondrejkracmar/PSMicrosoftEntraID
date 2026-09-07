BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Graph $select property lists' -Tag 'Unit' {

    # A $select naming a property the resource does not have is not a soft error:
    # Graph answers Request_UnsupportedQuery ("Invalid property: ...") and the WHOLE
    # read fails. That is how 'createdDateTime' in the administrativeUnit list took
    # down the AU delta leg of a production inventory sync, so the shipped defaults
    # are asserted here rather than mocked away in the per-cmdlet tests.

    It 'never selects createdDateTime on administrativeUnit - the resource has none' {
        $value = @((Get-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.AdministrativeUnit').Value)
        $value | Should -Not -Contain 'createdDateTime'
    }

    It 'selects only real administrativeUnit properties' {
        # Microsoft Graph v1.0 administrativeUnit resource.
        $known = @('id', 'deletedDateTime', 'displayName', 'description', 'isMemberManagementRestricted',
                   'visibility', 'membershipType', 'membershipRule', 'membershipRuleProcessingState')
        $value = @((Get-PSFConfig -Module $script:ModuleName -Name 'Settings.GraphApiQuery.Select.AdministrativeUnit').Value)
        $value | Should -Not -BeNullOrEmpty
        @($value | Where-Object { $_ -notin $known }) | Should -BeNullOrEmpty
        $value | Should -Contain 'id'
        $value | Should -Contain 'displayName'
    }
}
