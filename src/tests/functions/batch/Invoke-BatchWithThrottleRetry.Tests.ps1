BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

Describe 'Invoke-BatchWithThrottleRetry' -Tag 'Unit' {

    # Graph reports a throttled SUB-request inside the batch body while the envelope
    # comes back HTTP 200. Invoke-EntraRequest's retry inspects the HTTP error, so it
    # never saw these - the sub-request was dropped in silence, in the one feature that
    # exists for bulk work.

    BeforeAll {
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { if ($PSBoundParameters.ContainsKey('Fallback')) { $Fallback } else { $null } }
        Mock -ModuleName $script:ModuleName Start-Sleep { }   # no real waiting in tests
        Mock -ModuleName $script:ModuleName Write-PSFMessage { }

        function script:New-Payload {
            param([int] $Count = 2)
            $requests = foreach ($i in 1..$Count) {
                [PSMicrosoftEntraID.Batch.Request]@{ Id = "$i"; Method = 'GET'; Url = "/users/$i" }
            }
            [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{ Requests = $requests }
        }
    }

    It 're-sends only the throttled sub-request and keeps the one that succeeded' {
        InModuleScope PSMicrosoftEntraID {
            $script:calls = @()
            Mock Invoke-EntraRequest {
                $script:calls += , @($Body.requests | ForEach-Object { $_.id })
                if ($script:calls.Count -eq 1) {
                    # first pass: 1 is fine, 2 is throttled
                    [pscustomobject]@{ Responses = @(
                            [pscustomobject]@{ id = '1'; status = 200; headers = $null; body = 'ok-1' }
                            [pscustomobject]@{ id = '2'; status = 429; headers = $null; body = $null }
                        ) }
                }
                else {
                    [pscustomobject]@{ Responses = @(
                            [pscustomobject]@{ id = '2'; status = 200; headers = $null; body = 'ok-2' }
                        ) }
                }
            }

            $payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{
                Requests = @(
                    [PSMicrosoftEntraID.Batch.Request]@{ Id = '1'; Method = 'GET'; Url = '/users/1' }
                    [PSMicrosoftEntraID.Batch.Request]@{ Id = '2'; Method = 'GET'; Url = '/users/2' }
                )
            }
            $result = Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{} -Path '$batch' -RetryCount 3 -RetryWait ([timespan]::FromSeconds(1))

            $script:calls.Count | Should -Be 2
            # The retry carries ONLY the throttled id - re-sending the successful one
            # would duplicate a write.
            ($script:calls[1] -join ',') | Should -Be '2'

            @($result).Count | Should -Be 2
            # ...and the results come back in the original request order.
            $result[0].Id | Should -Be '1'
            $result[1].Id | Should -Be '2'
            $result[1].Status | Should -Be 200
            $result[1].Body | Should -Be 'ok-2'
        }
    }

    It 'gives up after RetryCount passes and returns the throttled response' {
        InModuleScope PSMicrosoftEntraID {
            $script:passes = 0
            Mock Invoke-EntraRequest {
                $script:passes++
                [pscustomobject]@{ Responses = @([pscustomobject]@{ id = '1'; status = 429; headers = $null; body = $null }) }
            }
            $payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{
                Requests = @([PSMicrosoftEntraID.Batch.Request]@{ Id = '1'; Method = 'GET'; Url = '/users/1' })
            }
            $result = Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{} -Path '$batch' -RetryCount 2 -RetryWait ([timespan]::FromSeconds(1))

            $script:passes | Should -Be 3          # initial + 2 retries
            @($result).Count | Should -Be 1
            $result[0].Status | Should -Be 429     # surfaced, not swallowed
        }
    }

    It 'does not retry a failure that is not throttling' {
        InModuleScope PSMicrosoftEntraID {
            $script:passes = 0
            Mock Invoke-EntraRequest {
                $script:passes++
                [pscustomobject]@{ Responses = @([pscustomobject]@{ id = '1'; status = 403; headers = $null; body = $null }) }
            }
            $payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{
                Requests = @([PSMicrosoftEntraID.Batch.Request]@{ Id = '1'; Method = 'GET'; Url = '/users/1' })
            }
            $result = Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{} -Path '$batch' -RetryCount 3 -RetryWait ([timespan]::FromSeconds(1))

            # Retrying a 403 only produces another 403.
            $script:passes | Should -Be 1
            $result[0].Status | Should -Be 403
        }
    }

    It 'prefers the Retry-After Graph asked for over our own wait' {
        InModuleScope PSMicrosoftEntraID {
            $script:slept = @()
            Mock Start-Sleep { $script:slept += $Seconds }
            $script:passes = 0
            Mock Invoke-EntraRequest {
                $script:passes++
                if ($script:passes -eq 1) {
                    [pscustomobject]@{ Responses = @([pscustomobject]@{ id = '1'; status = 429
                                headers = [pscustomobject]@{ 'Retry-After' = '17' }; body = $null }) }
                }
                else { [pscustomobject]@{ Responses = @([pscustomobject]@{ id = '1'; status = 200; headers = $null; body = 'ok' }) } }
            }
            $payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{
                Requests = @([PSMicrosoftEntraID.Batch.Request]@{ Id = '1'; Method = 'GET'; Url = '/users/1' })
            }
            $null = Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{} -Path '$batch' -RetryCount 3 -RetryWait ([timespan]::FromSeconds(2))

            # Graph knows how busy it is; 17 wins over our 2.
            $script:slept[0] | Should -Be 17
        }
    }

    It 'RetryCount 0 keeps the old behaviour - one pass, no retry' {
        InModuleScope PSMicrosoftEntraID {
            $script:passes = 0
            Mock Invoke-EntraRequest {
                $script:passes++
                [pscustomobject]@{ Responses = @([pscustomobject]@{ id = '1'; status = 429; headers = $null; body = $null }) }
            }
            $payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]@{
                Requests = @([PSMicrosoftEntraID.Batch.Request]@{ Id = '1'; Method = 'GET'; Url = '/users/1' })
            }
            $result = Invoke-BatchWithThrottleRetry -Payload $payload -Service 'PSMicrosoftEntraID.Graph' -Header @{} -Path '$batch' -RetryCount 0
            $script:passes | Should -Be 1
            $result[0].Status | Should -Be 429
        }
    }
}
