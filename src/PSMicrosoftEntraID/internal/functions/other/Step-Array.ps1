function Step-Array {
    <#
    .SYNOPSIS
        Slice a PowerShell array into groups of smaller arrays.

    .DESCRIPTION
        Slice a PowerShell array into groups of smaller arrays.

        Every chunk is written to the pipeline as ONE array object, so collect the
        output with @() and do not cast it: a cast to [string[]] turns each chunk into
        a single space-joined string. No empty chunk is written - an exact multiple of
        Size yields exactly Count / Size chunks.

    .PARAMETER Item
        Items to slice, from the pipeline or as an argument.

    .PARAMETER Size
        Maximum number of items in one chunk.

    .EXAMPLE
        PS C:\> $chunks = @($urlList | Step-Array -Size 20)

		Slice the list into chunks of at most 20 items; each $chunks[n] is an array.

#>
    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $True)]
        [object[]] $Item,
        [ValidateRange(1, [int]::MaxValue)]
        [int] $Size = 10
    )
    begin {
        [System.Collections.Generic.List[object]] $buffer = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($itemValue in $Item) { $buffer.Add($itemValue) }
    }
    end {
        for ([int] $offset = 0; $offset -lt $buffer.Count; $offset += $Size) {
            # The leading comma keeps the chunk one object instead of unrolling it.
            , $buffer.GetRange($offset, [math]::Min($Size, $buffer.Count - $offset)).ToArray()
        }
    }
}
