﻿<#
.SYNOPSIS
    Builds the PSMicrosoftEntraID binary library from source.

.DESCRIPTION
    Builds the PSMicrosoftEntraID binary library from source.

.PARAMETER WorkingDirectory
    Path where the project root is.
    Defaults to the parent folder this file is in.

.EXAMPLE
    PS C:\> .\vsts-build-library.ps1

    Builds the PSMicrosoftEntraID binary library from source.
#>
[CmdletBinding()]
param (
    $WorkingDirectory
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

Write-Host "Restoring .NET dependencies..."
dotnet restore "$WorkingDirectory\library\PSMicrosoftEntraID.sln"
if ($LASTEXITCODE -ne 0) {
    throw "dotnet restore failed!"
}

Write-Host "Building the PowerShell module..."
dotnet build "$WorkingDirectory\library\PSMicrosoftEntraID.sln"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build PSMicrosoftEntraID.dll!"
}
