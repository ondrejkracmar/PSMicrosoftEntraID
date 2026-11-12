BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force

    function Find-TestSecret {
        <#
        Runs the script block and returns every secret that shows up in what it left behind: every stream
        (output, error, warning, verbose, debug, information - merged), the records it added to $Error and the
        PSFramework log entries written while it ran. Empty when nothing leaked.
        #>
        param (
            [string[]] $Secret,
            [scriptblock] $ScriptBlock
        )
        $since = Get-Date
        $errorsBefore = $global:Error.Count
        $streams = try { & $ScriptBlock *>&1 | ForEach-Object { $_ | Out-String; if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.Exception.ToString(); [string]$_.TargetObject; [string]$_.ErrorDetails } } } catch { $_ | Out-String; $_.Exception.ToString(); [string]$_.TargetObject }
        $newErrors = @($global:Error | Select-Object -First ([Math]::Max(0, $global:Error.Count - $errorsBefore)))
        $errorText = foreach ($record in $newErrors) {
            if ($record -is [System.Management.Automation.ErrorRecord]) { $record | Out-String; $record.Exception.ToString(); [string]$record.TargetObject; [string]$record.ErrorDetails }
            else { [string]$record }
        }
        $logText = Get-PSFMessage | Where-Object Timestamp -GE $since | ForEach-Object { $_.LogMessage; $_.Message; ($_.StringValue -join ' ') }
        [string] $all = (@($streams) + @($errorText) + @($logText)) -join "`n"
        foreach ($entry in $Secret) { if ($all.Contains($entry)) { $entry } }
    }

    function New-TestHttpError {
        # An error record as Invoke-RestMethod raises it for an HTTP failure: the answer's body in ErrorDetails.
        param ([string] $Body, [string] $Message = 'Response status code does not indicate success.')
        $record = [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message), 'WebCmdletWebResponseException', 'InvalidOperation', $null)
        $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($Body)
        $record
    }

    $script:secrets = @('S3cr3tAcc3ssT0k3n', 'S3cr3tSk1pT0k3n', 'S3cr3tD3lt4T0k3n')
}

<#
No secret reaches a log or the output (ported in spirit from PSExchangeOnline's NoSecretInOutput.Tests.ps1).

Before this, Invoke-EntraRequest wrote the full request URL - query included - to the verbose stream and into its
"Request failed" warning, and the full @odata.deltaLink into a warning: delta and skip tokens ended up in the
PSFramework log and in transcripts. Now the request layer writes localized messages with the URL by scheme, host and
path only. The access token itself never appears.

Out of scope here, and not claimed: the error record Invoke-RestMethod raises for an HTTP failure keeps the request
(HttpRequestMessage, with its URL) as its target object, and PowerShell puts it into $Error before any catch block
runs. PSExchangeOnline closed that by replacing Invoke-RestMethod with its own HTTP client; that port is separate work.
#>
Describe 'No secret in logs or output' -Tag 'Unit' {

    Context 'Invoke-EntraRequest' {

        BeforeAll {
            InModuleScope PSMicrosoftEntraID {
                $script:secretToken = [pscustomobject]@{
                    Service    = 'SecretGraph'
                    ServiceUrl = 'https://graph.microsoft.com/v1.0'
                    Query      = @{}
                    RawOnly    = $false
                }
                $script:secretToken | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer S3cr3tAcc3ssT0k3n' } }
                $script:_EntraTokens['SecretGraph'] = $script:secretToken
                $script:_EntraEndpoints['SecretGraph'] = [pscustomobject]@{ Parameters = @{} }
            }
        }

        AfterAll {
            InModuleScope PSMicrosoftEntraID {
                $script:_EntraTokens.Remove('SecretGraph')
                $script:_EntraEndpoints.Remove('SecretGraph')
            }
        }

        BeforeEach {
            Mock Assert-EntraConnection -ModuleName PSMicrosoftEntraID { }
            Mock Start-Sleep -ModuleName PSMicrosoftEntraID { }
        }

        It 'leaves no skip token behind when the next page of a request fails' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID {
                if ($Uri -like '*skiptoken*') { throw (New-TestHttpError -Body '{"error":{"code":"InternalServerError","message":"boom"}}') }
                [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=S3cr3tSk1pT0k3n' }
            }
            $found = Find-TestSecret -Secret $script:secrets -ScriptBlock {
                InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service SecretGraph -Path 'users' -Verbose -Debug }
            }
            $found | Should -BeNullOrEmpty
            Should -Invoke Invoke-RestMethod -ModuleName PSMicrosoftEntraID -Times 2 -Exactly -Scope It
        }

        It 'leaves no delta token behind when a resumed delta read fails' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID {
                throw (New-TestHttpError -Body '{"error":{"code":"InternalServerError","message":"boom"}}')
            }
            $found = Find-TestSecret -Secret $script:secrets -ScriptBlock {
                InModuleScope PSMicrosoftEntraID {
                    $session = @{ 'https://graph.microsoft.com/v1.0/users/delta' = @{ Token = 'S3cr3tD3lt4T0k3n' } }
                    Invoke-EntraRequest -Service SecretGraph -Path 'users/delta' -DeltaSession $session -Verbose -Debug
                }
            }
            $found | Should -BeNullOrEmpty
            # The token WAS sent - only not logged.
            Should -Invoke Invoke-RestMethod -ModuleName PSMicrosoftEntraID -Times 1 -Exactly -Scope It -ParameterFilter { $Uri -like '*S3cr3tD3lt4T0k3n*' }
        }

        It 'leaves no token behind when a delta link carries no usable $deltatoken' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID {
                # Some endpoints name the token differently; the link is then warned about - by its path only.
                [pscustomobject]@{ value = @(); '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?token=S3cr3tD3lt4T0k3n' }
            }
            $found = Find-TestSecret -Secret $script:secrets -ScriptBlock {
                InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service SecretGraph -Path 'users/delta' -DeltaSession @{} -Verbose -Debug }
            }
            $found | Should -BeNullOrEmpty
            $log = Get-PSFMessage | Where-Object { $_.String -eq 'Request.DeltaLinkNoToken' } | Select-Object -Last 1
            $log.Message | Should -BeLike '*https://graph.microsoft.com/v1.0/users/delta*'
        }

        It 'leaves no token behind when a throttled request is retried' {
            $script:calls = 0
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID {
                $script:calls++
                if ($script:calls -eq 1) {
                    # A 429 as Invoke-RestMethod raises it: the answer (with its Retry-After) on the exception, the body in ErrorDetails.
                    $answer = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]429)
                    $null = $answer.Headers.TryAddWithoutValidation('Retry-After', '10')
                    $record = [System.Management.Automation.ErrorRecord]::new([Microsoft.PowerShell.Commands.HttpResponseException]::new('Response status code does not indicate success: 429 (Too Many Requests).', $answer), 'WebCmdletWebResponseException', 'InvalidOperation', $null)
                    $record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new('{"error":{"code":"TooManyRequests","message":"Retry after 10 seconds please"}}')
                    throw $record
                }
                [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }) }
            }
            $found = Find-TestSecret -Secret $script:secrets -ScriptBlock {
                InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service SecretGraph -Path 'users?$skiptoken=S3cr3tSk1pT0k3n' -Verbose -Debug }
            }
            $found | Should -BeNullOrEmpty
            Should -Invoke Start-Sleep -ModuleName PSMicrosoftEntraID -Times 1 -Exactly -Scope It
        }

        It 'leaves no token behind when a next link on another host is refused' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID {
                [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }); '@odata.nextLink' = 'https://attacker.example/v1.0/users?$skiptoken=S3cr3tSk1pT0k3n' }
            }
            $found = Find-TestSecret -Secret $script:secrets -ScriptBlock {
                InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service SecretGraph -Path 'users' -Verbose -Debug }
            }
            $found | Should -BeNullOrEmpty
        }

        It 'logs the request by scheme, host and path' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID { [pscustomobject]@{ value = @() } }
            InModuleScope PSMicrosoftEntraID { $null = Invoke-EntraRequest -Service SecretGraph -Path 'users' -Query @{ '$skiptoken' = 'S3cr3tSk1pT0k3n' } }
            $log = Get-PSFMessage | Where-Object { $_.String -eq 'Request.Execute' } | Select-Object -Last 1
            $log.Message | Should -Be 'Executing request: GET -> https://graph.microsoft.com/v1.0/users'
        }
    }

    Context 'Get-EntraLogUri' {

        It 'keeps <Expected> of <Uri>' -ForEach @(
            @{ Uri = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=S3cr3t'; Expected = 'https://graph.microsoft.com/v1.0/users/delta' }
            @{ Uri = 'https://user:S3cr3t@graph.microsoft.com/v1.0/users#frag'; Expected = 'https://graph.microsoft.com/v1.0/users' }
            @{ Uri = 'users/a@contoso.com/messages?$skiptoken=S3cr3t'; Expected = 'users/a@contoso.com/messages' }
            @{ Uri = 'https://user:p@ss@host/?x=S3cr3t'; Expected = 'https://<unparseable URL>' }
            @{ Uri = ''; Expected = '' }
        ) {
            InModuleScope PSMicrosoftEntraID -Parameters @{ Uri = $Uri; Expected = $Expected } {
                Get-EntraLogUri -Uri $Uri | Should -Be $Expected
            }
        }
    }

    Context 'Sign-in' {

        It 'shows the device code prompt on the host but never logs the device code' {
            Mock Start-Sleep -ModuleName PSMicrosoftEntraID { }
            $script:testJwt = '{0}.{1}.sig' -f 'eyJhbGciOiJub25lIn0', ([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"aud":"https://graph.microsoft.com","tid":"t"}')).TrimEnd('=').Replace('+', '-').Replace('/', '_'))
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID -ParameterFilter { $Uri -like '*/devicecode' } {
                [pscustomobject]@{ message = 'To sign in, enter the code ABCD-EFGH'; device_code = 'S3cr3tD3v1c3C0d3'; interval = 1; expires_in = 900 }
            }
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID -ParameterFilter { $Uri -like '*/token' } {
                [pscustomobject]@{ access_token = $script:testJwt; expires_in = 3600 }
            }
            $found = Find-TestSecret -Secret @('S3cr3tD3v1c3C0d3') -ScriptBlock {
                InModuleScope PSMicrosoftEntraID { Connect-ServiceDeviceCode -Resource 'https://graph.microsoft.com' -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com' -Verbose -Debug }
            }
            $found | Should -BeNullOrEmpty
            $prompt = Get-PSFMessage | Where-Object { $_.String -eq 'Identity.DeviceCode.Prompt' } | Select-Object -Last 1
            $prompt.Level | Should -Be 'Important'
            $prompt.Message | Should -Be 'To sign in, enter the code ABCD-EFGH'
        }

        It 'leaves no password behind when the password flow is turned off' {
            Mock Invoke-RestMethod -ModuleName PSMicrosoftEntraID { throw 'must not be called' }
            $found = Find-TestSecret -Secret @('S3cr3tP4ssw0rd') -ScriptBlock {
                InModuleScope PSMicrosoftEntraID {
                    $credential = [pscredential]::new('max@contoso.com', (ConvertTo-SecureString 'S3cr3tP4ssw0rd' -AsPlainText -Force))
                    Connect-ServicePassword -Resource 'https://graph.microsoft.com' -Credential $credential -ClientID 'c' -TenantID 't' -AuthenticationUrl 'https://login.microsoftonline.com'
                }
            }
            $found | Should -BeNullOrEmpty
            Should -Invoke Invoke-RestMethod -ModuleName PSMicrosoftEntraID -Times 0 -Exactly -Scope It
        }
    }
}
