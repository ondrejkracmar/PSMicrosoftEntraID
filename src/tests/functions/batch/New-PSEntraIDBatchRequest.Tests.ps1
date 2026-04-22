BeforeAll {
    $script:ModuleName = 'PSMicrosoftEntraID'

    # Create dummy EntraToken class to prevent type loading errors in tests
    if (-not ([System.Management.Automation.PSTypeName]'EntraToken').Type) {
        Add-Type -Language CSharp -TypeDefinition 'public class EntraToken { public string AccessToken; public string RefreshToken; public string ClientID; public string TenantID; public System.DateTime ValidAfter; public System.DateTime ValidUntil; }'
    }
}

Describe 'New-PSEntraIDBatchRequest' -Tag 'Unit' {

    BeforeAll {
        # Create mock Request objects for testing
        $script:CreateMockRequest = {
            param([int]$Count = 1, [int]$StartId = 1)
            
            $requests = @()
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
                # Ensure the object has the expected type
                $request.PSObject.TypeNames.Insert(0, 'PSMicrosoftEntraID.Batch.Request')
                $requests += $request
            }
            return $requests
        }
    }

    Context 'Parameter Validation' {
        It 'Should have mandatory InputObject parameter' {
            $param = (Get-Command New-PSEntraIDBatchRequest).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
        }

        It 'Should accept pipeline input for InputObject' {
            $param = (Get-Command New-PSEntraIDBatchRequest).Parameters['InputObject']
            $param.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
        }

        It 'Should support ShouldProcess' {
            $command = Get-Command New-PSEntraIDBatchRequest
            $command.Parameters.ContainsKey('WhatIf') | Should -Be $true
            $command.Parameters.ContainsKey('Confirm') | Should -Be $true
        }
    }

    Context 'Basic Functionality' {
        It 'Should accept a single request object' {
            $request = & $script:CreateMockRequest -Count 1
            $result = $request | New-PSEntraIDBatchRequest
            $result | Should -Not -BeNullOrEmpty
            $result.Requests | Should -HaveCount 1
        }

        It 'Should accept multiple request objects' {
            $requests = & $script:CreateMockRequest -Count 5
            $result = $requests | New-PSEntraIDBatchRequest
            $result | Should -Not -BeNullOrEmpty
            $result.Requests | Should -HaveCount 5
        }

        It 'Should reindex request Ids starting from 1' {
            $requests = & $script:CreateMockRequest -Count 3 -StartId 100
            $result = $requests | New-PSEntraIDBatchRequest
            $result.Requests[0].Id | Should -Be '1'
            $result.Requests[1].Id | Should -Be '2'
            $result.Requests[2].Id | Should -Be '3'
        }

        It 'Should output PSMicrosoftEntraID.Batch.BatchRequestPayload type' {
            $request = & $script:CreateMockRequest -Count 1
            $result = $request | New-PSEntraIDBatchRequest
            $result.PSObject.TypeNames | Should -Contain 'PSMicrosoftEntraID.Batch.BatchRequestPayload'
        }
    }

    Context 'Batch Size Handling' {
        It 'Should create single batch for exactly 20 requests' {
            $requests = & $script:CreateMockRequest -Count 20
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 1
            $result[0].Requests | Should -HaveCount 20
        }

        It 'Should create single batch for less than 20 requests' {
            $requests = & $script:CreateMockRequest -Count 15
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 1
            $result[0].Requests | Should -HaveCount 15
        }

        It 'Should create multiple batches for more than 20 requests' {
            $requests = & $script:CreateMockRequest -Count 25
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 2
            $result[0].Requests | Should -HaveCount 20
            $result[1].Requests | Should -HaveCount 5
        }

        It 'Should create 3 batches for 50 requests' {
            $requests = & $script:CreateMockRequest -Count 50
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 3
            $result[0].Requests | Should -HaveCount 20
            $result[1].Requests | Should -HaveCount 20
            $result[2].Requests | Should -HaveCount 10
        }

        It 'Should reindex each batch starting from 1' {
            $requests = & $script:CreateMockRequest -Count 25
            $result = @($requests | New-PSEntraIDBatchRequest)
            
            # First batch should be 1-20
            $result[0].Requests[0].Id | Should -Be '1'
            $result[0].Requests[19].Id | Should -Be '20'
            
            # Second batch should also be 1-5
            $result[1].Requests[0].Id | Should -Be '1'
            $result[1].Requests[4].Id | Should -Be '5'
        }
    }

    Context 'Request Properties Preservation' {
        It 'Should preserve Method property' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Method = 'POST'
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'POST'
        }

        It 'Should preserve Url property' {
            $request = & $script:CreateMockRequest -Count 1
            $customUrl = '/groups/12345/members'
            $request[0].Url = $customUrl
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Url | Should -Be $customUrl
        }

        It 'Should preserve Headers property' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Headers = @{ 'Custom-Header' = 'CustomValue' }
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Headers['Custom-Header'] | Should -Be 'CustomValue'
        }

        It 'Should preserve Body property' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Body = @{ 'displayName' = 'Test User' }
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Body['displayName'] | Should -Be 'Test User'
        }
    }

    Context 'Edge Cases' {
        It 'Should handle empty array input gracefully' {
            $result = @() | New-PSEntraIDBatchRequest
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle exactly 40 requests (2 full batches)' {
            $requests = & $script:CreateMockRequest -Count 40
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 2
            $result[0].Requests | Should -HaveCount 20
            $result[1].Requests | Should -HaveCount 20
        }

        It 'Should handle exactly 60 requests (3 full batches)' {
            $requests = & $script:CreateMockRequest -Count 60
            $result = @($requests | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 3
            $result[0].Requests | Should -HaveCount 20
            $result[1].Requests | Should -HaveCount 20
            $result[2].Requests | Should -HaveCount 20
        }
    }

    Context 'Pipeline Processing' {
        It 'Should process multiple arrays passed via pipeline' {
            $batch1 = & $script:CreateMockRequest -Count 15
            $batch2 = & $script:CreateMockRequest -Count 10
            
            # When arrays are passed together, they get combined (total 25 = 20 + 5)
            $result = @($batch1, $batch2 | New-PSEntraIDBatchRequest)
            $result | Should -HaveCount 2
            $result[0].Requests | Should -HaveCount 20
            $result[1].Requests | Should -HaveCount 5
        }

        It 'Should handle individual requests passed one at a time' {
            $request1 = (& $script:CreateMockRequest -Count 1)[0]
            $request2 = (& $script:CreateMockRequest -Count 1)[0]
            $request3 = (& $script:CreateMockRequest -Count 1)[0]
            
            $result = $request1, $request2, $request3 | New-PSEntraIDBatchRequest
            $result.Requests | Should -HaveCount 3
        }
    }

    Context 'Different HTTP Methods' {
        It 'Should handle GET requests' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Method = 'GET'
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'GET'
        }

        It 'Should handle POST requests' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Method = 'POST'
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'POST'
        }

        It 'Should handle PATCH requests' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Method = 'PATCH'
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'PATCH'
        }

        It 'Should handle DELETE requests' {
            $request = & $script:CreateMockRequest -Count 1
            $request[0].Method = 'DELETE'
            $result = $request | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'DELETE'
        }

        It 'Should handle mixed method types in single batch' {
            $requests = & $script:CreateMockRequest -Count 4
            $requests[0].Method = 'GET'
            $requests[1].Method = 'POST'
            $requests[2].Method = 'PATCH'
            $requests[3].Method = 'DELETE'
            
            $result = $requests | New-PSEntraIDBatchRequest
            $result.Requests[0].Method | Should -Be 'GET'
            $result.Requests[1].Method | Should -Be 'POST'
            $result.Requests[2].Method | Should -Be 'PATCH'
            $result.Requests[3].Method | Should -Be 'DELETE'
        }
    }
}
