BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

# The delta cmdlets themselves only forward -DeltaSession; the token round-trip that makes
# delta work at all lives here, in Invoke-EntraRequest. It had no coverage: nothing checked
# that a stored token is actually sent, or that a returned one is actually kept. Both
# failures are silent - the first re-reads the whole tenant on every run, the second means
# the caller persists a token that was never updated and keeps asking for the same window.
Describe 'Invoke-EntraRequest delta handling' -Tag 'Unit' {

    BeforeAll {
        InModuleScope PSMicrosoftEntraID {
            # Minimal stand-ins for the connection state. GetHeader() is what the real token
            # object exposes to refresh and hand over the auth header.
            $script:fakeToken = [pscustomobject]@{
                Service = 'Graph'
                Query   = @{}
                RawOnly = $false
            }
            $script:fakeToken | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer test' } }
            $script:_EntraTokens = @{ Graph = $script:fakeToken }
            $script:_EntraEndpoints = @{ Graph = [pscustomobject]@{ Parameters = @{} } }
        }
    }

    Context 'Token round-trip' {

        It 'sends no delta token on the first run and stores the one it gets back' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                $script:seenUri = $null
                Mock Invoke-RestMethod {
                    $script:seenUri = $Uri
                    [pscustomobject]@{
                        value            = @([pscustomobject]@{ id = '1' })
                        '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=TOKEN1'
                    }
                }

                $session = @{}
                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession $session

                # Nothing to resume from, so the request must not carry a token.
                $script:seenUri | Should -Not -BeLike '*deltaToken*'
                # And the answer has to be remembered, keyed by the URI it belongs to.
                $session['https://graph.microsoft.com/v1.0/users/delta'].Token | Should -Be 'TOKEN1'
            }
        }

        It 'sends the stored token on the next run' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                $script:seenUri = $null
                Mock Invoke-RestMethod {
                    $script:seenUri = $Uri
                    [pscustomobject]@{
                        value            = @()
                        '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=TOKEN2'
                    }
                }

                $session = @{ 'https://graph.microsoft.com/v1.0/users/delta' = @{ Token = 'TOKEN1' } }
                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession $session

                $script:seenUri | Should -BeLike '*$deltaToken=TOKEN1*'
                # ... and the token advances, or the next run asks for the same window again.
                $session['https://graph.microsoft.com/v1.0/users/delta'].Token | Should -Be 'TOKEN2'
            }
        }

        It 'keeps a token that contains = intact' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                Mock Invoke-RestMethod {
                    [pscustomobject]@{
                        value            = @()
                        # Graph delta tokens are opaque base64-ish blobs and can carry '='
                        # padding. Splitting the link on '=' and taking the last piece
                        # silently truncates such a token to nothing useful.
                        '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=abc123=='
                    }
                }

                $session = @{}
                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession $session

                $session['https://graph.microsoft.com/v1.0/users/delta'].Token | Should -Be 'abc123=='
            }
        }

        It 'finds the token even when it is not the last query parameter' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                Mock Invoke-RestMethod {
                    [pscustomobject]@{
                        value            = @()
                        '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=TOKEN3&$select=displayName'
                    }
                }

                $session = @{}
                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession $session

                $session['https://graph.microsoft.com/v1.0/users/delta'].Token | Should -Be 'TOKEN3'
            }
        }
    }

    Context 'Paging' {

        It 'follows nextLink and keeps the token from the final page' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                $script:calls = 0
                Mock Invoke-RestMethod {
                    $script:calls++
                    if ($script:calls -eq 1) {
                        [pscustomobject]@{
                            value           = @([pscustomobject]@{ id = 'page1' })
                            '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users/delta?$skiptoken=S1'
                        }
                    }
                    else {
                        [pscustomobject]@{
                            value            = @([pscustomobject]@{ id = 'page2' })
                            '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=FINAL'
                        }
                    }
                }

                $session = @{}
                $result = @(Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession $session)

                $script:calls | Should -Be 2
                $result.Count | Should -Be 2
                $result.id | Should -Be @('page1', 'page2')
                # Only the last page carries a deltaLink, and that is the resume point.
                $session['https://graph.microsoft.com/v1.0/users/delta'].Token | Should -Be 'FINAL'
            }
        }
    }

    Context 'Minimal delta' {

        It 'asks for return=minimal only when told to' {
            InModuleScope PSMicrosoftEntraID {
                Mock Assert-EntraConnection { }
                Mock Resolve-RequestUri { 'https://graph.microsoft.com/v1.0/users/delta' }
                $script:seenHeaders = $null
                Mock Invoke-RestMethod {
                    $script:seenHeaders = $Headers
                    [pscustomobject]@{ value = @() }
                }

                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession @{}
                $script:seenHeaders.Keys | Should -Not -Contain 'Prefer'

                $null = Invoke-EntraRequest -Service Graph -Path 'users/delta' -DeltaSession @{} -MinimalDelta
                $script:seenHeaders['Prefer'] | Should -Be 'return=minimal'
            }
        }
    }
}
