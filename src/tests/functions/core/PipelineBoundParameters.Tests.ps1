BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force

    # Key order of a serialized hashtable is not stable, so both sides are compared in a
    # canonical form: parsed back and re-serialized with every object's keys sorted.
    function ConvertTo-CanonicalJson {
        param ([Parameter(Mandatory = $true)] [string] $Json)
        function Format-Node ($node) {
            if ($node -is [System.Collections.IDictionary]) {
                $ordered = [ordered]@{}
                foreach ($key in ($node.Keys | Sort-Object)) { $ordered[$key] = Format-Node $node[$key] }
                return $ordered
            }
            if ($node -is [System.Collections.IList]) { return , @($node | ForEach-Object { Format-Node $_ }) }
            return $node
        }
        (Format-Node ($Json | ConvertFrom-Json -AsHashtable -NoEnumerate)) | ConvertTo-Json -Compress -Depth 10
    }

    # The JSON Invoke-EntraRequest would put on the wire, one entry per request, in order.
    # Global because the mock body runs in the module's session state, not the test's.
    function Get-WireBody {
        @($global:PipelineWireBody) | ForEach-Object { ConvertTo-CanonicalJson -Json $_.Body }
    }
    function Get-WirePath {
        @($global:PipelineWireBody) | ForEach-Object { $_.Path }
    }
}

# With ValueFromPipelineByPropertyName, PowerShell resets a parameter variable before the
# next record but leaves its key in $PSBoundParameters. Every cmdlet that decided "was this
# property given?" with ContainsKey therefore wrote the previous record's properties - with
# reset default values - into the next object. These tests pipe records with DIFFERENT
# property sets and assert the serialized body of each request.
Describe 'Pipeline records bind only their own properties' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 0 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            $global:PipelineWireBody.Add([pscustomobject]@{ Path = $Path; Body = ($Body | ConvertTo-Json -Compress -Depth 10) })
        }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDUser {
            [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Users.User'; Id = $Identity; UserPrincipalName = "$Identity@contoso.com" }
        }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDGroup {
            [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.Groups.Group'; Id = $Identity; DisplayName = 'Group' }
        }
        Mock -ModuleName $script:ModuleName Get-PSEntraIDAdministrativeUnit {
            [PSCustomObject]@{ PSTypeName = 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'; Id = $Identity; DisplayName = 'AU' }
        }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestInvitation { }

        $script:id1 = '00000000-0000-0000-0000-000000000001'
        $script:id2 = '00000000-0000-0000-0000-000000000002'
        $script:password = ConvertTo-SecureString 'P@ssw0rd123!' -AsPlainText -Force
    }

    AfterAll {
        Remove-Variable -Name PipelineWireBody -Scope Global -ErrorAction Ignore
    }

    BeforeEach {
        $global:PipelineWireBody = [System.Collections.Generic.List[object]]::new()
    }

    Context 'Set-PSEntraIDUser' {
        It 'sends only the second record''s properties for the second user' {
            @(
                [pscustomobject]@{ Id = $id1; AccountEnabled = $true; Department = 'IT' }
                [pscustomobject]@{ Id = $id2; JobTitle = 'Dev' }
            ) | Set-PSEntraIDUser -Force

            Get-WirePath | Should -Be @("users/$id1", "users/$id2")
            Get-WireBody | Should -Be @('{"accountEnabled":true,"department":"IT"}', '{"jobTitle":"Dev"}')
        }

        It 'keeps a command-line property on every record' {
            @(
                [pscustomobject]@{ Id = $id1; Department = 'IT' }
                [pscustomobject]@{ Id = $id2 }
            ) | Set-PSEntraIDUser -UsageLocation 'CZ' -Force

            Get-WireBody | Should -Be @('{"department":"IT","usageLocation":"CZ"}', '{"usageLocation":"CZ"}')
        }

        It 'does not carry a password-profile flag into the next record' {
            @(
                [pscustomobject]@{ Id = $id1; Password = $password; ForceChangePasswordNextSignIn = $true }
                [pscustomobject]@{ Id = $id2; Password = $password }
            ) | Set-PSEntraIDUser -Force

            Get-WireBody | Should -Be @(
                '{"passwordProfile":{"forceChangePasswordNextSignIn":true,"password":"P@ssw0rd123!"}}'
                '{"passwordProfile":{"password":"P@ssw0rd123!"}}'
            )
        }
    }

    Context 'New-PSEntraIDUser' {
        It 'creates the second user without the first record''s optional properties' {
            @(
                [pscustomobject]@{ DisplayName = 'A'; UserPrincipalName = 'a@contoso.com'; MailNickname = 'a'; Password = $password; Department = 'IT'; ForceChangePasswordNextSignIn = $false }
                [pscustomobject]@{ DisplayName = 'B'; UserPrincipalName = 'b@contoso.com'; MailNickname = 'b'; Password = $password }
            ) | New-PSEntraIDUser -Force

            Get-WireBody | Should -Be @(
                '{"accountEnabled":true,"department":"IT","displayName":"A","mailNickname":"a","passwordProfile":{"forceChangePasswordNextSignIn":false,"password":"P@ssw0rd123!"},"userPrincipalName":"a@contoso.com"}'
                '{"accountEnabled":true,"displayName":"B","mailNickname":"b","passwordProfile":{"password":"P@ssw0rd123!"},"userPrincipalName":"b@contoso.com"}'
            )
        }
    }

    Context 'New-PSEntraIDGroup' {
        It 'creates the second group without the first record''s optional properties' {
            @(
                [pscustomobject]@{ DisplayName = 'A'; MailNickname = 'a'; Description = 'first'; Visibility = 'Public'; IsAssignableToRole = $true; Classification = 'Low' }
                [pscustomobject]@{ DisplayName = 'B'; MailNickname = 'b' }
            ) | New-PSEntraIDGroup -Force

            Get-WireBody | Should -Be @(
                '{"classification":"Low","description":"first","displayName":"A","groupTypes":["Unified"],"isAssignableToRole":true,"mailEnabled":false,"mailNickName":"a","securityEnabled":true,"visibility":"Public"}'
                '{"displayName":"B","groupTypes":["Unified"],"mailEnabled":false,"mailNickName":"b","securityEnabled":true}'
            )
        }
    }

    Context 'Set-PSEntraIDGroup' {
        It 'patches the second group with the second record''s properties only' {
            @(
                [pscustomobject]@{ Id = $id1; Description = 'first' }
                [pscustomobject]@{ Id = $id2; DisplayName = 'Renamed' }
            ) | Set-PSEntraIDGroup -Force

            Get-WirePath | Should -Be @("groups/$id1", "groups/$id2")
            Get-WireBody | Should -Be @('{"description":"first"}', '{"displayName":"Renamed"}')
        }
    }

    Context 'New-PSEntraIDAdministrativeUnit' {
        It 'creates the second unit without the first record''s optional properties' {
            @(
                [pscustomobject]@{ DisplayName = 'A'; Description = 'first'; Visibility = 'HiddenMembership' }
                [pscustomobject]@{ DisplayName = 'B' }
            ) | New-PSEntraIDAdministrativeUnit -Force

            Get-WireBody | Should -Be @(
                '{"description":"first","displayName":"A","isMemberManagementRestricted":false,"visibility":"HiddenMembership"}'
                '{"displayName":"B","isMemberManagementRestricted":false}'
            )
        }
    }

    Context 'Set-PSEntraIDAdministrativeUnit' {
        It 'patches the second unit with the second record''s properties only' {
            @(
                [pscustomobject]@{ Id = $id1; Description = 'first'; IsMemberManagementRestricted = $true }
                [pscustomobject]@{ Id = $id2; DisplayName = 'Renamed' }
            ) | Set-PSEntraIDAdministrativeUnit -Force

            Get-WirePath | Should -Be @("directory/administrativeUnits/$id1", "directory/administrativeUnits/$id2")
            Get-WireBody | Should -Be @('{"description":"first","isMemberManagementRestricted":true}', '{"displayName":"Renamed"}')
        }
    }

    Context 'New-PSEntraIDInvitation' {
        It 'invites the second guest without the first record''s language or CC recipients' {
            @(
                [pscustomobject]@{ InvitedUserEmailAddress = 'a@partner.com'; InvitedUserDisplayName = 'A'; InviteRedirectUrl = 'https://myapps.microsoft.com'; MessageLanguage = 'cs-CZ'; CCRecipient = @(@{ emailAddress = @{ address = 'cc@contoso.com' } }) }
                [pscustomobject]@{ InvitedUserEmailAddress = 'b@partner.com'; InvitedUserDisplayName = 'B'; InviteRedirectUrl = 'https://myapps.microsoft.com' }
            ) | New-PSEntraIDInvitation -Force

            Get-WireBody | Should -Be @(
                '{"invitedUserDisplayName":"A","invitedUserEmailAddress":"a@partner.com","invitedUserMessageInfo":{"ccRecipients":[{"emailAddress":{"address":"cc@contoso.com"}}],"customizedMessageBody":"","messageLanguage":"cs-CZ"},"inviteRedirectUrl":"https://myapps.microsoft.com","messageLanguage":"cs-CZ","sendInvitationMessage":false}'
                '{"invitedUserDisplayName":"B","invitedUserEmailAddress":"b@partner.com","invitedUserMessageInfo":{"ccRecipients":[],"customizedMessageBody":"","messageLanguage":""},"inviteRedirectUrl":"https://myapps.microsoft.com","messageLanguage":null,"sendInvitationMessage":false}'
            )
        }
    }
}
