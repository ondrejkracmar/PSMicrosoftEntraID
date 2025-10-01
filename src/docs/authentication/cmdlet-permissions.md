# Microsoft Graph API Permissions for PSMicrosoftEntraID Cmdlets

> [Back to Overview](overview.md)

This document provides a comprehensive list of Microsoft Graph API permissions required for each cmdlet in the PSMicrosoftEntraID module. The permissions are categorized by cmdlet functionality and specify both **Delegated** and **Application** permission requirements.

## Table of Contents

- [Connection and Authentication](#connection-and-authentication)
- [Organization Management](#organization-management)
- [Service Announcements](#service-announcements)
- [User Management](#user-management)
- [Group Management](#group-management)
- [Administrative Unit Management](#administrative-unit-management)
- [Contact Management](#contact-management)
- [License Management](#license-management)
- [Utility and Core Functions](#utility-and-core-functions)
- [Permission Consent Requirements](#permission-consent-requirements)

---

## Connection and Authentication

### Connect-PSMicrosoftEntraID
**Required Permissions**: None (used for authentication)
- **Delegated**: None
- **Application**: None
- **Notes**: This cmdlet is used to establish authentication and doesn't require specific Graph permissions.

### Disconnect-PSMicrosoftEntraID
**Required Permissions**: None
- **Delegated**: None
- **Application**: None
- **Notes**: This cmdlet terminates the session and doesn't require specific Graph permissions.

---

## Organization Management

### Get-PSEntraIDOrganization
**Microsoft Graph API**: `GET /organization`
- **Delegated**: `Organization.Read.All` or `Directory.Read.All`
- **Application**: `Organization.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

---

## Service Announcements

### Get-PSEntraIDMessageCenter
**Microsoft Graph API**: `GET /admin/serviceAnnouncement/messages`
- **Delegated**: `ServiceMessage.Read.All`
- **Application**: `ServiceMessage.Read.All`
- **Admin Consent Required**: Yes

---

## User Management

### Get-PSEntraIDUser
**Microsoft Graph API**: `GET /users` or `GET /users/{id}`
- **Delegated**: `User.Read.All` or `Directory.Read.All`
- **Application**: `User.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDUserGuest
**Microsoft Graph API**: `GET /users`
- **Delegated**: `User.Read.All` or `Directory.Read.All`
- **Application**: `User.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### New-PSEntraIDUser
**Microsoft Graph API**: `POST /users`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Set-PSEntraIDUser
**Microsoft Graph API**: `PATCH /users/{id}`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Remove-PSEntraIDUser
**Microsoft Graph API**: `DELETE /users/{id}`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDUserMemberOf
**Microsoft Graph API**: `GET /users/{id}/memberOf`
- **Delegated**: `User.Read.All`, `GroupMember.Read.All`, or `Directory.Read.All`
- **Application**: `User.Read.All`, `GroupMember.Read.All`, or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Compare-PSEntraIDUserList
**Microsoft Graph API**: `GET /users`
- **Delegated**: `User.Read.All` or `Directory.Read.All`
- **Application**: `User.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Set-PSEntraIDUserUsageLocation
**Microsoft Graph API**: `PATCH /users/{id}`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### New-PSEntraIDInvitation
**Microsoft Graph API**: `POST /invitations`
- **Delegated**: `User.Invite.All` or `Directory.ReadWrite.All`
- **Application**: `User.Invite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

---

## Group Management

### Get-PSEntraIDGroup
**Microsoft Graph API**: `GET /groups` or `GET /groups/{id}`
- **Delegated**: `Group.Read.All` or `Directory.Read.All`
- **Application**: `Group.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDGroupAdditionalProperty
**Microsoft Graph API**: `GET /groups/{id}`
- **Delegated**: `Group.Read.All` or `Directory.Read.All`
- **Application**: `Group.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### New-PSEntraIDGroup
**Microsoft Graph API**: `POST /groups`
- **Delegated**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Set-PSEntraIDGroup
**Microsoft Graph API**: `PATCH /groups/{id}`
- **Delegated**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Remove-PSEntraIDGroup
**Microsoft Graph API**: `DELETE /groups/{id}`
- **Delegated**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDGroupMember
**Microsoft Graph API**: `GET /groups/{id}/members`
- **Delegated**: `GroupMember.Read.All`, `Group.Read.All`, or `Directory.Read.All`
- **Application**: `GroupMember.Read.All`, `Group.Read.All`, or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Add-PSEntraIDGroupMember
**Microsoft Graph API**: `POST /groups/{id}/members/$ref`
- **Delegated**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Application**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Remove-PSEntraIDGroupMember
**Microsoft Graph API**: `DELETE /groups/{id}/members/{id}/$ref`
- **Delegated**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Application**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Add-PSEntraIDGroupOwner
**Microsoft Graph API**: `POST /groups/{id}/owners/$ref`
- **Delegated**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Remove-PSEntraIDGroupOwner
**Microsoft Graph API**: `DELETE /groups/{id}/owners/{id}/$ref`
- **Delegated**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `Group.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Sync-PSEntraIDGroupMember
**Microsoft Graph API**: `GET /groups/{id}/members` and `POST /groups/{id}/members/$ref`
- **Delegated**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Application**: `GroupMember.ReadWrite.All`, `Group.ReadWrite.All`, or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

---

## Administrative Unit Management

### Get-PSEntraIDAdministrativeUnit
**Microsoft Graph API**: `GET /administrativeUnits` or `GET /administrativeUnits/{id}`
- **Delegated**: `AdministrativeUnit.Read.All` or `Directory.Read.All`
- **Application**: `AdministrativeUnit.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### New-PSEntraIDAdministrativeUnit
**Microsoft Graph API**: `POST /administrativeUnits`
- **Delegated**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Set-PSEntraIDAdministrativeUnit
**Microsoft Graph API**: `PATCH /administrativeUnits/{id}`
- **Delegated**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Remove-PSEntraIDAdministrativeUnit
**Microsoft Graph API**: `DELETE /administrativeUnits/{id}`
- **Delegated**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `AdministrativeUnit.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

---

## Contact Management

### Get-PSEntraIDContact
**Microsoft Graph API**: `GET /contacts` or `GET /contacts/{id}`
- **Delegated**: `Contacts.Read` or `Directory.Read.All`
- **Application**: `Contacts.Read` or `Directory.Read.All`
- **Admin Consent Required**: No (for Contacts.Read), Yes (for Directory.Read.All)

---

## License Management

### Get-PSEntraIDSubscribedLicense
**Microsoft Graph API**: `GET /subscribedSkus`
- **Delegated**: `Organization.Read.All` or `Directory.Read.All`
- **Application**: `Organization.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDLicenseIdentifier
**Microsoft Graph API**: `GET /subscribedSkus`
- **Delegated**: `Organization.Read.All` or `Directory.Read.All`
- **Application**: `Organization.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDUsageLocation
**Microsoft Graph API**: Internal cmdlet (no direct API call)
- **Delegated**: None
- **Application**: None
- **Notes**: This is a utility cmdlet that doesn't make direct API calls.

### Get-PSEntraIDUserLicense
**Microsoft Graph API**: `GET /users/{id}/licenseDetails`
- **Delegated**: `User.Read.All` or `Directory.Read.All`
- **Application**: `User.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Get-PSEntraIDUserLicenseDetail
**Microsoft Graph API**: `GET /users/{id}/licenseDetails`
- **Delegated**: `User.Read.All` or `Directory.Read.All`
- **Application**: `User.Read.All` or `Directory.Read.All`
- **Admin Consent Required**: Yes

### Enable-PSEntraIDUserLicense
**Microsoft Graph API**: `POST /users/{id}/assignLicense`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Disable-PSEntraIDUserLicense
**Microsoft Graph API**: `POST /users/{id}/assignLicense`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Enable-PSEntraIDUserLicenseServicePlan
**Microsoft Graph API**: `POST /users/{id}/assignLicense`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

### Disable-PSEntraIDUserLicenseServicePlan
**Microsoft Graph API**: `POST /users/{id}/assignLicense`
- **Delegated**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Application**: `User.ReadWrite.All` or `Directory.ReadWrite.All`
- **Admin Consent Required**: Yes

---

## Utility and Core Functions

### Invoke-PSEntraIDRequest
**Required Permissions**: Depends on the specific API endpoint being called
- **Delegated**: Varies based on the target API
- **Application**: Varies based on the target API
- **Notes**: This is a generic request cmdlet. Permissions depend on the specific Microsoft Graph endpoint being accessed.

### Invoke-PSEntraIDBatchRequest
**Required Permissions**: Depends on the specific API endpoints being called in the batch
- **Delegated**: Varies based on the target APIs in the batch
- **Application**: Varies based on the target APIs in the batch
- **Notes**: This cmdlet allows batch processing of multiple Graph API requests.

### New-PSEntraIDBatchRequest
**Required Permissions**: None (creates batch request objects)
- **Delegated**: None
- **Application**: None
- **Notes**: This cmdlet creates batch request objects and doesn't make API calls itself.

### Set-PSEntraIDCommandRetry / Get-PSEntraIDCommandRetry
**Required Permissions**: None (configuration cmdlets)
- **Delegated**: None
- **Application**: None
- **Notes**: These are configuration cmdlets that don't make API calls.

---

## Permission Consent Requirements

### Understanding Admin Consent

Most permissions in this module require **Admin Consent** because they access organizational data or perform administrative operations. This means:

1. **Global Administrator** or **Privileged Role Administrator** must grant consent
2. Users cannot consent to these permissions on their own
3. The application must be granted these permissions before users can use the cmdlets

### Minimum Permission Sets

For different use cases, here are the minimum permission sets required:

#### Read-Only Operations
- **Delegated**: `Directory.Read.All`
- **Application**: `Directory.Read.All`

#### User Management
- **Delegated**: `User.ReadWrite.All` + `Directory.Read.All`
- **Application**: `User.ReadWrite.All` + `Directory.Read.All`

#### Group Management
- **Delegated**: `Group.ReadWrite.All` + `Directory.Read.All`
- **Application**: `Group.ReadWrite.All` + `Directory.Read.All`

#### Administrative Unit Management
- **Delegated**: `AdministrativeUnit.ReadWrite.All` + `Directory.Read.All`
- **Application**: `AdministrativeUnit.ReadWrite.All` + `Directory.Read.All`

#### Full Module Functionality
- **Delegated**: `Directory.ReadWrite.All` + `User.Invite.All` + `ServiceMessage.Read.All` + `Organization.Read.All`
- **Application**: `Directory.ReadWrite.All` + `User.Invite.All` + `ServiceMessage.Read.All` + `Organization.Read.All`

### Best Practices

1. **Principle of Least Privilege**: Only grant the minimum permissions required for your use case
2. **Regular Review**: Periodically review and audit granted permissions
3. **Separate Applications**: Consider using separate app registrations for different permission levels
4. **Monitor Usage**: Use Azure AD audit logs to monitor how permissions are being used

---

## Additional Resources

- [Microsoft Graph permissions reference](https://docs.microsoft.com/en-us/graph/permissions-reference)
- [Best practices for working with Microsoft Graph](https://docs.microsoft.com/en-us/graph/best-practices-concept)
- [Application consent experience](https://docs.microsoft.com/en-us/azure/active-directory/develop/application-consent-experience)

> [Back to Overview](overview.md)