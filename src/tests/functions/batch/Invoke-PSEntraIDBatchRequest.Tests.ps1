<#
.SYNOPSIS
	Invoke-PSEntraIDBatchRequest end to end on the parallel batch engine, against a local fake $batch server
	(127.0.0.1, nothing leaves the machine): output shape and order, per-sub-request retry (only the failed ones),
	Retry-After honoured and capped, no re-send of a POST after a 500, exactly one retry layer, one error record per
	failed sub-request and one summary per run, -EnableException, -WhatIf, cancellation, the host guard.

.DESCRIPTION
	The cmdlet sends through [PSMicrosoftEntraID.Batch.GraphBatchClient] directly - no mock catches it - so the default
	Graph service is pointed at the local server before every call (Assert-TestLocalService) and every call line is
	marked '# Local test server' (general/NoNetwork.Tests.ps1). Only the clock (Start-Sleep) is mocked where a test
	waits for a Retry-After.
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
	. (Join-Path $PSScriptRoot 'BatchTestHelper.ps1')
	$script:manifest = (Resolve-Path "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1").Path
	Enable-TestHttpLoopback
	$script:service = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.DefaultService'
	$script:serviceBefore = InModuleScope PSMicrosoftEntraID -Parameters @{ Service = $script:service } { param ($Service) $script:_EntraTokens[$Service] }
	$script:retryBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount'

	function New-TestPayload {
		# A BatchRequestPayload of -Count requests with the ids 1..Count; -Url builds the URL of a request from its id.
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper: builds an in-memory payload, changes no state.')]
		param ([int]$Count, [scriptblock]$Url = { "/users/u$_" }, [string]$Method = 'GET', [hashtable]$Body)
		$payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]::new()
		foreach ($id in 1..$Count) {
			$request = [PSMicrosoftEntraID.Batch.Request]::new()
			$request.Id = [string]$id
			$request.Method = $Method
			$request.Url = $id | ForEach-Object $Url
			if ($Body) { $request.Body = $Body.Clone() }
			$payload.Requests.Add($request)
		}
		$payload
	}

	function Use-TestServer {
		# Points the default Graph service at -Server and refuses to go on unless it is the local server.
		param ($Server, [string]$Url)
		if (-not $Url) { $Url = "$($Server.Url)/v1.0" }
		Set-TestBatchService -Service $script:service -Url $Url
		if (-not $PSBoundParameters.ContainsKey('Url')) { Assert-TestLocalService -Service $script:service }
	}

	function Wait-TestBatchIdle {
		# Waits until the envelopes in flight of the process are down to -Baseline; returns whether that happened.
		param ([int]$Seconds = 5, [int]$Baseline = 0)
		$waited = [System.Diagnostics.Stopwatch]::StartNew()
		while ([PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight -gt $Baseline -and $waited.Elapsed.TotalSeconds -lt $Seconds) { Start-Sleep -Milliseconds 50 }
		[PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight -le $Baseline
	}
}

AfterAll {
	Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value $script:retryBefore
	InModuleScope PSMicrosoftEntraID -Parameters @{ Service = $script:service; Before = $script:serviceBefore } {
		param ($Service, $Before)
		if ($Before) { $script:_EntraTokens[$Service] = $Before } else { $script:_EntraTokens.Remove($Service) }
	}
	Enable-TestHttpLoopback -Disable
}

Describe 'Invoke-PSEntraIDBatchRequest' -Tag 'Unit' {

	BeforeEach {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value 5
		$script:warnings = [System.Collections.Generic.List[object]]::new()
		Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { if ($Level -eq 'Warning') { $script:warnings.Add([pscustomobject]@{ String = $String; Values = $StringValues }) } }
		$script:server = New-TestBatchServer
		Use-TestServer -Server $script:server
	}

	AfterEach {
		$script:server.Dispose()
	}

	Context 'Parameters (unchanged)' {

		It 'keeps InputObject (mandatory, from the pipeline), EnableException, Force, WhatIf and Confirm' {
			$command = Get-Command Invoke-PSEntraIDBatchRequest
			$inputObject = $command.Parameters['InputObject']
			$inputObject.ParameterType | Should -Be ([PSMicrosoftEntraID.Batch.BatchRequestPayload[]])
			$inputObject.Attributes.Where{ $_ -is [Parameter] }.Mandatory | Should -Contain $true
			$inputObject.Attributes.Where{ $_ -is [Parameter] }.ValueFromPipeline | Should -Contain $true
			$command.Parameters['EnableException'].SwitchParameter | Should -BeTrue
			$command.Parameters['Force'].SwitchParameter | Should -BeTrue
			$command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
			$command.Parameters.ContainsKey('Confirm') | Should -BeTrue
			$command.OutputType.Type | Should -Contain ([PSMicrosoftEntraID.Batch.BatchResponsePayload])
		}
	}

	Context 'Output' {

		It 'returns one BatchResponsePayload per payload, in the order of the input, with the responses in request order' {
			$payloads = @(
				New-TestPayload -Count 5 -Url { "/users/a$_" }
				New-TestPayload -Count 20 -Url { "/users/b$_" }
				New-TestPayload -Count 3 -Url { "/users/c$_" }
			)
			$results = @($payloads | Invoke-PSEntraIDBatchRequest -Force) # Local test server
			$results.Count | Should -Be 3
			$results | ForEach-Object { $_ | Should -BeOfType ([PSMicrosoftEntraID.Batch.BatchResponsePayload]) }
			for ($index = 0; $index -lt 3; $index++) {
				$prefix = 'a', 'b', 'c' | Select-Object -Index $index
				$result = $results[$index]
				$result.Requests.Count | Should -Be $result.Responses.Count
				for ($position = 0; $position -lt $result.Requests.Count; $position++) {
					$response = $result.Responses[$position]
					$response | Should -BeOfType ([PSMicrosoftEntraID.Batch.Response])
					$response.Id | Should -Be $result.Requests[$position].Id
					$response.Status | Should -Be 200
					$response.Body.value[0].displayName | Should -Be "/users/$prefix$($response.Id)"
					$response.Headers.'Content-Type' | Should -Be 'application/json'
				}
			}
			# 28 sub-requests are two envelopes of at most 20, whatever payload they came from.
			$script:server.Envelopes | Should -Be 2
			$script:warnings.Count | Should -Be 0
		}

		It 'sends a GET without a body and a POST with its body' {
			$payloads = @(
				New-TestPayload -Count 1 -Url { '/users/u1' }
				New-TestPayload -Count 1 -Url { '/groups/g1/members/$ref' } -Method POST -Body @{ '@odata.id' = 'https://graph.microsoft.com/v1.0/directoryObjects/u1' }
			)
			$null = $payloads | Invoke-PSEntraIDBatchRequest -Force # Local test server
			$requests = @(($script:server.Bodies | ForEach-Object { ($_ | ConvertFrom-Json).requests }))
			$get = $requests | Where-Object method -EQ 'GET'
			$post = $requests | Where-Object method -EQ 'POST'
			$get.PSObject.Properties.Name | Should -Not -Contain 'body'
			$post.body.'@odata.id' | Should -Be 'https://graph.microsoft.com/v1.0/directoryObjects/u1'
			$post.headers.'Content-Type' | Should -Be 'application/json'
		}

		It 'sends nothing with -WhatIf' {
			$null = New-TestPayload -Count 3 | Invoke-PSEntraIDBatchRequest -WhatIf # Local test server
			$script:server.Envelopes | Should -Be 0
		}
	}

	Context 'Retry: per sub-request, only the failed ones, one layer' {

		BeforeEach {
			$script:slept = [System.Collections.Generic.List[int]]::new()
			Mock -ModuleName PSMicrosoftEntraID Start-Sleep { $script:slept.Add($Milliseconds) }
		}

		It 'sends again only the sub-requests answered 429 or 503, and returns every final answer' {
			$script:server.Plan('/users/u2', [int[]]@(429, 429), '2')
			$script:server.Plan('/users/u3', [int[]]@(404), $null)
			$script:server.Plan('/users/u4', [int[]]@(503), '2')
			$errors = $null
			$result = New-TestPayload -Count 5 | Invoke-PSEntraIDBatchRequest -Force -ErrorVariable errors -ErrorAction SilentlyContinue # Local test server
			$result.Responses.Status | Should -Be @(200, 200, 404, 200, 200)
			$result.Responses[2].Body.error.code | Should -Be 'Planned'
			$script:server.Hits('/users/u1') | Should -Be 1
			$script:server.Hits('/users/u2') | Should -Be 3
			$script:server.Hits('/users/u3') | Should -Be 1 -Because 'a 404 is final'
			$script:server.Hits('/users/u4') | Should -Be 2
			$script:server.Hits('/users/u5') | Should -Be 1
			# The Retry-After of the throttled sub-request is waited for (plus the 50 ms that lets due requests share an envelope).
			$script:slept | Where-Object { $_ -ge 1900 -and $_ -le 2100 } | Should -Not -BeNullOrEmpty
			@($errors).Count | Should -Be 1
			$errors[0].TargetObject.Url | Should -Be '/users/u3'
			$errors[0].CategoryInfo.Category | Should -Be 'ObjectNotFound'
			$script:warnings.Count | Should -Be 1 -Because 'one summary per run'
			$script:warnings[0].String | Should -Be 'Batch.Summary'
		}

		It 'caps a Retry-After of an hour at 5 minutes' {
			$script:server.Plan('/users/u1', [int[]]@(429), '3600')
			$result = New-TestPayload -Count 1 | Invoke-PSEntraIDBatchRequest -Force # Local test server
			$result.Responses[0].Status | Should -Be 200
			$longest = ($script:slept | Measure-Object -Maximum).Maximum
			$longest | Should -BeGreaterThan 290000
			$longest | Should -BeLessOrEqual 300100
		}

		It 'does not send a POST again after <Status>' -ForEach @(@{ Status = 500 }, @{ Status = 502 }, @{ Status = 504 }) {
			$script:server.Plan('/groups/g1/members/$ref', [int[]]@($Status), $null)
			$result = New-TestPayload -Count 1 -Url { '/groups/g1/members/$ref' } -Method POST -Body @{ '@odata.id' = 'x' } | Invoke-PSEntraIDBatchRequest -Force -ErrorAction SilentlyContinue # Local test server
			$result.Responses[0].Status | Should -Be $Status
			$script:server.Hits('/groups/g1/members/$ref') | Should -Be 1
		}

		It 'sends a POST again after 429 and 503' {
			$script:server.Plan('/groups/g1/members/$ref', [int[]]@(429, 503), $null)
			$result = New-TestPayload -Count 1 -Url { '/groups/g1/members/$ref' } -Method POST -Body @{ '@odata.id' = 'x' } | Invoke-PSEntraIDBatchRequest -Force # Local test server
			$result.Responses[0].Status | Should -Be 200
			$script:server.Hits('/groups/g1/members/$ref') | Should -Be 3
		}

		It 'sends a sub-request that keeps failing exactly Settings.Batch.RetryCount + 1 times' {
			Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value 2
			$script:server.Plan('/users/u1', [int[]]@(503, 503, 503, 503, 503, 503, 503, 503), $null)
			$result = New-TestPayload -Count 2 | Invoke-PSEntraIDBatchRequest -Force -ErrorAction SilentlyContinue # Local test server
			$result.Responses.Status | Should -Be @(503, 200)
			$script:server.Hits('/users/u1') | Should -Be 3
			$script:server.Hits('/users/u2') | Should -Be 1
		}
	}

	Context 'Failures: one error record per failed sub-request, one summary, -EnableException' {

		It 'writes one error record per failed sub-request, its request as the target, and one summary' {
			$script:server.Plan('/users/b1', [int[]]@(403), $null)
			$script:server.Plan('/users/b2', [int[]]@(404), $null)
			$errors = $null
			$results = @(@((New-TestPayload -Count 2 -Url { "/users/a$_" }), (New-TestPayload -Count 2 -Url { "/users/b$_" })) | Invoke-PSEntraIDBatchRequest -Force -ErrorVariable errors -ErrorAction SilentlyContinue) # Local test server
			$results.Count | Should -Be 2
			@($errors).Count | Should -Be 2
			@($errors.TargetObject.Url | Sort-Object) | Should -Be @('/users/b1', '/users/b2')
			@($errors | ForEach-Object { $_.Exception.Message }) -join '|' | Should -BeLike '*Request 1 of batch 2*'
			$script:warnings.Count | Should -Be 1
			[string]$script:warnings[0].Values | Should -BeLike '2 of 4 sub-request(s) failed*'
		}

		It 'with -EnableException writes no error record and throws at the end, after all results were returned' {
			$script:server.Plan('/users/u2', [int[]]@(404), $null)
			$results = [System.Collections.Generic.List[object]]::new()
			$errors = $null
			{ New-TestPayload -Count 3 | Invoke-PSEntraIDBatchRequest -Force -EnableException -ErrorVariable errors | ForEach-Object { $results.Add($_) } } | Should -Throw '*1 of 3 sub-request(s)*' # Local test server
			$results.Count | Should -Be 1
			$results[0].Responses.Status | Should -Be @(200, 404, 200)
			@($errors | Where-Object { $_.FullyQualifiedErrorId -like 'PSMicrosoftEntraID_ItemFailed*' }).Count | Should -Be 0
		}

		It 'refuses a service URL the client may not reach: every sub-request comes back 421, nothing is sent' {
			# Plain http to a loopback host the test hook does not list - the guard of the client, not a mock.
			Use-TestServer -Server $script:server -Url 'http://127.0.0.2:1/v1.0'
			$errors = $null
			$result = New-TestPayload -Count 2 | Invoke-PSEntraIDBatchRequest -Force -ErrorVariable errors -ErrorAction SilentlyContinue # Local test server
			$result.Responses.Status | Should -Be @(421, 421)
			$result.Responses[0].Body.error.message | Should -Not -BeNullOrEmpty
			@($errors).Count | Should -Be 2
			$errors[0].CategoryInfo.Category | Should -Be 'SecurityError'
			$script:server.Envelopes | Should -Be 0
		}
	}

	Context 'Cancellation' {

		It 'Select-Object -First stops the run and cancels the envelopes still in flight' {
			$script:server.Dispose()
			$script:server = New-TestBatchServer -DelayMilliseconds 1500
			Use-TestServer -Server $script:server
			$null = Wait-TestBatchIdle
			[int] $baseline = [PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight
			# Three envelopes of 20 in flight together; the first result ends the run.
			$payloads = @(foreach ($batch in 1..3) { New-TestPayload -Count 20 -Url { "/users/p$batch-$_" }.GetNewClosure() })
			$watch = [System.Diagnostics.Stopwatch]::StartNew()
			$first = @($payloads | Invoke-PSEntraIDBatchRequest -Force | Select-Object -First 1) # Local test server
			$watch.Stop()
			$first.Count | Should -Be 1
			$first[0].Responses.Count | Should -Be 20
			Wait-TestBatchIdle -Baseline $baseline | Should -BeTrue -Because 'no envelope keeps running after the run ended'
		}

		It 'a stopped pipeline (Ctrl+C) cancels every envelope in flight at once' {
			$script:server.Dispose()
			$script:server = New-TestBatchServer -Hang
			$null = Wait-TestBatchIdle
			[int] $baseline = [PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight
			$shell = [powershell]::Create()
			try {
				$null = $shell.AddScript({
						param ($Manifest, $Url, $Service)
						Import-Module $Manifest
						# The test hook of this process is shared: the loopback host is listed already.
						& (Get-Module PSMicrosoftEntraID) {
							param ($Url, $Service)
							if ($Url -notmatch '^http://127\.0\.0\.1:\d+') { throw "Not the local test server: $Url" }
							$fakeToken = [pscustomobject]@{ Service = $Service; ServiceUrl = "$Url/v1.0" }
							Add-Member -InputObject $fakeToken -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer test' } }
							$script:_EntraTokens[$Service] = $fakeToken
						} $Url $Service
						$payloads = foreach ($batch in 1..3) {
							$payload = [PSMicrosoftEntraID.Batch.BatchRequestPayload]::new()
							foreach ($id in 1..20) { $payload.Requests.Add([PSMicrosoftEntraID.Batch.Request]@{ Id = [string]$id; Method = 'GET'; Url = "/users/p$batch-$id" }) }
							$payload
						}
						$payloads | Invoke-PSEntraIDBatchRequest -Force # Local test server
					}).AddArgument($script:manifest).AddArgument($script:server.Url).AddArgument($script:service)
				$null = $shell.BeginInvoke()
				$waited = [System.Diagnostics.Stopwatch]::StartNew()
				while ($script:server.Envelopes -lt 3 -and $waited.Elapsed.TotalSeconds -lt 30) { Start-Sleep -Milliseconds 100 }
				$script:server.Envelopes | Should -Be 3 -Because 'the three envelopes are in flight at the same time'
				$stopping = [System.Diagnostics.Stopwatch]::StartNew()
				$stop = $shell.BeginStop($null, $null)
				$stop.AsyncWaitHandle.WaitOne(5000) | Should -BeTrue -Because 'stopping the pipeline cancels the envelopes'
				$stopping.Elapsed.TotalSeconds | Should -BeLessThan 3
				Wait-TestBatchIdle -Baseline $baseline | Should -BeTrue -Because 'the envelopes still in flight are cancelled, not left running'
			}
			finally {
				if ($shell.InvocationStateInfo.State -notin 'Running', 'Stopping') { $shell.Dispose() }
			}
		}
	}
}
