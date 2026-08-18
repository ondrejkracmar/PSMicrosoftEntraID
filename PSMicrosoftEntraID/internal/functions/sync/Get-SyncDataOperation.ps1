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

    .PARAMETER EnableException
        This parameters disables user-friendly warnings and enables the throwing of exceptions. This is less user frien
        dly, but allows catching exceptions in calling scripts.

    .PARAMETER WhatIf
        Enables the function to simulate what it will do instead of actually executing.

    .PARAMETER Confirm
        Prompts for confirmation before the command makes a change. -Confirm:$false
        suppresses that prompt.

        Left unbound, the decision belongs to this command's ConfirmImpact and the
        session ConfirmPreference, which is the PowerShell default behaviour.

    .EXAMPLE
            PS C:\> Get-SyncDataOperation -ReferenceObjectList $referenceMemberList -DiferenceObjectList $differenceMemberList -MatchProperty Id -DiferenceObjectUniqueKeyName Id

            Get sync operation

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'The rule fires on the nested New-Result factory, which builds a result object and changes nothing. The outer function is a Get that computes a diff in memory.')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Justification = 'Compare-Hashtable and New-Result are function-local helpers called positionally within the same screenful of code; naming their two arguments adds noise, not safety.')]
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true, PositionalBinding = $false, HelpUri = 'http://www.microsoft.com/', ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 0, ParameterSetName = 'Default')]
        [AllowNull()]
        [Alias("Rol")]
        [Array]
        $ReferenceObjectList,
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, ValueFromRemainingArguments = $false, Position = 1, ParameterSetName = 'Default')]
        [AllowNull()]
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

        $compareList = Compare-Object -ReferenceObject @($ReferenceObjectList | Select-Object) -DifferenceObject @($DiferenceObjectList | Select-Object) -Property $MatchProperty -IncludeEqual

    }
    Process {
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            [System.Collections.ArrayList]$changeList = [System.Collections.ArrayList]::new()
            foreach ($compareItem in $compareList) {
                switch ($compareItem.SideIndicator) {
                    '==' {
                        $differenceObject = ($DiferenceObjectList.Where({ $_.$($MatchProperty) -eq $compareItem.$($MatchProperty) })[0]) | ConvertTo-HashtableFromPsCustomObject
                        $referenceObject = ($ReferenceObjectList.Where({ $_.$($MatchProperty) -eq $compareItem.$($MatchProperty) })[0]) | ConvertTo-HashtableFromPsCustomObject
                        $compareProperties = Compare-Hashtable $referenceObject $differenceObject

                        # Compare-Hashtable emits NOTHING when the two sides are identical,
                        # and identical is the ordinary case here - every member that is
                        # already in both groups lands in this branch. Reaching straight
                        # for .GetType() on that result turned "nothing to do" into
                        # "You cannot call a method on a null-valued expression", so the
                        # branch could only survive as long as it was unreachable.
                        [System.Collections.ArrayList]$comparePropertyList = [System.Collections.ArrayList]::new()
                        foreach ($compareProperty in @($compareProperties)) {
                            if ($null -ne $compareProperty) {
                                [void]$comparePropertyList.Add($compareProperty)
                            }
                        }

                        $propertyHash = @{}
                        foreach ($property in $comparePropertyList) {
                            if ($property.side -eq '!=') {
                                [void]($propertyHash.Add($property.Key, $property.lvalue))
                            }
                        }

                        if ($propertyHash.Count -gt 0) {
                            $changeObject = [pscustomobject]@{
                                Crud          = 'Update'
                                IdentityValue = $differenceObject.$($DiferenceObjectUniqueKeyName)
                                IdentityName  = $DiferenceObjectUniqueKeyName
                                Fields        = $propertyHash

                            }
                            [void]($changeList.Add($changeObject))
                        }
                    }
                    '<=' {
                        $referenceObject = ($ReferenceObjectList.Where({ $_.$($MatchProperty) -eq $compareItem.$($MatchProperty) })[0]) | ConvertTo-HashtableFromPsCustomObject
                        $propertyHash = @{}

                        $changeObject = [pscustomobject]@{
                            Crud          = 'Create'
                            IdentityValue = "-1"
                            IdentityName  = $DiferenceObjectUniqueKeyName
                            Fields        = $referenceObject
                        }
                        [void]($changeList.Add($changeObject))
                    }
                    '=>' {
                        $differenceObject = ($DiferenceObjectList.Where({ $_.$($MatchProperty) -eq $compareItem.$($MatchProperty) })[0]) | ConvertTo-HashtableFromPsCustomObject
                        $changeObject = [pscustomobject]@{
                            Crud          = 'Delete'
                            IdentityValue = $differenceObject.$($DiferenceObjectUniqueKeyName)
                            IdentityName  = $DiferenceObjectUniqueKeyName
                            Fields        = @{}
                        }
                        [void]($changeList.Add($changeObject))
                    }
                    Default {}
                }
            }
        }
    }
    End {
        $changeList
    }
}
