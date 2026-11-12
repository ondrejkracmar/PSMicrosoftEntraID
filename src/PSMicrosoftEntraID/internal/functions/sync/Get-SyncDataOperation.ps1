function Get-SyncDataOperation {
    <#
	.SYNOPSIS
		Disable user's license

	.DESCRIPTION
		Disable user's Office 365 subscription

	.PARAMETER ReferenceObjectList
        UserPrincipalName, Mail or Id of the user attribute populated in tenant/directory.

	.PARAMETER DiferenceObjectList
		Office 365 product GUID is identified using a GUID of subscribedSku.

    .PARAMETER MatchProperty
        Friendly name Office 365 product of subscribedSku.

    .PARAMETER DiferenceObjectUniqueKeyName
        Friendly name Office 365 product of subscribedSku.

    .EXAMPLE
            PS C:\> Get-SyncDataOperation -ReferenceObjectList $referenceMemberList -DiferenceObjectList $differenceMemberList -MatchProperty Id -DiferenceObjectUniqueKeyName Id

            Get sync operation

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The rule fires on the nested New-Result factory, which builds a result object and changes nothing. The outer function is a Get that computes a diff in memory.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Justification = 'Compare-Hashtable and New-Result are function-local helpers called positionally within the same screenful of code; naming their two arguments adds noise, not safety.')]
    [CmdletBinding(DefaultParameterSetName = 'Default', PositionalBinding = $false)]
    [Alias()]
    [OutputType([pscustomobject])]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 0, ParameterSetName = 'Default')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Alias("Rol")]
        [Array]
        $ReferenceObjectList,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 1, ParameterSetName = 'Default')]
        [AllowNull()]
        [AllowEmptyCollection()]
        [Alias("Dol")]
        [Array]
        $DiferenceObjectList,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 3, ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [String]
        $MatchProperty,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 4, ParameterSetName = 'Default')]
        [AllowNull()]
        [ValidateNotNullOrEmpty()]
        [String]
        $DiferenceObjectUniqueKeyName
    )

    Begin {
        function ConvertTo-HashtableFromPsCustomObject {
            param (
                [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                [object[]]$psCustomObject
            );

            process {
                foreach ($myPsObject in $psCustomObject) {
                    $output = @{};
                    $myPsObject | Get-Member -MemberType *Property | ForEach-Object {
                        $output.($_.name) = $myPsObject.($_.name);
                    }
                    $output;
                }
            }
        }
        function Compare-Hashtable {
            <#
            .SYNOPSIS
                Compare two Hashtable and returns an array of differences.

            .DESCRIPTION
                The Compare-Hashtable function computes differences between two Hashtables. Results are returned as
                an array of objects with the properties: "key" (the name of the key that caused a difference),
                "side" (one of "<=", "!=" or "=>"), "lvalue" an "rvalue" (resp. the left and right value
                associated with the key).

            .PARAMETER left
                The left hand side Hashtable to compare.

            .PARAMETER right
                The right hand side Hashtable to compare.

            .EXAMPLE
                Returns a difference for ("3 <="), c (3 "!=" 4) and e ("=>" 5).

                Compare-Hashtable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5}

            .EXAMPLE
                Returns a difference for a ("3 <="), c (3 "!=" 4), e ("=>" 5) and g (6 "<=").

                $left = @{ a = 1; b = 2; c = 3; f = $Null; g = 6 }
                $right = @{ b = 2; c = 4; e = 5; f = $Null; g = $Null }

                Compare-Hashtable $left $right

        #>
            [CmdletBinding()]
            param ([Parameter(Mandatory = $true)]
                [Hashtable]$Left,
                [Parameter(Mandatory = $true)]
                [Hashtable]$Right
            )

            function New-Result($Key, $LValue, $Side, $RValue) {
                New-Object -Type PSObject -Property @{
                    key    = $Key
                    lvalue = $LValue
                    rvalue = $RValue
                    side   = $Side
                }
            }
            [Object[]]$Results = $Left.Keys | ForEach-Object {
                if ($Left.ContainsKey($_) -and !$Right.ContainsKey($_)) {
                    New-Result $_ $Left[$_] "<=" $Null
                }
                else {
                    $LValue, $RValue = $Left[$_], $Right[$_]
                    if ($LValue -ne $RValue) {
                        New-Result $_ $LValue "!=" $RValue
                    }
                }
            }
            $Results += $Right.Keys | ForEach-Object {
                if (!$Left.ContainsKey($_) -and $Right.ContainsKey($_)) {
                    New-Result $_ $Null "=>" $Right[$_]
                }
            }
            $Results
        }

        # Index both sides by the match key once. The old code ran Compare-Object and then,
        # for EVERY compared item, scanned the whole other list with .Where() to find its
        # partner - O(n*m), minutes for a few thousand members. Lookups are now O(1).
        # Case-insensitive, as Compare-Object was; the first object per key wins, as
        # .Where()[0] did, so a duplicate no longer produces a second operation.
        function ConvertTo-KeyIndex ([object[]] $List, [string] $KeyProperty) {
            $index = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($item in $List) {
                if ($null -eq $item) { continue }
                [string] $key = $item.$($KeyProperty)
                if (-not $index.Contains($key)) { $index.Add($key, $item) }
            }
            , $index
        }
    }
    Process {
        # No ShouldProcess here: this computes a diff in memory. Gated on ShouldProcess it
        # returned NOTHING under the caller's -WhatIf - so Sync-PSEntraIDGroupMember
        # -WhatIf reported that nothing would change - and prompted under -Confirm.
        $referenceIndex = ConvertTo-KeyIndex -List @($ReferenceObjectList) -KeyProperty $MatchProperty
        $differenceIndex = ConvertTo-KeyIndex -List @($DiferenceObjectList) -KeyProperty $MatchProperty

        foreach ($key in $referenceIndex.Keys) {
            $referenceObject = $referenceIndex[$key] | ConvertTo-HashtableFromPsCustomObject
            if ($differenceIndex.Contains($key)) {
                $differenceObject = $differenceIndex[$key] | ConvertTo-HashtableFromPsCustomObject
                $compareProperties = Compare-Hashtable $referenceObject $differenceObject

                # Compare-Hashtable emits NOTHING when the two sides are identical, and
                # identical is the ordinary case - every member already in both groups.
                $propertyHash = @{}
                foreach ($property in @($compareProperties)) {
                    if ($null -ne $property -and $property.side -eq '!=') {
                        [void]($propertyHash.Add($property.Key, $property.lvalue))
                    }
                }
                if ($propertyHash.Count -gt 0) {
                    [pscustomobject]@{
                        Crud          = 'Update'
                        IdentityValue = $differenceObject.$($DiferenceObjectUniqueKeyName)
                        IdentityName  = $DiferenceObjectUniqueKeyName
                        Fields        = $propertyHash
                    }
                }
            }
            else {
                [pscustomobject]@{
                    Crud          = 'Create'
                    IdentityValue = "-1"
                    IdentityName  = $DiferenceObjectUniqueKeyName
                    Fields        = $referenceObject
                }
            }
        }
        foreach ($key in $differenceIndex.Keys) {
            if (-not $referenceIndex.Contains($key)) {
                [pscustomobject]@{
                    Crud          = 'Delete'
                    IdentityValue = $differenceIndex[$key].$($DiferenceObjectUniqueKeyName)
                    IdentityName  = $DiferenceObjectUniqueKeyName
                    Fields        = @{}
                }
            }
        }
    }
    End {
    }
}
