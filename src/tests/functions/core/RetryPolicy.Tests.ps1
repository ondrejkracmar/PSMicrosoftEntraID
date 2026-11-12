<#
.SYNOPSIS
	The one retry policy of the module: Test-EntraRetryStatus (which status is worth sending again) and
	Invoke-EntraRetry (the single retry layer of one call: Retry-After honoured, exponential fallback with jitter,
	at most 5 minutes per wait, a POST only on 429 and 503).
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force

	function New-TestHttpFailure {
		# The failure Invoke-RestMethod throws for an HTTP error answer: an HttpResponseException carrying the response.
		param ([int]$Status, [string]$RetryAfter)
		$response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]$Status)
		if ($RetryAfter) { $null = $response.Headers.TryAddWithoutValidation('Retry-After', $RetryAfter) }
		[Microsoft.PowerShell.Commands.HttpResponseException]::new("Response status code does not indicate success: $Status.", $response)
	}
}

Describe 'Test-EntraRetryStatus' -Tag 'Unit' {

	It 'repeats <Status> of a call that is safe to repeat: <Expected>' -ForEach @(
		@{ Status = 408; Expected = $true }
		@{ Status = 429; Expected = $true }
		@{ Status = 500; Expected = $true }
		@{ Status = 502; Expected = $true }
		@{ Status = 503; Expected = $true }
		@{ Status = 504; Expected = $true }
		@{ Status = 599; Expected = $true }
		@{ Status = 501; Expected = $false }
		@{ Status = 505; Expected = $false }
		@{ Status = 400; Expected = $false }
		@{ Status = 401; Expected = $false }
		@{ Status = 403; Expected = $false }
		@{ Status = 404; Expected = $false }
		@{ Status = 410; Expected = $false }
		@{ Status = 421; Expected = $false }
		@{ Status = 200; Expected = $false }
		@{ Status = 0; Expected = $false }
	) {
		InModuleScope PSMicrosoftEntraID -Parameters @{ Status = $Status } { param ($Status) Test-EntraRetryStatus -Status $Status } | Should -Be $Expected
	}

	It 'repeats <Status> of a call that is not idempotent: <Expected>' -ForEach @(
		@{ Status = 429; Expected = $true }
		@{ Status = 503; Expected = $true }
		@{ Status = 408; Expected = $false }
		@{ Status = 500; Expected = $false }
		@{ Status = 502; Expected = $false }
		@{ Status = 504; Expected = $false }
		@{ Status = 404; Expected = $false }
	) {
		InModuleScope PSMicrosoftEntraID -Parameters @{ Status = $Status } { param ($Status) Test-EntraRetryStatus -Status $Status -NotIdempotent } | Should -Be $Expected
	}

	It 'repeats a <Status> with the codes <Code> (not idempotent: <NotIdempotent>): <Expected>' -ForEach @(
		@{ Status = 400; Code = @('Directory_ConcurrencyViolation'); NotIdempotent = $false; Expected = $true }
		@{ Status = 400; Code = @('Directory_ConcurrencyViolation'); NotIdempotent = $true; Expected = $true }
		@{ Status = 400; Code = @('Request_BadRequest', 'Directory_ConcurrencyViolation'); NotIdempotent = $true; Expected = $true }
		@{ Status = 400; Code = @('Request_BadRequest'); NotIdempotent = $false; Expected = $false }
		@{ Status = 400; Code = @(); NotIdempotent = $false; Expected = $false }
		@{ Status = 400; Code = @('directory_concurrencyviolation_x'); NotIdempotent = $false; Expected = $false }
		@{ Status = 409; Code = @('Directory_ConcurrencyViolation'); NotIdempotent = $false; Expected = $false }
		@{ Status = 403; Code = @('Directory_ConcurrencyViolation'); NotIdempotent = $true; Expected = $false }
	) {
		InModuleScope PSMicrosoftEntraID -Parameters @{ Status = $Status; Code = $Code; NotIdempotent = $NotIdempotent } {
			param ($Status, $Code, $NotIdempotent)
			Test-EntraRetryStatus -Status $Status -ErrorCode $Code -NotIdempotent:$NotIdempotent
		} | Should -Be $Expected
	}
}

Describe 'Invoke-EntraRetry' -Tag 'Unit' {

	BeforeEach {
		$script:slept = [System.Collections.Generic.List[int]]::new()
		Mock -ModuleName PSMicrosoftEntraID Start-Sleep { $script:slept.Add($Milliseconds) }
		Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { }
	}

	It 'repeats a call answered <Status> and returns the result of the attempt that got through' -ForEach @(
		@{ Status = 429 }, @{ Status = 503 }, @{ Status = 500 }, @{ Status = 504 }, @{ Status = 408 }
	) {
		$counter = @{ N = 0 }
		$result = InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status $Status) } {
			param ($Failure, $Counter)
			Invoke-EntraRetry -RetryCount 3 -ScriptBlock { $Counter.N++; if ($Counter.N -lt 3) { throw $Failure }; 'done' }
		}
		$result | Should -Be 'done'
		$counter.N | Should -Be 3
		$script:slept.Count | Should -Be 2
	}

	It 'waits the Retry-After of the answer given as <Case>' -ForEach @(
		@{ Case = 'seconds'; Value = '7'; Minimum = 7000; Maximum = 7000 }
		@{ Case = 'seconds over 5 minutes, as 5 minutes'; Value = '3600'; Minimum = 300000; Maximum = 300000 }
		@{ Case = 'an HTTP date'; Offset = 60; Minimum = 55000; Maximum = 61000 }
		@{ Case = 'an HTTP date over 5 minutes, as 5 minutes'; Offset = 7200; Minimum = 300000; Maximum = 300000 }
	) {
		$value = if ($Offset) { [DateTimeOffset]::UtcNow.AddSeconds($Offset).ToString('r', [cultureinfo]::InvariantCulture) } else { $Value }
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status 429 -RetryAfter $value) } {
			param ($Failure, $Counter)
			$null = Invoke-EntraRetry -RetryCount 1 -ScriptBlock { $Counter.N++; if ($Counter.N -eq 1) { throw $Failure } }
		}
		$script:slept.Count | Should -Be 1
		$script:slept[0] | Should -BeGreaterOrEqual $Minimum
		$script:slept[0] | Should -BeLessOrEqual $Maximum
	}

	It 'waits 2^attempt seconds with a jitter of 0.8 to 1.2 without a Retry-After, at most 5 minutes' {
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status 503) } {
			param ($Failure, $Counter)
			{ Invoke-EntraRetry -RetryCount 10 -ScriptBlock { throw $Failure } } | Should -Throw
		}
		$script:slept.Count | Should -Be 10
		for ($attempt = 1; $attempt -le 8; $attempt++) {
			$script:slept[$attempt - 1] | Should -BeGreaterOrEqual ([Math]::Floor([Math]::Pow(2, $attempt) * 800)) -Because "attempt $attempt"
			$script:slept[$attempt - 1] | Should -BeLessOrEqual ([Math]::Ceiling([Math]::Pow(2, $attempt) * 1200)) -Because "attempt $attempt"
		}
		# 2^9 = 512 s and 2^10 = 1024 s are capped at 5 minutes.
		$script:slept[8] | Should -Be 300000
		$script:slept[9] | Should -Be 300000
	}

	It 'does not wait the same time on every call: the fallback is jittered' {
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status 503) } {
			param ($Failure, $Counter)
			foreach ($run in 1..20) { try { Invoke-EntraRetry -RetryCount 1 -ScriptBlock { throw $Failure } } catch { $null = $_ } }
		}
		@($script:slept | Sort-Object -Unique).Count | Should -BeGreaterThan 1
	}

	It 'throws the last failure as it is after RetryCount repetitions' {
		$counter = @{ N = 0 }
		$failure = New-TestHttpFailure -Status 503
		$thrown = InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = $failure } {
			param ($Failure, $Counter)
			try { Invoke-EntraRetry -RetryCount 2 -ScriptBlock { $Counter.N++; throw $Failure } } catch { $_ }
		}
		$counter.N | Should -Be 3
		$thrown.Exception | Should -Be $failure
	}

	It 'takes the number of repetitions from Settings.Request.RetryCount' {
		$counter = @{ N = 0 }
		Mock -ModuleName PSMicrosoftEntraID Get-PSFConfigValue { 1 } -ParameterFilter { $FullName -eq 'PSMicrosoftEntraID.Settings.Request.RetryCount' }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status 429) } {
			param ($Failure, $Counter)
			try { Invoke-EntraRetry -ScriptBlock { $Counter.N++; throw $Failure } } catch { $null = $_ }
		}
		$counter.N | Should -Be 2
	}

	It 'does not repeat a call answered <Status>' -ForEach @(@{ Status = 400 }, @{ Status = 403 }, @{ Status = 404 }, @{ Status = 501 }) {
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status $Status) } {
			param ($Failure, $Counter)
			{ Invoke-EntraRetry -RetryCount 5 -ScriptBlock { $Counter.N++; throw $Failure } } | Should -Throw
		}
		$counter.N | Should -Be 1
		$script:slept.Count | Should -Be 0
	}

	It 'repeats a POST answered <Status>: <Expected>' -ForEach @(
		@{ Status = 429; Expected = 2 }, @{ Status = 503; Expected = 2 }, @{ Status = 500; Expected = 1 }, @{ Status = 504; Expected = 1 }
	) {
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status $Status) } {
			param ($Failure, $Counter)
			try { Invoke-EntraRetry -NotIdempotent -RetryCount 1 -ScriptBlock { $Counter.N++; throw $Failure } } catch { $null = $_ }
		}
		$counter.N | Should -Be $Expected
	}

	It 'repeats a read without an answer, but not a POST' {
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter } {
			param ($Counter)
			try { Invoke-EntraRetry -RetryCount 1 -ScriptBlock { $Counter.N++; throw [System.Net.Http.HttpRequestException]::new('No such host is known.') } } catch { $null = $_ }
		}
		$counter.N | Should -Be 2
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter } {
			param ($Counter)
			try { Invoke-EntraRetry -NotIdempotent -RetryCount 1 -ScriptBlock { $Counter.N++; throw [System.TimeoutException]::new('timeout') } } catch { $null = $_ }
		}
		$counter.N | Should -Be 1
	}

	It 'does not repeat a failure of our own code' {
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter } {
			param ($Counter)
			{ Invoke-EntraRetry -RetryCount 3 -ScriptBlock { $Counter.N++; throw 'conversion failed' } } | Should -Throw 'conversion failed'
		}
		$counter.N | Should -Be 1
	}

	It 'counts every repetition in the run report' {
		$report = @{}
		$counter = @{ N = 0 }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Counter = $counter; Failure = (New-TestHttpFailure -Status 429 -RetryAfter '9'); Report = $report } {
			param ($Failure, $Report, $Counter)
			$null = Invoke-EntraRetry -RetryCount 3 -Report $Report -ScriptBlock { $Counter.N++; if ($Counter.N -lt 3) { throw $Failure } }
		}
		$report.Resent | Should -Be 2
		$report.Throttled | Should -Be 2
		$report['Resent.Recovered'] | Should -Be 1
		$report['Resent.Longest'] | Should -Be 9
	}
}
