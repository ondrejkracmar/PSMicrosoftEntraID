[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$moduleRoot = (Resolve-Path (Join-Path $global:testroot '..' 'PSMicrosoftEntraID')).Path

# Every user-facing message in this module is a key in en-us/strings.psd1, referenced from
# code by name. Nothing verifies the two sides agree: a renamed or mistyped key does not
# break the build, it produces an EMPTY message at runtime, in the one code path that uses
# it. That is invisible until a customer quotes a blank error back at you.
#
# Two real defects were in the file when this test was written - a value ending in a stray
# apostrophe, and 'Get xontact' - neither of which any other check could see.
Describe "Verifying localized strings" {

    BeforeAll {
        # Resolved again here on purpose: variables assigned at file scope belong to
        # Pester's discovery pass and are not visible inside BeforeAll, which runs later.
        $moduleRoot = (Resolve-Path (Join-Path $global:testroot '..' 'PSMicrosoftEntraID')).Path

        $script:stringsPath = Join-Path $moduleRoot 'en-us' 'strings.psd1'
        $script:strings = Import-PowerShellDataFile -Path $script:stringsPath

        # Only real code. Comment-based help contains example invocations with made-up
        # keys ('Some.Action' in Resolve-PSEntraIDConfirmPreference), and failing on a
        # documentation example would teach people to delete the examples.
        $script:referenced = @{}
        $files = Get-ChildItem -Path (Join-Path $moduleRoot 'functions'), (Join-Path $moduleRoot 'internal' 'functions') -Recurse -Filter '*.ps1'
        foreach ($file in $files) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)

            # Walk command AST rather than the raw text, so a key inside a help block or a
            # comment is never picked up.
            $commands = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)
            foreach ($command in $commands) {
                $elements = $command.CommandElements
                for ($i = 0; $i -lt $elements.Count - 1; $i++) {
                    $element = $elements[$i]
                    if ($element -isnot [System.Management.Automation.Language.CommandParameterAst]) { continue }
                    if ($element.ParameterName -notin 'ActionString', 'String', 'Name') { continue }

                    $value = $elements[$i + 1]
                    if ($value -isnot [System.Management.Automation.Language.StringConstantExpressionAst]) { continue }

                    # -Name is used by Get-PSFLocalizedString but also by unrelated cmdlets
                    # (Get-PSFConfigValue, Register-EntraService, ...). Only count it when
                    # the command really is the localisation lookup.
                    if ($element.ParameterName -eq 'Name' -and $command.GetCommandName() -ne 'Get-PSFLocalizedString') { continue }

                    if (-not $script:referenced.ContainsKey($value.Value)) {
                        $script:referenced[$value.Value] = $file.Name
                    }
                }
            }
        }
    }

    It "the strings file parses" {
        $script:strings | Should -Not -BeNullOrEmpty
        $script:strings.Keys.Count | Should -BeGreaterThan 0
    }

    It "every key referenced from code is defined" {
        $missing = @($script:referenced.Keys | Where-Object { -not $script:strings.ContainsKey($_) } |
                ForEach-Object { "$_ (used in $($script:referenced[$_]))" })

        if ($missing.Count -gt 0) {
            throw "Referenced but not defined in en-us/strings.psd1: $($missing -join '; ')"
        }
    }

    It "no value is empty" {
        $empty = @($script:strings.Keys | Where-Object { [string]::IsNullOrWhiteSpace([string]$script:strings[$_]) })
        if ($empty.Count -gt 0) { throw "Defined with an empty value: $($empty -join ', ')" }
    }

    It "no value has an unbalanced apostrophe" {
        # These messages quote identities - "Get user '{0}'" - so apostrophes come in
        # pairs. An odd count means one was typed by accident, which is exactly the
        # 'Announcements'' defect this test was written for.
        $bad = @(
            foreach ($key in $script:strings.Keys) {
                $value = [string]$script:strings[$key]
                $count = @($value.ToCharArray() | Where-Object { $_ -eq [char]39 }).Count
                if ($count % 2 -ne 0) { "$key -> $value" }
            }
        )
        if ($bad.Count -gt 0) { throw "Unbalanced apostrophe: $($bad -join '; ')" }
    }

    It "no value has an unbalanced format placeholder brace" {
        # PSFramework runs these through string formatting, where a lone '{' is a
        # malformed placeholder and throws FormatException at the point of use.
        $bad = @(
            foreach ($key in $script:strings.Keys) {
                $value = [string]$script:strings[$key]
                $open = @($value.ToCharArray() | Where-Object { $_ -eq '{' }).Count
                $close = @($value.ToCharArray() | Where-Object { $_ -eq '}' }).Count
                if ($open -ne $close) { "$key -> $value" }
            }
        )
        if ($bad.Count -gt 0) { throw "Unbalanced brace: $($bad -join '; ')" }
    }
}
