BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

# Nothing in the request layer percent-encoded anything, and Graph identifiers are full of
# URL metacharacters: every guest's userPrincipalName carries '#EXT#', and '#' starts the
# URI fragment - so both a $Filter naming a guest and the users/{upn} path were silently
# truncated mid-value. Graph then answered "unterminated string literal" or 404 for a user
# that plainly exists. Found by the live guest scenario, which could not read the one
# guest it was pointed at. These tests pin the encoding at each layer involved: the query
# builder, the request sender, and the two cmdlets that put a caller's identity into the
# URL path.
Describe 'URL encoding of request components' -Tag 'Unit' {

    Context 'ConvertTo-QueryString encodes values' {

        It 'percent-encodes # in a value, because # otherwise truncates the URL' {
            InModuleScope PSMicrosoftEntraID {
                $qs = ConvertTo-QueryString -QueryHash @{ '$Filter' = "userPrincipalName eq 'a_b.com#EXT#@t.onmicrosoft.com'" }
                $qs | Should -BeLike '*%23EXT%23*'
                $qs | Should -Not -BeLike '*#*'
            }
        }

        It 'percent-encodes + in a value, because a query-string + decodes to a space' {
            InModuleScope PSMicrosoftEntraID {
                $qs = ConvertTo-QueryString -QueryHash @{ '$deltaToken' = 'A+b==' }
                $qs | Should -BeLike '*A%2Bb%3D%3D*'
            }
        }

        It 'percent-encodes spaces' {
            InModuleScope PSMicrosoftEntraID {
                $qs = ConvertTo-QueryString -QueryHash @{ '$Filter' = "mail eq 'a@b.com'" }
                $qs | Should -BeLike '*mail%20eq%20*'
                $qs | Should -Not -BeLike '* *'
            }
        }

        It 'leaves parameter NAMES alone - they are this module''s own literals' {
            InModuleScope PSMicrosoftEntraID {
                $qs = ConvertTo-QueryString -QueryHash @{ '$select' = 'id,mail' }
                # '$select=' readable in every log; only the value side is opaque.
                $qs | Should -BeLike '?$select=*'
            }
        }

        It 'still lets an explicit value override the DefaultQuery' {
            InModuleScope PSMicrosoftEntraID {
                $qs = ConvertTo-QueryString -QueryHash @{ a = '1' } -DefaultQuery @{ a = '0'; b = '2' }
                $qs | Should -BeLike '*a=1*'
                $qs | Should -BeLike '*b=2*'
                $qs | Should -Not -BeLike '*a=0*'
            }
        }
    }

    Context 'Invoke-EntraRequest sends the encoded query' {

        BeforeAll {
            InModuleScope PSMicrosoftEntraID {
                $script:fakeToken = [pscustomobject]@{
                    Service = 'Graph'
                    # The token guard compares every request with the service URL of the token.
                    ServiceUrl = 'https://graph.microsoft.com/v1.0'
                    Query   = @{}
                    RawOnly = $false
                }
                $script:fakeToken | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer test' } }
                $script:_EntraTokens = @{ Graph = $script:fakeToken }
                $script:_EntraEndpoints = @{ Graph = [pscustomobject]@{ Parameters = @{} } }
            }
        }

        It 'the URI that goes on the wire carries %23, and no fragment' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users' }
                $script:seenUri = $null
                Mock Invoke-RestMethod {
                    $script:seenUri = $Uri
                    [pscustomobject]@{ value = @() }
                }

                $null = Invoke-EntraRequest -Service Graph -Path 'users' -Query @{ '$Filter' = "mail eq 'x#EXT#@t.com'" }

                $script:seenUri | Should -BeLike '*%23EXT%23*'
                # The proof that mattered live: an unescaped '#' turns the rest of the
                # request into a fragment, which never leaves the client.
                ([uri]$script:seenUri).Fragment | Should -BeNullOrEmpty
            }
        }
    }

    Context 'The identity fallback path is escaped' {

        # Both Get cmdlets try a mail lookup first and, when it finds nothing, put the
        # CALLER'S string into the path as users/{identity}. That is the only place raw
        # input reaches the URL path, and for a guest that input contains '#EXT#'.
        BeforeAll {
            # Fresh import first: the previous context replaced the module's endpoint
            # registry with a fake holding only 'Graph', and the ValidateScript on the
            # (mocked) Invoke-EntraRequest's -Service would reject the real service name.
            Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force

            Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 999 } -ParameterFilter { $FullName -like '*PageSize' }
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
            Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
            Mock -ModuleName $script:ModuleName Get-PSFConfig {
                [PSCustomObject]@{ Value = @('id', 'displayName', 'userPrincipalName', 'mail', 'userType') }
            }
            Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
            Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
            Mock -ModuleName $script:ModuleName ConvertFrom-RestUser { $InputObject }
            Mock -ModuleName $script:ModuleName ConvertFrom-RestUserGuest { $InputObject }
            Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }

            # The mail lookup ('users') finds nothing, which forces the fallback; the
            # direct read ('users/...') answers.
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                if ($Path -eq 'users') { return $null }
                [PSCustomObject]@{
                    id                = 'guest-id-001'
                    displayName       = 'Guest User'
                    userPrincipalName = 'guest_contoso.com#EXT#@tenant.onmicrosoft.com'
                    mail              = $null
                    userType          = 'Guest'
                }
            }
        }

        It 'Get-PSEntraIDUserGuest escapes the # in users/{upn}' {
            Get-PSEntraIDUserGuest -Identity 'guest_contoso.com#EXT#@tenant.onmicrosoft.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -like 'users/*%23EXT%23*'
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -ParameterFilter {
                $Path -like 'users/*#*'
            }
        }

        It 'Get-PSEntraIDUser escapes the # in users/{upn}' {
            Get-PSEntraIDUser -Identity 'guest_contoso.com#EXT#@tenant.onmicrosoft.com'
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -like 'users/*%23EXT%23*'
            }
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -ParameterFilter {
                $Path -like 'users/*#*'
            }
        }

        It 'a plain GUID identity passes through the escape unchanged' {
            $id = 'e3305c17-6656-4a6f-946e-56c6c005aef9'
            Get-PSEntraIDUser -Identity $id
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq "users/$id"
            }
        }
    }
}
