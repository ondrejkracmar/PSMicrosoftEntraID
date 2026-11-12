<#
	.SYNOPSIS
		Public API contract: the module's commands, parameters and output types must match the committed snapshot.

	.DESCRIPTION
		Installed by the CodexVault defaults pack (EP-08). Manifest.Tests.ps1 proves that every function is
		exported; nothing proved the SHAPE of the surface - a renamed parameter or a dropped parameter set
		passed every test and broke the first consumer. This test renders the public surface (command,
		parameter sets, parameters with type, mandatory, position and pipeline binding, output types) to
		PublicApi.snapshot.json next to it and fails when the live module differs from the committed file.

		A deliberate change of the surface is a deliberate change of the snapshot: delete the file, run the
		suite once, commit the regenerated snapshot together with the change, and version it per SemVer
		(added commands or parameters: minor; anything removed or renamed: major - a rename that keeps the old
		name as an alias still accepts every old call, so it counts as an addition: minor). The diff of the
		snapshot in the pull request is then the explicit record of the contract change.

		Locally a missing snapshot is written and the test is skipped so a repository can adopt it; on a
		build agent (TF_BUILD) a missing snapshot fails, because an unversioned contract is exactly what
		this test exists to prevent.
#>

BeforeAll {
	$srcRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
	$script:manifestFile = Get-ChildItem -Path $srcRoot -Directory |
		ForEach-Object { Join-Path $_.FullName "$($_.Name).psd1" } |
		Where-Object { Test-Path $_ } |
		Select-Object -First 1
	if (-not $script:manifestFile) { throw "No module manifest found under $srcRoot." }
	$script:moduleName = [System.IO.Path]::GetFileNameWithoutExtension($script:manifestFile)
	Import-Module $script:manifestFile -Force
	$script:snapshotPath = Join-Path $PSScriptRoot 'PublicApi.snapshot.json'

	function ConvertTo-OrdinalOrder {
		# Sort-Object follows the current culture (Czech sorts "Ch" after "H", so ChannelAlias lands after
		# EnableException on a Czech machine and before it on an English agent); ordinal order is the same
		# everywhere, which a snapshot compared across machines needs.
		param ([object[]]$Items, [string]$Property)
		if (-not $Items) { return @() }
		$keyed = foreach ($item in $Items) {
			[pscustomobject]@{ Key = [string]$(if ($Property) { $item.$Property } else { $item }); Item = $item }
		}
		$list = [System.Collections.Generic.List[object]]::new([object[]]@($keyed))
		$list.Sort([System.Comparison[object]]{ param ($a, $b) [string]::CompareOrdinal($a.Key, $b.Key) })
		foreach ($entry in $list) { $entry.Item }
	}

	function ConvertTo-StableTypeName {
		# A parameter whose type closes a generic over a type from THIS module renders with the assembly
		# identity in it: System.Nullable`1[[Module.Kind, Module, Version=0.1.0.0, Culture=neutral,
		# PublicKeyToken=null]]. The version is stamped per build (GitVersion in CI, 0.1.0.0 locally), so a
		# snapshot that kept it could never match anywhere but the machine that wrote it. The identity says
		# nothing about the contract either - the type name does - so it is stripped.
		param ([string]$Name)
		if (-not $Name) { return $Name }
		[regex]::Replace($Name, ',\s*(Version=\d+(\.\d+)*|Culture=[^,\]]+|PublicKeyToken=[^,\]]+)', '')
	}

	function Get-PublicApiSnapshot {
		# One ordered object per command, rendered deterministically so two renders of the same surface
		# are byte-identical and a diff shows exactly the contract that moved.
		$common = @([System.Management.Automation.PSCmdlet]::CommonParameters) + @([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)
		$commands = ConvertTo-OrdinalOrder -Items @(Get-Command -Module $script:moduleName -CommandType Function, Cmdlet) -Property Name
		$rendered = foreach ($command in $commands) {
			$sets = foreach ($set in (ConvertTo-OrdinalOrder -Items @($command.ParameterSets) -Property Name)) {
				$parameters = foreach ($parameter in (ConvertTo-OrdinalOrder -Items @($set.Parameters | Where-Object { $_.Name -notin $common }) -Property Name)) {
					[ordered]@{
						name                  = $parameter.Name
						type                  = ConvertTo-StableTypeName -Name $parameter.ParameterType.FullName
						mandatory             = [bool]$parameter.IsMandatory
						position              = $(if ($parameter.Position -eq [int]::MinValue) { $null } else { $parameter.Position })
						valueFromPipeline     = [bool]$parameter.ValueFromPipeline
						valueFromPipelineByPropertyName = [bool]$parameter.ValueFromPipelineByPropertyName
						aliases               = @(ConvertTo-OrdinalOrder -Items @($parameter.Aliases))
					}
				}
				[ordered]@{ name = $set.Name; isDefault = [bool]$set.IsDefault; parameters = @($parameters) }
			}
			[ordered]@{
				name          = $command.Name
				type          = $command.CommandType.ToString()
				outputTypes   = @(ConvertTo-OrdinalOrder -Items @($command.OutputType | ForEach-Object { ConvertTo-StableTypeName -Name $_.Name } | Select-Object -Unique))
				parameterSets = @($sets)
			}
		}
		[ordered]@{ module = $script:moduleName; commands = @($rendered) }
	}

	function ConvertTo-SnapshotJson {
		param ($Snapshot)
		# ConvertTo-Json renders [ordered] in insertion order; keys are sorted at render time above.
		(($Snapshot | ConvertTo-Json -Depth 10) -replace "`r`n", "`n").TrimEnd() + "`n"
	}
}

Describe 'Public API contract' {

	It 'matches the committed snapshot (PublicApi.snapshot.json next to this test)' {
		$current = ConvertTo-SnapshotJson -Snapshot (Get-PublicApiSnapshot)

		if (-not (Test-Path -LiteralPath $script:snapshotPath)) {
			if ($env:TF_BUILD -eq 'True') {
				throw "No PublicApi.snapshot.json next to this test. Run the suite locally once, review the generated snapshot and commit it: it is the versioned contract of $($script:moduleName)."
			}
			[System.IO.File]::WriteAllText($script:snapshotPath, $current, [System.Text.UTF8Encoding]::new($false))
			Set-ItResult -Skipped -Because "PublicApi.snapshot.json was written for the first time - review and commit it"
			return
		}

		$expected = ((Get-Content -LiteralPath $script:snapshotPath -Raw) -replace "`r`n", "`n").TrimEnd() + "`n"
		if ($current -eq $expected) { return }

		# Name what moved before failing: commands first, then parameters per command.
		$before = $expected | ConvertFrom-Json
		$after = $current | ConvertFrom-Json
		$beforeNames = @($before.commands.name)
		$afterNames = @($after.commands.name)
		$lines = [System.Collections.Generic.List[string]]::new()
		foreach ($name in ($afterNames | Where-Object { $_ -notin $beforeNames })) { $lines.Add("added command: $name") }
		foreach ($name in ($beforeNames | Where-Object { $_ -notin $afterNames })) { $lines.Add("removed command: $name") }
		foreach ($name in ($afterNames | Where-Object { $_ -in $beforeNames })) {
			$b = ($before.commands | Where-Object name -eq $name) | ConvertTo-Json -Depth 10
			$a = ($after.commands | Where-Object name -eq $name) | ConvertTo-Json -Depth 10
			if ($a -ne $b) {
				$lines.Add("changed command: $name")
				$lines.Add("  snapshot: $(($before.commands | Where-Object name -eq $name) | ConvertTo-Json -Depth 10 -Compress)")
				$lines.Add("  live:     $(($after.commands | Where-Object name -eq $name) | ConvertTo-Json -Depth 10 -Compress)")
			}
		}
		$summary = if ($lines.Count) { $lines -join "`n  " } else { 'the rendered JSON differs (ordering or formatting)' }
		throw "The public API of $($script:moduleName) differs from PublicApi.snapshot.json:`n  $summary`nA deliberate contract change: delete the snapshot, run the suite, commit the regenerated file with the change and version it per SemVer (additions, and renames that keep the old name as an alias: minor; removals or other renames: major)."
	}
}
