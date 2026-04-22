
# List of functions that should be ignored
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$global:FunctionHelpTestExceptions = @(
    # Internal helpers that are dot-sourced into the module and exposed when the
    # .psm1 is force-imported by the test harness, but are not part of the
    # public FunctionsToExport surface in PSMicrosoftEntraID.psd1.
    'Connect-EntraService'
    'Connect-ServiceAzToken'
    'ConvertFrom-RestAdministrativeUnit'
    'ConvertFrom-RestGroup'
    'ConvertFrom-RestGroupLicenseDetail'
    'ConvertFrom-RestInvitation'
    'ConvertFrom-RestUserLicenseDetail'
    'ConvertFrom-GroupLicenseDetailSubscriptionSku'
    'ConvertTo-ODataFilterString'
    'Resolve-PSEntraIDConfirmPreference'
    'Resolve-PSEntraIDLicenseIdentifierPath'
    'Test-PSMicrosoftEntraIDBatchRequest'
    'Update-PSEntraIDLicenseIdentifierCache'
    'Update-PSEntraIDSubscribedLicenseDisplayName'

    # Connect-PSMicrosoftEntraID has a multi-parameter-set TenantID parameter that
    # is mandatory in some sets and optional (with default 'organizations') in
    # others. Get-Help reports a single Required value that doesn't match the
    # IsMandatory of every set, which the parameter Mandatory test cannot
    # represent.
    'Connect-PSMicrosoftEntraID'
)

<#
  List of arrayed enumerations. These need to be treated differently. Add full name.
  Example:

  "Sqlcollaborative.Dbatools.Connection.ManagementConnectionType[]"
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$global:HelpTestEnumeratedArrays = @(
	
)

<#
  Some types on parameters just fail their validation no matter what.
  For those it becomes possible to skip them, by adding them to this hashtable.
  Add by following this convention: <command name> = @(<list of parameter names>)
  Example:

  "Get-DbaCmObject"       = @("DoNotUse")
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$global:HelpTestSkipParameterType = @{
    
}
