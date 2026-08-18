[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
$moduleRoot = (Resolve-Path (Join-Path $global:testroot '..' 'PSMicrosoftEntraID')).Path

# What ships is NOT what this suite imports.
#
# build/vsts-build.ps1 concatenates the module into a SINGLE PSMicrosoftEntraID.psm1 -
# the files preimport.ps1 names, then internal/functions, then functions, then the files
# postimport.ps1 names - and the manifest loads that compiled form by default
# (Import.IndividualFiles is $false). This suite imports the individual files instead, so
# it can be entirely green while the module published to the gallery does not import at
# all.
#
# Which is exactly what happened. Three files began with
#
#     using namespace PSMicrosoftEntraID.Users
#
# legal at the top of a file, and a parse error the moment that file is appended after
# another one. The compiled module exported ZERO commands. Nothing here could see it,
# because nothing here ever looked at the compiled form.
Describe "Verifying the module survives compilation" {

    BeforeAll {
        $script:moduleRoot = (Resolve-Path (Join-Path $global:testroot '..' 'PSMicrosoftEntraID')).Path

        # The concatenation includes internal/classes/*.ps1, whose class members are typed
        # with library types. PowerShell resolves those at PARSE time, so without the
        # assembly loaded the parse fails on a missing type rather than on real syntax -
        # and this test would then report the module as broken when it is not. Stated
        # here rather than inherited from whatever imported the module first.
        if (-not ('PSMicrosoftEntraID.FederationProvider' -as [type])) {
            Add-Type -Path (Join-Path $script:moduleRoot 'bin' 'PSMicrosoftEntraID.dll') -ErrorAction Stop
        }

        # Same source of truth the build uses: these scripts EMIT the file paths, they do
        # not load anything themselves.
        $script:preImportPaths = @(& (Join-Path $script:moduleRoot 'internal' 'scripts' 'preimport.ps1')) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $script:postImportPaths = @(& (Join-Path $script:moduleRoot 'internal' 'scripts' 'postimport.ps1')) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

        $script:functionFiles = @(
            Get-ChildItem -Path (Join-Path $script:moduleRoot 'internal' 'functions') -Recurse -File -Filter '*.ps1'
            Get-ChildItem -Path (Join-Path $script:moduleRoot 'functions') -Recurse -File -Filter '*.ps1'
        )
    }

    It "every path preimport.ps1 and postimport.ps1 emit resolves on this platform" {
        # These are written with literal backslashes. On Windows that is a separator; on
        # the Linux build agent and on macOS it is an ordinary character in a file name,
        # so a path that resolves here can silently name nothing there - and the build
        # reads these files by path. The cross-platform legs of the pipeline are what
        # make this test worth having.
        $missing = @($script:preImportPaths + $script:postImportPaths | Where-Object { -not (Test-Path -LiteralPath $_) })
        if ($missing.Count -gt 0) {
            throw "Paths emitted by pre/postimport that do not resolve on $([System.Environment]::OSVersion.Platform): $($missing -join '; ')"
        }
    }

    It "concatenates into something that parses" {
        # Read via the provider-resolved path, not the emitted string. The emitted paths
        # carry literal backslashes; PowerShell's Test-Path normalises them on Linux and
        # macOS, System.IO does not - so the guard said the file exists and ReadAllText
        # then threw FileNotFoundException for 'src/PSMicrosoftEntraID\bin\assembly.ps1'
        # on the Linux build agent.
        $sources = @(
            foreach ($path in $script:preImportPaths) {
                if (Test-Path -LiteralPath $path -PathType Leaf) { [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $path).ProviderPath) }
            }
            foreach ($file in $script:functionFiles) { [System.IO.File]::ReadAllText($file.FullName) }
            foreach ($path in $script:postImportPaths) {
                if (Test-Path -LiteralPath $path -PathType Leaf) { [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $path).ProviderPath) }
            }
        )

        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput(($sources -join "`r`n"), [ref]$null, [ref]$errors)

        if ($errors) {
            $detail = ($errors | Select-Object -First 5 | ForEach-Object { "line $($_.Extent.StartLineNumber): $($_.Message)" }) -join '; '
            throw "The compiled module does not parse - this is what gets published: $detail"
        }
    }

    It "has no file-scope 'using' statement outside the first file" {
        # Reported separately from the parse test on purpose: a parse failure names a line
        # in a generated file nobody has a copy of, while this names the source file to
        # edit. Fully qualify the type instead - the other 57 function files already do.
        $offenders = foreach ($file in $script:functionFiles) {
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$null)
            if ($ast.UsingStatements.Count -gt 0) {
                '{0} ({1})' -f $file.Name, (($ast.UsingStatements | ForEach-Object { $_.Extent.Text }) -join ', ')
            }
        }

        if ($offenders) {
            throw "A 'using' statement has to be the first statement in a script, so it cannot survive concatenation: $($offenders -join '; ')"
        }
    }
}
