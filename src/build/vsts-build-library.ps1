<#
.SYNOPSIS
    Builds a PowerShell module's .NET binary library (DLL) from source.

.DESCRIPTION
    This script compiles a .NET project, then copies all output files from the
    most recent target framework build directory (e.g., net8.0, netstandard2.1) into
    the module's `bin/` directory. It works without hardcoded framework names.

.PARAMETER WorkingDirectory
    The root directory of the project (where the .sln file is located).

.EXAMPLE
    .\vsts-build-library.ps1 -WorkingDirectory "C:\MyRepo\src"
#>

[CmdletBinding()]
param (
    [string]$WorkingDirectory
)

#region Resolve Working Directory
if (-not $WorkingDirectory) {
    $WorkingDirectory = Split-Path -Parent $PSScriptRoot
}
#endregion

# Find solution file
$SlnPath = Get-ChildItem -Path $WorkingDirectory -Filter *.sln -Recurse | Select-Object -First 1
if (-not $SlnPath) {
    throw "[vsts-build-library] ❌ Solution (.sln) file not found."
}

# Find project folder with .csproj
$ProjectFolder = Get-ChildItem -Path $WorkingDirectory -Directory -Recurse | Where-Object {
    Test-Path (Join-Path $_.FullName "*.csproj")
} | Select-Object -First 1

if (-not $ProjectFolder) {
    throw "[vsts-build-library] ❌ No folder with .csproj found."
}

$BinFolder = Join-Path $ProjectFolder.FullName "bin"

Write-Host "[vsts-build-library] 🔄 Restoring .NET dependencies..."
dotnet restore $SlnPath.FullName
if ($LASTEXITCODE -ne 0) {
    throw "[vsts-build-library] ❌ dotnet restore failed!"
}

Write-Host "[vsts-build-library] 🏗️ Building the project..."
dotnet build $SlnPath.FullName --configuration Release
if ($LASTEXITCODE -ne 0) {
    throw "[vsts-build-library] ❌ Build failed!"
}

# Detect latest net* output directory inside bin/
$LatestOutputDir = Get-ChildItem -Path $BinFolder -Directory |
    Where-Object { $_.Name -match '^net\d+' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $LatestOutputDir) {
    throw "[vsts-build-library] ❌ No 'net*' build output found in: $BinFolder"
}

Write-Host "[vsts-build-library] 📦 Copying build output from: $($LatestOutputDir.FullName)"

# Copy files to bin root (same level as 'net8.0', etc.)
Get-ChildItem -Path $LatestOutputDir.FullName -File | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $BinFolder -Force
    Write-Host "[vsts-build-library] ➕ Copied: $($_.Name)"
}

# Optionally clean the detected folder
Remove-Item -Path $LatestOutputDir.FullName -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[vsts-build-library] 🧹 Cleaned: $($LatestOutputDir.FullName)"

Write-Host "[vsts-build-library] ✅ Build complete."
Write-Host "[vsts-build-library] 📂 Final output directory: $BinFolder"
Set-Location -Path $WorkingDirectory
