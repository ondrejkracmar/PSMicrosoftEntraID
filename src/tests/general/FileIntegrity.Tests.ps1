[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$moduleRoot = (Resolve-Path (Join-Path $global:testroot '..' 'PSMicrosoftEntraID')).Path

# The syntax check below needs the compiled library loaded, and it needs it HERE.
#
# internal/classes/*.ps1 define PowerShell classes whose members are typed with library
# types - [PSMicrosoftEntraID.FederationProvider] and friends. PowerShell resolves types
# in a class definition at PARSE time, so without the assembly those files report
# "Unable to find type" and the syntax test fails for a reason that has nothing to do
# with their syntax. At runtime this never happens: RequiredAssemblies loads the DLL
# before the root module is parsed.
#
# It cannot go in BeforeAll. Parser::ParseFile runs in the Context block below, during
# Pester's DISCOVERY pass, which is over before any BeforeAll executes.
#
# Until now this passed only because pester.ps1 imports the module before running
# anything - an implicit dependency on run order, which is the same weakness that once
# had 208 tests failing as a suite while every file passed alone. Stating the
# precondition here means the test passes because the source is sound, rather than
# because of the order it happened to run in.
if (-not ('PSMicrosoftEntraID.FederationProvider' -as [type])) {
	Add-Type -Path (Join-Path $moduleRoot 'bin' 'PSMicrosoftEntraID.dll') -ErrorAction Stop
}

. (Join-Path $global:testroot 'general' 'FileIntegrity.Exceptions.ps1')

Describe "Verifying integrity of module files" {
	BeforeAll {
		function Get-FileEncoding
		{
		<#
			.SYNOPSIS
				Tests a file for encoding.
			
			.DESCRIPTION
				Tests a file for encoding.
			
			.PARAMETER Path
				The file to test
		#>
			[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
			[CmdletBinding()]
			Param (
				[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
				[Alias('FullName')]
				[string]
				$Path
			)
			
			if ($PSVersionTable.PSVersion.Major -lt 6)
			{
				[byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
			}
			else
			{
				[byte[]]$byte = Get-Content -AsByteStream -ReadCount 4 -TotalCount 4 -Path $Path
			}
			
			if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) { 'UTF8 BOM' }
			elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) { 'Unicode' }
			elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) { 'UTF32' }
			elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) { 'UTF7' }
			else { 'Unknown' }
		}
	}

	Context "Validating PS1 Script files" {
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -like "*.ps1" | Where-Object { $_.FullName -NotLike (Join-Path $moduleRoot 'tests' '*') }
		
		foreach ($file in $allFiles)
		{
			$name = $file.FullName.Replace($moduleRoot + [System.IO.Path]::DirectorySeparatorChar, '')
			
			It "[$name] Should have UTF8 encoding with Byte Order Mark" -TestCases @{ file = $file } {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
			
			It "[$name] Should have no trailing space" -TestCases @{ file = $file } {
				$badLines = @($file | Select-String "\s$" | Where-Object { $_.Line.Trim().Length -gt 0 })
				if ($badLines.Count -gt 0) {
					$lineNumbers = ($badLines | ForEach-Object { $_.LineNumber }) -join ', '
					throw "Trailing whitespace found on line(s): $lineNumbers"
				}
			}
			
			$tokens = $null
			$parseErrors = $null
			$ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
			
			It "[$name] Should have no syntax errors" -TestCases @{ parseErrors = $parseErrors } {
				$parseErrors | Should -BeNullOrEmpty
			}
			
			foreach ($command in $global:BannedCommands)
			{
				if ($global:MayContainCommand["$command"] -notcontains $file.Name)
				{
					It "[$name] Should not use $command" -TestCases @{ tokens = $tokens; command = $command } {
						$tokens | Where-Object Text -EQ $command | Should -BeNullOrEmpty
					}
				}
			}
		}
	}
	
	Context "Validating help.txt help files" {
		$allFiles = Get-ChildItem -Path $moduleRoot -Recurse | Where-Object Name -like "*.help.txt" | Where-Object { $_.FullName -NotLike (Join-Path $moduleRoot 'tests' '*') }
		
		foreach ($file in $allFiles)
		{
			$name = $file.FullName.Replace($moduleRoot + [System.IO.Path]::DirectorySeparatorChar, '')
			
			It "[$name] Should have UTF8 encoding" -TestCases @{ file = $file } {
				Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8 BOM'
			}
			
			It "[$name] Should have no trailing space" -TestCases @{ file = $file } {
				($file | Select-String "\s$" | Where-Object { $_.Line.Trim().Length -gt 0 } | Measure-Object).Count | Should -Be 0
			}
		}
	}
}