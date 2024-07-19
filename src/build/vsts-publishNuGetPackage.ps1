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
    [string]$PreRelease
)

# Variables
$packageSourceUrl = "https://pkgs.dev.azure.com/$($OrganizationName)/$ArtifactRepositoryName/_packaging/$ArtifactFeedName/nuget/v2" # NOTE: v2 Feed

$nugetPath = 'nuget'

# Create credential
$password = ConvertTo-SecureString -String $PersonalAccessToken -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($FeedUsername, $password)


# Step 1 - "Install NuGet" Agent job task now handles this
# Upgrade PowerShellGet
# Install-Module PowerShellGet -RequiredVersion $powershellGetVersion -Force
# Remove-Module PowerShellGet -Force
# Import-Module PowerShellGet -RequiredVersion $powershellGetVersion -Force

# Step 2
# Check NuGet is listed
#Get-PackageProvider -Name 'NuGet' -ForceBootstrap | Format-List *

# Step 3
# Register NuGet Package Source
& $nugetPath source add -Name $ArtifactFeedName -Source $packageSourceUrl -Username $FeedUsername -Password $PersonalAccessToken

# Step 4
# Upload NuGet Package
if (-not ([string]::IsNullOrEmpty($PreRelease))) {
    & $nugetPath push -Source $ArtifactFeedName -ApiKey ((New-Guid).Guid) "$($ModuleName).$($ModuleVersion)-$($PreRelease).nupkg" -SkipDuplicate
}
else {
    & $nugetPath push -Source $ArtifactFeedName -ApiKey ((New-Guid).Guid) "$($ModuleName).$($ModuleVersion).nupkg" -SkipDuplicate
}
