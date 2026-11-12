function Write-EntraBatchSummary {
	<#
	.SYNOPSIS
		Writes the one summary of a batch run: failed sub-requests, re-sent ones and failed input items.

	.DESCRIPTION
		Invoke-EntraParallelBatch, Invoke-EntraRetry and Write-EntraItemFailure only count into the run's report; this
		writes what the run collected as ONE warning - how many sub-requests failed (with up to five examples), how
		many were re-sent because Graph throttled them or was temporarily unavailable, how many of those got through,
		the longest pause, and how many input items got an error record. Nothing is written when nothing went wrong,
		and nothing twice: the report remembers that its summary was written.

	.PARAMETER Report
		The report of the run.

	.PARAMETER FunctionName
		The public command the summary is written for; default the caller.

	.EXAMPLE
		PS C:\> Write-EntraBatchSummary -Report $report -FunctionName $MyInvocation.MyCommand.Name

		Writes the summary of the run, if it had problems.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[hashtable]
		$Report,

		[string]
		$FunctionName
	)

	if ($Report['Written']) { return }
	$Report['Written'] = $true

	$parts = [System.Collections.Generic.List[string]]::new()
	if ([int]$Report['Failed'] -gt 0) {
		[string[]] $listed = @($Report['Failed.Examples'])
		[string] $examples = $listed -join ', '
		[int] $more = [int]$Report['Failed'] - $listed.Count
		if ($more -gt 0) { $examples = (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.Summary.More') -f $examples, $more }
		$parts.Add(((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.Summary.Failed') -f [int]$Report['Failed'], [int]$Report['Requests'], $examples))
	}
	if ([int]$Report['Resent'] -gt 0) {
		$parts.Add(((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.Summary.Resent') -f [int]$Report['Resent'], [int]$Report['Resent.Recovered'], [int]$Report['Resent.Longest']))
	}
	if ($Report['Items.Reported'] -and $Report['Items.Reported'].Count -gt 0) {
		$parts.Add(((Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.Summary.ItemFailed') -f $Report['Items.Reported'].Count))
	}
	if ($parts.Count -eq 0) { return }
	if (-not $FunctionName) { $FunctionName = (Get-PSCallStack)[1].Command }
	Write-PSFMessage -Level Warning -String 'Batch.Summary' -StringValues ($parts -join ' ') -FunctionName $FunctionName
}
