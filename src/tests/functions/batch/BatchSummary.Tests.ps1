<#
.SYNOPSIS
	One summary per run (Write-EntraBatchSummary) and one error record per failed input item (Write-EntraItemFailure).
#>

BeforeAll {
	Import-Module "$PSScriptRoot/../../../PSMicrosoftEntraID/PSMicrosoftEntraID.psd1" -Force

	function Invoke-TestItemRun {
		# A cmdlet of the module's shape: reports each failed input through Write-EntraItemFailure, then the summary.
		param ([object[]]$Failure, [hashtable]$Report, [bool]$EnableException = $false)
		InModuleScope PSMicrosoftEntraID -Parameters @{ Failure = $Failure; Report = $Report; EnableException = $EnableException } {
			param ($Failure, $Report, $EnableException)
			function Get-TestItem {
				[CmdletBinding()]
				param ($Failure, $Report, $EnableException)
				foreach ($item in $Failure) {
					Write-EntraItemFailure -Cmdlet $PSCmdlet -Report $Report -Target $item.Target -Label $item.Label -Status $item.Status -Reason $item.Reason -EnableException $EnableException
				}
				Write-EntraBatchSummary -Report $Report -FunctionName 'Get-TestItem'
			}
			$errors = $null
			$null = Get-TestItem -Failure $Failure -Report $Report -EnableException $EnableException -ErrorVariable errors -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
			, @($errors)
		}
	}
}

Describe 'Write-EntraBatchSummary' -Tag 'Unit' {

	BeforeEach {
		$script:warnings = [System.Collections.Generic.List[object]]::new()
		Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { if ($Level -eq 'Warning') { $script:warnings.Add([pscustomobject]@{ String = $String; Values = $StringValues; FunctionName = $FunctionName }) } }
	}

	It 'writes nothing for a run without problems' {
		InModuleScope PSMicrosoftEntraID { Write-EntraBatchSummary -Report @{ Requests = 40 } }
		$script:warnings.Count | Should -Be 0
	}

	It 'writes ONE warning naming failures, examples, re-sends and the longest pause' {
		$report = @{
			Requests = 45; Failed = 7; 'Failed.Examples' = [System.Collections.Generic.List[string]]@('a (404)', 'b (404)', 'c (403)', 'd (404)', 'e (500)')
			Resent = 12; 'Resent.Recovered' = 11; 'Resent.Longest' = 30
		}
		InModuleScope PSMicrosoftEntraID -Parameters @{ Report = $report } { param ($Report) Write-EntraBatchSummary -Report $Report -FunctionName 'Get-PSEntraIDGroupMember' }
		$script:warnings.Count | Should -Be 1
		$script:warnings[0].String | Should -Be 'Batch.Summary'
		$script:warnings[0].FunctionName | Should -Be 'Get-PSEntraIDGroupMember'
		$text = [string]$script:warnings[0].Values
		$text | Should -BeLike '7 of 45 sub-request(s) failed. Affected: a (404), b (404), c (403), d (404), e (500) and 2 more.*'
		$text | Should -BeLike '*12 sub-request(s) were throttled or temporarily unavailable and sent again, 11 of them got through; the longest pause was 30 seconds.*'
	}

	It 'writes the summary of a run only once' {
		$report = @{ Requests = 1; Failed = 1; 'Failed.Examples' = [System.Collections.Generic.List[string]]@('a (404)') }
		InModuleScope PSMicrosoftEntraID -Parameters @{ Report = $report } {
			param ($Report)
			Write-EntraBatchSummary -Report $Report
			Write-EntraBatchSummary -Report $Report
		}
		$script:warnings.Count | Should -Be 1
	}

	It 'counts the input items that got an error record' {
		$report = @{}
		$null = Invoke-TestItemRun -Report $report -Failure @(
			@{ Target = 'g1'; Label = 'g1'; Status = 404; Reason = 'gone' }
			@{ Target = 'g2'; Label = 'g2'; Status = 403; Reason = 'denied' }
		)
		$script:warnings.Count | Should -Be 1
		[string]$script:warnings[0].Values | Should -BeLike '*2 input item(s) failed; each has its own error record.*'
	}
}

Describe 'Write-EntraItemFailure' -Tag 'Unit' {

	BeforeEach { Mock -ModuleName PSMicrosoftEntraID Write-PSFMessage { } }

	It 'writes one non-terminating error per failed input item, targeted at the input object' {
		$group = [pscustomobject]@{ Id = 'g1'; DisplayName = 'Sales' }
		$errors = Invoke-TestItemRun -Report @{} -Failure @(
			@{ Target = $group; Label = 'g1'; Status = 404; Reason = 'Resource not found' }
			@{ Target = 'g2'; Label = 'g2'; Status = 403; Reason = 'Insufficient privileges' }
		)
		$errors.Count | Should -Be 2
		$errors[0].TargetObject | Should -Be $group
		$errors[0].Exception.Message | Should -Be 'g1 failed with status 404: Resource not found'
		$errors[0].FullyQualifiedErrorId | Should -BeLike 'PSMicrosoftEntraID_ItemFailed*'
		$errors[0].CategoryInfo.Category | Should -Be 'ObjectNotFound'
		$errors[1].CategoryInfo.Category | Should -Be 'PermissionDenied'
	}

	It 'reports an item only once in a run, however many of its pages failed' {
		$report = @{}
		$errors = Invoke-TestItemRun -Report $report -Failure @(
			@{ Target = 'g1'; Label = 'g1'; Status = 503; Reason = 'first page' }
			@{ Target = 'g1'; Label = 'G1'; Status = 503; Reason = 'second page' }
		)
		$errors.Count | Should -Be 1
		$report['Items.Reported'].Count | Should -Be 1
	}

	It 'maps <Status> to <Category>' -ForEach @(
		@{ Status = 401; Category = 'PermissionDenied' }
		@{ Status = 400; Category = 'InvalidArgument' }
		@{ Status = 422; Category = 'InvalidArgument' }
		@{ Status = 421; Category = 'SecurityError' }
		@{ Status = 429; Category = 'LimitsExceeded' }
		@{ Status = 503; Category = 'ConnectionError' }
		@{ Status = 0; Category = 'ConnectionError' }
	) {
		$errors = Invoke-TestItemRun -Report @{} -Failure @(@{ Target = 'x'; Label = 'x'; Status = $Status; Reason = 'why' })
		$errors[0].CategoryInfo.Category | Should -Be $Category
	}

	It 'writes a failure without status without one' {
		$errors = Invoke-TestItemRun -Report @{} -Failure @(@{ Target = 'x'; Label = 'x'; Status = 0; Reason = 'No answer within 600 seconds' })
		$errors[0].Exception.Message | Should -Be 'x failed: No answer within 600 seconds'
	}

	It 'never shows the query of a link or a bearer token' {
		$reason = 'GET https://graph.microsoft.com/v1.0/users?$skiptoken=S3cr3tSk1p failed; header Bearer eyJ0eXAiOiJKV1Qi.S3cr3tT0k3n.sig'
		$errors = Invoke-TestItemRun -Report @{} -Failure @(@{ Target = 'x'; Label = 'x'; Status = 500; Reason = $reason })
		$errors[0].Exception.Message | Should -Not -BeLike '*S3cr3t*'
		$errors[0].Exception.Message | Should -BeLike '*https://graph.microsoft.com/v1.0/users failed*'
	}

	It 'writes no record with EnableException, but still counts the item' {
		$report = @{}
		$errors = Invoke-TestItemRun -Report $report -EnableException $true -Failure @(@{ Target = 'x'; Label = 'x'; Status = 404; Reason = 'gone' })
		$errors.Count | Should -Be 0
		$report['Items.Reported'].Count | Should -Be 1
	}
}
