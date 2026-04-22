[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string] $CsvUrl = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv',

    [Parameter()]
    [string] $OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath '../PSMicrosoftEntraID/internal/identifiers/LicenseIdentifiers.json'),

    [Parameter()]
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string] $resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
[string] $outputDirectory = Split-Path -Path $resolvedOutputPath -Parent

if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
}

[string] $downloadPath = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.csv')

try {
    Invoke-WebRequest -Uri $CsvUrl -OutFile $downloadPath

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

    if ($PSCmdlet.ShouldProcess($resolvedOutputPath, 'Write license identifier catalog')) {
        [System.IO.File]::WriteAllText($resolvedOutputPath, $json, [System.Text.UTF8Encoding]::new($false))
    }

    if ($PassThru) {
        $licenseIdentifiers
    }
}
finally {
    if (Test-Path -Path $downloadPath) {
        Remove-Item -Path $downloadPath -Force
    }
}