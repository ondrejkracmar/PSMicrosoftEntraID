BeforeAll {
	$script:ModuleName = 'PSMicrosoftEntraID'

	Import-Module "$PSScriptRoot/../../../$script:ModuleName/$script:ModuleName.psd1" -Force
}

<#
	Every public Get-* cmdlet that reads Graph (or Defender for Endpoint) end to end through the real
	ConvertFrom-Rest* converters - only the wire is mocked. Invoke-EntraRequest is replaced by a stand-in that
	does what Invoke-RestMethod does to a response body (ConvertFrom-Json, value unwrapped), so the converters see
	exactly the objects they see in production, including the DateTime values ConvertFrom-Json makes of ISO dates
	and nesting deeper than the -Depth 4 the old ConvertTo-Json round trip kept.

	The assertions are on the values: the type of the object, dates as DateTime (UTC) with their exact instant,
	booleans as booleans, nulls as null, the deepest nested value - and that the format views render them.
#>
Describe 'Typed models from Graph JSON' -Tag 'Unit' {

	BeforeAll {
		$script:routes = [ordered]@{
			'^users/delta$'                                  = '{"@odata.deltaLink":"https://graph.microsoft.com/v1.0/users/delta?$deltatoken=t1","value":[
				{"id":"6e7b768e-07e2-4810-8459-485f84f8f204","displayName":"Adele Vance","accountEnabled":true,"createdDateTime":"2024-01-15T08:30:00Z",
				 "assignedLicenses":[{"skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","disabledPlans":["a23b959c-7ce8-4e57-9140-b90eb88a9e97"]}]},
				{"id":"87d349ed-44d7-43e1-9a83-5f2406dee5bd","@removed":{"reason":"deleted"}}]}'
			'^groups/delta$'                                 = '{"value":[
				{"id":"02bd9fd6-8f93-4758-87c3-1fb73740a315","displayName":"Licensing - E5","createdDateTime":"2023-05-01T10:00:00Z",
				 "members@delta":[{"@odata.type":"#microsoft.graph.user","id":"6e7b768e-07e2-4810-8459-485f84f8f204"},
				                  {"@odata.type":"#microsoft.graph.user","id":"87d349ed-44d7-43e1-9a83-5f2406dee5bd","@removed":"deleted"}]}]}'
			'^devices/delta$'                                = '{"value":[{"id":"c1b4a7f0-0000-4000-8000-000000000001","displayName":"CONTOSO-LT-042","registrationDateTime":"2025-02-03T09:15:00Z"},
				{"id":"c1b4a7f0-0000-4000-8000-000000000002","@removed":{"reason":"changed"}}]}'
			'^contacts/delta$'                               = '{"value":[{"id":"c-1","displayName":"Patti Fernandez (Fabrikam)","mail":"patti@fabrikam.com"},{"id":"c-2","@removed":{"reason":"deleted"}}]}'
			'^directory/administrativeUnits/delta$'          = '{"value":[{"id":"au-1","displayName":"Seattle","members@delta":[{"@odata.type":"#microsoft.graph.device","id":"dev-1","@removed":"deleted"}]}]}'
			'^users/[^/]+/licenseDetails$'                   = '{"value":[{"id":"ld-1","skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","skuPartNumber":"ENTERPRISEPREMIUM",
				"servicePlans":[{"servicePlanId":"a23b959c-7ce8-4e57-9140-b90eb88a9e97","servicePlanName":"SWAY","provisioningStatus":"Disabled","appliesTo":"User"}]}]}'
			'^users/[^/]+/memberOf$'                         = '{"value":[{"@odata.type":"#microsoft.graph.group","id":"02bd9fd6-8f93-4758-87c3-1fb73740a315","displayName":"HR Taskforce",
				"createdDateTime":"2023-05-01T10:00:00Z","renewedDateTime":"2026-05-01T10:00:00Z","mailEnabled":true,"securityEnabled":false}]}'
			'^users/[^/]+$'                                  = '{"@odata.context":"https://graph.microsoft.com/v1.0/$metadata#users/$entity",
				"id":"6e7b768e-07e2-4810-8459-485f84f8f204","userPrincipalName":"AdeleV@contoso.com","displayName":"Adele Vance","createdDateTime":"2024-01-15T08:30:00Z",
				"accountEnabled":true,"mobilePhone":null,"usageLocation":"US",
				"assignedLicenses":[{"skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","disabledPlans":["a23b959c-7ce8-4e57-9140-b90eb88a9e97","882e1d05-acd1-4ccb-8708-6ee03664b117"]}],
				"identities":[{"signInType":"userPrincipalName","issuer":"contoso.onmicrosoft.com","issuerAssignedId":"AdeleV@contoso.com"}]}'
			'^users$'                                        = '{"value":[{"id":"0b5a3c8e-1f0d-4c34-9b1d-2a8c6f0e7d11","userPrincipalName":"megan_fabrikam.com#EXT#@contoso.onmicrosoft.com",
				"displayName":"Megan Bowen","userType":"Guest","accountEnabled":null,"createdDateTime":"2025-06-30T22:15:09Z","externalUserState":"Accepted",
				"externalUserStateChangeDateTime":"2025-07-01T06:00:00Z",
				"identities":[{"signInType":"federated","issuer":"fabrikam.com","issuerAssignedId":null}],
				"assignedLicenses":[{"skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","disabledPlans":["a23b959c-7ce8-4e57-9140-b90eb88a9e97"]}]}]}'
			'^groups/[^/]+/(members|owners)$'                = '{"value":[{"@odata.type":"#microsoft.graph.user","id":"6e7b768e-07e2-4810-8459-485f84f8f204","displayName":"Adele Vance",
				"createdDateTime":"2024-01-15T08:30:00Z","accountEnabled":false,
				"assignedLicenses":[{"skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","disabledPlans":["a23b959c-7ce8-4e57-9140-b90eb88a9e97"]}]}]}'
			'^groups/[^/]+$'                                 = '{"id":"02bd9fd6-8f93-4758-87c3-1fb73740a315","displayName":"HR Taskforce","mail":"HRTaskforce@contoso.com","mailNickname":"HRTaskforce",
				"createdDateTime":"2023-05-01T10:00:00Z","deletedDateTime":null,"expirationDateTime":"2027-05-01T10:00:00Z","renewedDateTime":"2026-05-01T10:00:00Z",
				"mailEnabled":true,"securityEnabled":false,"isAssignableToRole":null,"groupTypes":["Unified"],
				"assignedLabels":[{"labelId":"a1b2c3d4-0000-0000-0000-000000000001","displayName":"Confidential"}],
				"assignedLicenses":[{"skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","disabledPlans":["a23b959c-7ce8-4e57-9140-b90eb88a9e97"]}],
				"hideFromAddressLists":false,"hideFromOutlookClients":true,"allowExternalSenders":false,"autoSubscribeNewMembers":true}'
			'^directory/administrativeUnits/[^/]+/members$'  = '{"value":[{"@odata.type":"#microsoft.graph.user","id":"6e7b768e-07e2-4810-8459-485f84f8f204","displayName":"Adele Vance","createdDateTime":"2024-01-15T08:30:00Z","accountEnabled":true}]}'
			'^directory/administrativeUnits/[^/]+$'          = '{"id":"4d7ea995-bc0f-45c0-8c4b-1d5f5a8a0a11","displayName":"Seattle District Technical Schools","deletedDateTime":null,
				"visibility":"HiddenMembership","isMemberManagementRestricted":true,
				"scopedRoleMembers":[{"id":"srm-1","roleId":"fe930be7-5e62-47db-91af-98c3a49a38b1","administrativeUnitId":"4d7ea995-bc0f-45c0-8c4b-1d5f5a8a0a11",
				  "roleMemberInfo":{"id":"6e7b768e-07e2-4810-8459-485f84f8f204","displayName":"Adele Vance"}}]}'
			'^contacts$'                                     = '{"value":[{"id":"c-1","displayName":"Patti Fernandez (Fabrikam)","mail":"patti@fabrikam.com","businessPhones":[],"mobilePhone":null}]}'
			'^devices$'                                      = '{"value":[{"id":"c1b4a7f0-0000-4000-8000-000000000001","deviceId":"4c299165-6e8f-4b45-a5ba-c5d250a707ff","displayName":"CONTOSO-LT-042",
				"accountEnabled":true,"isCompliant":null,"registrationDateTime":"2025-02-03T09:15:00Z","approximateLastSignInDateTime":"2026-11-10T07:00:00Z",
				"extensionAttributes":{"extensionAttribute1":"Finance","extensionAttribute15":null}}]}'
			'^machines$'                                     = '{"@odata.context":"https://api.securitycenter.microsoft.com/api/$metadata#Machines","value":[{"id":"1e5bc9d7e413ddd7902c2932e418702b84d0cc07",
				"computerDnsName":"contoso-lt-042.contoso.com","firstSeen":"2018-08-02T14:55:03.7791856Z","lastSeen":"2026-11-11T21:30:00Z","osPlatform":"Windows11",
				"healthStatus":"Active","riskScore":"Low","exposureLevel":"Medium","rbacGroupName":"Finance","osBuild":26100,"isAadJoined":true,
				"aadDeviceId":"4c299165-6e8f-4b45-a5ba-c5d250a707ff","machineTags":["Finance","VIP"]}]}'
			'^organization$'                                 = '{"value":[{"id":"48a80680-7326-48cd-9935-b556b81d3a4e","displayName":"Contoso","tenantType":"AAD",
				"isMultipleDataLocationsForServicesEnabled":true,"onPremisesLastSyncDateTime":"2026-11-12T06:40:12Z","onPremisesSyncEnabled":true,
				"createdDateTime":"2015-06-01T12:00:00Z","deletedDateTime":null,"directorySizeQuota":{"used":6157,"total":300000},"defaultUsageLocation":"US",
				"technicalNotificationMails":["it@contoso.com"],"privacyProfile":{"contactEmail":"privacy@contoso.com","statementUrl":"https://contoso.com/privacy"},
				"assignedPlans":[{"assignedDateTime":"2024-02-01T00:00:00Z","capabilityStatus":"Enabled","service":"exchange","servicePlanId":"efb87545-963c-4e0d-99df-69c6916d9eb0"}],
				"verifiedDomains":[{"capabilities":"Email","isDefault":true,"isInitial":false,"name":"contoso.com","type":"Managed"}]}]}'
			'^subscribedSkus$'                               = '{"value":[{"accountName":"Contoso","accountId":"48a80680-7326-48cd-9935-b556b81d3a4e","capabilityStatus":"Enabled",
				"id":"48a80680-7326-48cd-9935-b556b81d3a4e_c7df2760-2c81-4ef7-b578-5b5392b571df","skuId":"c7df2760-2c81-4ef7-b578-5b5392b571df","skuPartNumber":"ENTERPRISEPREMIUM",
				"appliesTo":"User","consumedUnits":14,"prepaidUnits":{"enabled":25,"suspended":0,"warning":null,"lockedOut":0},
				"servicePlans":[{"servicePlanId":"a23b959c-7ce8-4e57-9140-b90eb88a9e97","servicePlanName":"SWAY","provisioningStatus":"Success","appliesTo":"User"}]}]}'
			'^admin/serviceAnnouncement/messages$'           = '{"value":[
				{"id":"MC172851","title":"Microsoft Teams: New meeting experience","category":"planForChange","severity":"normal","services":["Microsoft Teams"],
				 "isMajorChange":true,"startDateTime":"2026-10-28T19:54:25Z","endDateTime":null,"lastModifiedDateTime":"2026-11-02T18:01:46Z","actionRequiredByDateTime":null,
				 "hasAttachments":false,"body":{"contentType":"html","content":"<p>Rollout.</p>"},"viewPoint":{"isRead":null,"isArchived":false,"isFavorited":true}},
				{"id":"MC100001","title":"Older message","category":"stayInformed","severity":"normal","services":["Exchange Online"],
				 "isMajorChange":false,"startDateTime":"2026-09-01T00:00:00Z","lastModifiedDateTime":"2026-09-01T00:00:00Z","hasAttachments":false}]}'
		}

		# A group read by id first looks the identity up as a mailNickname on the collection.
		$script:routes['^groups$'] = '{"value":[' + $script:routes['^groups/[^/]+$'] + ']}'

		Mock -ModuleName $script:ModuleName Assert-EntraConnection { }
		Mock -ModuleName $script:ModuleName Invoke-PSFProtectedCommand { & $ScriptBlock }
		Mock -ModuleName $script:ModuleName Test-PSFFunctionInterrupt { $false }
		Mock -ModuleName $script:ModuleName Invoke-EntraRequest {
			$pattern = @($script:routes.Keys).Where({ $Path -match $_ }, 'First')
			if (-not $pattern) { throw "No fixture for path '$Path'" }
			# What Invoke-RestMethod hands Invoke-EntraRequest, and what Invoke-EntraRequest hands on.
			$parsed = $script:routes[$pattern[0]] | ConvertFrom-Json -Depth 100
			if (-not $Raw -and $parsed.PSObject.Properties['value']) { $parsed.value } else { $parsed }
		}

		function script:Assert-Utc {
			param ($Value, [datetime] $Expected)
			$Value | Should -BeOfType [datetime]
			$Value | Should -Be $Expected
			$Value.Kind | Should -Be ([System.DateTimeKind]::Utc)
		}

		function script:Assert-Rendering {
			param ($InputObject)
			{ $InputObject | Format-Table | Out-String -Width 400 } | Should -Not -Throw
			{ $InputObject | Format-List | Out-String -Width 400 } | Should -Not -Throw
			{ $InputObject | Format-List -Property * | Out-String -Width 400 } | Should -Not -Throw
			# Wide enough that no column of the default view is dropped.
			$InputObject | Format-Table | Out-String -Width 400
		}

		$script:adeleId = '6e7b768e-07e2-4810-8459-485f84f8f204'
		$script:groupId = '02bd9fd6-8f93-4758-87c3-1fb73740a315'
		$script:unitId = '4d7ea995-bc0f-45c0-8c4b-1d5f5a8a0a11'
	}

	Context 'Users' {

		It 'Get-PSEntraIDUser emits User with a UTC DateTime, a bool and licences five levels deep' {
			$user = Get-PSEntraIDUser -Identity $script:adeleId -EnableException

			$user.GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.User'
			Assert-Utc $user.CreatedDateTime ([datetime]::new(2024, 1, 15, 8, 30, 0, [System.DateTimeKind]::Utc))
			$user.AccountEnabled | Should -BeOfType [bool]
			$user.AccountEnabled | Should -BeTrue
			$user.MobilePhone | Should -BeNullOrEmpty
			@($user.AssignedLicenses[0].DisabledPlans) | Should -Be @('a23b959c-7ce8-4e57-9140-b90eb88a9e97', '882e1d05-acd1-4ccb-8708-6ee03664b117')
			$user.Identities[0].Issuer | Should -Be 'contoso.onmicrosoft.com'
			Assert-Rendering $user | Should -Match 'Adele Vance'
		}

		It 'Get-PSEntraIDUserGuest emits UserGuest with both dates and a null AccountEnabled' {
			$guest = @(Get-PSEntraIDUserGuest -All -EnableException)

			$guest.Count | Should -Be 1
			$guest[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.UserGuest'
			Assert-Utc $guest[0].CreatedDateTime ([datetime]::new(2025, 6, 30, 22, 15, 9, [System.DateTimeKind]::Utc))
			Assert-Utc $guest[0].ExternalUserStateChangeDateTime ([datetime]::new(2025, 7, 1, 6, 0, 0, [System.DateTimeKind]::Utc))
			$guest[0].AccountEnabled | Should -BeNullOrEmpty
			$guest[0].HomeIssuer | Should -Be 'fabrikam.com'
			$guest[0].InvitationStatus | Should -Be 'Accepted'
			Assert-Rendering $guest | Should -Match 'fabrikam.com'
		}

		It 'Get-PSEntraIDUserLicenseDetail emits the licence detail with its service plans' {
			$detail = @(Get-PSEntraIDUserLicenseDetail -Identity $script:adeleId -EnableException)

			$detail[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.LicenseManagement.SubscriptionSku'
			$detail[0].SkuPartNumber | Should -Be 'ENTERPRISEPREMIUM'
			$detail[0].ServicePlans[0].ProvisioningStatus | Should -Be 'Disabled'
			Assert-Rendering $detail | Should -Match 'ENTERPRISEPREMIUM'
		}

		It 'Get-PSEntraIDUserMemberOf emits Group with DateTime values' {
			$groups = @(Get-PSEntraIDUserMemberOf -Identity $script:adeleId -EnableException)

			$groups[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Groups.Group'
			Assert-Utc $groups[0].RenewedDateTime ([datetime]::new(2026, 5, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
			$groups[0].MailEnabled | Should -BeTrue
			Assert-Rendering $groups | Should -Match 'HR Taskforce'
		}

		It 'Get-PSEntraIDUserDelta maps @removed and keeps the dates typed' {
			$delta = @(Get-PSEntraIDUserDelta -DeltaSession @{} -EnableException)

			$delta.Count | Should -Be 2
			$delta[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.UserDelta'
			$delta[0].ChangeType | Should -Be 'Changed'
			Assert-Utc $delta[0].CreatedDateTime ([datetime]::new(2024, 1, 15, 8, 30, 0, [System.DateTimeKind]::Utc))
			$delta[0].AssignedLicenses[0].DisabledPlans | Should -Be 'a23b959c-7ce8-4e57-9140-b90eb88a9e97'
			$delta[1].ChangeType | Should -Be 'Purged'
			$delta[1].Removed | Should -BeTrue
			$delta[1].AccountEnabled | Should -BeNullOrEmpty
			Assert-Rendering $delta | Should -Match 'Adele Vance'
		}
	}

	Context 'Groups' {

		It 'Get-PSEntraIDGroup emits Group with four typed dates, labels and licences' {
			$group = Get-PSEntraIDGroup -Identity $script:groupId -EnableException

			$group.GetType().FullName | Should -Be 'PSMicrosoftEntraID.Groups.Group'
			Assert-Utc $group.CreatedDateTime ([datetime]::new(2023, 5, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
			Assert-Utc $group.ExpirationDateTime ([datetime]::new(2027, 5, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
			Assert-Utc $group.RenewedDateTime ([datetime]::new(2026, 5, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
			$group.DeletedDateTime | Should -BeNullOrEmpty
			$group.IsAssignableToRole | Should -BeNullOrEmpty
			$group.SecurityEnabled | Should -BeFalse
			$group.AssignedLabels[0].DisplayName | Should -Be 'Confidential'
			$group.AssignedLicenses[0].DisabledPlans | Should -Be 'a23b959c-7ce8-4e57-9140-b90eb88a9e97'
			Assert-Rendering $group | Should -Match 'HR Taskforce'
		}

		It 'Get-PSEntraIDGroupAdditionalProperty reads allowExternalSenders and autoSubscribeNewMembers as booleans' {
			$additional = @(Get-PSEntraIDGroupAdditionalProperty -Identity $script:groupId -EnableException)

			$additional[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Groups.GroupAdditionalProperty'
			$additional[0].AllowExternalSenders | Should -BeOfType [bool]
			$additional[0].AllowExternalSenders | Should -BeFalse
			$additional[0].AutoSubscribeNewMembers | Should -BeTrue
			$additional[0].HideFromOutlookClients | Should -BeTrue
			Assert-Rendering $additional | Should -Match 'HRTaskforce'
		}

		It 'Get-PSEntraIDGroupMember emits User with typed values' {
			$members = @(Get-PSEntraIDGroupMember -Identity $script:groupId -EnableException)

			$members[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.User'
			Assert-Utc $members[0].CreatedDateTime ([datetime]::new(2024, 1, 15, 8, 30, 0, [System.DateTimeKind]::Utc))
			$members[0].AccountEnabled | Should -BeFalse
			$members[0].AssignedLicenses[0].SkuId | Should -Be 'c7df2760-2c81-4ef7-b578-5b5392b571df'
			Assert-Rendering $members | Should -Match 'Adele Vance'
		}

		It 'Get-PSEntraIDGroupDelta fills MembersDelta with ObjectType and Removed' {
			$delta = @(Get-PSEntraIDGroupDelta -DeltaSession @{} -EnableException)

			$delta[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Groups.GroupDelta'
			Assert-Utc $delta[0].CreatedDateTime ([datetime]::new(2023, 5, 1, 10, 0, 0, [System.DateTimeKind]::Utc))
			$delta[0].MembersDelta.Count | Should -Be 2
			$delta[0].MembersDelta[0].ObjectType | Should -Be '#microsoft.graph.user'
			$delta[0].MembersDelta[0].Removed | Should -BeFalse
			$delta[0].MembersDelta[1].Removed | Should -BeTrue
			Assert-Rendering $delta | Should -Match 'Licensing - E5'
		}
	}

	Context 'Administrative units, contacts, devices, machines' {

		It 'Get-PSEntraIDAdministrativeUnit keeps roleMemberInfo five levels deep' {
			$unit = Get-PSEntraIDAdministrativeUnit -Identity $script:unitId -EnableException

			$unit.GetType().FullName | Should -Be 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnit'
			$unit.DeletedDateTime | Should -BeNullOrEmpty
			$unit.IsMemberManagementRestricted | Should -BeTrue
			$unit.ScopedRoleMembers[0].RoleMemberInfo.DisplayName | Should -Be 'Adele Vance'
			Assert-Rendering $unit | Should -Match 'Seattle'
		}

		It 'Get-PSEntraIDAdministrativeUnitMember emits User' {
			$members = @(Get-PSEntraIDAdministrativeUnitMember -Identity $script:unitId -EnableException)

			$members[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Users.User'
			Assert-Utc $members[0].CreatedDateTime ([datetime]::new(2024, 1, 15, 8, 30, 0, [System.DateTimeKind]::Utc))
		}

		It 'Get-PSEntraIDAdministrativeUnitDelta maps members@delta' {
			$delta = @(Get-PSEntraIDAdministrativeUnitDelta -DeltaSession @{} -EnableException)

			$delta[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.DirectoryManagement.AdministrativeUnitDelta'
			$delta[0].MembersDelta[0].ObjectType | Should -Be '#microsoft.graph.device'
			$delta[0].MembersDelta[0].Removed | Should -BeTrue
			Assert-Rendering $delta | Out-Null
		}

		It 'Get-PSEntraIDContact and Get-PSEntraIDContactDelta emit Contact and ContactDelta' {
			$contact = @(Get-PSEntraIDContact -All -EnableException)
			$contact[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Contacts.Contact'
			$contact[0].Mail | Should -Be 'patti@fabrikam.com'
			Assert-Rendering $contact | Should -Match 'patti@fabrikam.com'

			$delta = @(Get-PSEntraIDContactDelta -DeltaSession @{} -EnableException)
			$delta[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Contacts.ContactDelta'
			$delta[1].ChangeType | Should -Be 'Purged'
		}

		It 'Get-PSEntraIDDevice and Get-PSEntraIDDeviceDelta emit DateTime values' {
			$device = @(Get-PSEntraIDDevice -EnableException)
			$device[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Devices.Device'
			Assert-Utc $device[0].RegistrationDateTime ([datetime]::new(2025, 2, 3, 9, 15, 0, [System.DateTimeKind]::Utc))
			Assert-Utc $device[0].ApproximateLastSignInDateTime ([datetime]::new(2026, 11, 10, 7, 0, 0, [System.DateTimeKind]::Utc))
			$device[0].IsCompliant | Should -BeNullOrEmpty
			$device[0].ExtensionAttributes.ExtensionAttribute1 | Should -Be 'Finance'
			Assert-Rendering $device | Should -Match 'CONTOSO-LT-042'

			$delta = @(Get-PSEntraIDDeviceDelta -DeltaSession @{} -EnableException)
			$delta[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.Devices.DeviceDelta'
			Assert-Utc $delta[0].RegistrationDateTime ([datetime]::new(2025, 2, 3, 9, 15, 0, [System.DateTimeKind]::Utc))
			$delta[1].ChangeType | Should -Be 'Deleted'
		}

		It 'Get-PSEntraIDMachine emits Machine with FirstSeen/LastSeen as DateTime and renders LastSeen' {
			$machine = @(Get-PSEntraIDMachine -EnableException)

			$machine[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.DefenderEndpoint.Machine'
			Assert-Utc $machine[0].FirstSeen ([datetime]::new(2018, 8, 2, 14, 55, 3, [System.DateTimeKind]::Utc).AddTicks(7791856))
			Assert-Utc $machine[0].LastSeen ([datetime]::new(2026, 11, 11, 21, 30, 0, [System.DateTimeKind]::Utc))
			$machine[0].OsBuild | Should -Be 26100
			$machine[0].IsAadJoined | Should -BeTrue
			Assert-Rendering $machine | Should -Match '2026-11-11 21:30'
		}
	}

	Context 'Organization, licences, message center' {

		It 'Get-PSEntraIDOrganization maps TenantId, the booleans, PrivacyProfile and renders the date column' {
			$organization = Get-PSEntraIDOrganization -EnableException

			$organization.GetType().FullName | Should -Be 'PSMicrosoftEntraID.Organization.OrganizationDetail'
			$organization.TenantId | Should -Be '48a80680-7326-48cd-9935-b556b81d3a4e'
			$organization.IsMultipleDataLocationsForServicesEnabled | Should -BeTrue
			Assert-Utc $organization.CreatedDateTime ([datetime]::new(2015, 6, 1, 12, 0, 0, [System.DateTimeKind]::Utc))
			Assert-Utc $organization.OnPremisesLastSyncDateTime ([datetime]::new(2026, 11, 12, 6, 40, 12, [System.DateTimeKind]::Utc))
			$organization.DeletedDateTime | Should -BeNullOrEmpty
			$organization.DirectorySizeQuota.Used | Should -Be 6157
			$organization.DirectorySizeQuota.Total | Should -Be 300000
			$organization.PrivacyProfile.GetType().FullName | Should -Be 'PSMicrosoftEntraID.Organization.PrivacyProfile'
			$organization.PrivacyProfile.ContactEmail | Should -Be 'privacy@contoso.com'
			Assert-Utc $organization.AssignedPlans[0].AssignedDateTime ([datetime]::new(2024, 2, 1, 0, 0, 0, [System.DateTimeKind]::Utc))
			$organization.VerifiedDomains[0].IsDefault | Should -BeTrue
			Assert-Rendering $organization | Should -Match '2015-06-01 12:00'
		}

		It 'Get-PSEntraIDSubscribedLicense reads the units as numbers and a null as null' {
			$sku = @(Get-PSEntraIDSubscribedLicense -EnableException)

			$sku[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.License.SubscriptionSkuLicense'
			$sku[0].ConsumedUnits | Should -Be 14
			$sku[0].PrepaidUnits.Enabled | Should -Be 25
			$sku[0].PrepaidUnits.Warning | Should -BeNullOrEmpty
			$sku[0].ServicePlans[0].ServicePlanName | Should -Be 'SWAY'
			Assert-Rendering $sku | Should -Match 'ENTERPRISEPREMIUM'
		}

		It 'Get-PSEntraIDLicenseIdentifier reads the catalog into LicenseIdentifier objects' {
			$catalog = @(Get-PSEntraIDLicenseIdentifier -EnableException)

			$catalog.Count | Should -BeGreaterThan 100
			$catalog[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.License.LicenseIdentifier'
			$e5 = @($catalog.Where({ $_.SkuId -eq 'c7df2760-2c81-4ef7-b578-5b5392b571df' }))
			$e5.Count | Should -Be 1
			$e5[0].SkuPartNumber | Should -Be 'ENTERPRISEPREMIUM'
			$e5[0].ServicePlans.Count | Should -BeGreaterThan 10
		}

		It 'Get-PSEntraIDMessageCenter emits Message with typed dates, booleans and view point' {
			$messages = @(Get-PSEntraIDMessageCenter -EnableException)

			$messages.Count | Should -Be 2
			$messages[0].GetType().FullName | Should -Be 'PSMicrosoftEntraID.ServiceAnnouncement.Message'
			Assert-Utc $messages[0].StartDateTime ([datetime]::new(2026, 10, 28, 19, 54, 25, [System.DateTimeKind]::Utc))
			$messages[0].EndDateTime | Should -BeNullOrEmpty
			$messages[0].IsMajorChange | Should -BeTrue
			$messages[0].HasAttachments | Should -BeFalse
			$messages[0].ViewPoint.IsRead | Should -BeNullOrEmpty
			$messages[0].ViewPoint.IsFavorited | Should -BeTrue
			Assert-Rendering $messages | Should -Match 'MC172851'
		}

		It 'Get-PSEntraIDMessageCenter filters on the DateTime StartDateTime' -ForEach @(
			@{ After = [datetime]::new(2026, 10, 1, 0, 0, 0, [System.DateTimeKind]::Utc); Before = $null; Expected = @('MC172851') }
			@{ After = [datetime]::new(2026, 10, 1); Before = $null; Expected = @('MC172851') }
			@{ After = $null; Before = [datetime]::new(2026, 10, 1, 0, 0, 0, [System.DateTimeKind]::Utc); Expected = @('MC100001') }
			@{ After = [datetime]::new(2026, 10, 28, 19, 54, 25, [System.DateTimeKind]::Utc); Before = [datetime]::new(2026, 10, 28, 19, 54, 25, [System.DateTimeKind]::Utc); Expected = @('MC172851') }
		) {
			$parameters = @{ EnableException = $true }
			if ($After) { $parameters.PublishedAfter = $After }
			if ($Before) { $parameters.PublishedBefore = $Before }

			@(Get-PSEntraIDMessageCenter @parameters).Id | Should -Be $Expected
		}
	}

	Context 'Converter input forms' {

		It 'ConvertFrom-GraphResponse reads JSON text, one object and a set the same way' {
			InModuleScope PSMicrosoftEntraID {
				$json = '{"value":[{"id":"u1","createdDateTime":"2024-01-15T08:30:00Z","accountEnabled":false},{"id":"u2","createdDateTime":null}]}'
				$fromText = @(ConvertFrom-GraphResponse -InputObject $json -Type ([PSMicrosoftEntraID.Users.User]))
				$fromObjects = @(ConvertFrom-GraphResponse -InputObject ($json | ConvertFrom-Json).value -Type ([PSMicrosoftEntraID.Users.User]))
				$fromOne = @(ConvertFrom-GraphResponse -InputObject ($json | ConvertFrom-Json).value[0] -Type ([PSMicrosoftEntraID.Users.User]))

				foreach ($result in $fromText, $fromObjects) {
					$result.Count | Should -Be 2
					$result[0].CreatedDateTime | Should -Be ([datetime]::new(2024, 1, 15, 8, 30, 0, [System.DateTimeKind]::Utc))
					$result[0].AccountEnabled | Should -BeFalse
					$result[1].CreatedDateTime | Should -BeNullOrEmpty
				}
				$fromOne.Count | Should -Be 1
				$fromOne[0].Id | Should -Be 'u1'
				@(ConvertFrom-GraphResponse -InputObject $null -Type ([PSMicrosoftEntraID.Users.User])).Count | Should -Be 0
				@(ConvertFrom-GraphResponse -InputObject @() -Type ([PSMicrosoftEntraID.Users.User])).Count | Should -Be 0
				@(ConvertFrom-GraphResponse -InputObject ' ' -Type ([PSMicrosoftEntraID.Users.User])).Count | Should -Be 0
			}
		}

		It 'keeps data nested deeper than the old -Depth 4 (ten levels)' {
			InModuleScope PSMicrosoftEntraID {
				# value > user > assignedLicenses > [] > disabledPlans was cut at -Depth 4 before; this goes further
				# through the parsed-object path, which is the one that serializes.
				$deep = '{"id":"u1","assignedLicenses":[{"skuId":"s1","disabledPlans":["p1","p2"]}],"identities":[{"issuer":"contoso.com"}],"x":{"a":{"b":{"c":{"d":{"e":{"f":{"g":1}}}}}}}}' | ConvertFrom-Json
				$user = @(ConvertFrom-RestUser -InputObject @($deep, $deep))

				$user.Count | Should -Be 2
				$user[1].AssignedLicenses[0].DisabledPlans | Should -Be @('p1', 'p2')
				$user[1].Identities[0].Issuer | Should -Be 'contoso.com'
			}
		}
	}
}
