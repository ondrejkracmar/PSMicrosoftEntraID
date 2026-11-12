<#
.SYNOPSIS
	Invoke-EntraRequest on the one retry policy of the module, through the real code path: only the HTTP layer
	(Invoke-RestMethod) and the clock (Start-Sleep) are faked, nothing reaches the network.

.DESCRIPTION
	- 429 with Retry-After honoured (seconds and HTTP date) and capped at 5 minutes;
	- a POST is repeated only on 429 and 503 - never after a 500;
	- exactly one retry layer: a request that keeps failing is sent Settings.Request.RetryCount + 1 times, also
	  through Invoke-PSEntraIDRequest and a cmdlet, which call Invoke-PSFProtectedCommand around it;
	- a failed page is repeated on its own, the pages before it are not emitted again;
	- Settings.Request.TimeoutSeconds reaches the request;
	- the token host guard stays in front of every request and every next link.
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force

	function New-TestHttpFailure {
		# The failure Invoke-RestMethod throws for an HTTP error answer: an HttpResponseException carrying the response.
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper: builds an exception object, changes no state.')]
		param ([int]$Status, [string]$RetryAfter)
		$response = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]$Status)
		if ($RetryAfter) { $null = $response.Headers.TryAddWithoutValidation('Retry-After', $RetryAfter) }
		[Microsoft.PowerShell.Commands.HttpResponseException]::new("Response status code does not indicate success: $Status.", $response)
	}

	function Set-TestAnswer {
		# What the fake HTTP layer answers, in order: an exception is thrown, anything else returned. The last answer
		# repeats once the list is used up.
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test helper: sets a variable of the test file, changes no system state.')]
		param ([object[]]$Answer)
		$script:answers = [System.Collections.Generic.List[object]]::new()
		foreach ($item in $Answer) { $script:answers.Add($item) }
	}

	# A fake connected token per service name; the previous token of the default Graph service is put back in AfterAll.
	$script:retryRequestBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount'
	$script:timeoutBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds'
	$script:graphBefore = InModuleScope PSMicrosoftEntraID {
		$previous = $script:_EntraTokens['PSMicrosoftEntraID.Graph']
		foreach ($name in 'RetryGraph', 'PSMicrosoftEntraID.Graph') {
			$token = [pscustomobject]@{ Service = $name; ServiceUrl = 'https://graph.microsoft.com/v1.0'; Query = @{}; RawOnly = $false; HeaderCalls = 0 }
			$token | Add-Member -MemberType ScriptMethod -Name GetHeader -Value { $this.HeaderCalls++; @{ Authorization = 'Bearer S3cr3tAcc3ssT0k3n' } }
			$script:_EntraTokens[$name] = $token
		}
		$script:_EntraEndpoints['RetryGraph'] = [pscustomobject]@{ Parameters = @{} }
		$previous
	}
}

AfterAll {
	Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value $script:retryRequestBefore
	Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value $script:timeoutBefore
	InModuleScope PSMicrosoftEntraID -Parameters @{ Before = $script:graphBefore } {
		param ($Before)
		$script:_EntraTokens.Remove('RetryGraph')
		$script:_EntraEndpoints.Remove('RetryGraph')
		if ($Before) { $script:_EntraTokens['PSMicrosoftEntraID.Graph'] = $Before }
		else { $script:_EntraTokens.Remove('PSMicrosoftEntraID.Graph') }
	}
}

Describe 'Invoke-EntraRequest retries through the one retry policy' -Tag 'Unit' {

	BeforeEach {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value 5
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value 600
		$script:sent = [System.Collections.Generic.List[object]]::new()
		$script:slept = [System.Collections.Generic.List[int]]::new()
		Set-TestAnswer -Answer @([pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }) })
		Mock -ModuleName PSMicrosoftEntraID Start-Sleep { $script:slept.Add($Milliseconds) }
		Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { }
		Mock -ModuleName PSMicrosoftEntraID Invoke-RestMethod {
			$script:sent.Add([pscustomobject]@{ Uri = [string]$Uri; Method = [string]$Method; Headers = $Headers.Clone(); TimeoutSec = [int]$(if (Test-Path variable:ConnectionTimeoutSeconds) { $ConnectionTimeoutSeconds } else { $TimeoutSec }) })
			$answer = $script:answers[[Math]::Min($script:sent.Count, $script:answers.Count) - 1]
			if ($answer -is [System.Exception]) { throw $answer }
			$answer
		}
	}

	It 'repeats a GET answered 429 after the Retry-After of the answer' {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 429 -RetryAfter '7'), [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }) })
		$items = InModuleScope PSMicrosoftEntraID { @(Invoke-EntraRequest -Service RetryGraph -Path 'users') }
		$items.id | Should -Be '1'
		$script:sent.Count | Should -Be 2
		$script:slept | Should -Be @(7000)
	}

	It 'caps a Retry-After of an hour at 5 minutes' {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 429 -RetryAfter '3600'), [pscustomobject]@{ value = @() })
		$null = InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' }
		$script:slept | Should -Be @(300000)
	}

	It 'reads a Retry-After given as an HTTP date' {
		$date = [DateTimeOffset]::UtcNow.AddSeconds(20).ToString('r')
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 503 -RetryAfter $date), [pscustomobject]@{ value = @() })
		$null = InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' }
		$script:slept.Count | Should -Be 1
		$script:slept[0] | Should -BeGreaterThan 15000
		$script:slept[0] | Should -BeLessOrEqual 21000
	}

	It 'sends a request that keeps failing exactly RetryCount + 1 times, then throws the last failure' {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value 2
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 503))
		$caught = { InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' } } | Should -Throw -PassThru
		$caught.Exception | Should -BeOfType [Microsoft.PowerShell.Commands.HttpResponseException]
		$script:sent.Count | Should -Be 3
		$script:slept.Count | Should -Be 2
	}

	It 'does not repeat <Method> answered <Status>' -ForEach @(
		@{ Method = 'POST'; Status = 500 }
		@{ Method = 'POST'; Status = 502 }
		@{ Method = 'POST'; Status = 504 }
		@{ Method = 'POST'; Status = 408 }
		@{ Method = 'GET'; Status = 501 }
		@{ Method = 'GET'; Status = 505 }
		@{ Method = 'GET'; Status = 404 }
		@{ Method = 'PATCH'; Status = 400 }
	) {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status $Status), [pscustomobject]@{ id = 'created' })
		{ InModuleScope PSMicrosoftEntraID -Parameters @{ Method = $Method } { param ($Method) Invoke-EntraRequest -Service RetryGraph -Path 'groups' -Method $Method -Body @{ displayName = 'x' } } } | Should -Throw
		$script:sent.Count | Should -Be 1 -Because "a $Method answered $Status is final"
		$script:slept.Count | Should -Be 0
	}

	It 'repeats <Method> answered <Status>' -ForEach @(
		@{ Method = 'POST'; Status = 429 }
		@{ Method = 'POST'; Status = 503 }
		@{ Method = 'PATCH'; Status = 500 }
		@{ Method = 'DELETE'; Status = 502 }
		@{ Method = 'PUT'; Status = 408 }
	) {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status $Status -RetryAfter '1'), [pscustomobject]@{ id = 'done' })
		$result = InModuleScope PSMicrosoftEntraID -Parameters @{ Method = $Method } { param ($Method) Invoke-EntraRequest -Service RetryGraph -Path 'groups' -Method $Method -Body @{ displayName = 'x' } }
		$result.id | Should -Be 'done'
		$script:sent.Count | Should -Be 2
		$script:sent.Method | Should -Be @($Method, $Method)
	}

	It 'repeats a request that got no answer (GET), not a POST' {
		Set-TestAnswer -Answer @([System.Net.Http.HttpRequestException]::new('No such host is known.'), [pscustomobject]@{ value = @() })
		$null = InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' }
		$script:sent.Count | Should -Be 2
		$script:sent.Clear()
		{ InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'groups' -Method POST -Body @{ displayName = 'x' } } } | Should -Throw
		$script:sent.Count | Should -Be 1
	}

	It 'repeats a failed page on its own: the pages before it are neither sent nor emitted again' {
		Set-TestAnswer -Answer @(
			[pscustomobject]@{ value = @([pscustomobject]@{ id = 'a' }); '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2' }
			(New-TestHttpFailure -Status 503 -RetryAfter '2')
			[pscustomobject]@{ value = @([pscustomobject]@{ id = 'b' }) }
		)
		$items = InModuleScope PSMicrosoftEntraID { @(Invoke-EntraRequest -Service RetryGraph -Path 'users') }
		$items.id | Should -Be @('a', 'b')
		$script:sent.Uri | Should -Be @('https://graph.microsoft.com/v1.0/users', 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2', 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2')
	}

	It 'builds the header afresh for every attempt and keeps the caller''s headers on the repeat' {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 429 -RetryAfter '1'), [pscustomobject]@{ value = @() })
		$calls = InModuleScope PSMicrosoftEntraID {
			$before = $script:_EntraTokens['RetryGraph'].HeaderCalls
			$null = Invoke-EntraRequest -Service RetryGraph -Path 'users' -Header @{ ConsistencyLevel = 'eventual' }
			$script:_EntraTokens['RetryGraph'].HeaderCalls - $before
		}
		$calls | Should -Be 2
		foreach ($request in $script:sent) {
			$request.Headers.ConsistencyLevel | Should -Be 'eventual'
			$request.Headers.Authorization | Should -Be 'Bearer S3cr3tAcc3ssT0k3n'
		}
	}

	It 'passes Settings.Request.TimeoutSeconds to the request (TimeoutSec, ConnectionTimeoutSeconds since PowerShell 7.4), none for 0' {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value 42
		$null = InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' }
		$script:sent[0].TimeoutSec | Should -Be 42
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value 0
		$null = InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'users' }
		$script:sent[1].TimeoutSec | Should -Be 0 -Because 'no timeout is passed: the request may take as long as it takes'
	}

	It 'still refuses a foreign host: as -Path before anything is sent, as a next link after a repeated page' {
		{ InModuleScope PSMicrosoftEntraID { Invoke-EntraRequest -Service RetryGraph -Path 'https://attacker.example/v1.0/users' } } | Should -Throw '*goes only to https://graph.microsoft.com*'
		$script:sent.Count | Should -Be 0

		Set-TestAnswer -Answer @(
			(New-TestHttpFailure -Status 429 -RetryAfter '1')
			[pscustomobject]@{ value = @([pscustomobject]@{ id = 'a' }); '@odata.nextLink' = 'https://attacker.example/v1.0/users?$skiptoken=S3cr3tSk1p' }
		)
		$caught = { InModuleScope PSMicrosoftEntraID { $null = Invoke-EntraRequest -Service RetryGraph -Path 'users' } } | Should -Throw -PassThru
		$caught.CategoryInfo.Category | Should -Be 'SecurityError'
		$script:sent.Uri | Should -Be @('https://graph.microsoft.com/v1.0/users', 'https://graph.microsoft.com/v1.0/users')
	}
}

Describe 'Exactly one retry layer under the cmdlets' -Tag 'Unit' {

	BeforeEach {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value 2
		$script:sent = [System.Collections.Generic.List[object]]::new()
		$script:slept = [System.Collections.Generic.List[int]]::new()
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 503))
		Mock -ModuleName PSMicrosoftEntraID Start-Sleep { $script:slept.Add($Milliseconds) }
		Mock -ModuleName PSMicrosoftEntraID Invoke-RestMethod {
			$script:sent.Add([string]$Uri)
			$answer = $script:answers[[Math]::Min($script:sent.Count, $script:answers.Count) - 1]
			if ($answer -is [System.Exception]) { throw $answer }
			$answer
		}
	}

	It 'Invoke-PSEntraIDRequest sends a failing request RetryCount + 1 times, not more' {
		{ Invoke-PSEntraIDRequest -Path 'users' -Force -EnableException -WarningAction SilentlyContinue } | Should -Throw
		$script:sent.Count | Should -Be 3
	}

	It 'Get-PSEntraIDUser sends a failing read RetryCount + 1 times, not more' {
		$null = Get-PSEntraIDUser -Identity 'someone@contoso.com' -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		$script:sent.Count | Should -Be 3
	}

	It 'New-PSEntraIDGroup sends a POST answered 500 once' {
		Set-TestAnswer -Answer @((New-TestHttpFailure -Status 500))
		$null = New-PSEntraIDGroup -DisplayName 'Retry test' -MailNickname 'retrytest' -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		$script:sent.Count | Should -Be 1
	}

	It 'Settings.Request.RetryCount 0 sends every request once' {
		Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.RetryCount' -Value 0
		$null = Get-PSEntraIDUser -Identity 'someone@contoso.com' -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
		$script:sent.Count | Should -Be 1
		$script:slept.Count | Should -Be 0
	}
}
