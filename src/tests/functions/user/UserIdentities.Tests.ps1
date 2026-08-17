BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'User identities collection' -Tag 'Unit' {

    # The identities collection is what says where a guest actually comes from. The
    # #EXT# user principal name only looks like it does: it is a mangled copy of the
    # invited address, it survives the guest changing their sign-in name at home, and
    # for a social guest it says nothing about the provider. Everything here exists so
    # that stays true through the C# model, the deserializer and the $select config -
    # the three places that can each independently drop the property on the floor.

    Context 'ObjectIdentity type' {
        It 'carries exactly the three properties of the Graph resource' {
            $properties = [PSMicrosoftEntraID.Users.ObjectIdentity].GetProperties().Name
            $properties | Should -Contain 'SignInType'
            $properties | Should -Contain 'Issuer'
            $properties | Should -Contain 'IssuerAssignedId'
            @($properties).Count | Should -Be 3
        }

        It 'renders readably in a collection' {
            $identity = [PSMicrosoftEntraID.Users.ObjectIdentity]@{
                SignInType       = 'federated'
                Issuer           = 'contoso.com'
                IssuerAssignedId = 'j.smith@contoso.com'
            }
            "$identity" | Should -Be 'federated:contoso.com/j.smith@contoso.com'
        }
    }

    Context 'Model' {
        It 'exposes Identities on User, so a member account carries it too' {
            [PSMicrosoftEntraID.Users.User].GetProperty('Identities') | Should -Not -BeNullOrEmpty
            [PSMicrosoftEntraID.Users.User].GetProperty('Identities').PropertyType |
                Should -Be ([PSMicrosoftEntraID.Users.ObjectIdentity[]])
        }

        It 'inherits Identities on UserGuest' {
            [PSMicrosoftEntraID.Users.UserGuest].GetProperty('Identities') | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Derived guest properties' {
        BeforeAll {
            # The shape Entra actually returns for a B2B guest: the federated identity
            # names the HOME organization, the userPrincipalName identity names THIS
            # tenant. Reading the wrong one is the whole trap.
            $script:b2bGuest = [PSMicrosoftEntraID.Users.UserGuest]@{
                Identities = @(
                    [PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'userPrincipalName'; Issuer = 'fabrikam.onmicrosoft.com'; IssuerAssignedId = 'j.smith_contoso.com#EXT#@fabrikam.onmicrosoft.com' }
                    [PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'federated'; Issuer = 'contoso.com'; IssuerAssignedId = 'j.smith@contoso.com' }
                )
            }
        }

        It 'reads HomeIssuer off the federated identity, not the local one' {
            $script:b2bGuest.HomeIssuer | Should -Be 'contoso.com'
        }

        It 'matches the sign-in type case-insensitively, as Graph does not promise casing' {
            $guest = [PSMicrosoftEntraID.Users.UserGuest]@{
                Identities = @([PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'Federated'; Issuer = 'google.com' })
            }
            $guest.HomeIssuer | Should -Be 'google.com'
        }

        It 'lists the distinct sign-in types' {
            $script:b2bGuest.SignInTypes | Should -Be @('userPrincipalName', 'federated')
        }

        It 'collapses duplicate sign-in types' {
            $guest = [PSMicrosoftEntraID.Users.UserGuest]@{
                Identities = @(
                    [PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'emailAddress'; Issuer = 'contoso.com' }
                    [PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'emailAddress'; Issuer = 'fabrikam.com' }
                )
            }
            @($guest.SignInTypes).Count | Should -Be 1
        }

        It 'returns null rather than throwing when identities was never selected' {
            $guest = [PSMicrosoftEntraID.Users.UserGuest]@{ DisplayName = 'No identities' }
            $guest.HomeIssuer | Should -BeNullOrEmpty
            @($guest.SignInTypes).Count | Should -Be 0
        }

        It 'returns null when the account has no federated identity at all' {
            $guest = [PSMicrosoftEntraID.Users.UserGuest]@{
                Identities = @([PSMicrosoftEntraID.Users.ObjectIdentity]@{ SignInType = 'userPrincipalName'; Issuer = 'fabrikam.onmicrosoft.com' })
            }
            $guest.HomeIssuer | Should -BeNullOrEmpty
        }
    }

    Context 'Deserialization' {
        # ConvertFrom-RestUserGuest serializes the REST object back to JSON at a fixed
        # depth and reads it through DataContractJsonSerializer. identities is one level
        # deeper than any scalar property, so a depth regression would silently blank it.
        It 'maps the identities array off a Graph response' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{
                    id         = 'guest-id-001'
                    userType   = 'Guest'
                    identities = @(
                        [pscustomobject]@{ signInType = 'federated'; issuer = 'contoso.com'; issuerAssignedId = 'j.smith@contoso.com' }
                    )
                }

                $guest = ConvertFrom-RestUserGuest -InputObject $response

                @($guest.Identities).Count | Should -Be 1
                $guest.Identities[0].SignInType | Should -Be 'federated'
                $guest.Identities[0].Issuer | Should -Be 'contoso.com'
                $guest.Identities[0].IssuerAssignedId | Should -Be 'j.smith@contoso.com'
                $guest.HomeIssuer | Should -Be 'contoso.com'
            }
        }

        It 'maps identities onto a plain user as well' {
            InModuleScope PSMicrosoftEntraID {
                $response = [pscustomobject]@{
                    id         = 'user-id-001'
                    userType   = 'Member'
                    identities = @(
                        [pscustomobject]@{ signInType = 'userPrincipalName'; issuer = 'fabrikam.onmicrosoft.com'; issuerAssignedId = 'j@fabrikam.onmicrosoft.com' }
                    )
                }

                $user = ConvertFrom-RestUser -InputObject $response

                @($user.Identities).Count | Should -Be 1
                $user.Identities[0].Issuer | Should -Be 'fabrikam.onmicrosoft.com'
            }
        }
    }

    Context 'Query surface' {
        # Selecting it is not optional: Graph omits identities unless it is named in
        # $select, so a model that has the property and a query that does not ask for it
        # produces an empty column and no error anywhere.
        It 'asks Graph for identities on the user query' {
            (Get-PSFConfig -Module PSMicrosoftEntraID -Name Settings.GraphApiQuery.Select.User).Value |
                Should -Contain 'identities'
        }

        It 'asks Graph for identities on the guest query' {
            (Get-PSFConfig -Module PSMicrosoftEntraID -Name Settings.GraphApiQuery.Select.UserGuest).Value |
                Should -Contain 'identities'
        }
    }
}
