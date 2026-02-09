BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Compare-PSEntraIDUserList' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Assert-RestConnection is not defined in the module — define it so it can be mocked.
        # Use script: scope so the function persists beyond the InModuleScope scriptblock.
        InModuleScope $script:ModuleName {
            function script:Assert-RestConnection { param($Service, $Cmdlet) }
        }

        Mock -ModuleName $script:ModuleName Assert-RestConnection { }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory ReferenceIdentity parameter' {
            $param = (Get-Command Compare-PSEntraIDUserList).Parameters['ReferenceIdentity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory DifferenceIdentity parameter' {
            $param = (Get-Command Compare-PSEntraIDUserList).Parameters['DifferenceIdentity']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have OutputType System.Collections.ArrayList' {
            (Get-Command Compare-PSEntraIDUserList).OutputType.Name | Should -Contain 'System.Collections.ArrayList'
        }

        It 'Should have UserIdentity parameter set' {
            (Get-Command Compare-PSEntraIDUserList).ParameterSets.Name | Should -Contain 'UserIdentity'
        }
    }

    Context 'Compare identical lists' {
        It 'Should return empty list when both lists are identical' {
            $list1 = @('user1@contoso.com', 'user2@contoso.com')
            $list2 = @('user1@contoso.com', 'user2@contoso.com')

            $result = Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            $result | Where-Object { $_.Crud -eq 'Create' -or $_.Crud -eq 'Delete' } | Should -BeNullOrEmpty
        }
    }

    Context 'Compare lists with users to create' {
        It 'Should return Create for users in reference but not in difference' {
            $list1 = @('user1@contoso.com', 'user2@contoso.com', 'user3@contoso.com')
            $list2 = @('user1@contoso.com', 'user2@contoso.com')

            $result = Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            $createItems = @($result | Where-Object { $_.Crud -eq 'Create' })
            $createItems.Count | Should -Be 1
            $createItems[0].Identity | Should -Be 'user3@contoso.com'
        }
    }

    Context 'Compare lists with users to delete' {
        It 'Should return Delete for users in difference but not in reference' {
            $list1 = @('user1@contoso.com')
            $list2 = @('user1@contoso.com', 'user2@contoso.com')

            $result = Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            $deleteItems = @($result | Where-Object { $_.Crud -eq 'Delete' })
            $deleteItems.Count | Should -Be 1
            $deleteItems[0].Identity | Should -Be 'user2@contoso.com'
        }
    }

    Context 'Compare lists with both create and delete' {
        It 'Should return Create and Delete items' {
            $list1 = @('user1@contoso.com', 'newuser@contoso.com')
            $list2 = @('user1@contoso.com', 'olduser@contoso.com')

            $result = Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            $createItems = @($result | Where-Object { $_.Crud -eq 'Create' })
            $deleteItems = @($result | Where-Object { $_.Crud -eq 'Delete' })
            $createItems.Count | Should -Be 1
            $createItems[0].Identity | Should -Be 'newuser@contoso.com'
            $deleteItems.Count | Should -Be 1
            $deleteItems[0].Identity | Should -Be 'olduser@contoso.com'
        }
    }

    Context 'Compare completely disjoint lists' {
        It 'Should return all as Create or Delete' {
            $list1 = @('userA@contoso.com', 'userB@contoso.com')
            $list2 = @('userC@contoso.com', 'userD@contoso.com')

            $result = Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            $createItems = @($result | Where-Object { $_.Crud -eq 'Create' })
            $deleteItems = @($result | Where-Object { $_.Crud -eq 'Delete' })
            $createItems.Count | Should -Be 2
            $deleteItems.Count | Should -Be 2
        }
    }

    Context 'Connection handling' {
        It 'Should assert REST connection to graph service' {
            $list1 = @('user1@contoso.com')
            $list2 = @('user1@contoso.com')

            Compare-PSEntraIDUserList -ReferenceIdentity $list1 -DifferenceIdentity $list2

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-RestConnection -Times 1 -Exactly
        }
    }
}
