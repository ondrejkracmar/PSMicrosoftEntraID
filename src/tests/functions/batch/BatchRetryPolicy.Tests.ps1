<#
.SYNOPSIS
	Invoke-EntraParallelBatch through its sequential seam (Send-EntraBatchEnvelope mocked): the retry decision per
	sub-request, Retry-After, per-request method, headers and body, results streamed per key, nextLink paging with
	-First and the refusal of a next link to another host, and the run report.
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force
	. (Join-Path $PSScriptRoot 'BatchTestHelper.ps1')
	$script:service = 'PSMicrosoftEntraID.Test'
	$script:serviceUrl = 'https://graph.microsoft.com/v1.0'

	function New-TestSubResponse {
		param ([string]$Id, [int]$Status = 200, [string]$Body = '{"value":[{"id":"x"}]}', [int]$RetryAfter, [string]$NextLink, [int]$ItemCount = 1, [string]$ErrorMessage)
		[PSMicrosoftEntraID.Batch.BatchSubResponse]@{ Id = $Id; Status = $Status; Body = $Body; RetryAfter = $RetryAfter; NextLink = $NextLink; ItemCount = $ItemCount; ErrorMessage = $ErrorMessage }
	}

	function Invoke-TestBatch {
		# Runs the engine in the module with one envelope at a time (the mocked seam).
		param ([object[]]$Request, [hashtable]$Report = @{}, [switch]$FollowNextLink, [int]$First = 0, [type]$ElementType)
		InModuleScope PSMicrosoftEntraID -Parameters @{ Request = $Request; Report = $Report; Follow = $FollowNextLink.IsPresent; First = $First; Service = $script:service; ElementType = $ElementType } {
			param ($Request, $Report, $Follow, $First, $Service, $ElementType)
			Invoke-EntraParallelBatch -Request $Request -Service $Service -ThrottleLimit 1 -FollowNextLink:$Follow -First $First -Report $Report -ElementType $ElementType
		}
	}
}

Describe 'Invoke-EntraParallelBatch' -Tag 'Unit' {

	BeforeAll { Set-TestBatchService -Service $script:service -Url $script:serviceUrl }
	AfterAll { Set-TestBatchService -Service $script:service -Remove }

	BeforeEach {
		$script:slept = [System.Collections.Generic.List[int]]::new()
		Mock -ModuleName PSMicrosoftEntraID Start-Sleep { $script:slept.Add($Milliseconds) }
		Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { }
		$script:envelopes = [System.Collections.Generic.List[object]]::new()
		# Per pass: url -> answer (a scriptblock that gets the id and returns a sub-response); default 200.
		$script:answers = @{}
		Mock -ModuleName PSMicrosoftEntraID Send-EntraBatchEnvelope {
			$script:envelopes.Add([pscustomobject]@{ Uri = $Uri; Header = $Header; AuthorizedUrl = $AuthorizedUrl; Requests = @($Envelope.requests); Json = ($Envelope | ConvertTo-Json -Depth 20 -Compress) })
			, @(foreach ($request in $Envelope.requests) {
					$queue = $script:answers[$request.url]
					if ($queue -and $queue.Count -gt 0) { $answer = $queue[0]; if ($queue.Count -gt 1) { $queue.RemoveAt(0) }; & $answer $request.id }
					else { New-TestSubResponse -Id $request.id }
				})
		}
		function script:Set-TestAnswer {
			# The answers for a URL, one per pass; the last one repeats.
			param ([string]$Url, [scriptblock[]]$Answer)
			$script:answers[$Url] = [System.Collections.Generic.List[scriptblock]]::new($Answer)
		}
	}

	Context 'The retry decision per sub-request' {

		It 're-sends only the sub-request answered <Status> and keeps the one that succeeded' -ForEach @(
			@{ Status = 429 }, @{ Status = 503 }, @{ Status = 500 }, @{ Status = 504 }, @{ Status = 408 }
		) {
			Set-TestAnswer -Url '/users/b' -Answer { param ($id) New-TestSubResponse -Id $id -Status $Status -RetryAfter 3 }, { param ($id) New-TestSubResponse -Id $id }
			$pages = Invoke-TestBatch -Request @(
				[pscustomobject]@{ Key = 'a'; Url = '/users/a' }
				[pscustomobject]@{ Key = 'b'; Url = '/users/b' }
			)
			$script:envelopes.Count | Should -Be 2
			@($script:envelopes[1].Requests.url) | Should -Be @('/users/b')
			@($pages.Key) | Should -Be @('a', 'b')
			$pages | ForEach-Object { $_.Status | Should -Be 200; $_.Succeeded | Should -BeTrue }
		}

		It 'waits the Retry-After of the sub-request, at most 5 minutes' -ForEach @(
			@{ RetryAfter = 7; Expected = 7050 }, @{ RetryAfter = 300; Expected = 300050 }
		) {
			Set-TestAnswer -Url '/users/a' -Answer { param ($id) New-TestSubResponse -Id $id -Status 429 -RetryAfter $RetryAfter }, { param ($id) New-TestSubResponse -Id $id }
			# The engine sleeps only when nothing is ready: the wait is the time left until the Retry-After.
			$null = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' })
			$script:slept.Count | Should -BeGreaterThan 0
			$script:slept[0] | Should -BeGreaterThan ($Expected - 1000)
			$script:slept[0] | Should -BeLessOrEqual $Expected
		}

		It 'waits 2^attempt seconds with jitter when the sub-request has no Retry-After' {
			Set-TestAnswer -Url '/users/a' -Answer { param ($id) New-TestSubResponse -Id $id -Status 503 }, { param ($id) New-TestSubResponse -Id $id }
			$null = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' })
			# Attempt 1: 2 s * 0.8 .. 1.2.
			$script:slept[0] | Should -BeGreaterThan 1500
			$script:slept[0] | Should -BeLessOrEqual 2450
		}

		It 'does not re-send a POST answered <Status>' -ForEach @(@{ Status = 500 }, @{ Status = 502 }, @{ Status = 504 }, @{ Status = 408 }) {
			Set-TestAnswer -Url '/groups' -Answer { param ($id) New-TestSubResponse -Id $id -Status $Status -ErrorMessage 'failed' }
			$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'new'; Method = 'POST'; Url = '/groups'; Body = @{ displayName = 'Sales' } })
			$script:envelopes.Count | Should -Be 1
			$pages.Status | Should -Be $Status
			$pages.Succeeded | Should -BeFalse
			$pages.Error | Should -Be 'failed'
		}

		It 're-sends a POST answered <Status>' -ForEach @(@{ Status = 429 }, @{ Status = 503 }) {
			Set-TestAnswer -Url '/groups' -Answer { param ($id) New-TestSubResponse -Id $id -Status $Status }, { param ($id) New-TestSubResponse -Id $id -Status 201 }
			$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'new'; Method = 'POST'; Url = '/groups'; Body = @{ displayName = 'Sales' } })
			$script:envelopes.Count | Should -Be 2
			$pages.Status | Should -Be 201
		}

		It 're-sends a GET, PATCH and DELETE answered 500 but not the POST beside them' {
			foreach ($url in '/users/a', '/users/b', '/users/c', '/groups') { Set-TestAnswer -Url $url -Answer { param ($id) New-TestSubResponse -Id $id -Status 500 -RetryAfter 1 }, { param ($id) New-TestSubResponse -Id $id } }
			$pages = Invoke-TestBatch -Request @(
				[pscustomobject]@{ Key = 'get'; Url = '/users/a' }
				[pscustomobject]@{ Key = 'patch'; Method = 'PATCH'; Url = '/users/b'; Body = @{ jobTitle = 'x' } }
				[pscustomobject]@{ Key = 'delete'; Method = 'Delete'; Url = '/users/c' }
				[pscustomobject]@{ Key = 'post'; Method = 'POST'; Url = '/groups'; Body = @{ displayName = 'x' } }
			)
			@($script:envelopes[1].Requests.method) | Should -Be @('GET', 'PATCH', 'DELETE')
			($pages | Where-Object Key -EQ 'post').Status | Should -Be 500
			@($pages | Where-Object Status -EQ 200).Count | Should -Be 3
		}

		It 'gives up after Settings.Batch.RetryCount re-sends and returns the last answer' {
			Set-TestAnswer -Url '/users/a' -Answer { param ($id) New-TestSubResponse -Id $id -Status 503 -RetryAfter 1 -ErrorMessage 'unavailable' }
			$report = @{}
			$before = Get-PSFConfigValue -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount'
			try {
				Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value 2
				$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' }) -Report $report
			}
			finally { Set-PSFConfig -FullName 'PSMicrosoftEntraID.Settings.Batch.RetryCount' -Value $before }
			$script:envelopes.Count | Should -Be 3
			$pages.Status | Should -Be 503
			$pages.Error | Should -Be 'unavailable'
			$report.Resent | Should -Be 2
			$report.Failed | Should -Be 1
		}

		It 'does not re-send <Status>' -ForEach @(@{ Status = 400 }, @{ Status = 403 }, @{ Status = 404 }, @{ Status = 501 }, @{ Status = 421 }) {
			Set-TestAnswer -Url '/users/a' -Answer { param ($id) New-TestSubResponse -Id $id -Status $Status }
			$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' })
			$script:envelopes.Count | Should -Be 1
			$pages.Status | Should -Be $Status
		}

		It 're-sends a 401 once, with a fresh header, without waiting' {
			Set-TestAnswer -Url '/users/a' -Answer { param ($id) New-TestSubResponse -Id $id -Status 401 }
			$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' })
			$script:envelopes.Count | Should -Be 2
			$pages.Status | Should -Be 401
			$script:slept | Where-Object { $_ -gt 1000 } | Should -BeNullOrEmpty
		}
	}

	Context 'What the envelope carries' {

		It 'posts to the $batch URL of the service with the token header and the service URL as the authorized URL' {
			$null = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users/a' })
			$script:envelopes[0].Uri | Should -Be 'https://graph.microsoft.com/v1.0/$batch'
			$script:envelopes[0].AuthorizedUrl | Should -Be $script:serviceUrl
			$script:envelopes[0].Header.Authorization | Should -Be 'Bearer test'
			$script:envelopes[0].Header.ContainsKey('Content-Type') | Should -BeFalse
		}

		It 'carries the headers of each request, so ConsistencyLevel: eventual reaches the sub-request that needs it' {
			$null = Invoke-TestBatch -Request @(
				[pscustomobject]@{ Key = 'count'; Url = '/users?$count=true&$filter=endsWith(mail,''@contoso.com'')'; Headers = @{ ConsistencyLevel = 'eventual' } }
				[pscustomobject]@{ Key = 'plain'; Url = '/users/a' }
			)
			$requests = $script:envelopes[0].Requests
			$requests[0].headers.ConsistencyLevel | Should -Be 'eventual'
			$requests[1].ContainsKey('headers') | Should -BeFalse
		}

		It 'serializes the body of a write with its content type' {
			$null = Invoke-TestBatch -Request @(
				[pscustomobject]@{ Key = 'patch'; Method = 'PATCH'; Url = '/users/a'; Body = @{ assignedLicenses = @(@{ skuId = 's1'; disabledPlans = @('p1', 'p2') }) } }
				[pscustomobject]@{ Key = 'json'; Method = 'POST'; Url = '/groups'; Body = '{"displayName":"Sales"}' }
			)
			$json = $script:envelopes[0].Json | ConvertFrom-Json
			$json.requests[0].headers.'Content-Type' | Should -Be 'application/json'
			# Five levels deep: arrays stay arrays on the wire.
			$json.requests[0].body.assignedLicenses[0].disabledPlans | Should -Be @('p1', 'p2')
			$json.requests[1].body.displayName | Should -Be 'Sales'
		}

		It 'packs at most 20 sub-requests per envelope' {
			$requests = foreach ($index in 1..45) { [pscustomobject]@{ Key = "u$index"; Url = "/users/u$index" } }
			$pages = Invoke-TestBatch -Request $requests
			@($script:envelopes | ForEach-Object { $_.Requests.Count }) | Should -Be @(20, 20, 5)
			@($pages).Count | Should -Be 45
		}

		It 'does nothing for no request' {
			@(Invoke-TestBatch -Request @()).Count | Should -Be 0
			$script:envelopes.Count | Should -Be 0
		}
	}

	Context 'Paging per key' {

		It 'follows @odata.nextLink per key and streams every page with its key' {
			Set-TestAnswer -Url '/groups/g1/members' -Answer { param ($id) New-TestSubResponse -Id $id -NextLink 'https://graph.microsoft.com/v1.0/groups/g1/members?$skiptoken=p2' -ItemCount 100 }
			Set-TestAnswer -Url '/groups/g1/members?$skiptoken=p2' -Answer { param ($id) New-TestSubResponse -Id $id -ItemCount 5 }
			$pages = Invoke-TestBatch -FollowNextLink -Request @(
				[pscustomobject]@{ Key = 'g1'; Url = '/groups/g1/members'; Headers = @{ ConsistencyLevel = 'eventual' } }
				[pscustomobject]@{ Key = 'g2'; Url = '/groups/g2/members' }
			)
			@($pages.Key) | Should -Be @('g1', 'g2', 'g1')
			$script:envelopes[1].Requests[0].url | Should -Be '/groups/g1/members?$skiptoken=p2'
			$script:envelopes[1].Requests[0].method | Should -Be 'GET'
			$script:envelopes[1].Requests[0].headers.ConsistencyLevel | Should -Be 'eventual' -Because 'the next page needs the header of the first'
		}

		It 'stops paging a key once -First items were returned' {
			Set-TestAnswer -Url '/users' -Answer { param ($id) New-TestSubResponse -Id $id -NextLink 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2' -ItemCount 100 }
			$pages = Invoke-TestBatch -FollowNextLink -First 100 -Request @([pscustomobject]@{ Key = 'all'; Url = '/users' })
			@($pages).Count | Should -Be 1
			$script:envelopes.Count | Should -Be 1
		}

		It 'does not follow a next link without -FollowNextLink' {
			Set-TestAnswer -Url '/users' -Answer { param ($id) New-TestSubResponse -Id $id -NextLink 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2' }
			$pages = Invoke-TestBatch -Request @([pscustomobject]@{ Key = 'all'; Url = '/users' })
			$pages.NextLink | Should -Be 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2'
			$script:envelopes.Count | Should -Be 1
		}

		It 'refuses a next link <Case> and ends the key with a 421 page that does not quote the link query' -ForEach @(
			@{ Case = 'on another host'; Link = 'https://graph.contoso.com/v1.0/users?$skiptoken=S3cr3t' }
			@{ Case = 'over http'; Link = 'http://graph.microsoft.com/v1.0/users?$skiptoken=S3cr3t' }
			@{ Case = 'on another port'; Link = 'https://graph.microsoft.com:8443/v1.0/users?$skiptoken=S3cr3t' }
			@{ Case = 'outside the service URL'; Link = 'https://graph.microsoft.com/beta/users?$skiptoken=S3cr3t' }
			@{ Case = 'that is not absolute'; Link = '/v1.0/users?$skiptoken=S3cr3t' }
		) {
			Set-TestAnswer -Url '/users' -Answer { param ($id) New-TestSubResponse -Id $id -NextLink $Link }
			$report = @{}
			$pages = Invoke-TestBatch -FollowNextLink -Report $report -Request @([pscustomobject]@{ Key = 'all'; Url = '/users' })
			$script:envelopes.Count | Should -Be 1 -Because 'the refused link is never sent'
			@($pages).Count | Should -Be 2
			$pages[1].Key | Should -Be 'all'
			$pages[1].Status | Should -Be 421
			$pages[1].Succeeded | Should -BeFalse
			$pages[1].Error | Should -BeLike 'The next link of the page is not followed.*'
			$pages[1].Error | Should -Not -BeLike '*S3cr3t*'
			$report.Failed | Should -Be 1
		}
	}

	Context 'The run report' {

		It 'counts pages, failures with up to five examples, re-sends and how many of them got through' {
			Set-TestAnswer -Url '/users/t' -Answer { param ($id) New-TestSubResponse -Id $id -Status 429 -RetryAfter 4 }, { param ($id) New-TestSubResponse -Id $id }
			$requests = @([pscustomobject]@{ Key = 't'; Url = '/users/t' })
			foreach ($index in 1..7) {
				Set-TestAnswer -Url "/users/missing$index" -Answer { param ($id) New-TestSubResponse -Id $id -Status 404 -ErrorMessage 'Resource not found' }
				$requests += [pscustomobject]@{ Key = "missing$index"; Url = "/users/missing$index" }
			}
			$report = @{}
			$null = Invoke-TestBatch -Request $requests -Report $report
			$report.Requests | Should -Be 8
			$report.Failed | Should -Be 7
			$report['Failed.Examples'].Count | Should -Be 5
			$report['Failed.Examples'][0] | Should -Be 'missing1 (404)'
			$report.Resent | Should -Be 1
			$report.Throttled | Should -Be 1
			$report['Resent.Recovered'] | Should -Be 1
			$report['Resent.Longest'] | Should -Be 4
		}
	}

	Context 'Typed pages (-ElementType)' {

		It 'passes the element type to the transport and returns the typed items instead of the body' {
			Mock -ModuleName PSMicrosoftEntraID Send-EntraBatchEnvelope {
				$script:elementType = $ElementType
				, @(foreach ($request in $Envelope.requests) {
						$response = New-TestSubResponse -Id $request.id
						$response.Items = [PSMicrosoftEntraID.Users.User[]]@([PSMicrosoftEntraID.Users.User]@{ Id = 'u1'; UserPrincipalName = 'AdeleV@contoso.com' })
						$response
					})
			}
			$pages = Invoke-TestBatch -ElementType ([PSMicrosoftEntraID.Users.User]) -Request @([pscustomobject]@{ Key = 'a'; Url = '/users' })
			$script:elementType | Should -Be ([PSMicrosoftEntraID.Users.User])
			$pages.Items[0].UserPrincipalName | Should -Be 'AdeleV@contoso.com'
			$pages.Body | Should -BeNullOrEmpty
		}

		It 'fails a page that did not convert, with the reason, and does not follow its next link' {
			Mock -ModuleName PSMicrosoftEntraID Send-EntraBatchEnvelope {
				, @(foreach ($request in $Envelope.requests) {
						$response = New-TestSubResponse -Id $request.id -NextLink 'https://graph.microsoft.com/v1.0/users?$skiptoken=p2'
						$response.ConversionError = 'The page could not be converted to PSMicrosoftEntraID.Users.User (JsonException at $[0].accountEnabled)'
						$response
					})
			}
			$pages = Invoke-TestBatch -FollowNextLink -ElementType ([PSMicrosoftEntraID.Users.User]) -Request @([pscustomobject]@{ Key = 'a'; Url = '/users' })
			@($pages).Count | Should -Be 1
			$pages.Succeeded | Should -BeFalse
			$pages.Error | Should -BeLike 'The page could not be converted*'
		}
	}

	Context 'Preconditions' {

		It 'refuses a service that is not connected' {
			InModuleScope PSMicrosoftEntraID {
				{ Invoke-EntraParallelBatch -Request @([pscustomobject]@{ Key = 'a'; Url = '/users' }) -Service 'PSMicrosoftEntraID.NotConnected' -ThrottleLimit 1 } | Should -Throw "*Not connected*"
			}
		}

		It 'refuses a throttle limit outside 1 to 20' -ForEach @(@{ Limit = 0 }, @{ Limit = 21 }) {
			InModuleScope PSMicrosoftEntraID -Parameters @{ Limit = $Limit } {
				param ($Limit)
				{ Invoke-EntraParallelBatch -Request @() -Service 'PSMicrosoftEntraID.Test' -ThrottleLimit $Limit } | Should -Throw
			}
		}
	}
}
