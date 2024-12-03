param (
    [string]$AzureDevOpsOrganizationName,
    [string]$AzureDevOpsProjectName,
    [string]$AzureDevOpsRepositoryName,
    [string]$AzureDevOpsUsername,
    [string]$AzureDevOpsToken,
    [string]$GitHubUsername,
    [string]$GitHubRepositoryName,
    [string]$GitHubToken
)

try {
    # Construct the Azure DevOps and GitHub repository URLs
    $EncodedPAT = [System.Web.HttpUtility]::UrlEncode($AzureDevOpsToken)
    $AzureRepoUrl = ('https://{0}@dev.azure.com/{1}/{2}/_git/{3}' -f $EncodedPAT, $AzureDevOpsOrganizationName, $AzureDevOpsProjectName, $AzureDevOpsRepositoryName)
    $GitHubRepoUrl = ('https://github.com/{0}/{1}' -f $GitHubUsername, $GitHubRepositoryName)

    # Log the constructed URLs
    Write-PSFMessage -Level Host -Message ('Azure DevOps Repository URL: {0}' -f $AzureRepoUrl)
    Write-PSFMessage -Level Host -Message ('GitHub Repository URL: {0}' -f $GitHubRepoUrl)

    # Configure Git to use credentials for Azure DevOps
    Write-Host "Configuring Git credentials for Azure DevOps..."
    $CredentialContent = @'
protocol=https
host=dev.azure.com
username=$AzureDevOpsUserName
password=$AzureDevOpsToken
'@

    $TempCredentialFile = New-TemporaryFile
    $CredentialContent | Set-Content -Path $TempCredentialFile.FullName

    # Pipe credentials to Git credential helper
    Get-Content $TempCredentialFile.FullName | git credential approve

    # Remove temporary credential file
    Remove-Item $TempCredentialFile.FullName

    # Clone the Azure DevOps repository in mirror mode
    Write-PSFMessage -Level Host -Message "Cloning Azure DevOps repository..."
    git clone --mirror $AzureRepoUrl repo.git

    # Navigate to the cloned repository folder
    Set-Location -Path repo.git

    # Add GitHub as a remote repository
    Write-PSFMessage -Level Host -Message "Adding GitHub remote repository..."
    git remote add github ('{0}@{1}' -f $GitHubToken, $GitHubRepoUrl)

    # Push changes to GitHub
    Write-PSFMessage -Level Host -Message "Pushing to GitHub..."
    git push --mirror github

    # Return to the original directory
    Set-Location -Path ..
    Write-PSFMessage -Level Important -Message "Synchronization completed successfully."
} catch {
    Stop-PSFFunction -Message "An error occurred" -EnableException $true -ErrorRecord $_
}