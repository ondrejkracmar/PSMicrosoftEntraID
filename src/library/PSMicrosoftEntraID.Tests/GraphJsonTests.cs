using System.Text.Json;
using System.Text.Json.Serialization;
using PSMicrosoftEntraID.Devices;
using PSMicrosoftEntraID.DirectoryManagement;
using PSMicrosoftEntraID.Groups;
using PSMicrosoftEntraID.License;
using PSMicrosoftEntraID.Organization;
using PSMicrosoftEntraID.Serialization;
using PSMicrosoftEntraID.Users;
using Xunit;

namespace PSMicrosoftEntraID.Tests;

/// <summary>
/// GraphJson against Graph-shaped JSON (fake contoso data) and the module's typed models. A property maps when its
/// own name equals the JSON name ignoring case, or by [JsonPropertyName] where the wire name differs beyond case.
/// The former model gaps (names that differ beyond case, strings Graph fills with a boolean or an object,
/// non-nullable values Graph sends as null, dates held as text) are asserted fixed here; the per-model round
/// trips are in ModelRoundTripTests.
/// </summary>
public class GraphJsonTests
{
    private const string UserPage = """
        {
          "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",
          "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=X",
          "value": [
            {
              "@odata.etag": "W/\"1\"",
              "id": "6e7b768e-07e2-4810-8459-485f84f8f204",
              "userPrincipalName": "AdeleV@contoso.com",
              "createdDateTime": "2024-01-15T08:30:00Z",
              "mail": "AdeleV@contoso.com",
              "mailNickname": "AdeleV",
              "proxyAddresses": ["SMTP:AdeleV@contoso.com", "smtp:adele@contoso.onmicrosoft.com"],
              "userType": "Member",
              "accountEnabled": true,
              "givenName": "Adele",
              "surname": "Vance",
              "displayName": "Adele Vance",
              "employeeId": "1001",
              "jobTitle": "Retail Manager",
              "department": "Retail",
              "officeLocation": "18/2111",
              "companyName": "Contoso",
              "city": "Bellevue",
              "postalCode": "98004",
              "country": "United States",
              "usageLocation": "US",
              "mobilePhone": null,
              "businessPhones": ["+1 425 555 0109"],
              "faxNumber": null,
              "otherMails": [],
              "assignedLicenses": [
                { "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df", "disabledPlans": ["a23b959c-7ce8-4e57-9140-b90eb88a9e97", "882e1d05-acd1-4ccb-8708-6ee03664b117"] }
              ],
              "identities": [
                { "signInType": "userPrincipalName", "issuer": "contoso.com", "issuerAssignedId": "AdeleV@contoso.com" }
              ]
            },
            { "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd", "USERPRINCIPALNAME": "AlexW@contoso.com", "accountEnabled": false }
          ]
        }
        """;

    [Fact]
    public void DeserializesAUserPageWithNestedCollections()
    {
        var users = Assert.IsType<User[]>(GraphJson.DeserializeCollection(UserPage, typeof(User)));

        Assert.Equal(2, users.Length);
        var adele = users[0];
        Assert.Equal("6e7b768e-07e2-4810-8459-485f84f8f204", adele.Id);
        Assert.Equal("AdeleV@contoso.com", adele.UserPrincipalName);
        Assert.Equal(new DateTime(2024, 1, 15, 8, 30, 0, DateTimeKind.Utc), adele.CreatedDateTime);
        Assert.Equal(DateTimeKind.Utc, adele.CreatedDateTime.Value.Kind);
        Assert.True(adele.AccountEnabled);
        Assert.Equal(new[] { "SMTP:AdeleV@contoso.com", "smtp:adele@contoso.onmicrosoft.com" }, adele.ProxyAddresses);
        Assert.Equal("+1 425 555 0109", Assert.Single(adele.BusinessPhones));
        Assert.Empty(adele.OtherMails);
        Assert.Null(adele.MobilePhone);
        // page > value > user > assignedLicenses > license > disabledPlans: deeper than the -Depth 4 the
        // ConvertTo-Json round trip of ConvertFrom-Rest* used to have, which handed the converter a truncated string.
        var license = Assert.Single(adele.AssignedLicenses);
        Assert.Equal("c7df2760-2c81-4ef7-b578-5b5392b571df", license.SkuId);
        Assert.Equal(2, license.DisabledPlans.Length);
        Assert.Equal("contoso.com", Assert.Single(adele.Identities).Issuer);
        // Names match ignoring case.
        Assert.Equal("AlexW@contoso.com", users[1].UserPrincipalName);
        Assert.False(users[1].AccountEnabled);
    }

    [Fact]
    public void DeserializesAGroupPageWithLabelsAndLicensesDeeperThanFourLevels()
    {
        const string page = """
            {"value":[{
              "id": "02bd9fd6-8f93-4758-87c3-1fb73740a315",
              "createdDateTime": "2023-05-01T10:00:00Z",
              "displayName": "HR Taskforce",
              "mail": "HRTaskforce@contoso.com",
              "mailEnabled": true,
              "securityEnabled": false,
              "isAssignableToRole": null,
              "groupTypes": ["Unified", "DynamicMembership"],
              "membershipRule": "user.department -eq \"HR\"",
              "membershipRuleProcessingState": "On",
              "expirationDateTime": null,
              "resourceProvisioningOptions": ["Team"],
              "assignedLabels": [{ "labelId": "a1b2c3d4-0000-0000-0000-000000000001", "displayName": "Confidential" }],
              "assignedLicenses": [{ "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df", "disabledPlans": ["a23b959c-7ce8-4e57-9140-b90eb88a9e97"] }]
            }]}
            """;

        var group = Assert.Single(Assert.IsType<Group[]>(GraphJson.DeserializeCollection(page, typeof(Group))));

        Assert.Equal("HR Taskforce", group.DisplayName);
        Assert.True(group.MailEnabled);
        Assert.False(group.SecurityEnabled);
        Assert.Null(group.IsAssignableToRole);
        Assert.Null(group.ExpirationDateTime);
        Assert.Equal(new DateTime(2023, 5, 1, 10, 0, 0, DateTimeKind.Utc), group.CreatedDateTime);
        Assert.Equal(new[] { "Unified", "DynamicMembership" }, group.GroupTypes);
        Assert.Equal("Confidential", Assert.Single(group.AssignedLabels).DisplayName);
        Assert.Equal("a23b959c-7ce8-4e57-9140-b90eb88a9e97", Assert.Single(Assert.Single(group.AssignedLicenses).DisabledPlans));
    }

    [Fact]
    public void DeserializesSubscribedSkusWithUnitsAndServicePlans()
    {
        const string page = """
            {"value":[{
              "id": "48a80680-7326-48cd-9935-b556b81d3a4e_c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuId": "c7df2760-2c81-4ef7-b578-5b5392b571df",
              "skuPartNumber": "ENTERPRISEPREMIUM",
              "appliesTo": "User",
              "capabilityStatus": "Enabled",
              "consumedUnits": 14,
              "prepaidUnits": { "enabled": 25, "suspended": 0, "warning": "1", "lockedOut": 0 },
              "servicePlans": [
                { "servicePlanId": "8c098270-9dd4-4350-9b30-ba4703f3b36b", "servicePlanName": "ADALLOM_S_O365", "provisioningStatus": "Success", "appliesTo": "User" }
              ]
            }]}
            """;

        var sku = Assert.Single(Assert.IsType<SubscriptionSku[]>(GraphJson.DeserializeCollection(page, typeof(SubscriptionSku))));

        Assert.Equal("ENTERPRISEPREMIUM", sku.SkuPartNumber);
        Assert.Equal(14, sku.ConsumedUnits);
        Assert.Equal(25, sku.PrepaidUnits.Enabled);
        // A number sent as text is read (NumberHandling.AllowReadingFromString).
        Assert.Equal(1, sku.PrepaidUnits.Warning);
        var plan = Assert.Single(sku.ServicePlans);
        Assert.Equal("ADALLOM_S_O365", plan.ServicePlanName);
        Assert.Equal("Success", plan.ProvisioningStatus);
        // skuFriendlyName is no Graph property: the module fills it from its catalog after the read.
        Assert.Null(sku.SkuFriendlyName);
    }

    [Fact]
    public void DeserializesADeviceWithItsExtensionAttributes()
    {
        const string page = """
            {"value":[{
              "id": "c1b4a7f0-0000-4000-8000-000000000001",
              "deviceId": "4c299165-6e8f-4b45-a5ba-c5d250a707ff",
              "displayName": "CONTOSO-LT-042",
              "accountEnabled": true,
              "operatingSystem": "Windows",
              "operatingSystemVersion": "10.0.26100.1",
              "trustType": "AzureAd",
              "isManaged": true,
              "isCompliant": null,
              "registrationDateTime": "2025-02-03T09:15:00Z",
              "approximateLastSignInDateTime": "2026-11-10T07:00:00Z",
              "extensionAttributes": { "extensionAttribute1": "Finance", "extensionAttribute15": null }
            }]}
            """;

        var device = Assert.Single(Assert.IsType<Device[]>(GraphJson.DeserializeCollection(page, typeof(Device))));

        Assert.Equal("CONTOSO-LT-042", device.DisplayName);
        Assert.True(device.AccountEnabled);
        Assert.True(device.IsManaged);
        Assert.Null(device.IsCompliant);
        Assert.Equal(new DateTime(2025, 2, 3, 9, 15, 0, DateTimeKind.Utc), device.RegistrationDateTime);
        Assert.Equal(new DateTime(2026, 11, 10, 7, 0, 0, DateTimeKind.Utc), device.ApproximateLastSignInDateTime);
        Assert.Equal("Finance", device.ExtensionAttributes.ExtensionAttribute1);
        Assert.Null(device.ExtensionAttributes.ExtensionAttribute15);
    }

    [Fact]
    public void DeserializesAnAdministrativeUnitFiveLevelsDeep()
    {
        const string page = """
            {"value":[{"id":"au1","displayName":"Seattle","scopedRoleMembers":[{"id":"srm1","roleId":"r1","administrativeUnitId":"au1","roleMemberInfo":{"id":"u1","displayName":"Adele Vance"}}]}]}
            """;

        var unit = Assert.Single(Assert.IsType<AdministrativeUnit[]>(GraphJson.DeserializeCollection(page, typeof(AdministrativeUnit))));

        Assert.Equal("Adele Vance", Assert.Single(unit.ScopedRoleMembers).RoleMemberInfo.DisplayName);
    }

    // The former gaps of the models under System.Text.Json (pinned as gaps by PR 1321), now asserted fixed.

    [Fact]
    public void MapsTheWireNamesThatDifferBeyondCase()
    {
        const string page = """
            {"value":[{"id":"g1","displayName":"Sales","members@delta":[
              {"@odata.type":"#microsoft.graph.user","id":"u1"},
              {"@odata.type":"#microsoft.graph.group","id":"g9","@removed":"deleted"}]}]}
            """;

        var group = Assert.Single(Assert.IsType<GroupDelta[]>(GraphJson.DeserializeCollection(page, typeof(GroupDelta))));

        Assert.Equal("Sales", group.DisplayName);
        Assert.Equal(2, group.MembersDelta.Length);
        Assert.Equal("u1", group.MembersDelta[0].Id);
        Assert.Equal("#microsoft.graph.user", group.MembersDelta[0].ObjectType);
        Assert.False(group.MembersDelta[0].Removed);
        Assert.Equal("g9", group.MembersDelta[1].Id);
        Assert.Equal("#microsoft.graph.group", group.MembersDelta[1].ObjectType);
        Assert.True(group.MembersDelta[1].Removed);

        var organization = (OrganizationDetail)GraphJson.Deserialize("""{"id":"48a80680-7326-48cd-9935-b556b81d3a4e","displayName":"Contoso"}""", typeof(OrganizationDetail));
        Assert.Equal("Contoso", organization.DisplayName);
        Assert.Equal("48a80680-7326-48cd-9935-b556b81d3a4e", organization.TenantId);
    }

    [Fact]
    public void ReadsTheValuesThatUsedToFailTheWholePage()
    {
        var additional = (GroupAdditionalProperty)GraphJson.Deserialize("""{"id":"g1","allowExternalSenders":false,"autoSubscribeNewMembers":true,"hideFromAddressLists":null}""", typeof(GroupAdditionalProperty));
        Assert.False(additional.AllowExternalSenders);
        Assert.True(additional.AutoSubscribeNewMembers);
        Assert.Null(additional.HideFromAddressLists);

        var organization = (OrganizationDetail)GraphJson.Deserialize("""{"id":"t1","isMultipleDataLocationsForServicesEnabled":true,"privacyProfile":{"contactEmail":"privacy@contoso.com","statementUrl":"https://contoso.com/privacy"}}""", typeof(OrganizationDetail));
        Assert.True(organization.IsMultipleDataLocationsForServicesEnabled);
        Assert.Equal("privacy@contoso.com", organization.PrivacyProfile.ContactEmail);
        Assert.Equal("https://contoso.com/privacy", organization.PrivacyProfile.StatementUrl);
        Assert.Equal("https://contoso.com/privacy", organization.PrivacyProfile.ToString());

        // accountEnabled is null for some accounts (and absent when not selected): no longer a failed page.
        Assert.Null(((User)GraphJson.Deserialize("""{"id":"u1","accountEnabled":null}""", typeof(User))).AccountEnabled);
        Assert.Null(((UserDelta)GraphJson.Deserialize("""{"id":"u1","accountEnabled":null}""", typeof(UserDelta))).AccountEnabled);
        Assert.Null(((UserGuest)GraphJson.Deserialize("""{"id":"u1","accountEnabled":null}""", typeof(UserGuest))).AccountEnabled);
    }

    [Theory]
    [InlineData(typeof(User), """{"id":"u1","createdDateTime":"yesterday"}""")]
    [InlineData(typeof(GroupAdditionalProperty), """{"id":"g1","allowExternalSenders":"maybe"}""")]
    public void StillRefusesAValueThatIsNotOfThePropertyType(Type type, string json)
    {
        // System.Text.Json does not guess: a date that is no ISO 8601 date and a bool that is no bool fail the
        // conversion (GraphBatchClient reports it as ConversionError) rather than silently becoming null.
        Assert.ThrowsAny<JsonException>(() => GraphJson.Deserialize(json, type));
    }

    [Fact]
    public void ReadsASingleObjectABareArrayAndAnEmptyPage()
    {
        Assert.Equal("u1", Assert.Single(Assert.IsType<User[]>(GraphJson.DeserializeCollection("""{"id":"u1"}""", typeof(User)))).Id);
        Assert.Equal(2, GraphJson.DeserializeCollection("""[{"id":"u1"},{"id":"u2"}]""", typeof(User)).Length);
        Assert.Empty(GraphJson.DeserializeCollection("""{"value":[]}""", typeof(User)));
        Assert.Empty(GraphJson.DeserializeCollection("null", typeof(User)));
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("  ")]
    public void RefusesEmptyJson(string json)
    {
        Assert.Throws<ArgumentException>(() => GraphJson.DeserializeCollection(json, typeof(User)));
        Assert.Throws<ArgumentException>(() => GraphJson.Deserialize(json, typeof(User)));
    }

    private sealed class Wrapped
    {
        [JsonConverter(typeof(StringOrValueConverter))]
        public string Purpose { get; set; }
    }

    [Theory]
    [InlineData("""{"purpose":"user"}""", "user")]
    [InlineData("""{"purpose":{"value":"shared"}}""", "shared")]
    [InlineData("""{"purpose":{"other":1}}""", null)]
    [InlineData("""{"purpose":null}""", null)]
    [InlineData("""{"purpose":true}""", "true")]
    [InlineData("""{"purpose":42}""", "42")]
    public void ReadsAStringOrAValueWrapper(string json, string expected)
    {
        Assert.Equal(expected, ((Wrapped)GraphJson.Deserialize(json, typeof(Wrapped))).Purpose);
    }

    [Fact]
    public void WritesAStringOrValueAsAPlainString()
    {
        Assert.Equal("""{"Purpose":"room"}""", JsonSerializer.Serialize(new Wrapped { Purpose = "room" }));
        Assert.Equal("""{"Purpose":null}""", JsonSerializer.Serialize(new Wrapped()));
    }
}
