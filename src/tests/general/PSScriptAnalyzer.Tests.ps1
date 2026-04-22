[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[CmdletBinding()]
Param (
	[switch]
	$SkipTest,
	
	[string[]]
	$CommandPath = @((Join-Path $global:testroot '..' 'PSMicrosoftEntraID' 'functions'), (Join-Path $global:testroot '..' 'PSMicrosoftEntraID' 'internal' 'functions'))
)

if ($SkipTest) { return }

$global:__pester_data.ScriptAnalyzer = New-Object System.Collections.ArrayList

Describe 'Invoking PSScriptAnalyzer against commandbase' {
	$commandFiles = Get-ChildItem -Path $CommandPath -Recurse | Where-Object Name -like "*.ps1"
	$scriptAnalyzerRules = Get-ScriptAnalyzerRule
	
	foreach ($file in $commandFiles)
	{
		Context "Analyzing $($file.BaseName)" {
			$analysis = Invoke-ScriptAnalyzer -Path $file.FullName -ExcludeRule PSAvoidTrailingWhitespace, PSShouldProcess, PSUseDeclaredVarsMoreThanAssignments, PSAvoidGlobalVars
			
			forEach ($rule in $scriptAnalyzerRules)
			{
				$ruleName = $rule.RuleName
				It "Should pass $ruleName" -TestCases @{ analysis = $analysis; ruleName = $ruleName } {
					$failures = @($analysis | Where-Object {
						$null -ne $_ -and $_.RuleName -eq $ruleName
					})

					If ($failures.Count -gt 0)
					{
						$failures | ForEach-Object { $null = $global:__pester_data.ScriptAnalyzer.Add($_) }
						
						1 | Should -Be 0
					}
					else
					{
						0 | Should -Be 0
					}
				}
			}
		}
	}
}