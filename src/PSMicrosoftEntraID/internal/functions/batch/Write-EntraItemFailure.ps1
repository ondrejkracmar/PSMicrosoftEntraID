function Write-EntraItemFailure {
	<#
	.SYNOPSIS
		Reports an input item that could not be processed: ONE non-terminating error for it.

	.DESCRIPTION
		A cmdlet that takes many input items (pipeline, an array parameter) reports each one that failed as ONE error
		record - its target object is the caller's input object, so -ErrorAction and -ErrorVariable work per item - and
		goes on with the others. There is no warning per item: the run's one summary (Write-EntraBatchSummary) counts
		them. An item reported once in a run is not reported again (a key whose second page failed is still one item).
		With -EnableException no record is written here; the cmdlet throws at the end of the run.
		The reason is cleaned before it is shown: a URL loses its query (skip and delta tokens), a bearer token its
		value. The category follows the status: 401/403 PermissionDenied, 404 ObjectNotFound, 400/405/422
		InvalidArgument, 421 SecurityError, 429 LimitsExceeded, another status or none ConnectionError, unless
		-Category names one.

	.PARAMETER Cmdlet
		The $PSCmdlet of the public cmdlet; the error is written in its name.

	.PARAMETER Report
		The run's report.

	.PARAMETER Target
		The caller's input object.

	.PARAMETER Label
		What failed, for the message and the summary: an id or a name. Never a link or a token.

	.PARAMETER Status
		The HTTP status of the failure, 0 when there is none.

	.PARAMETER Reason
		The failure message; it is cleaned of queries and tokens.

	.PARAMETER Category
		The error category, instead of the one the status gives.

	.PARAMETER ErrorId
		The FullyQualifiedErrorId of the record.

	.PARAMETER EnableException
		Record only; the cmdlet throws at the end of the run.

	.EXAMPLE
		PS C:\> Write-EntraItemFailure -Cmdlet $PSCmdlet -Report $report -Target $group -Label $group.Id -Status $page.Status -Reason $page.Error

		Writes one error for the group and counts it for the summary.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet,

		[Parameter(Mandatory = $true)]
		[hashtable]
		$Report,

		[AllowNull()]
		[object]
		$Target,

		[Parameter(Mandatory = $true)]
		[string]
		$Label,

		[int]
		$Status,

		[AllowEmptyString()]
		[AllowNull()]
		[string]
		$Reason,

		[System.Management.Automation.ErrorCategory]
		$Category,

		[string]
		$ErrorId = 'PSMicrosoftEntraID_ItemFailed',

		[bool]
		$EnableException
	)

	if (-not $Report.ContainsKey('Items.Reported')) { $Report['Items.Reported'] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase) }
	# One record per input item and run.
	if (-not $Report['Items.Reported'].Add($Label)) { return }

	# No query of a link (skip and delta tokens) and no bearer token in a message.
	[string] $text = [string]$Reason
	$text = [regex]::Replace($text, '(https?://[^\s?#"'']+)[?#][^\s"'']*', '$1')
	$text = [regex]::Replace($text, '(?i)(bearer\s+)[A-Za-z0-9\-\._~\+/]+=*', '$1***')

	if (-not $PSBoundParameters.ContainsKey('Category')) {
		$Category = switch ($Status) {
			{ $_ -in 401, 403 } { 'PermissionDenied'; break }
			404 { 'ObjectNotFound'; break }
			{ $_ -in 400, 405, 422 } { 'InvalidArgument'; break }
			421 { 'SecurityError'; break }
			429 { 'LimitsExceeded'; break }
			default { 'ConnectionError' }
		}
	}
	[string] $message = if ($Status) { (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.ItemFailed') -f $Label, $Status, $text }
	else { (Get-PSFLocalizedString -Module 'PSMicrosoftEntraID' -Name 'Batch.ItemFailed.NoStatus') -f $Label, $text }
	Write-PSFMessage -Level Debug -Message $message -FunctionName $Cmdlet.MyInvocation.MyCommand.Name
	if ($EnableException) { return }
	$record = [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($message), $ErrorId, $Category, $Target)
	$Cmdlet.WriteError($record)
}
