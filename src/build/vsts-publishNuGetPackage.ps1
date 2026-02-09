[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param (
    $WorkingDirectory,
    [string]$OrganizationName,
    [string]$ArtifactRepositoryName,
    [string]$ArtifactFeedName,
    [string]$FeedUsername,
    [string]$PersonalAccessToken,
    [string]$ModuleName,
    [string]$ModuleVersion,
    [string]$PreRelease,
    [string]$CommitsSinceVersion
)

# Variables
# NOTE: Using v3 feed URL for dotnet nuget compatibility
$packageSourceUrl = "https://pkgs.dev.azure.com/$($OrganizationName)/$ArtifactRepositoryName/_packaging/$ArtifactFeedName/nuget/v3/index.json"

# Step 1
# Register NuGet Package Source (remove existing source first to avoid duplicates)
dotnet nuget remove source $ArtifactFeedName 2>$null
dotnet nuget add source $packageSourceUrl --name $ArtifactFeedName --username $FeedUsername --password $PersonalAccessToken --store-password-in-clear-text
if ($LASTEXITCODE -ne 0) {
    throw "[vsts-publishNuGetPackage] Failed to add NuGet source '$ArtifactFeedName'!"
}

# Step 2
# Upload NuGet Package
if (-not ([string]::IsNullOrEmpty($PreRelease))) {
    # Sestavení prerelease části a odstranění nevalidních znaků
    $sanitizedSuffix = ($PreRelease + $CommitsSinceVersion) -replace '[^a-zA-Z0-9]', ''
    $packageName = "$ModuleName.$ModuleVersion-$sanitizedSuffix.nupkg"

    dotnet nuget push $packageName --source $ArtifactFeedName --api-key ((New-Guid).Guid) --skip-duplicate
}
else {
    $packageName = "$ModuleName.$ModuleVersion.nupkg"

    dotnet nuget push $packageName --source $ArtifactFeedName --api-key ((New-Guid).Guid) --skip-duplicate
}

if ($LASTEXITCODE -ne 0) {
    throw "[vsts-publishNuGetPackage] Failed to push package '$packageName'!"
}