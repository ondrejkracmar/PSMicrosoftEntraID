
<#
This script create markdown documentation for the module.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$WorkingDirectory,
	$ModuleName,
	$MarkdownDirectoryName = 'docs',
	$Location = 'en-us',
	[switch]$NoMetadata,
	[switch]$SkipMaml,
	[switch]$CleanPlaceholders,
	[switch]$KeepPlaceholders,
	[switch]$KeepRelatedLinks
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory) {
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS) {
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

# Import the new Microsoft.PowerShell.PlatyPS module
if (-not (Get-Module -Name Microsoft.PowerShell.PlatyPS -ListAvailable)) {
	Write-Warning "Microsoft.PowerShell.PlatyPS module not found. Installing..."
	Install-Module Microsoft.PowerShell.PlatyPS -Force -Scope CurrentUser
}
Import-Module Microsoft.PowerShell.PlatyPS -Force

#define module for documentation
$MarkdownFullPath = Join-Path -Path $WorkingDirectory -ChildPath $MarkdownDirectoryName -AdditionalChildPath "cmdlets"
if (Test-Path -Path $MarkdownFullPath) {
	$MarkdownPath = Get-Item -Path $MarkdownFullPath
}
else {
	$MarkdownPath = New-Item -Path $MarkdownFullPath -ItemType Directory -Force
}

$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath $ModuleName -AdditionalChildPath "$($ModuleName).psd1"
if (-not (Test-Path $ModuleManifestPath)) {
	# Try alternative path structure under src folder
	$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath "src" -AdditionalChildPath $ModuleName, "$($ModuleName).psd1"
}
if (-not (Test-Path $ModuleManifestPath)) {
	# Try root level
	$ModuleManifestPath = Join-Path -Path $WorkingDirectory -ChildPath "$($ModuleName).psd1"
}
Import-Module $ModuleManifestPath -Force

$MamlFullPath = Join-Path -Path $WorkingDirectory -ChildPath $ModuleName -AdditionalChildPath $Location
if (-not (Test-Path -Path $MamlFullPath)) {
	# Try alternative path structure under src folder
	$MamlFullPath = Join-Path -Path $WorkingDirectory -ChildPath "src" -AdditionalChildPath $ModuleName, $Location
}
if (Test-Path -Path $MamlFullPath) {
	$MamlPath = Get-Item -Path $MamlFullPath
}
else {
	$MamlPath = New-Item -Path $MamlFullPath -ItemType Directory -Force
}

$MdHelpParams = @{
	ModuleInfo     = (Get-Module $ModuleName)
	OutputFolder   = $MarkdownPath.FullName
	WithModulePage = $false
	Encoding       = [System.Text.Encoding]::UTF8
}

# Try to suppress metadata if NoMetadata switch is used
if ($NoMetadata) {
	$MdHelpParams.Metadata = @{}
}

$ExtHelpParams = @{
	OutputFolder = $MamlPath.FullName
	Encoding     = [System.Text.Encoding]::UTF8
}

$ExtHelpCabParams = @{
	CabFilesFolder  = $MamlPath.FullName
	LandingPagePath = Join-Path -Path $MarkdownPath.FullName -ChildPath "$($ModuleName).md"
	OutputFolder    = Join-Path -Path $MamlPath.FullName -ChildPath "cab"
}

# Generate documentation
$MDFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter *.md -ErrorAction SilentlyContinue
if (-not $MDFiles -or $MDFiles.Count -eq 0) {
	Write-PSFMessage -Level Important -Message "Generate initial Markdown help"
	New-MarkdownCommandHelp @MdHelpParams
}
else {
	Write-PSFMessage -Level Important -Message "Updating Markdown files"
	Remove-Item -Path (Join-Path -Path $MarkdownPath.FullName -ChildPath "*.md") -Force
	New-MarkdownCommandHelp @MdHelpParams
}

# Move files from module subfolder to cmdlets folder directly
$ModuleSubfolder = Join-Path -Path $MarkdownPath.FullName -ChildPath $ModuleName
if (Test-Path -Path $ModuleSubfolder) {
	Write-PSFMessage -Level Important -Message "Moving markdown files to cmdlets folder"
	$SubfolderFiles = Get-ChildItem -Path $ModuleSubfolder -Filter "*.md"
	foreach ($File in $SubfolderFiles) {
		$DestinationPath = Join-Path -Path $MarkdownPath.FullName -ChildPath $File.Name
		if (Test-Path -Path $DestinationPath) {
			Remove-Item -Path $DestinationPath -Force
		}
		Move-Item -Path $File.FullName -Destination $DestinationPath
	}
	# Remove empty subfolder
	if ((Get-ChildItem -Path $ModuleSubfolder).Count -eq 0) {
		Remove-Item -Path $ModuleSubfolder -Force
	}
}

# Remove YAML front matter metadata if NoMetadata switch is used
if ($NoMetadata) {
	Write-PSFMessage -Level Important -Message "Removing YAML front matter from markdown files"
	$MarkdownFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter "*.md"
	foreach ($MarkdownFile in $MarkdownFiles) {
		$Content = Get-Content -Path $MarkdownFile.FullName -Raw
		# Remove YAML front matter (everything between first --- and second ---)
		if ($Content -match '^---\r?\n.*?\r?\n---\r?\n(.*)$') {
			$CleanContent = $matches[1]
			Set-Content -Path $MarkdownFile.FullName -Value $CleanContent -NoNewline -Encoding UTF8
			Write-PSFMessage -Level Verbose -Message "Removed metadata from $($MarkdownFile.Name)"
		}
	}
}

# Remove PlatyPS placeholder texts from all markdown files
if (($CleanPlaceholders -or $NoMetadata) -and -not $KeepPlaceholders) {
	Write-PSFMessage -Level Important -Message "Removing PlatyPS placeholder texts from markdown files"
	$MarkdownFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter "*.md"
	foreach ($MarkdownFile in $MarkdownFiles) {
		$Content = Get-Content -Path $MarkdownFile.FullName -Raw
		$OriginalContent = $Content

		# Remove common PlatyPS placeholder texts
		$Content = $Content -replace '\{\{ Fill in the Description \}\}', ''
		$Content = $Content -replace '\{\{Insert list of aliases\}\}', ''
		$Content = $Content -replace 'This cmdlet has the following aliases,\s*\r?\n\s*$', ''

		# Conditionally remove RELATED LINKS placeholder based on KeepRelatedLinks parameter
		if (-not $KeepRelatedLinks) {
			$Content = $Content -replace '\{\{ Fill in the related links here \}\}', ''
			# Clean up empty RELATED LINKS sections only if we're removing the placeholder
			$Content = $Content -replace '## RELATED LINKS\s*\r?\n\s*\r?\n', ''
		}

		# Clean up empty ALIASES sections
		$Content = $Content -replace '## ALIASES\s*\r?\n\s*This cmdlet has the following aliases,\s*\r?\n\s*\r?\n', ''

		# Remove trailing whitespace and normalize line endings
		$Content = $Content -replace '\s+$', ''
		$Content = $Content -replace '\r?\n', "`n"

		# Only update if content changed
		if ($Content -ne $OriginalContent) {
			Set-Content -Path $MarkdownFile.FullName -Value $Content -NoNewline -Encoding UTF8
			Write-PSFMessage -Level Verbose -Message "Cleaned placeholder texts from $($MarkdownFile.Name)"
		}
	}
}

Write-PSFMessage -Level Important -Message "Creating about help topics"
# Note: New-MarkdownAboutHelp is not available in Microsoft.PowerShell.PlatyPS
# About topics need to be created manually or using other methods

if (-not $SkipMaml) {
	Write-PSFMessage -Level Important -Message "Creating external help"
	# Check if markdown files exist before trying to import them
	$MarkdownFiles = Get-ChildItem -Path $MarkdownPath.FullName -Filter "*.md" -ErrorAction SilentlyContinue
	Write-PSFMessage -Level Verbose -Message "Found $($MarkdownFiles.Count) markdown files in $($MarkdownPath.FullName)"

	if ($MarkdownFiles -and $MarkdownFiles.Count -gt 0) {
		try {
			# Try to import markdown files for MAML generation
			# Note: Import-MarkdownCommandHelp expects files with YAML metadata
			if ($NoMetadata) {
				Write-PSFMessage -Level Warning -Message "Cannot generate MAML from markdown files without metadata. Using direct module approach."
				throw "Metadata required for MAML generation"
			}

			# Ensure we have the correct path format
			$ImportPath = $MarkdownPath.FullName
			Write-PSFMessage -Level Verbose -Message "Attempting to import markdown files from: $ImportPath"

			# Try importing with individual files first
			$ImportedHelp = @()
			foreach ($MarkdownFile in $MarkdownFiles) {
				try {
					$FileHelp = Import-MarkdownCommandHelp -Path $MarkdownFile.FullName -ErrorAction Stop
					if ($FileHelp) {
						$ImportedHelp += $FileHelp
					}
				}
				catch {
					Write-PSFMessage -Level Warning -Message "Failed to import $($MarkdownFile.Name): $($_.Exception.Message)"
				}
			}

			if ($ImportedHelp.Count -gt 0) {
				Export-MamlCommandHelp -CommandHelp $ImportedHelp @ExtHelpParams -Force
				Write-PSFMessage -Level Important -Message "Successfully generated MAML help files from $($ImportedHelp.Count) markdown files"

				# Move any XML files from subfolders to the target directory (including module-named subfolders)
				$ModuleSubfolder = Join-Path -Path $MamlPath.FullName -ChildPath $ModuleName
				if (Test-Path -Path $ModuleSubfolder) {
					$SubfolderXmlFiles = Get-ChildItem -Path $ModuleSubfolder -Filter "*.xml" -ErrorAction SilentlyContinue
					foreach ($XmlFile in $SubfolderXmlFiles) {
						$TargetPath = Join-Path -Path $MamlPath.FullName -ChildPath $XmlFile.Name
						if (Test-Path -Path $TargetPath) {
							Remove-Item -Path $TargetPath -Force
						}
						Move-Item -Path $XmlFile.FullName -Destination $TargetPath
						Write-PSFMessage -Level Verbose -Message "Moved $($XmlFile.Name) from module subfolder to target directory"
					}
					# Remove empty module subfolder
					if ((Get-ChildItem -Path $ModuleSubfolder).Count -eq 0) {
						Remove-Item -Path $ModuleSubfolder -Force
						Write-PSFMessage -Level Verbose -Message "Removed empty module subfolder"
					}
				}

				# Also check for any other XML files in subfolders
				$OtherSubfolderXmlFiles = Get-ChildItem -Path $MamlPath.FullName -Recurse -Filter "*.xml" | Where-Object { $_.Directory.FullName -ne $MamlPath.FullName }
				foreach ($XmlFile in $OtherSubfolderXmlFiles) {
					$TargetPath = Join-Path -Path $MamlPath.FullName -ChildPath $XmlFile.Name
					if (Test-Path -Path $TargetPath) {
						Remove-Item -Path $TargetPath -Force
					}
					Move-Item -Path $XmlFile.FullName -Destination $TargetPath
					Write-PSFMessage -Level Verbose -Message "Moved $($XmlFile.Name) to target directory"
				}
			}
			else {
				Write-PSFMessage -Level Warning -Message "No command help imported from markdown files"
				throw "No valid markdown files imported"
			}
		}
		catch {
			Write-PSFMessage -Level Warning -Message "Failed to import markdown for MAML: $($_.Exception.Message)"
			Write-PSFMessage -Level Important -Message "Attempting direct module MAML generation"

			# Alternative approach: Generate MAML directly from the loaded module
			try {
				$ModuleCommands = Get-Command -Module $ModuleName -CommandType Cmdlet, Function
				if ($ModuleCommands) {
					Write-PSFMessage -Level Important -Message "Generating MAML from $($ModuleCommands.Count) module commands"

					# Create command help objects from module commands
					$CommandHelpObjects = @()
					foreach ($Command in $ModuleCommands) {
						try {
							$CmdHelp = New-CommandHelp -CommandInfo $Command
							if ($CmdHelp) {
								$CommandHelpObjects += $CmdHelp
							}
						}
						catch {
							Write-PSFMessage -Level Warning -Message "Failed to create help for $($Command.Name): $($_.Exception.Message)"
						}
					}

					if ($CommandHelpObjects.Count -gt 0) {
						Export-MamlCommandHelp -CommandHelp $CommandHelpObjects @ExtHelpParams -Force
						Write-PSFMessage -Level Important -Message "Successfully generated MAML help from module commands"

						# Move any XML files from subfolders to the target directory (including module-named subfolders)
						$ModuleSubfolder = Join-Path -Path $MamlPath.FullName -ChildPath $ModuleName
						if (Test-Path -Path $ModuleSubfolder) {
							$SubfolderXmlFiles = Get-ChildItem -Path $ModuleSubfolder -Filter "*.xml" -ErrorAction SilentlyContinue
							foreach ($XmlFile in $SubfolderXmlFiles) {
								$TargetPath = Join-Path -Path $MamlPath.FullName -ChildPath $XmlFile.Name
								if (Test-Path -Path $TargetPath) {
									Remove-Item -Path $TargetPath -Force
								}
								Move-Item -Path $XmlFile.FullName -Destination $TargetPath
								Write-PSFMessage -Level Verbose -Message "Moved $($XmlFile.Name) from module subfolder to target directory"
							}
							# Remove empty module subfolder
							if ((Get-ChildItem -Path $ModuleSubfolder).Count -eq 0) {
								Remove-Item -Path $ModuleSubfolder -Force
								Write-PSFMessage -Level Verbose -Message "Removed empty module subfolder"
							}
						}

						# Also check for any other XML files in subfolders
						$OtherSubfolderXmlFiles = Get-ChildItem -Path $MamlPath.FullName -Recurse -Filter "*.xml" | Where-Object { $_.Directory.FullName -ne $MamlPath.FullName }
						foreach ($XmlFile in $OtherSubfolderXmlFiles) {
							$TargetPath = Join-Path -Path $MamlPath.FullName -ChildPath $XmlFile.Name
							if (Test-Path -Path $TargetPath) {
								Remove-Item -Path $TargetPath -Force
							}
							Move-Item -Path $XmlFile.FullName -Destination $TargetPath
							Write-PSFMessage -Level Verbose -Message "Moved $($XmlFile.Name) to target directory"
						}
					}
					else {
						Write-PSFMessage -Level Error -Message "No command help objects created"
					}
				}
				else {
					Write-PSFMessage -Level Error -Message "No commands found in module $ModuleName"
				}
			}
			catch {
				Write-PSFMessage -Level Error -Message "Direct module MAML generation also failed: $($_.Exception.Message)"
				Write-PSFMessage -Level Important -Message "MAML generation skipped - markdown files are still available"
			}
		}
	}
	else {
		Write-PSFMessage -Level Warning -Message "No markdown files found to convert to MAML in path: $($MarkdownPath.FullName)"
	}
}
else {
	Write-PSFMessage -Level Important -Message "Skipping MAML generation as requested"
}

# Note: New-ExternalHelpCab is only supported on Windows because it relies on makecab.exe to create CAB files.
# Uncomment the following line if you need CAB file generation on Windows:
# New-ExternalHelpCab @ExtHelpCabParams
