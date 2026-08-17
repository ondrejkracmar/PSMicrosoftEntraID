[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param (
	$TestGeneral = $true,
	
	$TestFunctions = $true,
	
	[ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
	[Alias('Show')]
	$Output = "None",
	
	$Include = "*",
	
	$Exclude = ""
)

Write-PSFMessage -Level Important -Message "Starting Tests"

Write-PSFMessage -Level Important -Message "Importing Module"

$global:testroot = $PSScriptRoot
$global:__pester_data = @{ }

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

$testresults | Sort-Object Describe, Context, Name, Result, Message | Format-List

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