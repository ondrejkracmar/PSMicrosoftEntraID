# PSMicrosoftEntraID

PSMicrosoftEntraID is a PowerShell module that simplifies management and automation tasks in Microsoft Entra ID (formerly known as Azure Active Directory). It provides a suite of cmdlets for user and license management, as well as support for batch processing of operations.

## Features

- **User Management:** Retrieve and manage users within your Microsoft Entra ID tenant.
- **License Management:** Easily enable or disable user licenses.
- **Batch Processing:** Create batch request objects for deferred execution using the `-PassThru` parameter.
- **Robust Error Handling:** Built-in error handling with options for retry mechanisms.

## Prerequisites

- PowerShell **7.x or later** (PowerShell 5.1 is **not supported**)
- The **PSFramework** module (required dependency)
- A valid Microsoft Entra ID tenant and the necessary permissions to manage users and licenses

## Installation

First, install the required **PSFramework** module:

```powershell
Install-Module -Name PSFramework -Scope CurrentUser
```

Then, install the **PSMicrosoftEntraID** module:

```powershell
Install-Module -Name PSMicrosoftEntraID -Scope CurrentUser
```

Or import it into your current session:

```powershell
Import-Module PSMicrosoftEntraID
```

## Usage Examples

### Authentication and Connection

First, connect to Microsoft Entra ID using one of the available authentication methods:

```powershell
# Interactive browser authentication (most common)
Connect-PSMicrosoftEntraID -ClientId "your-app-id" -TenantId "your-tenant-id"

# Device code authentication (for headless scenarios)
Connect-PSMicrosoftEntraID -ClientId "your-app-id" -TenantId "your-tenant-id" -DeviceCode

# Client secret authentication (app-only)
Connect-PSMicrosoftEntraID -ClientId "your-app-id" -TenantId "your-tenant-id" -ClientSecret "your-secret"
```

### User Management Examples

#### Get User Information
```powershell
# Get a specific user by email
$user = Get-PSEntraIDUser -Identity "john.doe@contoso.com"

# Get all users in the organization
$allUsers = Get-PSEntraIDUser

# Get users with specific properties
$users = Get-PSEntraIDUser -Property "displayName", "mail", "department"

# Search for users by display name
$users = Get-PSEntraIDUser -Filter "startswith(displayName,'John')"
```

#### Create and Manage Users
```powershell
# Create a new user
$newUser = New-PSEntraIDUser -DisplayName "Jane Smith" -UserPrincipalName "jane.smith@contoso.com" -MailNickname "jane.smith" -AccountEnabled $true

# Update user properties
Set-PSEntraIDUser -Identity "jane.smith@contoso.com" -Department "IT" -JobTitle "System Administrator"

# Set user usage location for licensing
Set-PSEntraIDUserUsageLocation -Identity "jane.smith@contoso.com" -UsageLocation "US"

# Invite a guest user
New-PSEntraIDInvitation -InvitedUserEmailAddress "external@partner.com" -InviteRedirectUrl "https://portal.azure.com"
```

### License Management Examples

#### View License Information
```powershell
# Get all available licenses in the tenant
$licenses = Get-PSEntraIDSubscribedLicense

# Get user's current license assignments
$userLicenses = Get-PSEntraIDUserLicense -Identity "john.doe@contoso.com"

# Get detailed license information including service plans
$licenseDetails = Get-PSEntraIDUserLicenseDetail -Identity "john.doe@contoso.com"
```

#### Assign and Remove Licenses
```powershell
# Enable a license for a user
Enable-PSEntraIDUserLicense -Identity "john.doe@contoso.com" -SkuPartNumber "ENTERPRISEPACK"

# Disable a license for a user
Disable-PSEntraIDUserLicense -Identity "john.doe@contoso.com" -SkuPartNumber "ENTERPRISEPACK"

# Enable specific service plan within a license
Enable-PSEntraIDUserLicenseServicePlan -Identity "john.doe@contoso.com" -SkuPartNumber "ENTERPRISEPACK" -ServicePlanName "TEAMS1"

# Disable specific service plan
Disable-PSEntraIDUserLicenseServicePlan -Identity "john.doe@contoso.com" -SkuPartNumber "ENTERPRISEPACK" -ServicePlanName "TEAMS1"
```

### Group Management Examples

#### Create and Manage Groups
```powershell
# Create a new security group
$group = New-PSEntraIDGroup -DisplayName "IT Security Team" -MailNickname "it-security" -GroupTypes @() -SecurityEnabled $true

# Create a Microsoft 365 group
$m365Group = New-PSEntraIDGroup -DisplayName "Project Alpha" -MailNickname "project-alpha" -GroupTypes @("Unified") -MailEnabled $true

# Update group properties
Set-PSEntraIDGroup -Identity "it-security@contoso.com" -Description "Security team for IT operations"
```

#### Manage Group Membership
```powershell
# Add users to a group
Add-PSEntraIDGroupMember -Identity "it-security@contoso.com" -MemberIdentity "john.doe@contoso.com"

# Get all group members
$members = Get-PSEntraIDGroupMember -Identity "it-security@contoso.com"

# Remove a user from a group
Remove-PSEntraIDGroupMember -Identity "it-security@contoso.com" -MemberIdentity "john.doe@contoso.com"

# Add group owner
Add-PSEntraIDGroupOwner -Identity "it-security@contoso.com" -OwnerIdentity "manager@contoso.com"

# Synchronize group membership with a list of users
$targetMembers = @("user1@contoso.com", "user2@contoso.com", "user3@contoso.com")
Sync-PSEntraIDGroupMember -Identity "it-security@contoso.com" -MemberIdentity $targetMembers
```

### Administrative Unit Management Examples

```powershell
# Create an administrative unit
$adminUnit = New-PSEntraIDAdministrativeUnit -DisplayName "Sales Department" -Description "Administrative unit for sales team"

# Add users to administrative unit
Add-PSEntraIDAdministrativeUnitMember -Identity "Sales Department" -MemberIdentity "sales1@contoso.com"

# Get administrative unit members
$auMembers = Get-PSEntraIDAdministrativeUnitMember -Identity "Sales Department"

# Remove user from administrative unit
Remove-PSEntraIDAdministrativeUnitMember -Identity "Sales Department" -MemberIdentity "sales1@contoso.com"
```

### Batch Processing Examples

#### Create Batch Requests for Deferred Execution
```powershell
# Create multiple batch request objects
$batchRequests = @()

# Add license disable requests to batch
$batchRequests += Disable-PSEntraIDUserLicense -Identity "user1@contoso.com" -SkuPartNumber "ENTERPRISEPACK" -PassThru
$batchRequests += Disable-PSEntraIDUserLicense -Identity "user2@contoso.com" -SkuPartNumber "ENTERPRISEPACK" -PassThru

# Execute all batch requests together
$results = Invoke-PSEntraIDBatchRequest -BatchRequest $batchRequests
```

#### Advanced Batch Operations
```powershell
# Create a complex batch with different operations
$batch = New-PSEntraIDBatchRequest

# Add multiple operations to the batch
$batch.Requests += (Get-PSEntraIDUser -Identity "user1@contoso.com" -PassThru)
$batch.Requests += (Set-PSEntraIDUser -Identity "user2@contoso.com" -Department "HR" -PassThru)
$batch.Requests += (Enable-PSEntraIDUserLicense -Identity "user3@contoso.com" -SkuPartNumber "ENTERPRISEPACK" -PassThru)

# Execute the batch
$batchResults = Invoke-PSEntraIDBatchRequest -BatchRequest $batch
```

### Advanced Scenarios

#### Bulk User License Assignment
```powershell
# Get all users without licenses and assign Enterprise license
$unlicensedUsers = Get-PSEntraIDUser | Where-Object { 
    $userLicenses = Get-PSEntraIDUserLicense -Identity $_.UserPrincipalName
    $userLicenses.Count -eq 0
}

foreach ($user in $unlicensedUsers) {
    # Set usage location first (required for licensing)
    Set-PSEntraIDUserUsageLocation -Identity $user.UserPrincipalName -UsageLocation "US"
    
    # Assign license
    Enable-PSEntraIDUserLicense -Identity $user.UserPrincipalName -SkuPartNumber "ENTERPRISEPACK"
    
    Write-Host "Licensed user: $($user.DisplayName)"
}
```

#### Department-based Group Management
```powershell
# Get all users from IT department
$itUsers = Get-PSEntraIDUser -Filter "department eq 'IT'"

# Create IT group if it doesn't exist
$itGroup = Get-PSEntraIDGroup -Filter "displayName eq 'IT Department'" -ErrorAction SilentlyContinue
if (-not $itGroup) {
    $itGroup = New-PSEntraIDGroup -DisplayName "IT Department" -MailNickname "it-dept" -GroupTypes @() -SecurityEnabled $true
}

# Add all IT users to the group
foreach ($user in $itUsers) {
    Add-PSEntraIDGroupMember -Identity $itGroup.Id -MemberIdentity $user.Id
    Write-Host "Added $($user.DisplayName) to IT Department group"
}
```

#### License Compliance Report
```powershell
# Generate a report of all users and their license status
$allUsers = Get-PSEntraIDUser
$licenseReport = foreach ($user in $allUsers) {
    $licenses = Get-PSEntraIDUserLicense -Identity $user.UserPrincipalName
    
    [PSCustomObject]@{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        Department = $user.Department
        LicenseCount = $licenses.Count
        LicenseNames = ($licenses.SkuPartNumber -join ', ')
        AccountEnabled = $user.AccountEnabled
    }
}

# Export to CSV
$licenseReport | Export-Csv -Path "UserLicenseReport.csv" -NoTypeInformation
```

### Error Handling and Retry Configuration

```powershell
# Configure retry behavior for resilient operations
Set-PSEntraIDCommandRetry -MaxRetries 5 -RetryDelaySeconds 2

# Get current retry configuration
$retryConfig = Get-PSEntraIDCommandRetry

# Use try-catch for error handling
try {
    $user = Get-PSEntraIDUser -Identity "nonexistent@contoso.com"
}
catch {
    Write-Error "User not found: $($_.Exception.Message)"
}
```

This command returns an object of type `PSMicrosoftEntraID.Batch.Request` that can be passed to another cmdlet for batch processing.

## Documentation

### Authentication and Setup
- [Authentication Overview](docs/authentication/overview.md) - Complete guide to authentication methods
- [Creating Applications](docs/authentication/creating-applications.md) - How to create Azure AD applications
- [Managing Applications](docs/authentication/managing-applications.md) - Managing application permissions
- [API Permissions](docs/authentication/api-permissions.md) - Required API permissions
- [Cmdlet Permissions](docs/authentication/cmdlet-permissions.md) - Detailed permissions for each cmdlet

#### Authentication Methods
- [Browser Authentication](docs/authentication/authenticate-browser.md) - Interactive browser authentication
- [Device Code Authentication](docs/authentication/authenticate-devicecode.md) - Device code flow
- [Client Secret Authentication](docs/authentication/authenticate-clientsecret.md) - App-only with client secret
- [Certificate Authentication](docs/authentication/authenticate-certificate.md) - App-only with certificate
- [Application vs Delegated Permissions](docs/authentication/application-vs-delegate.md) - Understanding permission types

### Cmdlet Reference

#### Connection and Authentication
- [Connect-PSMicrosoftEntraID](docs/cmdlets/Connect-PSMicrosoftEntraID.md) - Establish connection to Microsoft Entra ID
- [Disconnect-PSMicrosoftEntraID](docs/cmdlets/Disconnect-PSMicrosoftEntraID.md) - Disconnect from Microsoft Entra ID

#### User Management
- [Get-PSEntraIDUser](docs/cmdlets/Get-PSEntraIDUser.md) - Retrieve user information
- [Get-PSEntraIDUserGuest](docs/cmdlets/Get-PSEntraIDUserGuest.md) - Retrieve guest users
- [Get-PSEntraIDUserMemberOf](docs/cmdlets/Get-PSEntraIDUserMemberOf.md) - Get user group memberships
- [New-PSEntraIDUser](docs/cmdlets/New-PSEntraIDUser.md) - Create new users
- [Set-PSEntraIDUser](docs/cmdlets/Set-PSEntraIDUser.md) - Update user properties
- [Set-PSEntraIDUserUsageLocation](docs/cmdlets/Set-PSEntraIDUserUsageLocation.md) - Set user usage location
- [Remove-PSEntraIDUser](docs/cmdlets/Remove-PSEntraIDUser.md) - Delete users
- [Compare-PSEntraIDUserList](docs/cmdlets/Compare-PSEntraIDUserList.md) - Compare user lists
- [New-PSEntraIDInvitation](docs/cmdlets/New-PSEntraIDInvitation.md) - Invite guest users

#### Group Management
- [Get-PSEntraIDGroup](docs/cmdlets/Get-PSEntraIDGroup.md) - Retrieve group information
- [Get-PSEntraIDGroupAdditionalProperty](docs/cmdlets/Get-PSEntraIDGroupAdditionalProperty.md) - Get additional group properties
- [Get-PSEntraIDGroupMember](docs/cmdlets/Get-PSEntraIDGroupMember.md) - Get group members
- [New-PSEntraIDGroup](docs/cmdlets/New-PSEntraIDGroup.md) - Create new groups
- [Set-PSEntraIDGroup](docs/cmdlets/Set-PSEntraIDGroup.md) - Update group properties
- [Remove-PSEntraIDGroup](docs/cmdlets/Remove-PSEntraIDGroup.md) - Delete groups
- [Add-PSEntraIDGroupMember](docs/cmdlets/Add-PSEntraIDGroupMember.md) - Add members to groups
- [Remove-PSEntraIDGroupMember](docs/cmdlets/Remove-PSEntraIDGroupMember.md) - Remove members from groups
- [Add-PSEntraIDGroupOwner](docs/cmdlets/Add-PSEntraIDGroupOwner.md) - Add group owners
- [Remove-PSEntraIDGroupOwner](docs/cmdlets/Remove-PSEntraIDGroupOwner.md) - Remove group owners
- [Sync-PSEntraIDGroupMember](docs/cmdlets/Sync-PSEntraIDGroupMember.md) - Synchronize group membership

#### Administrative Unit Management
- [Get-PSEntraIDAdministrativeUnit](docs/cmdlets/Get-PSEntraIDAdministrativeUnit.md) - Retrieve administrative units
- [Get-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Get-PSEntraIDAdministrativeUnitMember.md) - Get administrative unit members
- [New-PSEntraIDAdministrativeUnit](docs/cmdlets/New-PSEntraIDAdministrativeUnit.md) - Create administrative units
- [Set-PSEntraIDAdministrativeUnit](docs/cmdlets/Set-PSEntraIDAdministrativeUnit.md) - Update administrative units
- [Remove-PSEntraIDAdministrativeUnit](docs/cmdlets/Remove-PSEntraIDAdministrativeUnit.md) - Delete administrative units
- [Add-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Add-PSEntraIDAdministrativeUnitMember.md) - Add members to administrative units
- [Remove-PSEntraIDAdministrativeUnitMember](docs/cmdlets/Remove-PSEntraIDAdministrativeUnitMember.md) - Remove members from administrative units

#### License Management
- [Get-PSEntraIDSubscribedLicense](docs/cmdlets/Get-PSEntraIDSubscribedLicense.md) - Get tenant license information
- [Get-PSEntraIDLicenseIdentifier](docs/cmdlets/Get-PSEntraIDLicenseIdentifier.md) - Get license identifiers
- [Get-PSEntraIDUsageLocation](docs/cmdlets/Get-PSEntraIDUsageLocation.md) - Get usage location information
- [Get-PSEntraIDUserLicense](docs/cmdlets/Get-PSEntraIDUserLicense.md) - Get user license assignments
- [Get-PSEntraIDUserLicenseDetail](docs/cmdlets/Get-PSEntraIDUserLicenseDetail.md) - Get detailed user license information
- [Enable-PSEntraIDUserLicense](docs/cmdlets/Enable-PSEntraIDUserLicense.md) - Assign licenses to users
- [Disable-PSEntraIDUserLicense](docs/cmdlets/Disable-PSEntraIDUserLicense.md) - Remove licenses from users
- [Enable-PSEntraIDUserLicenseServicePlan](docs/cmdlets/Enable-PSEntraIDUserLicenseServicePlan.md) - Enable license service plans
- [Disable-PSEntraIDUserLicenseServicePlan](docs/cmdlets/Disable-PSEntraIDUserLicenseServicePlan.md) - Disable license service plans

#### Organization and Directory
- [Get-PSEntraIDOrganization](docs/cmdlets/Get-PSEntraIDOrganization.md) - Get organization information
- [Get-PSEntraIDContact](docs/cmdlets/Get-PSEntraIDContact.md) - Retrieve contacts
- [Get-PSEntraIDMessageCenter](docs/cmdlets/Get-PSEntraIDMessageCenter.md) - Get service messages

#### Core Functions and Utilities
- [Invoke-PSEntraIDRequest](docs/cmdlets/Invoke-PSEntraIDRequest.md) - Make direct Graph API requests
- [Invoke-PSEntraIDBatchRequest](docs/cmdlets/Invoke-PSEntraIDBatchRequest.md) - Execute batch requests
- [New-PSEntraIDBatchRequest](docs/cmdlets/New-PSEntraIDBatchRequest.md) - Create batch request objects
- [Get-PSEntraIDCommandRetry](docs/cmdlets/Get-PSEntraIDCommandRetry.md) - Get retry configuration
- [Set-PSEntraIDCommandRetry](docs/cmdlets/Set-PSEntraIDCommandRetry.md) - Configure retry behavior

## Getting Help

For detailed information on any cmdlet, use the `Get-Help` command:

```powershell
Get-Help Disable-PSEntraIDUserLicense -Full
```

## Contributing

Contributions are welcome! If you encounter any issues or would like to add features, please open an issue or submit a pull request on the project's repository.

## License

This project is licensed under the [MIT License](LICENSE).
