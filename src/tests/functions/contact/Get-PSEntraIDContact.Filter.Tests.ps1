BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Get-PSEntraIDContact filter escaping' -Tag 'Unit' {

    # This was the one place in the module that interpolated caller input straight into
    # an OData filter. An apostrophe in a name (O'Brien) breaks the query, and can be
    # used to rewrite it. Everywhere else goes through ConvertTo-ODataFilterString.

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { if ($PSBoundParameters.ContainsKey('Fallback')) { $Fallback } else { $null } }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        # The begin block feeds these into New-TimeSpan, which rejects $null.
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { $Name }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
    }

    It "doubles an apostrophe in -Identity instead of letting it break the filter" {
        InModuleScope PSMicrosoftEntraID {
            $script:seenFilter = $null
            Mock Invoke-EntraRequest { $script:seenFilter = $Query['$filter'] }

            Get-PSEntraIDContact -Identity "o'brien@contoso.com" -ErrorAction SilentlyContinue

            $script:seenFilter | Should -Be "mail eq 'o''brien@contoso.com'"
        }
    }

    It "doubles an apostrophe in -Name across every clause" {
        InModuleScope PSMicrosoftEntraID {
            $script:seenFilter = $null
            Mock Invoke-EntraRequest { $script:seenFilter = $Query['$filter'] }

            Get-PSEntraIDContact -Name "O'Brien" -ErrorAction SilentlyContinue

            # All three clauses must be escaped, not just the first.
            $script:seenFilter | Should -BeLike "*displayName,'O''Brien'*"
            $script:seenFilter | Should -BeLike "*givenName,'O''Brien'*"
            $script:seenFilter | Should -BeLike "*surname,'O''Brien'*"
        }
    }

    It "does not let a crafted value close the string and append a clause" {
        InModuleScope PSMicrosoftEntraID {
            $script:seenFilter = $null
            Mock Invoke-EntraRequest { $script:seenFilter = $Query['$filter'] }

            Get-PSEntraIDContact -Identity "x' or displayName eq 'admin" -ErrorAction SilentlyContinue

            # The injected quote is doubled, so the whole thing stays one literal.
            $script:seenFilter | Should -Be "mail eq 'x'' or displayName eq ''admin'"
        }
    }
}
