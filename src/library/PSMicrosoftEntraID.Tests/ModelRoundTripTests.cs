using System.Text.Json;
using PSMicrosoftEntraID.Contacts;
using PSMicrosoftEntraID.DefenderEndpoint;
using PSMicrosoftEntraID.Delta;
using PSMicrosoftEntraID.Devices;
using PSMicrosoftEntraID.DirectoryManagement;
using PSMicrosoftEntraID.Groups;
using PSMicrosoftEntraID.License;
using PSMicrosoftEntraID.Organization;
using PSMicrosoftEntraID.Serialization;
using PSMicrosoftEntraID.ServiceAnnouncement;
using PSMicrosoftEntraID.Users;
using PSMicrosoftEntraID.Users.Invitations;
using Xunit;

namespace PSMicrosoftEntraID.Tests;

/// <summary>
/// One round trip per model: a realistic Graph (or Defender for Endpoint) response for the fictitious contoso
/// tenant, deserialized with GraphJson exactly as ConvertFrom-Rest* does it, and every mapped value asserted -
/// dates as DateTime (UTC), booleans and numbers as their types, nulls as null, nesting deeper than four levels
/// intact. Then the typed object is serialized with System.Text.Json and read back, and the values must survive
/// that too (the JSON the module writes for a cache or an export reads back into the same object).
/// </summary>
public class ModelRoundTripTests
{
    private static readonly JsonSerializerOptions WriteOptions = new JsonSerializerOptions();

    private static T[] Page<T>(string json)
    {
        return Assert.IsType<T[]>(GraphJson.DeserializeCollection(json, typeof(T)));
    }

    private static T Again<T>(T value)
    {
        return (T)GraphJson.Deserialize(JsonSerializer.Serialize(value, WriteOptions), typeof(T));
    }

    private static DateTime Utc(int year, int month, int day, int hour = 0, int minute = 0, int second = 0)
    {
        return new DateTime(year, month, day, hour, minute, second, DateTimeKind.Utc);
    }

    [Fact]
    public void User()
    {
        const string page = """
            {
              "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users(id,createdDateTime,accountEnabled)",
              "value": [
                {
                  "id": "6e7b768e-07e2-4810-8459-485f84f8f204",
                  "createdDateTime": "2024-01-15T08:30:00Z",
                  "userPrincipalName": "AdeleV@contoso.com",
                  "accountEnabled": true,
                  "displayName": "Adele Vance",
                  "usageLocation": "US",
                  "mobilePhone": null,
                  "otherMails": ["adele.vance@fabrikam.com"],
                  "assignedLicenses": [
                    { "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df", "disabledPlans": ["a23b959c-7ce8-4e57-9140-b90eb88a9e97"] },
                    { "skuId": "f30db892-07e9-47e9-837c-80727f46fd3d", "disabledPlans": [] }
                  ],
                  "identities": [{ "signInType": "userPrincipalName", "issuer": "contoso.onmicrosoft.com", "issuerAssignedId": "AdeleV@contoso.com" }]
                },
                { "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd", "createdDateTime": null, "accountEnabled": null }
              ]
            }
            """;

        var users = Page<User>(page);
        foreach (var user in new[] { users[0], Again(users[0]) })
        {
            Assert.Equal("6e7b768e-07e2-4810-8459-485f84f8f204", user.Id);
            Assert.Equal(Utc(2024, 1, 15, 8, 30), user.CreatedDateTime);
            Assert.Equal(DateTimeKind.Utc, user.CreatedDateTime.Value.Kind);
            Assert.True(user.AccountEnabled);
            Assert.Null(user.MobilePhone);
            Assert.Equal("adele.vance@fabrikam.com", Assert.Single(user.OtherMails));
            Assert.Equal(2, user.AssignedLicenses.Length);
            Assert.Equal("a23b959c-7ce8-4e57-9140-b90eb88a9e97", Assert.Single(user.AssignedLicenses[0].DisabledPlans));
            Assert.Empty(user.AssignedLicenses[1].DisabledPlans);
            Assert.Equal("contoso.onmicrosoft.com", Assert.Single(user.Identities).Issuer);
        }

        Assert.Null(users[1].CreatedDateTime);
        Assert.Null(users[1].AccountEnabled);
    }

    [Fact]
    public void UserGuest()
    {
        const string page = """
            {"value":[{
              "id": "0b5a3c8e-1f0d-4c34-9b1d-2a8c6f0e7d11",
              "userPrincipalName": "megan_fabrikam.com#EXT#@contoso.onmicrosoft.com",
              "userType": "Guest",
              "accountEnabled": false,
              "createdDateTime": "2025-06-30T22:15:09Z",
              "externalUserState": "Accepted",
              "externalUserStateChangeDateTime": "2025-07-01T06:00:00Z",
              "identities": [
                { "signInType": "userPrincipalName", "issuer": "contoso.onmicrosoft.com", "issuerAssignedId": "megan_fabrikam.com#EXT#@contoso.onmicrosoft.com" },
                { "signInType": "federated", "issuer": "fabrikam.com", "issuerAssignedId": null }
              ]
            }]}
            """;

        var guest = Assert.Single(Page<UserGuest>(page));
        foreach (var value in new[] { guest, Again(guest) })
        {
            Assert.False(value.AccountEnabled);
            Assert.Equal(Utc(2025, 6, 30, 22, 15, 9), value.CreatedDateTime);
            Assert.Equal(Utc(2025, 7, 1, 6), value.ExternalUserStateChangeDateTime);
            Assert.Equal("Accepted", value.InvitationStatus);
            Assert.Equal("fabrikam.com", value.HomeIssuer);
            Assert.Equal(new[] { "userPrincipalName", "federated" }, value.SignInTypes);
            Assert.Null(value.Identities[1].IssuerAssignedId);
        }
    }

    [Fact]
    public void UserDeltaMapsTheRemovedAnnotation()
    {
        const string page = """
            {
              "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",
              "@odata.deltaLink": "https://graph.microsoft.com/v1.0/users/delta?$deltatoken=abc%3D",
              "value": [
                { "id": "u-changed", "displayName": "Adele Vance", "accountEnabled": true, "createdDateTime": "2024-01-15T08:30:00Z" },
                { "id": "u-soft", "@removed": { "reason": "changed" } },
                { "id": "u-hard", "@removed": { "reason": "deleted" } }
              ]
            }
            """;

        var users = Page<UserDelta>(page);

        Assert.Equal(DeltaChangeType.Changed, users[0].ChangeType);
        Assert.False(users[0].Removed);
        Assert.Equal(Utc(2024, 1, 15, 8, 30), users[0].CreatedDateTime);
        Assert.Equal(DeltaChangeType.Deleted, users[1].ChangeType);
        Assert.True(users[1].Removed);
        Assert.Null(users[1].AccountEnabled);
        Assert.Equal(DeltaChangeType.Purged, users[2].ChangeType);
        Assert.Equal("[Purged] u-hard", users[2].ToString());

        // The annotation is not written back; the ChangeType it produced is.
        var json = JsonSerializer.Serialize(users[2], WriteOptions);
        Assert.DoesNotContain("@removed", json);
        Assert.Equal(DeltaChangeType.Purged, Again(users[2]).ChangeType);
    }

    [Fact]
    public void Group()
    {
        const string page = """
            {"value":[{
              "id": "02bd9fd6-8f93-4758-87c3-1fb73740a315",
              "createdDateTime": "2023-05-01T10:00:00Z",
              "deletedDateTime": null,
              "expirationDateTime": "2027-05-01T10:00:00Z",
              "renewedDateTime": "2026-05-01T10:00:00.1234567Z",
              "displayName": "HR Taskforce",
              "mailEnabled": true,
              "securityEnabled": false,
              "isAssignableToRole": null,
              "groupTypes": ["Unified"],
              "assignedLabels": [{ "labelId": "a1b2c3d4-0000-0000-0000-000000000001", "displayName": "Confidential" }],
              "assignedLicenses": [{ "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df", "disabledPlans": ["a23b959c-7ce8-4e57-9140-b90eb88a9e97", "882e1d05-acd1-4ccb-8708-6ee03664b117"] }]
            }]}
            """;

        var group = Assert.Single(Page<Group>(page));
        foreach (var value in new[] { group, Again(group) })
        {
            Assert.Equal(Utc(2023, 5, 1, 10), value.CreatedDateTime);
            Assert.Null(value.DeletedDateTime);
            Assert.Equal(Utc(2027, 5, 1, 10), value.ExpirationDateTime);
            Assert.Equal(Utc(2026, 5, 1, 10).AddTicks(1234567), value.RenewedDateTime);
            Assert.True(value.MailEnabled);
            Assert.False(value.SecurityEnabled);
            Assert.Null(value.IsAssignableToRole);
            Assert.Equal("Confidential", Assert.Single(value.AssignedLabels).DisplayName);
            Assert.Equal("882e1d05-acd1-4ccb-8708-6ee03664b117", Assert.Single(value.AssignedLicenses).DisabledPlans[1]);
        }
    }

    [Fact]
    public void GroupDeltaWithMembersDelta()
    {
        const string page = """
            {"value":[
              {
                "id": "02bd9fd6-8f93-4758-87c3-1fb73740a315",
                "displayName": "Licensing - E5",
                "createdDateTime": "2023-05-01T10:00:00Z",
                "members@delta": [
                  { "@odata.type": "#microsoft.graph.user", "id": "6e7b768e-07e2-4810-8459-485f84f8f204" },
                  { "@odata.type": "#microsoft.graph.user", "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd", "@removed": "deleted" },
                  { "@odata.type": "#microsoft.graph.group", "id": "b320ee12-b1cd-4cca-b648-a437be61c5cd", "@removed": { "reason": "changed" } }
                ]
              },
              { "id": "d7797254-3084-44d0-99c9-a3b5ab149538", "@removed": { "reason": "changed" } }
            ]}
            """;

        var groups = Page<GroupDelta>(page);
        var members = groups[0].MembersDelta;

        Assert.Equal(DeltaChangeType.Changed, groups[0].ChangeType);
        Assert.Equal(Utc(2023, 5, 1, 10), groups[0].CreatedDateTime);
        Assert.Equal(3, members.Length);
        Assert.Equal("+ 6e7b768e-07e2-4810-8459-485f84f8f204", members[0].ToString());
        Assert.Equal("#microsoft.graph.user", members[0].ObjectType);
        Assert.False(members[0].Removed);
        Assert.True(members[1].Removed);
        Assert.Equal("- 87d349ed-44d7-43e1-9a83-5f2406dee5bd", members[1].ToString());
        Assert.Equal("#microsoft.graph.group", members[2].ObjectType);
        Assert.True(members[2].Removed);
        Assert.Null(groups[1].MembersDelta);
        Assert.Equal(DeltaChangeType.Deleted, groups[1].ChangeType);

        var again = Again(groups[0]);
        Assert.Equal(new[] { false, true, true }, again.MembersDelta.Select(member => member.Removed));
        Assert.Equal("#microsoft.graph.group", again.MembersDelta[2].ObjectType);
    }

    [Fact]
    public void GroupAdditionalProperty()
    {
        const string json = """
            {
              "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#groups(id,mail,allowExternalSenders,autoSubscribeNewMembers,hideFromAddressLists,hideFromOutlookClients)/$entity",
              "id": "02bd9fd6-8f93-4758-87c3-1fb73740a315",
              "mail": "HRTaskforce@contoso.com",
              "mailNickname": "HRTaskforce",
              "displayName": "HR Taskforce",
              "hideFromAddressLists": false,
              "hideFromOutlookClients": true,
              "allowExternalSenders": false,
              "autoSubscribeNewMembers": true
            }
            """;

        var group = Assert.Single(Page<GroupAdditionalProperty>(json));
        foreach (var value in new[] { group, Again(group) })
        {
            Assert.Equal("HRTaskforce@contoso.com", value.Mail);
            Assert.False(value.HideFromAddressLists);
            Assert.True(value.HideFromOutlookClients);
            Assert.False(value.AllowExternalSenders);
            Assert.True(value.AutoSubscribeNewMembers);
        }
    }

    [Fact]
    public void AdministrativeUnitSixLevelsDeep()
    {
        const string page = """
            {"value":[{
              "id": "4d7ea995-bc0f-45c0-8c4b-1d5f5a8a0a11",
              "createdDateTime": "2022-03-04T05:06:07Z",
              "deletedDateTime": null,
              "displayName": "Seattle District Technical Schools",
              "visibility": "HiddenMembership",
              "isMemberManagementRestricted": true,
              "members": [{ "id": "6e7b768e-07e2-4810-8459-485f84f8f204", "deletedDateTime": "2026-10-01T00:00:00Z" }],
              "scopedRoleMembers": [{
                "id": "srm-1",
                "roleId": "fe930be7-5e62-47db-91af-98c3a49a38b1",
                "administrativeUnitId": "4d7ea995-bc0f-45c0-8c4b-1d5f5a8a0a11",
                "roleMemberInfo": { "id": "6e7b768e-07e2-4810-8459-485f84f8f204", "displayName": "Adele Vance", "tenantId": null }
              }]
            }]}
            """;

        var unit = Assert.Single(Page<AdministrativeUnit>(page));
        foreach (var value in new[] { unit, Again(unit) })
        {
            Assert.Equal(Utc(2022, 3, 4, 5, 6, 7), value.CreatedDateTime);
            Assert.Null(value.DeletedDateTime);
            Assert.True(value.IsMemberManagementRestricted);
            Assert.Equal(Utc(2026, 10, 1), Assert.Single(value.Members).DeletedDateTime);
            // page > value > unit > scopedRoleMembers > member > roleMemberInfo > displayName
            Assert.Equal("Adele Vance", Assert.Single(value.ScopedRoleMembers).RoleMemberInfo.DisplayName);
            Assert.Null(value.ScopedRoleMembers[0].RoleMemberInfo.TenantId);
        }
    }

    [Fact]
    public void AdministrativeUnitDelta()
    {
        const string page = """
            {"value":[
              { "id": "au-1", "displayName": "Seattle", "members@delta": [{ "@odata.type": "#microsoft.graph.device", "id": "dev-1", "@removed": "deleted" }] },
              { "id": "au-2", "@removed": { "reason": "deleted" } }
            ]}
            """;

        var units = Page<AdministrativeUnitDelta>(page);

        Assert.Equal(DeltaChangeType.Changed, units[0].ChangeType);
        var member = Assert.Single(units[0].MembersDelta);
        Assert.Equal("#microsoft.graph.device", member.ObjectType);
        Assert.True(member.Removed);
        Assert.Equal(DeltaChangeType.Purged, units[1].ChangeType);
    }

    [Fact]
    public void ContactAndContactDelta()
    {
        const string page = """
            {"value":[
              { "id": "c-1", "displayName": "Patti Fernandez (Fabrikam)", "mail": "patti@fabrikam.com", "businessPhones": [], "mobilePhone": null, "proxyAddresses": ["SMTP:patti@fabrikam.com"] },
              { "id": "c-2", "@removed": { "reason": "changed" } }
            ]}
            """;

        var contact = Page<Contact>(page)[0];
        Assert.Equal("patti@fabrikam.com", Again(contact).Mail);
        Assert.Empty(contact.BusinessPhones);
        Assert.Null(contact.MobilePhone);

        var deltas = Page<ContactDelta>(page);
        Assert.Equal(DeltaChangeType.Changed, deltas[0].ChangeType);
        Assert.Equal(DeltaChangeType.Deleted, deltas[1].ChangeType);
    }

    [Fact]
    public void DeviceAndDeviceDelta()
    {
        const string page = """
            {"value":[
              {
                "id": "c1b4a7f0-0000-4000-8000-000000000001",
                "deviceId": "4c299165-6e8f-4b45-a5ba-c5d250a707ff",
                "displayName": "CONTOSO-LT-042",
                "accountEnabled": true,
                "isCompliant": null,
                "registrationDateTime": "2025-02-03T09:15:00Z",
                "approximateLastSignInDateTime": null,
                "extensionAttributes": { "extensionAttribute1": "Finance", "extensionAttribute15": null }
              },
              { "id": "c1b4a7f0-0000-4000-8000-000000000002", "@removed": { "reason": "deleted" } }
            ]}
            """;

        var device = Page<Device>(page)[0];
        foreach (var value in new[] { device, Again(device) })
        {
            Assert.Equal(Utc(2025, 2, 3, 9, 15), value.RegistrationDateTime);
            Assert.Null(value.ApproximateLastSignInDateTime);
            Assert.Null(value.IsCompliant);
            Assert.Equal("Finance", value.ExtensionAttributes.ExtensionAttribute1);
            Assert.Equal("CONTOSO-LT-042", value.ToString());
        }

        var deltas = Page<DeviceDelta>(page);
        Assert.Equal(DeltaChangeType.Changed, deltas[0].ChangeType);
        Assert.Equal(DeltaChangeType.Purged, deltas[1].ChangeType);
    }

    [Fact]
    public void OrganizationDetail()
    {
        const string page = """
            {"value":[{
              "id": "48a80680-7326-48cd-9935-b556b81d3a4e",
              "displayName": "Contoso",
              "tenantType": "AAD",
              "isMultipleDataLocationsForServicesEnabled": null,
              "onPremisesLastSyncDateTime": "2026-11-12T06:40:12Z",
              "onPremisesSyncEnabled": true,
              "onPremisesSyncStatus": [{ "attributeSetName": "Default", "state": "enabled", "version": 1 }],
              "createdDateTime": "2015-06-01T12:00:00Z",
              "deletedDateTime": null,
              "directorySizeQuota": { "used": 6157, "total": 300000 },
              "countryLetterCode": "US",
              "businessPhones": ["4258280010"],
              "technicalNotificationMails": ["it@contoso.com"],
              "privacyProfile": { "contactEmail": "privacy@contoso.com", "statementUrl": "https://contoso.com/privacy" },
              "assignedPlans": [
                { "assignedDateTime": "2024-02-01T00:00:00Z", "capabilityStatus": "Enabled", "service": "exchange", "servicePlanId": "efb87545-963c-4e0d-99df-69c6916d9eb0" }
              ],
              "provisionedPlans": [{ "capabilityStatus": "Enabled", "provisioningStatus": "Success", "service": "exchange" }],
              "verifiedDomains": [{ "capabilities": "Email, OfficeCommunicationsOnline", "isDefault": true, "isInitial": false, "name": "contoso.com", "type": "Managed" }]
            }]}
            """;

        var organization = Assert.Single(Page<OrganizationDetail>(page));
        foreach (var value in new[] { organization, Again(organization) })
        {
            Assert.Equal("48a80680-7326-48cd-9935-b556b81d3a4e", value.TenantId);
            Assert.Null(value.IsMultipleDataLocationsForServicesEnabled);
            Assert.Equal(Utc(2026, 11, 12, 6, 40, 12), value.OnPremisesLastSyncDateTime);
            Assert.Equal("enabled", value.OnPremisesSyncStatus.State);
            Assert.Equal("1", value.OnPremisesSyncStatus.Version);
            Assert.Null(value.OnPremisesNextSyncDateTime);
            Assert.Equal(Utc(2015, 6, 1, 12), value.CreatedDateTime);
            Assert.Null(value.DeletedDateTime);
            Assert.Equal(6157L, value.DirectorySizeQuota.Used);
            Assert.Equal(300000L, value.DirectorySizeQuota.Total);
            Assert.Equal("https://contoso.com/privacy", value.PrivacyProfile.StatementUrl);
            Assert.Equal(Utc(2024, 2, 1), Assert.Single(value.AssignedPlans).AssignedDateTime);
            Assert.True(Assert.Single(value.VerifiedDomains).IsDefault);
        }
    }

    [Theory]
    [InlineData("""{"id":"t1","onPremisesSyncStatus":{"attributeSetName":"Default","state":"enabled","version":"2"}}""", "2")]
    [InlineData("""{"id":"t1","onPremisesSyncStatus":[{"attributeSetName":"Default","state":"enabled","version":3}]}""", "3")]
    [InlineData("""{"id":"t1","onPremisesSyncStatus":[]}""", null)]
    [InlineData("""{"id":"t1","onPremisesSyncStatus":null}""", null)]
    public void OrganizationSyncStatusAsObjectOrCollection(string json, string version)
    {
        var organization = (OrganizationDetail)GraphJson.Deserialize(json, typeof(OrganizationDetail));
        Assert.Equal(version, organization.OnPremisesSyncStatus?.Version);
    }

    [Fact]
    public void SubscribedSku()
    {
        const string page = """
            {"value":[{
              "accountName": "Contoso",
              "accountId": "48a80680-7326-48cd-9935-b556b81d3a4e",
              "capabilityStatus": "Enabled",
              "id": "48a80680-7326-48cd-9935-b556b81d3a4e_c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuPartNumber": "ENTERPRISEPREMIUM",
              "appliesTo": "User",
              "consumedUnits": 14,
              "subscriptionIds": ["91a32a28-0000-0000-0000-000000000001"],
              "prepaidUnits": { "enabled": 25, "suspended": 0, "warning": null, "lockedOut": 0 },
              "servicePlans": [{ "servicePlanId": "8c098270-9dd4-4350-9b30-ba4703f3b36b", "servicePlanName": "ADALLOM_S_O365", "provisioningStatus": "Success", "appliesTo": "User" }]
            }]}
            """;

        var sku = Assert.Single(Page<SubscriptionSkuLicense>(page));
        foreach (var value in new[] { sku, Again(sku) })
        {
            Assert.Equal("Contoso", value.AccountName);
            Assert.Equal(14, value.ConsumedUnits);
            Assert.Equal(25, value.PrepaidUnits.Enabled);
            Assert.Equal(0, value.PrepaidUnits.Suspended);
            Assert.Null(value.PrepaidUnits.Warning);
            Assert.Equal("91a32a28-0000-0000-0000-000000000001", Assert.Single(value.SubscriptionIds));
            Assert.Equal("ADALLOM_S_O365", Assert.Single(value.ServicePlans).ServicePlanName);
        }

        Assert.Null(Assert.Single(Page<SubscriptionSkuLicense>("""{"value":[{"skuId":"x","consumedUnits":null}]}""")).ConsumedUnits);
    }

    [Fact]
    public void UserAndGroupLicenseDetails()
    {
        const string page = """
            {"value":[{
              "id": "LicenseDetailId",
              "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuPartNumber": "ENTERPRISEPREMIUM",
              "servicePlans": [
                { "servicePlanId": "a23b959c-7ce8-4e57-9140-b90eb88a9e97", "servicePlanName": "SWAY", "provisioningStatus": "Disabled", "appliesTo": "User" },
                { "servicePlanId": "882e1d05-acd1-4ccb-8708-6ee03664b117", "servicePlanName": "INTUNE_O365", "provisioningStatus": "PendingActivation", "appliesTo": "User" }
              ]
            }]}
            """;

        var user = Assert.Single(Page<Users.LicenseManagement.SubscriptionSku>(page));
        Assert.Equal("ENTERPRISEPREMIUM", Again(user).SkuPartNumber);
        Assert.Equal(new[] { "Disabled", "PendingActivation" }, user.ServicePlans.Select(plan => plan.ProvisioningStatus));

        var group = Assert.Single(Page<Groups.LicenseManagement.SubscriptionSku>(page));
        Assert.Equal("INTUNE_O365", Again(group).ServicePlans[1].ServicePlanName);
    }

    [Fact]
    public void InvitationWithTheInvitedUserFiveLevelsDeep()
    {
        const string json = """
            {
              "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#invitations/$entity",
              "id": "7b92124c-9fa9-406f-8b8e-225df8376ba9",
              "inviteRedeemUrl": "https://login.microsoftonline.com/redeem?rd=https%3a%2f%2finvitations.microsoft.com",
              "invitedUserDisplayName": "Megan Bowen (Fabrikam)",
              "invitedUserType": "Guest",
              "invitedUserEmailAddress": "megan@fabrikam.com",
              "sendInvitationMessage": false,
              "resetRedemption": null,
              "inviteRedirectUrl": "https://myapps.microsoft.com",
              "status": "PendingAcceptance",
              "invitedUserMessageInfo": { "messageLanguage": null, "ccRecipients": [{ "emailAddress": { "name": null, "address": null } }], "customizedMessageBody": null },
              "invitedUser": {
                "id": "0b5a3c8e-1f0d-4c34-9b1d-2a8c6f0e7d11",
                "createdDateTime": "2026-11-12T08:00:00Z",
                "accountEnabled": true,
                "assignedLicenses": [{ "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df", "disabledPlans": ["a23b959c-7ce8-4e57-9140-b90eb88a9e97"] }]
              }
            }
            """;

        var invitation = Assert.Single(Page<Invitation>(json));
        foreach (var value in new[] { invitation, Again(invitation) })
        {
            Assert.Equal("PendingAcceptance", value.Status);
            Assert.False(value.SendInvitationMessage);
            Assert.Null(value.ResetRedemption);
            Assert.Null(value.ExpirationDateTime);
            Assert.Null(value.InvitedUserMessageInfo.MessageLanguage);
            Assert.Equal(Utc(2026, 11, 12, 8), value.InvitedUser.CreatedDateTime);
            Assert.True(value.InvitedUser.AccountEnabled);
            // invitation > invitedUser > assignedLicenses > license > disabledPlans
            Assert.Equal("a23b959c-7ce8-4e57-9140-b90eb88a9e97", Assert.Single(Assert.Single(value.InvitedUser.AssignedLicenses).DisabledPlans));
        }
    }

    [Fact]
    public void MessageCenterMessage()
    {
        const string page = """
            {"value":[{
              "id": "MC172851",
              "title": "(Updated) Microsoft Teams: New meeting experience",
              "category": "planForChange",
              "severity": "normal",
              "services": ["Microsoft Teams"],
              "tags": ["Updated message", "User impact"],
              "isMajorChange": true,
              "startDateTime": "2026-10-28T19:54:25Z",
              "endDateTime": null,
              "lastModifiedDateTime": "2026-11-02T18:01:46.4560000Z",
              "actionRequiredByDateTime": null,
              "hasAttachments": false,
              "attachmentsArchive": null,
              "body": { "contentType": "html", "content": "<p>Updated rollout.</p>" },
              "viewPoint": { "isRead": null, "isArchived": false, "isFavorited": true },
              "details": [{ "name": "ExternalLink", "value": "https://learn.microsoft.com/microsoftteams" }]
            }]}
            """;

        var message = Assert.Single(Page<Message>(page));
        foreach (var value in new[] { message, Again(message) })
        {
            Assert.True(value.IsMajorChange);
            Assert.False(value.HasAttachments);
            Assert.Equal(Utc(2026, 10, 28, 19, 54, 25), value.StartDateTime);
            Assert.Null(value.EndDateTime);
            Assert.Equal(Utc(2026, 11, 2, 18, 1, 46).AddMilliseconds(456), value.LastModifiedDateTime);
            Assert.Null(value.ActionRequiredByDateTime);
            Assert.Null(value.ViewPoint.IsRead);
            Assert.False(value.ViewPoint.IsArchived);
            Assert.True(value.ViewPoint.IsFavorited);
            Assert.Equal("html", value.Body.ContentType);
            Assert.Equal("ExternalLink", Assert.Single(value.Details).Name);
        }
    }

    [Fact]
    public void DefenderEndpointMachine()
    {
        const string page = """
            {
              "@odata.context": "https://api.securitycenter.microsoft.com/api/$metadata#Machines",
              "value": [{
                "id": "1e5bc9d7e413ddd7902c2932e418702b84d0cc07",
                "computerDnsName": "contoso-lt-042.contoso.com",
                "firstSeen": "2018-08-02T14:55:03.7791856Z",
                "lastSeen": "2026-11-11T21:30:00Z",
                "osPlatform": "Windows11",
                "osBuild": 26100,
                "rbacGroupId": 140,
                "isAadJoined": true,
                "aadDeviceId": "4c299165-6e8f-4b45-a5ba-c5d250a707ff",
                "machineTags": ["Finance", "VIP"],
                "isPotentialDuplication": null,
                "ipAddresses": [{ "ipAddress": "10.0.0.4", "macAddress": "000D3A1B2C3D", "type": "Ethernet", "operationalStatus": "Up" }]
              }]
            }
            """;

        var machine = Assert.Single(Page<Machine>(page));
        foreach (var value in new[] { machine, Again(machine) })
        {
            Assert.Equal(Utc(2018, 8, 2, 14, 55, 3).AddTicks(7791856), value.FirstSeen);
            Assert.Equal(Utc(2026, 11, 11, 21, 30), value.LastSeen);
            Assert.Equal(26100L, value.OsBuild);
            Assert.Equal(140L, value.RbacGroupId);
            Assert.True(value.IsAadJoined);
            Assert.Null(value.IsPotentialDuplication);
            Assert.Equal(new[] { "Finance", "VIP" }, value.MachineTags);
        }
    }

    [Fact]
    public void LicenseIdentifierCatalogEntry()
    {
        const string catalog = """
            [{
              "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuPartNumber": "ENTERPRISEPREMIUM",
              "skuFriendlyName": "Office 365 E5",
              "servicePlans": [{ "servicePlanId": "a23b959c-7ce8-4e57-9140-b90eb88a9e97", "servicePlanName": "SWAY", "servicePlanFriendlyName": "Sway" }]
            }]
            """;

        var entry = Assert.Single(Page<LicenseIdentifier>(catalog));
        Assert.Equal("Office 365 E5", entry.SkuFriendlyName);
        Assert.Equal("Sway", Assert.Single(Again(entry).ServicePlans).ServicePlanFriendlyName);
    }
}
