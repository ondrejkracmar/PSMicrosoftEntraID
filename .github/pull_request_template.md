## Summary

<!-- One change, one purpose. What changed and why, in two to five lines. -->

## Verified

<!-- What was run and the result. "Tests pass" without numbers does not count. -->

- [ ] `Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1` is clean
- [ ] Pester suite (`src/tests/pester.ps1` or `Invoke-Pester -Path ./tests`): `<passed>` passed, `<failed>` failed, `<skipped>` skipped
- [ ] `Test-CodexVaultStandardCompliance` reports no Error
- [ ] Manual steps, if any:

## Compatibility

<!-- Public functions, parameters, output types, configuration keys, file formats. -->

- [ ] No breaking change
- [ ] Breaking change (major version): what, why, and the migration note in the changelog

## Checklist

- [ ] `changelog.md` updated under Unreleased
- [ ] Documentation updated where behaviour changed
- [ ] Commits and this description carry no AI attribution; the person running the agent is the author
