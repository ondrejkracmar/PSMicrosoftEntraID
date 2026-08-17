BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'New-EntraIdentityFilter' -Tag 'Unit' {

    # Graph supports only some of the shapes this filter can take, and the unsupported
    # ones fail by returning NOTHING rather than by erroring - which is indistinguishable
    # from "no such guest". These tests pin which shapes the module builds and which it
    # refuses, so a future edit cannot quietly start emitting a filter that always
    # matches nothing.

    BeforeAll {
        # The helper terminates in its caller's context, so it needs a real $PSCmdlet -
        # which only exists inside an advanced function. An InModuleScope block is not
        # one, so calls go through this wrapper rather than passing a stub that would
        # make the rejection path untestable.
        InModuleScope PSMicrosoftEntraID {
            function script:Invoke-IdentityFilter {
                [CmdletBinding()]
                param (
                    [string] $Issuer,
                    [string] $IssuerAssignedId,
                    [string] $SignInType
                )
                New-EntraIdentityFilter -Cmdlet $PSCmdlet -Issuer $Issuer -IssuerAssignedId $IssuerAssignedId -SignInType $SignInType
            }
        }
    }

    Context 'Filter composition' {
        It 'builds the identities lambda from the issuer alone' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer 'google.com' |
                    Should -Be "identities/any(i:i/issuer eq 'google.com')"
            }
        }

        It 'adds issuerAssignedId in the order Graph documents' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer 'contoso.com' -IssuerAssignedId 'j.smith@contoso.com' |
                    Should -Be "identities/any(i:i/issuer eq 'contoso.com' and i/issuerAssignedId eq 'j.smith@contoso.com')"
            }
        }

        It 'adds signInType when asked' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer 'contoso.com' -IssuerAssignedId 'j@contoso.com' -SignInType 'federated' |
                    Should -Be "identities/any(i:i/issuer eq 'contoso.com' and i/issuerAssignedId eq 'j@contoso.com' and i/signInType eq 'federated')"
            }
        }

        It 'ignores empty optional values rather than emitting empty comparisons' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer 'mail' -IssuerAssignedId '' -SignInType '' |
                    Should -Be "identities/any(i:i/issuer eq 'mail')"
            }
        }
    }

    Context 'Escaping' {
        # The same class of defect as the Get-PSEntraIDContact filter injection: these
        # are free strings that end up inside an OData string literal.
        It 'doubles an apostrophe in the issuer' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer "o'brien.com" -IssuerAssignedId 'x@y.com' |
                    Should -BeLike "*i/issuer eq 'o''brien.com'*"
            }
        }

        It 'doubles an apostrophe in the issuerAssignedId' {
            InModuleScope PSMicrosoftEntraID {
                Invoke-IdentityFilter -Issuer 'contoso.com' -IssuerAssignedId "o'brien@contoso.com" |
                    Should -BeLike "*i/issuerAssignedId eq 'o''brien@contoso.com'*"
            }
        }

        It 'does not let a crafted value break out of the string literal' {
            InModuleScope PSMicrosoftEntraID {
                $filter = Invoke-IdentityFilter -Issuer "x') or true or ('" -IssuerAssignedId 'a@b.com'

                # The parens the caller sent survive - they are just characters once they
                # are inside a literal. What must not survive is a quote that ENDS the
                # literal, which is the only way the rest becomes filter syntax. Every
                # apostrophe is doubled, so the count stays even and the payload reads
                # back as one string value.
                $filter | Should -BeLike "*i/issuer eq 'x'') or true or (''*"
                @($filter.ToCharArray() | Where-Object { $_ -eq [char]39 }).Count % 2 | Should -Be 0
            }
        }
    }

    Context 'Shapes Graph does not support' {
        It 'refuses a signInType of userPrincipalName, naming the parameter to use instead' {
            $record = $null
            try {
                InModuleScope PSMicrosoftEntraID {
                    Invoke-IdentityFilter -Issuer 'contoso.com' -IssuerAssignedId 'a@b.com' -SignInType 'userPrincipalName'
                }
            }
            catch { $record = $_ }

            $record | Should -Not -BeNullOrEmpty
            # Not just "it threw": a binding failure would also throw. This is the
            # documented-unsupported path, and the message has to send the caller
            # somewhere that works.
            $record.Exception.Message | Should -BeLike '*userPrincipalName*'
            $record.Exception.Message | Should -BeLike '*-Identity*'
        }

        It 'warns when an issuer Graph cannot match on its own is used without an issuerAssignedId' {
            Mock -ModuleName $script:ModuleName Write-PSFMessage { }
            InModuleScope PSMicrosoftEntraID {
                $null = Invoke-IdentityFilter -Issuer 'contoso.com'
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Write-PSFMessage -ParameterFilter {
                $String -eq 'User.Identity.Issuer.Alone'
            }
        }

        It 'stays quiet for the four issuers Graph does match on their own' {
            foreach ($issuerValue in 'google.com', 'facebook.com', 'mail', 'phone') {
                Mock -ModuleName $script:ModuleName Write-PSFMessage { }
                InModuleScope PSMicrosoftEntraID -Parameters @{ issuerValue = $issuerValue } {
                    param($issuerValue)
                    $null = Invoke-IdentityFilter -Issuer $issuerValue
                }
                Should -Not -Invoke -ModuleName $script:ModuleName -CommandName Write-PSFMessage -ParameterFilter {
                    $String -eq 'User.Identity.Issuer.Alone'
                }
            }
        }
    }
}
