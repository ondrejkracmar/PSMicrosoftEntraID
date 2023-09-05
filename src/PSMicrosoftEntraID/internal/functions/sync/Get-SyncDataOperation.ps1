function Get-SyncDataOperation {
    <#
    .Synopsis
        Short description

    .DESCRIPTION
        Long description

    .EXAMPLE
        Example of how to use this cmdlet

    .EXAMPLE
        Another example of how to use this cmdlet

    .INPUTS
        Inputs to this cmdlet (if any)

    .OUTPUTS
        Output from this cmdlet (if any)

    .NOTES
        General notes

    .COMPONENT
        The component this cmdlet belongs to

    .ROLE
        The role this cmdlet belongs to

    .FUNCTIONALITY
        The functionality that best describes this cmdlet

#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
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

                        [System.Collections.ArrayList]$comparePropertyList = [System.Collections.ArrayList]::new()
                        if ((($compareProperties.GetType()).BaseType).Name -eq 'Array') {
                            $comparePropertyList.AddRange($compareProperties) | Out-Null
                        }
                        if ((($compareProperties.GetType()).BaseType).Name -eq 'Object') {
                            $comparePropertyList.Add($compareProperties) | Out-Null
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