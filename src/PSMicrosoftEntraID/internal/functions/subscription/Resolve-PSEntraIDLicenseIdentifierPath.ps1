function Get-PSEntraIDDefaultLicenseIdentifierCachePath {
    [CmdletBinding()]
    param ()

    [string] $basePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
    if ([string]::IsNullOrWhiteSpace($basePath)) {
        $basePath = [System.IO.Path]::GetTempPath()
    }

    [string] $moduleCacheDirectory = Join-Path -Path $basePath -ChildPath 'PSMicrosoftEntraID'
    [string] $identifierDirectory = Join-Path -Path $moduleCacheDirectory -ChildPath 'identifiers'
    Join-Path -Path $identifierDirectory -ChildPath 'LicenseIdentifiers.json'
}

function Resolve-PSEntraIDLicenseIdentifierPath {
    [CmdletBinding()]
    param ()

    [string] $bundledCatalogPath = Join-Path -Path (Join-Path -Path $script:ModuleRoot -ChildPath 'internal') -ChildPath (Join-Path -Path 'identifiers' -ChildPath 'LicenseIdentifiers.json')
    [string] $cachePath = Get-PSFConfigValue -FullName ('{0}.LicenseIdentifiers.CachePath' -f $script:ModuleName) -Fallback (Get-PSEntraIDDefaultLicenseIdentifierCachePath)

    if (-not [string]::IsNullOrWhiteSpace($cachePath)) {
        [string] $resolvedCachePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cachePath)
        if (Test-Path -Path $resolvedCachePath -PathType Leaf) {
            return $resolvedCachePath
        }
    }

    return $bundledCatalogPath
}