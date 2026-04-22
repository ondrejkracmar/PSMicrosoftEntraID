BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'New-PSEntraIDInvitation' -Tag 'Unit' {

    BeforeAll {
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            [PSCustomObject]@{ id = 'inv-001'; invitedUserEmailAddress = 'guest@partner.com'; status = 'PendingAcceptance' }
        }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName ConvertFrom-RestInvitation { $InputObject }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }
        Mock -ModuleName $script:ModuleName Test-PSFParameterBinding { $false }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InvitedUserEmailAddress parameter' {
            $param = (Get-Command New-PSEntraIDInvitation).Parameters['InvitedUserEmailAddress']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory InvitedUserDisplayName parameter' {
            $param = (Get-Command New-PSEntraIDInvitation).Parameters['InvitedUserDisplayName']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should have mandatory InviteRedirectUrl parameter' {
            $param = (Get-Command New-PSEntraIDInvitation).Parameters['InviteRedirectUrl']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-PSEntraIDInvitation
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should have OutputType PSMicrosoftEntraID.Users.Invitations.Invitation' {
            (Get-Command New-PSEntraIDInvitation).OutputType.Name | Should -Contain 'PSMicrosoftEntraID.Users.Invitations.Invitation'
        }
    }

    Context 'Create invitation with required parameters' {
        It 'Should call API with POST to invitations path' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Post' -and $Path -eq 'invitations'
            }
        }

        It 'Should include email address in body' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.invitedUserEmailAddress -eq 'guest@partner.com'
            }
        }

        It 'Should set sendInvitationMessage to false by default' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.sendInvitationMessage -eq $false
            }
        }

        It 'Should include Content-Type header' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header.'Content-Type' -eq 'application/json'
            }
        }

        It 'Should convert response using ConvertFrom-RestInvitation' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName ConvertFrom-RestInvitation -Times 1
        }
    }

    Context 'Create invitation with optional parameters' {
        It 'Should include SendInvitationMessage when specified' {
            Mock -ModuleName $script:ModuleName Test-PSFParameterBinding { $true } -ParameterFilter { $ParameterName -eq 'SendInvitationMessage' }

            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -SendInvitationMessage -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.sendInvitationMessage -eq $true
            }
        }
    }

    Context 'PassThru parameter' {
        It 'Should return batch request when PassThru is specified' {
            $result = New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -PassThru

            $result.PSTypeNames[0] | Should -Be 'PSMicrosoftEntraID.Batch.Request'
            $result.Method | Should -Be 'POST'
            $result.Url | Should -Be '/invitations'
        }

        It 'Should not call Invoke-EntraRequest when PassThru is specified' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -PassThru

            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 0 -Exactly
        }
    }

    Context 'Error handling' {
        It 'Should call Assert-EntraConnection' {
            New-PSEntraIDInvitation -InvitedUserEmailAddress 'guest@partner.com' -InvitedUserDisplayName 'Guest User' -InviteRedirectUrl 'https://myapp.contoso.com' -Confirm:$false

            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1 -Exactly
        }
    }
}
