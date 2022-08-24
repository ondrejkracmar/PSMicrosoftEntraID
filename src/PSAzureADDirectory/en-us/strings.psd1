# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
	'ValidIdentityException'     = "This is not valid identity format '{0}'."
	
	'QueryMoreData'              = 'The query contains more data, use recursive to get all!'
	'QueryCommandOutput'         = 'The command executed successfully'
	'QueryBatchCommandOutput'    = 'The batch command'
	'TokenExpired'               = 'Access token has expired.'
	'FailedInvokeRest'           = "Failed to invoke rest method '{0}' from '{1}'."
	'StringAssemblyError'        = "Failed to assemble url '{0}'."
	'FailedGetAssignLicense'     = "Failed to get assign service plan '{0}'."
	'FailedEnableAssignLicense'  = "Failed to enable license '{0}'."
	'FailedDisableAssignLicense' = "Failed to disable license '{0}'. '{0}'."
	'FailedGetUser'              = "Failed to receive Id of  UserPrincipalName '{0}'."
	'FailedGetUsers'             = "Failed to receive uri '{0}'."
	'FailedGetSubscribedSkus'    = "Failed to get subscribed skus."

	'LicenseServicePLan.Enable'  = 'Enable service plans for identity: {0}' # $Identity
	'LicenseServicePLan.Disable' = 'Disable service plans for identity: {0}' # $Identity
	'License.Disable'            = 'Disable license for identity: {0}' # $Identity
}