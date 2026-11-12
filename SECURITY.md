# Security

## Reporting a vulnerability

Report a suspected vulnerability privately through GitHub's private vulnerability reporting: **Security → Report a vulnerability** on [github.com/ondrejkracmar/PSMicrosoftEntraID](https://github.com/ondrejkracmar/PSMicrosoftEntraID/security/advisories/new). Do not open a public issue for a security problem. You get an acknowledgement within five working days and a fix or a mitigation plan after triage.

## What this repository guarantees

- **No secrets in the repository.** Tokens, passwords and connection strings are resolved at call time (SecretManagement, Key Vault, environment variables). The compliance gate (`NoHardcodedSecretAssignment`) and PSScriptAnalyzer fail a change that hardcodes one, and secret values are never logged.
- **No code-injection surface.** `Invoke-Expression` is forbidden (`NoInvokeExpression`); input is validated by parameter attributes, never by string concatenation into commands.
- **HTTPS and authentication by default** for any endpoint the code exposes or calls; an opt-out is explicit and documented.
- **Supply chain.** Dependencies are pinned in the build scripts and scanned for known vulnerabilities in CI; every published package carries a changelog generated from the commit history. Signing requirements for public distribution are stated in the release runbook (`docs/runbooks/release.md`).

## Supported versions

Only the latest released minor version receives security fixes. Upgrade before reporting an issue in an older one.
