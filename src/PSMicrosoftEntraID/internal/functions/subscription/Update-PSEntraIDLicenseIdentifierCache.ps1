function Update-PSEntraIDLicenseIdentifierCache {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Internal cache helper; refreshes a local CSV file without modifying remote tenant state.')]
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $Force
    )

    [string] $cachePath = Get-PSFConfigValue -FullName ('{0}.LicenseIdentifiers.CachePath' -f $script:ModuleName) -Fallback (Get-PSEntraIDDefaultLicenseIdentifierCachePath)
    [string] $resolvedCachePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($cachePath)
    [string] $sourceUrl = Get-PSFConfigValue -FullName ('{0}.LicenseIdentifiers.SourceUrl' -f $script:ModuleName) -Fallback 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
    [int] $refreshIntervalDays = Get-PSFConfigValue -FullName ('{0}.LicenseIdentifiers.AutoUpdateIntervalDays' -f $script:ModuleName) -Fallback 30

    if (-not $Force -and (Test-Path -Path $resolvedCachePath -PathType Leaf)) {
        [datetime] $minimumWriteTime = [datetime]::UtcNow.AddDays(-1 * $refreshIntervalDays)
        if ((Get-Item -Path $resolvedCachePath).LastWriteTimeUtc -ge $minimumWriteTime) {
            return $resolvedCachePath
        }
    }

    [string] $cacheDirectory = Split-Path -Path $resolvedCachePath -Parent
    if (-not (Test-Path -Path $cacheDirectory)) {
        New-Item -Path $cacheDirectory -ItemType Directory -Force | Out-Null
    }

    [string] $downloadPath = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.csv')

    try {
        Invoke-WebRequest -Uri $sourceUrl -OutFile $downloadPath

        [object[]] $rows = @(Import-Csv -Path $downloadPath)
        if ($rows.Count -eq 0) {
            throw 'The licensing reference CSV did not contain any rows.'
        }

        [object[]] $licenseIdentifiers = @(foreach ($skuGroup in ($rows | Group-Object GUID, String_Id)) {
            [object[]] $groupRows = @($skuGroup.Group)
            [pscustomobject[]] $servicePlans = @(
                foreach ($servicePlanGroup in ($groupRows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Service_Plan_Id) } | Group-Object Service_Plan_Id, Service_Plan_Name)) {
                    [object] $servicePlanRow = $servicePlanGroup.Group |
                        Sort-Object @{ Expression = { [string]::IsNullOrWhiteSpace($_.Service_Plans_Included_Friendly_Names) } }, Service_Plans_Included_Friendly_Names |
                        Select-Object -First 1

                    [pscustomobject]@{
                        servicePlanId = $servicePlanRow.Service_Plan_Id
                        servicePlanName = $servicePlanRow.Service_Plan_Name
                        servicePlanFriendlyName = $servicePlanRow.Service_Plans_Included_Friendly_Names
                    }
                }
            ) | Sort-Object servicePlanName, servicePlanId

            [object] $skuRow = $groupRows |
                Sort-Object @{ Expression = { [string]::IsNullOrWhiteSpace($_.Product_Display_Name) } }, Product_Display_Name |
                Select-Object -First 1

            [pscustomobject]@{
                skuId = $skuRow.GUID
                skuPartNumber = $skuRow.String_Id
                skuFriendlyName = $skuRow.Product_Display_Name
                servicePlans = @($servicePlans)
            }
        }) | Sort-Object skuPartNumber, skuId

        [string] $json = $licenseIdentifiers | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($resolvedCachePath, $json, [System.Text.UTF8Encoding]::new($false))

        return $resolvedCachePath
    }
    catch {
        Write-PSFMessage -Level Verbose -Message ('License identifier cache refresh failed: {0}' -f $_.Exception.Message)
        return $null
    }
    finally {
        if (Test-Path -Path $downloadPath) {
            Remove-Item -Path $downloadPath -Force
        }
    }
}