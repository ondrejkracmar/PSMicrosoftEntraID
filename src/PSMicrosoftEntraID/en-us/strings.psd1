# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Identity.Platform'            = "Microsoft Entra ID (Azure AD)"
	"Office365.Platform"           = "Microsoft Office 365"
	'Identity.Connect.Failed'      = "Establish a connection to '{0}' failed"
	'Identity.Disconnect'          = "Disconnect from '{0}'"

	'Organization.Get'             = 'Get organization detail'

	"MessageCenter.Get"            = "Get Microsoft 365 Message Center Announcements'"
	"MessageCenter.Get.Validation" = "Parameter validation failed: {0} cannot be later than {1}"

	'Request.Invoke'               = 'Invoke request command with the following url {0}'
	'Request.Invoke.Failed'        = 'Invoke command failed'

	'Batch.Invoke'                 = 'Invoke batch command with the following Ids {0}'
	'Batch.Invoke.Failed'          = 'Invoke batch command failed'

	'SubscribedSku.List'           = "List subscribed Sku"
	'SubscribedSku.Get.Failed'     = "Get subscribed Sku '{0}' failed"
	'SubscribedSku.Filter'         = "List subscribed Sku with filter '{0}'"
	'ServicePlan.Filter'           = "List service plan with filter '{0}'"
	'ServicePlanName.Get.Failed'   = "Get service plan '{0}' failed"

	'LicenseServicePLan.Enable'    = "Enable service plans '{0}' in subscription '{1}'"
	'LicenseServicePLan.Disable'   = "Disable service plans '{0}' in subscription '{1}'"
	'License.Enable'               = "Enable license '{0}'"
	'License.Disable'              = "Disable license '{0}'"

	'User.UsageLocation'           = "Set usagelocation '{0}'"
	'User.Delete'                  = "Delete user '{0}'"
	'User.Get'                     = "Get user '{0}'"
	'User.Get.Failed'              = "Get user '{0}' failed"
	'User.Filter'                  = "List users with filter '{0}'"
	'User.List'                    = "List users '{0}'"
	'User.Name'                    = "List users by name '{0}'"
	'User.Invitation'              = "Invite user '{0}'"
	'User.LicenseDetai.List'       = "List license detail of user '{0}'"

	'Group.Get'                    = "Get group '{0}'"
	'Group.AdditionalProperty'     = "Get group additional properties '{0}'"
	'Group.Get.Failed'             = "Get group '{0}' failed"
	'Group.Filter'                 = "List groups with filter '{0}'"
	'Group.List'                   = "List groups '{0}'"
	'Group.New'                    = "Create new group '{0}'"
	'Group.Delete'                 = "Delete group '{0}'"
	'Group.Set'                    = "Set group '{0}'"
	'Group.Set.Failed'             = "Set group '{0}' failed"
	'GroupMember.Add'              = "Add members '{0}'"
	'GroupMember.Add.Failed'       = "Add members to the group '{0}' failed"
	'GroupMember.Delete'           = "Remove members '{0}'"
	'GroupOwner.Add'               = "Add owners '{0}'"
	'GroupOwner.Add.Failed'        = "Add owners to the group '{0}' failed"
	'GroupOwner.Delete'            = "Remove owners '{0}'"
	'GroupMember.List'             = "List members from the group '{0}'"
	'GroupMember.Sync'             = "Sync members of group"

	'Contact.Get'                  = "Get xontact '{0}'"
	'Contact.Filter'               = "List contacts with filter '{0}'"
	'Contact.List'                 = "List contacts '{0}'"
	'Contact.Name'                 = "List contacts by name '{0}'"
}