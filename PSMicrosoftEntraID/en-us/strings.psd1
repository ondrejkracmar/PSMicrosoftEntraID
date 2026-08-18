# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Identity.Platform'                    = "Microsoft Entra ID (Azure AD)"
	"Office365.Platform"                   = "Microsoft Office 365"
	'Identity.Connect.Failed'              = "Establish a connection to '{0}' failed"
	'Identity.Disconnect'                  = "Disconnect from '{0}'"

	'Organization.Get'                     = 'Get organization detail'

	"MessageCenter.Get"                    = "Get Microsoft 365 Message Center Announcements"
	"MessageCenter.Get.Validation"         = "Parameter validation failed: {0} cannot be later than {1}"

	'Request.Invoke'                       = 'Invoke request command with the following url {0}'
	#'Request.Invoke.Failed'        = 'Invoke command failed'

	'Batch.Invoke'                         = 'Invoke batch command with the following Ids {0}'
	#'Batch.Invoke.Failed'          = 'Invoke batch command failed'

	'SubscribedSku.List'                   = "List subscribed Sku"
	'SubscribedSku.Get.Failed'             = "Get subscribed Sku '{0}' failed"
	'SubscribedSku.Filter'                 = "List subscribed Sku with filter '{0}'"
	'SubscribedSku.SkuPartNumber.NotFound' = "SkuPartNumber '{0}' was not found in the subscribed Sku catalog of the tenant"
	'ServicePlan.Filter'                   = "List service plan with filter '{0}'"
	'ServicePlanName.Get.Failed'           = "Get service plan '{0}' failed"

	'LicenseServicePlan.Enable'            = "Enable service plans '{0}' in subscription '{1}'"
	'LicenseServicePlan.Disable'           = "Disable service plans '{0}' in subscription '{1}'"
	'License.Enable'                       = "Enable license '{0}'"
	'License.Disable'                      = "Disable license '{0}'"

	'User.UsageLocation'                   = "Set usagelocation '{0}'"
	'User.New'                             = "Create new user '{0}'"
	'User.Set'                             = "Set user '{0}'"
	'User.Delete'                          = "Delete user '{0}'"
	'User.Get'                             = "Get user '{0}'"
	'User.Get.Failed'                      = "Get user '{0}' failed"
	'User.Filter'                          = "List users with filter '{0}'"
	'User.List'                            = "List users '{0}'"
	'User.Name'                            = "List users by name '{0}'"
	'User.Invitation'                      = "Invite user '{0}'"
	'User.Identity.Filter'                 = "List users by identity with filter '{0}'"
	'User.Identity.SignInType.Unsupported' = "Microsoft Graph does not support filtering identities on a signInType of userPrincipalName. Use -Identity to look the account up by its user principal name instead."
	'User.Identity.Issuer.Alone'           = "Microsoft Graph matches an issuer on its own only for {1}. For issuer '{0}' supply -IssuerAssignedId as well, or the request returns nothing rather than failing."
	'User.LicenseDetail.List'              = "List license detail of user '{0}'"

	'Group.Get'                            = "Get group '{0}'"
	'Group.LicenseDetail.List'             = "List license detail of group '{0}'"
	'Group.License.List'                   = "List assigned licenses of group '{0}'"
	'Group.AdditionalProperty'             = "Get group additional properties '{0}'"
	'Group.Get.Failed'                     = "Get group '{0}' failed"
	# Emitted where the code used to `continue` in silence. A caller could not tell
	# "done" from "did nothing", which is how a group template looked configured while
	# nothing had been written to it.
	'License.Sku.NotAssigned'              = "Subscription '{0}' is not assigned to '{1}'; nothing to change"
	'License.Target.NotFound'              = "Target '{0}' could not be resolved; skipping"
	'DirectoryObject.NoServiceUrl'         = "Service '{0}' has no ServiceUrl; falling back to the public Graph endpoint for the object binding"
	'Delta.Get'                            = "Get changes from '{0}'"
	'DeltaSession.Export'                  = "Save delta session to '{0}'"
	'DeltaSession.Import'                  = "Load delta session from '{0}'"
	'DeltaSession.NotFound'                = "No delta session at '{0}' yet; starting from scratch and tracking from now on"
	'Batch.Throttled'                      = "Graph throttled {0} sub-request(s); waiting {1}s before retry {2} of {3}"
	'Batch.SubRequestFailed'               = "{0} of {1} sub-request(s) failed: {2}. The batch itself succeeded - Graph returns HTTP 200 for the envelope regardless."
	'Group.Filter'                         = "List groups with filter '{0}'"
	'Group.List'                           = "List groups '{0}'"
	'Group.New'                            = "Create new group '{0}'"
	'Group.Delete'                         = "Delete group '{0}'"
	'Group.Set'                            = "Set group '{0}'"
	'Group.Set.Failed'                     = "Set group '{0}' failed"
	'GroupMember.Add'                      = "Add members '{0}'"
	#'GroupMember.Add.Failed'       = "Add members to the group '{0}' failed"
	'GroupMember.Delete'                   = "Remove members '{0}'"
	'GroupOwner.Add'                       = "Add owners '{0}'"
	#'GroupOwner.Add.Failed'        = "Add owners to the group '{0}' failed"
	'GroupOwner.Delete'                    = "Remove owners '{0}'"
	'GroupMember.List'                     = "List members from the group '{0}'"
	'GroupMember.Sync'                     = "Sync members of group"

	'Device.Get'                           = "Get device '{0}'"
	'Device.Get.Failed'                    = "Get device '{0}' failed"

	'AdministrativeUnit.Get'               = "Get administrative unit '{0}'"
	'AdministrativeUnit.Get.Failed'        = "Get administrative unit '{0}' failed"
	'AdministrativeUnit.Filter'            = "List administrative units with filter '{0}'"
	'AdministrativeUnit.List'              = "List administrative units '{0}'"
	'AdministrativeUnit.Create'            = "Create new administrative unit '{0}'"
	'AdministrativeUnit.Set'               = "Set administrative unit '{0}'"
	'AdministrativeUnit.Set.Failed'        = "Set administrative unit '{0}' failed"
	'AdministrativeUnit.Remove'            = "Delete administrative unit '{0}'"
	'AdministrativeUnit.Remove.Failed'     = "Delete administrative unit '{0}' failed"
	'AdministrativeUnitMember.List'        = "List members from the administrative unit '{0}'"
	'AdministrativeUnitMember.Add'         = "Add member '{0}' to administrative unit"
	'AdministrativeUnitMember.Delete'      = "Remove member '{0}' from administrative unit"

	'Contact.Get'                          = "Get contact '{0}'"
	'Contact.Filter'                       = "List contacts with filter '{0}'"
	'Contact.List'                         = "List contacts '{0}'"
	'Contact.Name'                         = "List contacts by name '{0}'"
}