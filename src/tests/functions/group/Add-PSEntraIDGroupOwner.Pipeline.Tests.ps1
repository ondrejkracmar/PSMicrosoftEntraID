BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'
    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Add-PSEntraIDGroupOwner resolves the group per pipeline record' -Tag 'Unit' {
    # -Identity is ValueFromPipelineByPropertyName, but the group used to be resolved in
    # begin - where a piped Identity is still empty. Piping group records therefore never
    # worked. Only the HTTP layer is faked here: Get-PSEntraIDGroup and Get-PSEntraIDUser
    # run for real, so the URLs below are what would go on the wire.
    BeforeAll {
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            if ($Method -eq 'Get' -and $Path -in 'groups', 'users') { return }
            if ($Method -eq 'Get' -and $Path -like 'groups/*') {
                $groupKey = $Path.Substring('groups/'.Length)
                return [PSCustomObject]@{ id = $groupKey; displayName = "Group $groupKey" }
            }
            if ($Method -eq 'Get' -and $Path -like 'users/*') {
                $userKey = [uri]::UnescapeDataString($Path.Substring('users/'.Length))
                $userObjectId = if ($userKey -like 'alice*') { 'aaaaaaaa-0000-0000-0000-000000000001' } else { 'bbbbbbbb-0000-0000-0000-000000000002' }
                return [PSCustomObject]@{ id = $userObjectId; userPrincipalName = $userKey; mail = $userKey }
            }
        }

        $script:GroupOne = '11111111-1111-1111-1111-111111111111'
        $script:GroupTwo = '22222222-2222-2222-2222-222222222222'
    }

    It 'sends each record''s owner to that record''s group' {
        @(
            [PSCustomObject]@{ Identity = $script:GroupOne; User = 'alice@contoso.com' }
            [PSCustomObject]@{ Identity = $script:GroupTwo; User = 'bob@contoso.com' }
        ) | Add-PSEntraIDGroupOwner -Force

        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq ('groups/{0}/owners/$ref' -f '11111111-1111-1111-1111-111111111111') -and
            ($Body | ConvertTo-Json -Compress) -eq '{"@odata.id":"https://graph.microsoft.com/v1.0/users/aaaaaaaa-0000-0000-0000-000000000001"}'
        }
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'POST' -and $Path -eq ('groups/{0}/owners/$ref' -f '22222222-2222-2222-2222-222222222222') -and
            ($Body | ConvertTo-Json -Compress) -eq '{"@odata.id":"https://graph.microsoft.com/v1.0/users/bbbbbbbb-0000-0000-0000-000000000002"}'
        }
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }

    It 'returns batch requests addressed to each record''s group with -PassThru' {
        $requests = @(
            [PSCustomObject]@{ Identity = $script:GroupOne; User = 'alice@contoso.com' }
            [PSCustomObject]@{ Identity = $script:GroupTwo; User = 'bob@contoso.com' }
        ) | Add-PSEntraIDGroupOwner -PassThru

        @($requests.Url) | Should -Be @(
            ('/groups/{0}/owners/$ref' -f $script:GroupOne)
            ('/groups/{0}/owners/$ref' -f $script:GroupTwo)
        )
    }

    It 'stops before any write when a piped group does not resolve' {
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            if ($Method -eq 'Get' -and $Path -like 'groups/*') { throw 'Resource not found' }
        } -ParameterFilter { $Path -eq 'groups/22222222-2222-2222-2222-222222222222' }

        {
            [PSCustomObject]@{ Identity = $script:GroupTwo; User = 'bob@contoso.com' } | Add-PSEntraIDGroupOwner -Force -WarningAction SilentlyContinue
        } | Should -Throw -ExpectedMessage '*22222222-2222-2222-2222-222222222222*'
        Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly -ParameterFilter { $Method -eq 'POST' }
    }
}
