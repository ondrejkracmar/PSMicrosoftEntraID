<#
.SYNOPSIS
	The function tests of the batch engine never reach the network.

.DESCRIPTION
	With -ThrottleLimit 1, Invoke-EntraParallelBatch sends through Send-EntraBatchEnvelope, which the tests mock.
	With more than one envelope in flight it sends through [PSMicrosoftEntraID.Batch.GraphBatchClient] directly, which
	no mock catches - and Settings.Batch.ThrottleLimit defaults to 4. So:
	- every call of Invoke-EntraParallelBatch in a function test passes -ThrottleLimit explicitly, and
	- no function test passes -ThrottleLimit followed by anything but a literal 1 (a variable too fails the check;
	  a value passed by splatting is not seen - do not splat it).
	The one exception: a line marked with the comment '# Local test server', in a file that really calls (not only
	names) New-TestBatchServer and Assert-TestLocalService - read from the syntax tree, so a comment or a string that
	mentions them does not count. Such a file points the service at a fake $batch server on 127.0.0.1.
	Invoke-PSEntraIDBatchRequest sends through the engine with the configured ThrottleLimit, so a function test may
	call it only on such a marked line of such a file.
	The client itself is the second layer: it refuses, before opening a connection, any URI that is not https on the
	authorized host; plain http only for a loopback host the private test hook lists.
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
	$script:functionRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' 'functions')).Path
}

Describe 'The batch client opens no connection it was not authorized for' {

	It 'refuses <Case> with a synthetic 421 for every sub-request, at once' -ForEach @(
		@{ Case = 'plain http to a remote host'; Uri = 'http://graph.example.invalid/v1.0/$batch'; Authorized = 'http://graph.example.invalid/v1.0' }
		@{ Case = 'another host than the service'; Uri = 'https://graph.example.invalid/v1.0/$batch'; Authorized = 'https://service.example.invalid/v1.0' }
		@{ Case = 'plain http to a loopback host the test hook does not list'; Uri = 'http://127.0.0.2:1/v1.0/$batch'; Authorized = 'http://127.0.0.2:1/v1.0' }
	) {
		$watch = [System.Diagnostics.Stopwatch]::StartNew()
		$responses = [PSMicrosoftEntraID.Batch.GraphBatchClient]::SendAsync($Uri, @{ Authorization = 'Bearer test' }, '{"requests":[]}', [string[]]@('1', '2'), 10, $Authorized, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
		$watch.Stop()
		$responses.Count | Should -Be 2
		$responses | ForEach-Object { $_.Status | Should -Be 421 }
		$watch.Elapsed.TotalSeconds | Should -BeLessThan 2 -Because 'the envelope is refused before a connection is opened'
	}
}

Describe 'Function tests stay off the network' {

	It 'calls Invoke-EntraParallelBatch with an explicit -ThrottleLimit in <Name> (the default of 4 sends unmocked)' -ForEach @(
		Get-ChildItem -Path (Resolve-Path (Join-Path $PSScriptRoot '..' 'functions')).Path -Recurse -Filter '*.Tests.ps1' | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
	) {
		$ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
		$calls = $ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Invoke-EntraParallelBatch' }, $true)
		$missing = foreach ($call in $calls) {
			$parameters = @($call.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.CommandParameterAst] } | ForEach-Object ParameterName)
			if ($parameters -notcontains 'ThrottleLimit') { $call.Extent.Text }
		}
		$missing | Should -BeNullOrEmpty
	}

	It 'passes no -ThrottleLimit above 1 in <Name>' -ForEach @(
		Get-ChildItem -Path (Resolve-Path (Join-Path $PSScriptRoot '..' 'functions')).Path -Recurse -Filter '*.Tests.ps1' | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
	) {
		[string[]] $lines = [System.IO.File]::ReadAllLines($Path)
		# Calls, read from the syntax tree: a comment or a string naming the helpers does not unlock the marker.
		$ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
		[string[]] $called = @($ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })
		[bool] $localServer = ($called -contains 'New-TestBatchServer') -and ($called -contains 'Assert-TestLocalService')
		$offending = foreach ($line in $lines) {
			# A value the parameter validation rejects never sends anything.
			if ($line -match 'Should -Throw') { continue }
			if ($localServer -and $line -match '# Local test server\s*$') { continue }
			foreach ($match in [regex]::Matches($line, '-ThrottleLimit(?::|\s+)(\S+)')) {
				if ($match.Groups[1].Value -ne '1') { $line.Trim() }
			}
		}
		$offending | Should -BeNullOrEmpty -Because 'a throttle limit above 1 sends real HTTPS requests to Graph'
	}

	It 'calls Invoke-PSEntraIDBatchRequest only against the local test server in <Name>' -ForEach @(
		Get-ChildItem -Path (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'functions')).Path -Recurse -Filter '*.Tests.ps1' | ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
	) {
		[string[]] $lines = [System.IO.File]::ReadAllLines($Path)
		$ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
		[string[]] $called = @($ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) | ForEach-Object { $_.GetCommandName() })
		[bool] $localServer = ($called -contains 'New-TestBatchServer') -and ($called -contains 'Assert-TestLocalService')
		$calls = $ast.FindAll({ param ($node) $node -is [System.Management.Automation.Language.CommandAst] -and $node.GetCommandName() -eq 'Invoke-PSEntraIDBatchRequest' }, $true)
		$offending = foreach ($call in $calls) {
			[string] $line = $lines[$call.Extent.StartLineNumber - 1]
			if (-not ($localServer -and $line -match '# Local test server\s*$')) { $line.Trim() }
		}
		$offending | Should -BeNullOrEmpty -Because 'the batch cmdlet sends real HTTPS requests to Graph unless the service points at the local server'
	}
}
