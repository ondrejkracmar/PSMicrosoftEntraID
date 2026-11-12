<#
.SYNOPSIS
	Invoke-EntraParallelBatch end to end against a local fake $batch server (127.0.0.1, nothing leaves the machine):
	cancellation of the envelopes in flight, the request timeout, ThrottleLimit honoured, typed pages.

.DESCRIPTION
	The parallel path sends through [PSMicrosoftEntraID.Batch.GraphBatchClient] directly - no mock catches it - so
	every run here points the service at the local server first (Assert-TestLocalService) and marks the line with
	'# Local test server' (general/NoNetwork.Tests.ps1).
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
	. (Join-Path $PSScriptRoot 'BatchTestHelper.ps1')
	$script:manifest = (Resolve-Path "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1").Path
	Enable-TestHttpLoopback

	function Wait-TestBatchIdle {
		# Waits until the envelopes in flight of the process are down to -Baseline; returns whether that happened.
		param ([int]$Seconds = 5, [int]$Baseline = 0)
		$waited = [System.Diagnostics.Stopwatch]::StartNew()
		while ([PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight -gt $Baseline -and $waited.Elapsed.TotalSeconds -lt $Seconds) { Start-Sleep -Milliseconds 50 }
		[PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight -le $Baseline
	}

	function Invoke-TestStoppedBatch {
		# Runs a batch against a server that never answers in a pipeline of its own, stops that pipeline once
		# -Envelopes envelopes reached the server, and returns how the stop went.
		param ([int]$ThrottleLimit, [int]$Requests, [int]$Envelopes)
		$null = Wait-TestBatchIdle
		[int] $baseline = [PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight
		$server = New-TestBatchServer -Hang
		$shell = [powershell]::Create()
		try {
			$null = $shell.AddScript({
					param ($Manifest, $Url, $ThrottleLimit, $Requests)
					Import-Module $Manifest
					# The test hook of this process is shared: the loopback host is listed already.
					& (Get-Module PSMicrosoftEntraID) {
						param ($Url, $ThrottleLimit, $Requests)
						if ($Url -notmatch '^http://127\.0\.0\.1:\d+') { throw "Not the local test server: $Url" }
						$fakeToken = [pscustomobject]@{ Service = 'PSMicrosoftEntraID.Test'; ServiceUrl = "$Url/v1.0" }
						Add-Member -InputObject $fakeToken -MemberType ScriptMethod -Name GetHeader -Value { @{ Authorization = 'Bearer test' } }
						$script:_EntraTokens['PSMicrosoftEntraID.Test'] = $fakeToken
						$reads = foreach ($index in 1..$Requests) { [pscustomobject]@{ Key = "u$index"; Url = "/users/u$index" } }
						Invoke-EntraParallelBatch -Request $reads -Service 'PSMicrosoftEntraID.Test' -ThrottleLimit $ThrottleLimit # Local test server
					} $Url $ThrottleLimit $Requests
				}).AddArgument($script:manifest).AddArgument($server.Url).AddArgument($ThrottleLimit).AddArgument($Requests)
			$null = $shell.BeginInvoke()
			$waited = [System.Diagnostics.Stopwatch]::StartNew()
			while ($server.Envelopes -lt $Envelopes -and $waited.Elapsed.TotalSeconds -lt 30) { Start-Sleep -Milliseconds 100 }
			$server.Envelopes | Should -Be $Envelopes -Because 'the envelopes are on their way'
			[PSMicrosoftEntraID.Batch.GraphBatchClient]::InFlight - $baseline | Should -Be $Envelopes
			$stopping = [System.Diagnostics.Stopwatch]::StartNew()
			$stop = $shell.BeginStop($null, $null)
			$stopped = $stop.AsyncWaitHandle.WaitOne(5000)
			[pscustomobject]@{ Stopped = $stopped; Seconds = $stopping.Elapsed.TotalSeconds; Idle = (Wait-TestBatchIdle -Baseline $baseline) }
		}
		finally {
			$server.Dispose()
			if ($shell.InvocationStateInfo.State -notin 'Running', 'Stopping') { $shell.Dispose() }
		}
	}

	function Invoke-TestLocalBatch {
		# Runs the engine in this process against -Server; returns the pages.
		param ($Server, [int]$ThrottleLimit, [object[]]$Request, [type]$ElementType, [hashtable]$Report = @{})
		Set-TestBatchService -Url "$($Server.Url)/v1.0"
		Assert-TestLocalService
		InModuleScope PSMicrosoftEntraID -Parameters @{ ThrottleLimit = $ThrottleLimit; Request = $Request; ElementType = $ElementType; Report = $Report } {
			param ($ThrottleLimit, $Request, $ElementType, $Report)
			Invoke-EntraParallelBatch -Request $Request -Service 'PSMicrosoftEntraID.Test' -ThrottleLimit $ThrottleLimit -ElementType $ElementType -Report $Report # Local test server
		}
	}
}

AfterAll {
	Set-TestBatchService -Remove
	Enable-TestHttpLoopback -Disable
}

Describe 'The batch engine against a local $batch server' -Tag 'Unit' {

	Context 'A stopped pipeline (Ctrl+C, Select-Object -First)' {

		It 'cancels the envelope of the sequential path (ThrottleLimit 1) at once' {
			$run = Invoke-TestStoppedBatch -ThrottleLimit 1 -Requests 3 -Envelopes 1
			$run.Stopped | Should -BeTrue -Because 'stopping the pipeline cancels the envelope'
			$run.Seconds | Should -BeLessThan 3
			$run.Idle | Should -BeTrue -Because 'no envelope keeps running after the run ended'
		}

		It 'cancels every envelope in flight of the parallel path at once' {
			# 45 requests are three envelopes of at most 20, all in flight at the same time.
			$run = Invoke-TestStoppedBatch -ThrottleLimit 4 -Requests 45 -Envelopes 3 # Local test server
			$run.Stopped | Should -BeTrue
			$run.Seconds | Should -BeLessThan 3
			$run.Idle | Should -BeTrue -Because 'the envelopes still in flight are cancelled, not left running in the background'
		}
	}

	Context 'An envelope without an answer within Settings.Request.TimeoutSeconds' {

		BeforeAll {
			$script:timeoutBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds'
			$script:retryBefore = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount'
			Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value 1
		}
		AfterAll {
			Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Request.TimeoutSeconds' -Value $script:timeoutBefore
			Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value $script:retryBefore
		}

		It 'comes back as 504 and is retried like an unavailable envelope, on the <Name> path' -ForEach @(
			@{ Name = 'sequential'; ThrottleLimit = 1 }
			@{ Name = 'parallel'; ThrottleLimit = 2 }
		) {
			Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value 1
			Mock -ModuleName PSMicrosoftEntraID Start-Sleep { }
			$server = New-TestBatchServer -Hang
			try {
				$waited = [System.Diagnostics.Stopwatch]::StartNew()
				$pages = @(Invoke-TestLocalBatch -Server $server -ThrottleLimit $ThrottleLimit -Request @([pscustomobject]@{ Key = 'u1'; Url = '/users/u1?$skiptoken=S3cr3tSk1p' })) # Local test server
				$waited.Elapsed.TotalSeconds | Should -BeLessThan 15
				$pages.Count | Should -Be 1
				$pages[0].Status | Should -Be 504
				$pages[0].Error | Should -BeExactly 'No answer within 1 second'
				$server.Envelopes | Should -Be 2 -Because 'a 504 is sent once more with RetryCount 1'
				Wait-TestBatchIdle | Should -BeTrue
			}
			finally { $server.Dispose() }
		}
	}

	Context 'ThrottleLimit' {

		It 'keeps at most <Limit> envelopes in flight, and uses all of them' -ForEach @(
			@{ Limit = 1 }, @{ Limit = 2 }, @{ Limit = 4 }
		) {
			$server = New-TestBatchServer -DelayMilliseconds 300
			try {
				# 160 requests are 8 envelopes: more than any limit here.
				$requests = foreach ($index in 1..160) { [pscustomobject]@{ Key = "u$index"; Url = "/users/u$index" } }
				$pages = @(Invoke-TestLocalBatch -Server $server -ThrottleLimit $Limit -Request $requests) # Local test server
				$pages.Count | Should -Be 160
				@($pages | Where-Object Status -NE 200).Count | Should -Be 0
				$server.Envelopes | Should -Be 8
				$server.MaxOpen | Should -BeLessOrEqual $Limit
				$server.MaxOpen | Should -Be $Limit -Because 'the engine keeps the pipe full'
			}
			finally { $server.Dispose() }
		}

		It 'streams the pages of each key with the key, whichever envelope answered first' {
			$server = New-TestBatchServer
			try {
				$requests = foreach ($index in 1..50) { [pscustomobject]@{ Key = "u$index"; Url = "/users/u$index" } }
				$pages = @(Invoke-TestLocalBatch -Server $server -ThrottleLimit 3 -Request $requests) # Local test server
				@($pages.Key | Sort-Object { [int]($_ -replace 'u') }) | Should -Be @(1..50 | ForEach-Object { "u$_" })
				foreach ($page in $pages) { ($page.Body | ConvertFrom-Json).value[0].displayName | Should -Be "/users/$($page.Key)" }
			}
			finally { $server.Dispose() }
		}
	}

	Context 'Typed pages' {

		It 'returns the items of every page as <ElementType> objects, converted in C#' -ForEach @(@{ ElementType = 'PSMicrosoftEntraID.Users.User' }) {
			$server = New-TestBatchServer
			try {
				$requests = foreach ($index in 1..25) { [pscustomobject]@{ Key = "u$index"; Url = "/users/u$index" } }
				$pages = @(Invoke-TestLocalBatch -Server $server -ThrottleLimit 2 -ElementType ([type]$ElementType) -Request $requests) # Local test server
				$pages.Count | Should -Be 25
				foreach ($page in $pages) {
					$page.Items.Count | Should -Be 1
					$page.Items[0] | Should -BeOfType ([type]$ElementType)
					$page.Items[0].DisplayName | Should -Be "/users/$($page.Key)"
				}
			}
			finally { $server.Dispose() }
		}
	}
}
