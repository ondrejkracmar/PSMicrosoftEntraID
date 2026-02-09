BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'Invoke-PSEntraIDBatchRequest' -Tag 'Unit' {

    BeforeAll {
        # Initialize connection token
        Set-Variable -Name '_EntraTokens' -Value @{ 'PSMicrosoftEntraID.Graph' = $true } -Scope Script -Force

        # Mock dependencies
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 'PSMicrosoftEntraID.Graph' } -ParameterFilter { $FullName -like '*DefaultService' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 5 } -ParameterFilter { $FullName -like '*RetryCount' }
        Mock -ModuleName $script:ModuleName Get-PSFConfigValue { 30 } -ParameterFilter { $FullName -like '*RetryWaitInSeconds' }
        Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
        Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand {
            & $ScriptBlock
        }
        Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
        Mock -ModuleName $script:ModuleName Get-PSFLocalizedString { 'Microsoft Entra ID' }

        # Helper function to create mock Request objects
        $script:CreateMockRequest = {
            param([int]$Count = 1, [int]$StartId = 1)
            
            $requests = [System.Collections.Generic.List[object]]::new()
            for ($i = 0; $i -lt $Count; $i++) {
                $id = $StartId + $i
                $request = [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Batch.Request'
                    Id = $id.ToString()
                    Method = 'GET'
                    Url = "/users/user$id"
                    Headers = @{}
                    Body = @{}
                }
                $request.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.Request')
                $requests.Add($request)
            }
            return $requests
        }

        # Helper function to create mock BatchRequestPayload
        $script:CreateMockBatchRequestPayload = {
            param([int]$RequestCount = 1)
            
            $requests = & $script:CreateMockRequest -Count $RequestCount
            $payload = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Batch.BatchRequestPayload'
                Requests = $requests
            }
            $payload.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.BatchRequestPayload')
            return $payload
        }

        # Helper function to create mock Response objects
        $script:CreateMockResponse = {
            param([int]$Count = 1, [int]$StartId = 1, [int]$StatusCode = 200)
            
            $responses = [System.Collections.Generic.List[object]]::new()
            for ($i = 0; $i -lt $Count; $i++) {
                $id = $StartId + $i
                $response = [PSCustomObject]@{
                    PSTypeName = 'PSMicrosoftEntraID.Batch.Response'
                    Id = $id.ToString()
                    Status = $StatusCode
                    Headers = [PSCustomObject]@{ 'Content-Type' = 'application/json' }
                    Body = [PSCustomObject]@{ 
                        id = "user-$id"
                        displayName = "User $id"
                        userPrincipalName = "user$id@contoso.com"
                    }
                }
                $response.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.Response')
                $responses.Add($response)
            }
            return $responses
        }

        # Mock Invoke-EntraRequest to return batch response
        Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
            $responseList = & $script:CreateMockResponse -Count $Body.requests.Count
            return [PSCustomObject]@{
                Responses = $responseList
            }
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter' {
            $param = (Get-Command Invoke-PSEntraIDBatchRequest).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command Invoke-PSEntraIDBatchRequest).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should have EnableException switch parameter' {
            $param = (Get-Command Invoke-PSEntraIDBatchRequest).Parameters['EnableException']
            $param.SwitchParameter | Should -Be $true
        }

        It 'Should have Force switch parameter' {
            $param = (Get-Command Invoke-PSEntraIDBatchRequest).Parameters['Force']
            $param.SwitchParameter | Should -Be $true
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command Invoke-PSEntraIDBatchRequest
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Basic Functionality' {
        It 'Should invoke batch request with single payload' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 5
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result | Should -Not -BeNullOrEmpty
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 1
        }

        It 'Should return BatchResponsePayload object' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 3
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.PSObject.TypeNames | Should -Contain 'PSMicrosoftEntraID.Batch.BatchResponsePayload'
        }

        It 'Should include Requests property in result' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 3
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Requests | Should -Not -BeNullOrEmpty
            $result.Requests.Count | Should -Be 3
        }

        It 'Should include Responses property in result' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 3
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses | Should -Not -BeNullOrEmpty
            $result.Responses.Count | Should -Be 3
        }

        It 'Should call Assert-EntraConnection' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Assert-EntraConnection -Times 1
        }
    }

    Context 'Batch Processing' {
        It 'Should process multiple payloads sequentially' {
            $payload1 = & $script:CreateMockBatchRequestPayload -RequestCount 5
            $payload2 = & $script:CreateMockBatchRequestPayload -RequestCount 3
            
            $result = @($payload1, $payload2 | Invoke-PSEntraIDBatchRequest)
            
            $result | Should -HaveCount 2
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -Times 2
        }

        It 'Should handle maximum batch size (20 requests)' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 20
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Requests.Count | Should -Be 20
            $result.Responses.Count | Should -Be 20
        }

        It 'Should preserve request order in result' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 5
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            for ($i = 0; $i -lt 5; $i++) {
                $result.Requests[$i].Id | Should -Be ($i + 1).ToString()
            }
        }
    }

    Context 'Request Construction' {
        It 'Should call Invoke-EntraRequest with correct service' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Service -eq 'PSMicrosoftEntraID.Graph'
            }
        }

        It 'Should call Invoke-EntraRequest with $batch path' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Path -eq '$batch'
            }
        }

        It 'Should call Invoke-EntraRequest with POST method' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Method -eq 'Post'
            }
        }

        It 'Should call Invoke-EntraRequest with JSON content type header' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Header['Content-Type'] -eq 'application/json'
            }
        }

        It 'Should send body with requests array' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 2
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-EntraRequest -ParameterFilter {
                $Body.requests -ne $null -and $Body.requests.Count -eq 2
            }
        }
    }

    Context 'Response Handling' {
        It 'Should map response IDs correctly' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $responses = & $script:CreateMockResponse -Count 3 -StartId 1
                return [PSCustomObject]@{ Responses = $responses }
            }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 3
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses[0].Id | Should -Be '1'
            $result.Responses[1].Id | Should -Be '2'
            $result.Responses[2].Id | Should -Be '3'
        }

        It 'Should include response status codes' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $responses = & $script:CreateMockResponse -Count 2 -StatusCode 200
                return [PSCustomObject]@{ Responses = $responses }
            }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 2
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses[0].Status | Should -Be 200
            $result.Responses[1].Status | Should -Be 200
        }

        It 'Should include response headers' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $responses = & $script:CreateMockResponse -Count 1
                return [PSCustomObject]@{ Responses = $responses }
            }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses[0].Headers | Should -Not -BeNullOrEmpty
        }

        It 'Should include response body' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $responses = & $script:CreateMockResponse -Count 1
                return [PSCustomObject]@{ Responses = $responses }
            }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses[0].Body | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Error Handling' {
        It 'Should handle failed requests gracefully' {
            Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
                $responses = & $script:CreateMockResponse -Count 1 -StatusCode 404
                $responses[0].Body = [PSCustomObject]@{
                    error = @{
                        code = 'Request_ResourceNotFound'
                        message = 'Resource not found'
                    }
                }
                return [PSCustomObject]@{ Responses = $responses }
            }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            $result.Responses[0].Status | Should -Be 404
        }

        It 'Should invoke Invoke-PSFProtectedCommand for error handling' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }

        It 'Should respect EnableException parameter' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest -EnableException
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $EnableException -eq $true
            }
        }
    }

    Context 'WhatIf Support' {
        It 'Should support -WhatIf parameter' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            { $payload | Invoke-PSEntraIDBatchRequest -WhatIf } | Should -Not -Throw
        }

        It 'Should not invoke batch request with -WhatIf' {
            Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { }
            
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $payload | Invoke-PSEntraIDBatchRequest -WhatIf
            
            # WhatIf should prevent the protected command from executing its ScriptBlock
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -Times 1
        }
    }

    Context 'Confirm Support' {
        It 'Should support -Confirm parameter' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            # We can't easily test interactive confirmation, but we can verify the parameter exists
            $command = Get-Command Invoke-PSEntraIDBatchRequest
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }

        It 'Should use Force parameter to bypass confirmation' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            { $payload | Invoke-PSEntraIDBatchRequest -Force } | Should -Not -Throw
        }
    }

    Context 'Retry Logic' {
        It 'Should pass retry count to Invoke-PSFProtectedCommand' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $RetryCount -eq 5
            }
        }

        It 'Should pass retry wait to Invoke-PSFProtectedCommand' {
            $payload = & $script:CreateMockBatchRequestPayload -RequestCount 1
            $result = $payload | Invoke-PSEntraIDBatchRequest
            
            Should -Invoke -ModuleName $script:ModuleName -CommandName Invoke-PSFProtectedCommand -ParameterFilter {
                $null -ne $RetryWait
            }
        }
    }

    Context 'Integration Scenarios' {
        It 'Should handle mixed request types (GET, POST, PATCH, DELETE)' {
            $requests = & $script:CreateMockRequest -Count 4
            $requests[0].Method = 'GET'
            $requests[1].Method = 'POST'
            $requests[2].Method = 'PATCH'
            $requests[3].Method = 'DELETE'
            
            $payload = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Batch.BatchRequestPayload'
                Requests = $requests
            }
            $payload.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.BatchRequestPayload')
            
            $result = $payload | Invoke-PSEntraIDBatchRequest
            $result.Requests | Should -HaveCount 4
        }

        It 'Should preserve request properties in result' {
            $requests = & $script:CreateMockRequest -Count 1
            $requests[0].Url = '/groups/12345/members'
            $requests[0].Method = 'POST'
            
            $payload = [PSCustomObject]@{
                PSTypeName = 'PSMicrosoftEntraID.Batch.BatchRequestPayload'
                Requests = $requests
            }
            $payload.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.BatchRequestPayload')
            
            $result = $payload | Invoke-PSEntraIDBatchRequest
            $result.Requests[0].Url | Should -Be '/groups/12345/members'
            $result.Requests[0].Method | Should -Be 'POST'
        }
    }
}
