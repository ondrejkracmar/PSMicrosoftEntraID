BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'ConvertFrom-RestDelta' -Tag 'Unit' {

    BeforeAll {
        function script:New-DeltaResponse {
            param([object[]] $Value)
            [pscustomobject]@{ value = $Value }
        }
    }

    Context 'Change type' {

        It 'treats the absence of an annotation as Changed' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @([pscustomobject]@{ id = 'u1'; userPrincipalName = 'a@x.test' }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))

                $result.Count | Should -Be 1
                $result[0].ChangeType | Should -Be 'Changed'
                $result[0].Removed | Should -BeFalse
                $result[0].UserPrincipalName | Should -Be 'a@x.test'
            }
        }

        It "maps @removed reason 'changed' to Deleted - soft-deleted, still restorable" {
            InModuleScope PSMicrosoftEntraID {
                # Graph's naming is inverted from intuition, which is the whole reason
                # this mapping is not a passthrough.
                $response = [pscustomobject]@{ value = @(
                        [pscustomobject]@{ id = 'u2'; '@removed' = [pscustomobject]@{ reason = 'changed' } }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))

                $result[0].ChangeType | Should -Be 'Deleted'
                $result[0].Removed | Should -BeTrue
                # A removed object carries little but its id; that is Graph, not a bug.
                $result[0].Id | Should -Be 'u2'
            }
        }

        It "maps @removed reason 'deleted' to Purged" {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @(
                        [pscustomobject]@{ id = 'u3'; '@removed' = [pscustomobject]@{ reason = 'deleted' } }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))

                $result[0].ChangeType | Should -Be 'Purged'
                $result[0].Removed | Should -BeTrue
            }
        }

        It 'keeps changed and removed entries of one page apart' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @(
                        [pscustomobject]@{ id = 'a'; userPrincipalName = 'a@x.test' }
                        [pscustomobject]@{ id = 'b'; '@removed' = [pscustomobject]@{ reason = 'changed' } }
                        [pscustomobject]@{ id = 'c'; userPrincipalName = 'c@x.test' }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))

                # The page is deserialized in one go, so the annotations have to line up
                # with the right objects afterwards - this is what would break if they did not.
                $result.Count | Should -Be 3
                $result[0].Removed | Should -BeFalse
                $result[1].Removed | Should -BeTrue
                $result[2].Removed | Should -BeFalse
                $result[2].UserPrincipalName | Should -Be 'c@x.test'
            }
        }

        It 'handles a single-entry page without unrolling it' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @([pscustomobject]@{ id = 'only' }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))
                $result.Count | Should -Be 1
                $result[0].Id | Should -Be 'only'
            }
        }

        It 'returns nothing for an empty page' {
            InModuleScope PSMicrosoftEntraID {
                $result = @(ConvertFrom-RestDelta -InputObject ([pscustomobject]@{ value = @() }) -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))
                $result.Count | Should -Be 0
            }
        }
    }

    Context 'Group membership' {

        It 'reports who joined and who left' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @(
                        [pscustomobject]@{
                            id             = 'g1'
                            displayName    = 'Licensing'
                            'members@delta' = @(
                                [pscustomobject]@{ id = 'u-joined'; '@odata.type' = '#microsoft.graph.user' }
                                [pscustomobject]@{ id = 'u-left'; '@odata.type' = '#microsoft.graph.user'; '@removed' = [pscustomobject]@{ reason = 'changed' } }
                            )
                        }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Groups.GroupDelta]))

                $result[0].DisplayName | Should -Be 'Licensing'
                @($result[0].MembersDelta).Count | Should -Be 2

                $joined = $result[0].MembersDelta | Where-Object { -not $_.Removed }
                $left = $result[0].MembersDelta | Where-Object { $_.Removed }
                $joined.Id | Should -Be 'u-joined'
                $left.Id | Should -Be 'u-left'
                # '@odata.type' differs from the property name beyond case; the model maps
                # it with [JsonPropertyName] - this asserts that it actually arrives.
                $joined.ObjectType | Should -Be '#microsoft.graph.user'
            }
        }

        It 'leaves MembersDelta null when the membership did not change' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{ value = @([pscustomobject]@{ id = 'g2'; displayName = 'Unchanged' }) }
                $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Groups.GroupDelta]))
                $result[0].MembersDelta | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Cost' {

        It 'serializes the page once, not once per object' {
            InModuleScope PSMicrosoftEntraID {
                # A delta page can hold thousands of objects. The naive implementation
                # round-trips each one through JSON three times; this asserts the shape
                # stays linear enough to be usable on a real tenant.
                $entries = 1..500 | ForEach-Object { [pscustomobject]@{ id = "u$_"; userPrincipalName = "u$_@x.test" } }
                $response = [pscustomobject]@{ value = $entries }

                $elapsed = Measure-Command {
                    $result = @(ConvertFrom-RestDelta -InputObject $response -TargetType ([PSMicrosoftEntraID.Users.UserDelta]))
                }
                $result.Count | Should -Be 500
                $result[499].UserPrincipalName | Should -Be 'u500@x.test'
                # Generous: the point is to catch a regression to per-object conversion,
                # not to pin a number to this machine.
                $elapsed.TotalSeconds | Should -BeLessThan 10
            }
        }
    }
}
