# RescueMeAI™ Security Policy

RescueMeAI operates in a high-impact system-recovery context. Security reports should be handled conservatively and should not expose credentials, recovery keys, private machine logs, or exploit details unnecessarily.

## Core security boundaries

- No unrestricted remote shell.
- Outbound-only recovery communications by default.
- Allowlisted command protocol.
- Immutable source commit and integrity validation for remotely queued recovery actions.
- Monotonic command IDs and replay/crash protection.
- Local safety classification is authoritative and may increase risk but never reduce it.
- Destructive operations require separate local human authorization.
- General Terms acceptance does not authorize destructive operations.
- Secrets must not be committed to public or private recovery evidence repositories.
- Private recovery evidence must remain separate from reusable public source code.
- Authentication credentials should be narrowly scoped and short-lived where practical.

## Reporting a security issue

Do not open a public issue containing:

- access tokens or API keys;
- passwords;
- BitLocker or encryption recovery keys;
- private repository contents;
- private recovery reports;
- personal files or personal information;
- weaponized exploit instructions that would materially increase risk before a fix is available.

During the development recovery workflow, use the project's private owner-controlled channel for sensitive security evidence. A dedicated production vulnerability-reporting channel should be established before commercial public launch.

## Supported development state

RescueMeAI is under active development. Security-sensitive components may change rapidly while the recovery agent, provider abstraction, pairing system, integrity model, and local safety engine are stabilized.

## Third-party dependencies

Security issues in Microsoft Windows, WinRE, GitHub, AI providers, drivers, firmware, hardware, or other third-party components may need to be reported to the appropriate vendor as well as evaluated for their effect on RescueMeAI.

## No weakening of safety controls

A contribution or build that disables integrity verification, converts the command queue into arbitrary shell execution, bypasses local destructive authorization, embeds secrets, or silently reduces risk classification must not be represented as an official RescueMeAI release.
