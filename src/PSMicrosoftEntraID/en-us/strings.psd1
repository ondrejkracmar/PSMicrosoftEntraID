# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'Identity.Platform'                    = "Microsoft Entra ID (Azure AD)"
	"Office365.Platform"                   = "Microsoft Office 365"
	'Identity.Connect.Failed'              = "Establish a connection to '{0}' failed: {1}"
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
	'LicenseServicePlan.NotFound'          = "Service plans {0} were not found in subscription '{1}'; nothing was changed"
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
	# Enable-*LicenseServicePlan assigning a SKU the target does not hold: without the
	# full plan list it would go out with every plan enabled, so these stop the command.
	'LicenseServicePlan.Catalog.Failed'    = "The service plans of subscription '{0}' could not be read from the subscribed Sku catalog; nothing was changed"
	'LicenseServicePlan.Catalog.Empty'     = "The subscribed Sku catalog lists no service plans for subscription '{0}'; assigning it would enable every plan, so nothing was changed"
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
	'GroupMember.Sync.Add'                 = "Add {0} member(s) to the group '{1}'"
	'GroupMember.Sync.Remove'              = "Remove member '{0}' from the group '{1}'"
	'GroupMember.Sync.ReadFailed'          = "Sync of group '{0}' aborted, no member was changed: reading {1} failed. {2}"
	'GroupMember.Sync.Unresolved'          = "Sync of group '{0}' aborted, no member was changed: the reference identities {1} could not be resolved. Without them every such user still in the group would be removed."
	'GroupMember.Sync.EmptyReference'      = "Sync of group '{0}' aborted, no member was changed: the reference is empty, which would remove all {1} member(s). Pass -AllowEmptyReference to empty the group deliberately."

	'Device.Get'                           = "Get device '{0}'"
	'Device.Get.Failed'                    = "Get device '{0}' failed"
	'Device.List'                          = "List devices with filter '{0}'"
	'Device.ExtensionAttribute.Set'        = "Set {0} on '{1}'"

	'Machine.Get'                          = "Get machine '{0}'"
	'Machine.List'                         = "List machines with filter '{0}'"
	'MachineTag.Add'                       = "Add tag '{0}' to machine '{1}'"
	'MachineTag.Remove'                    = "Remove tag '{0}' from machine '{1}'"

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

	'Request.Retry'                        = "The request failed ({0}); trying again in {1}s (retry {2} of {3})"
	'Batch.Parallel.Throttled'             = "Every pending sub-request waits for its Retry-After; waiting {0}s for the earliest one"
	'Batch.Parallel.Resend'                = "Sub-request of {0} answered {1}; sending it again in {2}s (retry {3} of {4})"
	'Batch.NextLinkRefused'                = "The next link of the page is not followed. {0}"
	'Batch.NextLinkNotUnderService'        = "The link is not under the service URL {0}."
	'Batch.Summary'                        = "The batch run finished with problems. {0}"
	'Batch.Summary.Failed'                 = "{0} of {1} sub-request(s) failed. Affected: {2}."
	'Batch.Summary.More'                   = "{0} and {1} more"
	'Batch.Summary.Resent'                 = "{0} sub-request(s) were throttled or temporarily unavailable and sent again, {1} of them got through; the longest pause was {2} seconds."
	'Batch.Summary.ItemFailed'             = "{0} input item(s) failed; each has its own error record."
	'Batch.ItemFailed'                     = "{0} failed with status {1}: {2}"
	'Batch.ItemFailed.NoStatus'            = "{0} failed: {1}"

	# ---- Request layer (Invoke-EntraRequest): URLs are logged by scheme, host and path only ----------------
	'Request.Execute'                      = 'Executing request: {0} -> {1}'
	'Request.Throttled'                    = 'Throttling: {0}'
	'Request.ThrottledWait'                = 'Request is being throttled for {0} seconds'
	'Request.Failed'                       = 'Request failed: {0} -> {1}'
	'Request.DeltaLinkNoToken'             = 'Delta link returned without a usable token, keeping the previous one: {0}'
	'Request.UriInvalid'                   = 'The request URL is not an absolute URL without user info; the access token is not sent with it.'
	'Request.UriNotHttps'                  = 'The request to {0} is refused before it is sent: the access token goes only over https.'
	'Request.UriForeignHost'               = 'The request to {0} is refused before it is sent: the access token goes only to {1}, the service the connection belongs to. Pass a path relative to the service, or a URL on {1}.'
	'Request.UriRefused'                   = 'Request refused: {0}'

	# ---- Sign-in ------------------------------------------------------------------------------------------
	'Identity.Browser.PrintLink'           = 'Ready to authenticate. Paste the following link into the browser of your choice on the local computer: {0}'
	'Identity.Browser.Authorize'           = 'Opening the sign-in page {0} in the browser; waiting up to {1} seconds for the sign-in.'
	'Identity.Browser.Listener'            = 'Failed to create a local HTTP listener on port {0}. Use -LocalPort to select a different port. {1}'
	'Identity.Browser.Timeout'             = 'The sign-in in the browser was not completed within {0} seconds. Run the command again, or raise PSMicrosoftEntraID.Settings.Authentication.BrowserTimeoutSeconds.'
	'Identity.Browser.Ignored'             = 'A request to the local port did not carry the state of this sign-in and was refused; waiting on for the answer of the sign-in.'
	'Identity.Browser.Refused'             = 'The sign-in was refused: {0}. {1}'
	'Identity.Browser.InvalidClient'       = "The App Registration {0} has not been configured correctly. Ensure it has a 'Mobile and desktop applications' platform with the redirect URI 'http://localhost' (and not a 'Web' platform). {1}"
	'Identity.Browser.Page.Title'          = 'PSMicrosoftEntraID sign-in'
	'Identity.Browser.Page.Done'           = 'Sign-in complete. You can close this window and return to PowerShell.'
	'Identity.Browser.Page.Failed'         = 'The sign-in did not complete. Return to PowerShell for the details; you can close this window.'
	'Identity.DeviceCode.Prompt'           = '{0}'
	'Identity.DeviceCode.SlowDown'         = 'The sign-in endpoint asked to poll more slowly; polling every {0} seconds.'
	'Identity.DeviceCode.Expired'          = 'The device code expired before the sign-in was completed (it was valid for {0} seconds). Run the command again and complete the sign-in in time.'
	'Identity.DeviceCode.Denied'           = 'The sign-in with the device code was declined (access_denied).'
	'Identity.AzToken.Missing'             = 'The object passed with -AzToken carries no access token: its Token property is empty.'
	'Identity.AzToken.NotRenewable'        = 'The token passed with -AzToken has expired and cannot be renewed: only a token of Get-AzAccessToken (Az.Accounts) is renewed, with Az.Accounts loaded. Pass a new token to Connect-PSMicrosoftEntraID -AzToken.'
	'Identity.AzToken.RenewFailed'         = 'The token passed with -AzToken has expired, and Get-AzAccessToken could not renew it: {0} Run Connect-AzAccount again, or pass a new token to Connect-PSMicrosoftEntraID -AzToken.'
	'Identity.AzToken.OtherIdentity'       = 'The token passed with -AzToken has expired, and Get-AzAccessToken returned a token of another identity or tenant than the one it would replace - Az.Accounts is signed in differently by now. The connection keeps its identity and is not renewed; pass a new token to Connect-PSMicrosoftEntraID -AzToken.'
	'Identity.ManagedIdentity.NotFound'    = 'No managed identity was found: IDENTITY_ENDPOINT and IDENTITY_HEADER (App Service, Azure Functions, Automation runbooks, Container Apps) are not both set, and the instance metadata service of an Azure VM did not answer within 2 seconds. A managed identity sign-in works only in Azure, on a resource with a managed identity assigned; Azure Arc is not supported.'
	'Identity.ManagedIdentity.Retry'       = 'The instance metadata service answered {0}; asking again in {1} seconds.'
	'Identity.ManagedIdentity.Request'     = 'Requesting a managed identity token from {0}'
	'Identity.ManagedIdentity.Failed'      = 'The managed identity sign-in failed: {0}'
	'Identity.Password.Disabled'           = 'Signing in with a user name and password (-Credential, the resource owner password credentials flow) is turned off: it bypasses multi-factor authentication and Conditional Access, and Microsoft discourages it. Sign in with the browser or a device code, a certificate or a managed identity instead. To use it anyway, opt in with: Set-PSFConfig -FullName PSMicrosoftEntraID.Settings.Authentication.AllowPasswordFlow -Value $true'
	'Identity.Password.Warning'            = 'Signing in with a user name and password (-Credential): this flow bypasses multi-factor authentication and Conditional Access. Prefer the browser or device code sign-in, a certificate or a managed identity.'
}