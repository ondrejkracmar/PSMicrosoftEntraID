[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param (
	$TestGeneral = $true,
	
	$TestFunctions = $true,
	
	[ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
	[Alias('Show')]
	$Output = "None",
	
	$Include = "*",
	
	$Exclude = "",

	# The rest is the contract of the CodexVault.Build template: build/vsts-validate.ps1 runs this script with
	# -EnableCodeCoverage, the template's optional integration step with -TestIntegration.
	# Runs the *Tests.ps1 under tests/integration (none yet).
	$TestIntegration = $false,

	# Measures line coverage of the module's functions and writes TestResults/coverage.xml (JaCoCo-like), which the
	# template converts for the Code Coverage tab and reports.
	[switch]
	$EnableCodeCoverage,

	# The files or folders coverage is measured for. Default: functions/ and internal/functions/ of the module.
	[string[]]
	$CodeCoveragePath
)

Write-PSFMessage -Level Important -Message "Starting Tests"

Write-PSFMessage -Level Important -Message "Importing Module"

$global:testroot = $PSScriptRoot
$global:__pester_data = @{ }

# Coverage maps executed lines back to the source files only when the module dot-sources them; the default import
# runs them from strings and reports 0%. The module reads the setting on import (the tests import it again per file).
if ($EnableCodeCoverage) { Set-PSFConfig -FullName 'PSMicrosoftEntraID.Import.DoDotSource' -Value $true }

Remove-Module PSMicrosoftEntraID -ErrorAction Ignore
Import-Module (Join-Path $PSScriptRoot '..' 'PSMicrosoftEntraID' 'PSMicrosoftEntraID.psd1')
Import-Module (Join-Path $PSScriptRoot '..' 'PSMicrosoftEntraID' 'PSMicrosoftEntraID.psm1') -Force

# Need to import explicitly so we can use the configuration class
Import-Module Pester

Write-PSFMessage -Level Important -Message "Creating test result folder"
$null = New-Item -Path (Join-Path $PSScriptRoot '..' '..') -Name TestResults -ItemType Directory -Force

$totalFailed = 0
$totalRun = 0
$totalSkipped = 0
$skippedTests = @()

$testresults = @()
$config = [PesterConfiguration]::Default
$config.TestResult.Enabled = $true

#region Code coverage setup
# One coverage result per Invoke-Pester; they are merged into one report at the end.
$coverageRuns = [System.Collections.Generic.List[object]]::new()
if ($EnableCodeCoverage)
{
	if (-not $CodeCoveragePath)
	{
		$CodeCoveragePath = @(
			(Join-Path $PSScriptRoot '..' 'PSMicrosoftEntraID' 'functions')
			(Join-Path $PSScriptRoot '..' 'PSMicrosoftEntraID' 'internal' 'functions')
		) | Where-Object { Test-Path $_ }
	}
	Write-PSFMessage -Level Important -Message "Code coverage enabled for: $($CodeCoveragePath -join ', ')"
	$config.CodeCoverage.Enabled = $true
	$config.CodeCoverage.Path = $CodeCoveragePath
	$config.CodeCoverage.OutputFormat = 'JaCoCo'
	# Overwritten by every run; the merged report is written at the end.
	$config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot '..' '..' 'TestResults' 'coverage.partial.xml'
}
#endregion Code coverage setup

#region Run General Tests
if ($TestGeneral)
{
	Write-PSFMessage -Level Important -Message "Modules imported, proceeding with general tests"
	foreach ($file in (Get-ChildItem (Join-Path $PSScriptRoot 'general') | Where-Object Name -like "*.Tests.ps1"))
	{
		if ($file.Name -notlike $Include) { continue }
		if ($file.Name -like $Exclude) { continue }

		Write-PSFMessage -Level Significant -Message "  Executing <c='em'>$($file.Name)</c>"
		$config.TestResult.OutputPath = Join-Path $PSScriptRoot '..' '..' 'TestResults' "TEST-$($file.BaseName).xml"
		$config.Run.Path = $file.FullName
		$config.Run.PassThru = $true
		$config.Output.Verbosity = $Output
		$results = Invoke-Pester -Configuration $config
		if ($EnableCodeCoverage -and $results.CodeCoverage) { $coverageRuns.Add($results.CodeCoverage) }
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			# 'Failed', not 'not Passed'. A skipped test is not a failure, and it carries no
			# ErrorRecord - reading .DisplayErrorMessage off $null is a terminating error
			# under the StrictMode this script turns on, so a single -Skip used to take the
			# whole run down with a message about a missing property rather than reporting
			# anything. Skips are still visible: they are counted and listed below.
			$result.Tests | Where-Object Result -eq 'Failed' | ForEach-Object {
				$testresults += [pscustomobject]@{
					Block    = $_.Block
					Name	 = "It $($_.Name)"
					Result   = $_.Result
					Message  = $_.ErrorRecord.DisplayErrorMessage
				}
			}
			$totalSkipped += $result.SkippedCount
			$result.Tests | Where-Object Result -eq 'Skipped' | ForEach-Object {
				$skippedTests += '{0}: It {1}' -f $file.BaseName, $_.Name
			}
		}
	}
}
#endregion Run General Tests
$global:__pester_data.ScriptAnalyzer | Out-Host

#region Test Commands
if ($TestFunctions)
{
	Write-PSFMessage -Level Important -Message "Proceeding with individual tests"
	foreach ($file in (Get-ChildItem (Join-Path $PSScriptRoot 'functions') -Recurse -File | Where-Object Name -like "*Tests.ps1"))
	{
		if ($file.Name -notlike $Include) { continue }
		if ($file.Name -like $Exclude) { continue }
		
		Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
		$config.TestResult.OutputPath = Join-Path $PSScriptRoot '..' '..' 'TestResults' "TEST-$($file.BaseName).xml"
		$config.Run.Path = $file.FullName
		$config.Run.PassThru = $true
		$config.Output.Verbosity = $Output
		$results = Invoke-Pester -Configuration $config
		if ($EnableCodeCoverage -and $results.CodeCoverage) { $coverageRuns.Add($results.CodeCoverage) }
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			# 'Failed', not 'not Passed'. A skipped test is not a failure, and it carries no
			# ErrorRecord - reading .DisplayErrorMessage off $null is a terminating error
			# under the StrictMode this script turns on, so a single -Skip used to take the
			# whole run down with a message about a missing property rather than reporting
			# anything. Skips are still visible: they are counted and listed below.
			$result.Tests | Where-Object Result -eq 'Failed' | ForEach-Object {
				$testresults += [pscustomobject]@{
					Block    = $_.Block
					Name	 = "It $($_.Name)"
					Result   = $_.Result
					Message  = $_.ErrorRecord.DisplayErrorMessage
				}
			}
			$totalSkipped += $result.SkippedCount
			$result.Tests | Where-Object Result -eq 'Skipped' | ForEach-Object {
				$skippedTests += '{0}: It {1}' -f $file.BaseName, $_.Name
			}
		}
	}
}
#endregion Test Commands

#region Integration Tests
if ($TestIntegration)
{
	Write-PSFMessage -Level Important -Message "Proceeding with integration tests"
	foreach ($file in (Get-ChildItem (Join-Path $PSScriptRoot 'integration') -Recurse -File -ErrorAction Ignore | Where-Object Name -like "*Tests.ps1"))
	{
		if ($file.Name -notlike $Include) { continue }
		if ($file.Name -like $Exclude) { continue }

		Write-PSFMessage -Level Significant -Message "  Executing $($file.Name)"
		$config.TestResult.OutputPath = Join-Path $PSScriptRoot '..' '..' 'TestResults' "TEST-$($file.BaseName).xml"
		$config.Run.Path = $file.FullName
		$config.Run.PassThru = $true
		$config.Output.Verbosity = $Output
		$results = Invoke-Pester -Configuration $config
		if ($EnableCodeCoverage -and $results.CodeCoverage) { $coverageRuns.Add($results.CodeCoverage) }
		foreach ($result in $results)
		{
			$totalRun += $result.TotalCount
			$totalFailed += $result.FailedCount
			$result.Tests | Where-Object Result -eq 'Failed' | ForEach-Object {
				$testresults += [pscustomobject]@{
					Block    = $_.Block
					Name	 = "It $($_.Name)"
					Result   = $_.Result
					Message  = $_.ErrorRecord.DisplayErrorMessage
				}
			}
			$totalSkipped += $result.SkippedCount
			$result.Tests | Where-Object Result -eq 'Skipped' | ForEach-Object {
				$skippedTests += '{0}: It {1}' -f $file.BaseName, $_.Name
			}
		}
	}
}
#endregion Integration Tests

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

#region Merge and write code coverage
if ($EnableCodeCoverage)
{
	# A line is covered when any run executed it: per file and line, so the runs of the separate test files add up.
	$lines = @{ }
	foreach ($coverage in $coverageRuns)
	{
		foreach ($command in $coverage.CommandsMissed)
		{
			if (-not $command.File) { continue }
			if (-not $lines.ContainsKey($command.File)) { $lines[$command.File] = @{ } }
			if (-not $lines[$command.File].ContainsKey($command.Line)) { $lines[$command.File][$command.Line] = $false }
		}
		foreach ($command in $coverage.CommandsExecuted)
		{
			if (-not $command.File) { continue }
			if (-not $lines.ContainsKey($command.File)) { $lines[$command.File] = @{ } }
			$lines[$command.File][$command.Line] = $true
		}
	}

	$builder = [System.Text.StringBuilder]::new()
	$null = $builder.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
	$null = $builder.AppendLine('<report name="PSMicrosoftEntraID">')
	$null = $builder.AppendLine('  <package name="PSMicrosoftEntraID">')
	$coveredTotal = 0
	$missedTotal = 0
	foreach ($path in ($lines.Keys | Sort-Object))
	{
		$fileLines = $lines[$path]
		$fileCovered = @($fileLines.Values | Where-Object { $_ }).Count
		$fileMissed = $fileLines.Count - $fileCovered
		$coveredTotal += $fileCovered
		$missedTotal += $fileMissed
		$null = $builder.AppendLine(('    <sourcefile name="{0}">' -f [System.Security.SecurityElement]::Escape((Split-Path $path -Leaf))))
		foreach ($number in ($fileLines.Keys | Sort-Object))
		{
			$hit = [int]$fileLines[$number]
			$null = $builder.AppendLine(('      <line nr="{0}" mi="{1}" ci="{2}" mb="0" cb="0" />' -f $number, (1 - $hit), $hit))
		}
		$null = $builder.AppendLine(('      <counter type="LINE" missed="{0}" covered="{1}" />' -f $fileMissed, $fileCovered))
		$null = $builder.AppendLine('    </sourcefile>')
	}
	$null = $builder.AppendLine(('    <counter type="LINE" missed="{0}" covered="{1}" />' -f $missedTotal, $coveredTotal))
	$null = $builder.AppendLine('  </package>')
	$null = $builder.AppendLine(('  <counter type="LINE" missed="{0}" covered="{1}" />' -f $missedTotal, $coveredTotal))
	$null = $builder.AppendLine('</report>')

	$resultsDirectory = Join-Path $PSScriptRoot '..' '..' 'TestResults'
	$coverageFile = Join-Path $resultsDirectory 'coverage.xml'
	[System.IO.File]::WriteAllText($coverageFile, $builder.ToString())
	Remove-Item -LiteralPath (Join-Path $resultsDirectory 'coverage.partial.xml') -ErrorAction Ignore
	$percent = if ($coveredTotal + $missedTotal) { [math]::Round(100 * $coveredTotal / ($coveredTotal + $missedTotal), 2) } else { 0 }
	Write-PSFMessage -Level Critical -Message "Code coverage: $percent% ($coveredTotal of $($coveredTotal + $missedTotal) lines) -> $coverageFile"
}
#endregion Merge and write code coverage

# Named, not just counted. A skip that nobody sees is indistinguishable from coverage.
if ($totalSkipped -gt 0) {
	Write-PSFMessage -Level Warning -Message "<c='em'>$totalSkipped</c> test(s) skipped:"
	foreach ($skipped in $skippedTests) { Write-PSFMessage -Level Warning -Message "  $skipped" }
}

if ($totalFailed -eq 0) { Write-PSFMessage -Level Critical -Message "All <c='em'>$totalRun</c> tests executed without a single failure!" }
else { Write-PSFMessage -Level Critical -Message "<c='em'>$totalFailed tests</c> out of <c='sub'>$totalRun</c> tests failed!" }

if ($totalFailed -gt 0)
{
	throw "$totalFailed / $totalRun tests failed!"
}