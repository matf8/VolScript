# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Older releases | No |

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Use [GitHub Security Advisories](https://github.com/matf8/VolScript/security/advisories/new) (**Report a vulnerability**) and include:

- What you found
- Steps to reproduce
- Windows and PowerShell version (`$PSVersionTable.PSVersion`)
- VolScript version (release tag or commit)

I'll respond as soon as I can — usually within a few days.

## Scope

**In scope**

- Hijacking VolScript behavior without the user's consent
- Privilege escalation beyond the running user
- Unsafe config or path handling that leads to arbitrary code execution

**Out of scope**

- Global hotkeys working as designed (VolScript listens system-wide on purpose)
- Games or anti-cheat blocking keyboard hooks — report those as [compatibility issues](https://github.com/matf8/VolScript/issues/new?template=compatibility.yml)
- Running VolScript from untrusted folders — only use a path you trust

## Notes

VolScript runs locally, does not send data over the network, and does not require admin rights for normal use. Download releases only from [GitHub Releases](https://github.com/matf8/VolScript/releases).
