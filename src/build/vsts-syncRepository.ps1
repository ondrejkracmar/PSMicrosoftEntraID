param (
    [string]$AzureDevOpsOrganizationName,
    [string]$AzureDevOpsProjectName,
    [string]$AzureDevOpsRepositoryName,
    [string]$GitHubUsername,
    [string]$GitHubRepositoryName,
    [string]$GitHubToken
)

try {
    # Construct the Azure DevOps and GitHub repository URLs
    $AzureRepoUrl = ('https://dev.azure.com/{0}/{1}/_git/{2}]' -f $AzureDevOpsOrganizationName, $AzureDevOpsProjectName, $AzureDevOpsRepositoryName)
    $GitHubRepoUrl = ('github.com/{0}/{1}' -f $GitHubUsername, $GitHubRepositoryName)

    # Log the constructed URLs
    Write-PSFMessage -Level Host -Message ('Azure DevOps Repository URL: {0}' -f $AzureRepoUrl)
    Write-PSFMessage -Level Host -Message ('GitHub Repository URL: ' -f $GitHubRepoUrl)

    # Clone the Azure DevOps repository in mirror mode
    Write-PSFMessage -Level Host -Message "Cloning Azure DevOps repository..."
    git clone --mirror $AzureRepoUrl repo.git

    # Navigate to the cloned repository folder
    Set-Location -Path repo.git

    # Add GitHub as a remote repository
    Write-PSFMessage -Level Host -Message "Adding GitHub remote repository..."
    git remote add github ('https://{0}@{1}' -f $GitHubToken, $GitHubRepoUrl)

    # Push changes to GitHub
    Write-PSFMessage -Level Host -Message "Pushing to GitHub..."
    git push --mirror github

    # Return to the original directory
    Set-Location -Path ..
    Write-PSFMessage -Level Important -Message "Synchronization completed successfully."
} catch {
    Stop-PSFFunction -Message "An error occurred" -EnableException $true -ErrorRecord $_
}