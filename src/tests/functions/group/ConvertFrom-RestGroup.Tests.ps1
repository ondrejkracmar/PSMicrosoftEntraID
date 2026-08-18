BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

# Regression coverage for a typo that lived in FOUR places at once: the C# contract said
# [DataMember(Name = "gropupTypes")], the $select configuration asked Graph for
# 'gropupTypes', and the type and format files displayed 'GropupTypes'. Each layer was
# consistent with the others, so nothing errored anywhere - Graph silently ignores an
# unknown $select property - and GroupTypes was simply always empty. Only a live tenant
# read of a group that HAS types could have caught it, and the delta scenario's request
# log is what did.
Describe 'ConvertFrom-RestGroup' -Tag 'Unit' {

    It 'maps groupTypes - the field Graph actually sends - onto GroupTypes' {
        InModuleScope PSMicrosoftEntraID {
            $rest = [PSCustomObject]@{
                id          = '00000000-0000-0000-0000-000000000001'
                displayName = 'unified group'
                groupTypes  = @('Unified', 'DynamicMembership')
            }

            $group = ConvertFrom-RestGroup -InputObject $rest

            $group.GroupTypes | Should -Be @('Unified', 'DynamicMembership')
        }
    }

    It 'asks Graph for groupTypes in the group select list' {
        # The contract fix alone is not enough: with the typo still in the $select list
        # Graph would never send the field in the first place.
        InModuleScope PSMicrosoftEntraID {
            $select = (Get-PSFConfig -Module PSMicrosoftEntraID -Name Settings.GraphApiQuery.Select.Group).Value
            $select | Should -Contain 'groupTypes'
            $select | Should -Not -Contain 'gropupTypes'
        }
    }
}
