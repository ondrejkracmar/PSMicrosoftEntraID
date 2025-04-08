function Get-FilterObject {
    <#
	.SYNOPSIS
		Filter input object via several crieria.

	.DESCRIPTION
		Filter input object via several crieria.

	.PARAMETER InputObject
		The text to convert.

	.PARAMETER Criteria
		Hashtable of filter criteria

	.EXAMPLE
		PS C:\> Get-FilterObject -InputObject $usageReport -Criteria $criteria

		Filter input object.
#>
    param (
        [Parameter(Mandatory = $true)]
        [array]$InputObject,
        [Parameter(Mandatory = $true)]
        [hashtable]$Criteria
    )

    $filteredObject = $InputObject
    foreach ($criterion in $Criteria.GetEnumerator()) {
        $property = $criterion.Key
        $value = $criterion.Value
        $filteredObject = $filteredObject | Where-Object { $_.$property -eq $value }
    }

    $filteredObject
}