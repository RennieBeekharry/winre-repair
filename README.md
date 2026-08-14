# RescueMeAI™

**AI-assisted Windows recovery with local safety controls.**

RescueMeAI is a recovery system designed to diagnose and repair Windows problems using the least-destructive, evidence-driven approach first. It combines local recovery tooling, validated command execution, recovery evidence, and optional AI-assisted diagnosis while keeping destructive authorization physically at the recovery computer.

> **Repository transition:** the GitHub repository is currently still named `winre-repair` because an active recovery machine depends on that URL. The product/app name is now **RescueMeAI™**. The repository and legacy local paths can be migrated after the active recovery channel is stable without breaking the machine currently under repair.

## Core principles

1. **Safety first.** Read-only and reversible actions are preferred before high-impact recovery.
2. **Least destructive first.** Reset, reinstall, formatting, and partition changes are last-resort operations.
3. **Evidence before action.** Recovery decisions should be based on logs, system state, validation, and prior outcomes.
4. **Fail closed.** Integrity or safety validation failures stop execution.
5. **Local destructive authorization.** AI, GitHub, a remote relay, or another backend cannot remotely authorize a destructive action.
6. **Minimal manual work.** Safe routine recovery should be automated where practical.
7. **Durable recovery memory.** Machine state and recovery history belong in a recovery manifest/evidence store rather than relying on chat memory.

## RescueMeAI result protocol

Every recovery action ends with one result:

- `[PASS]` — successful completion; user replies `pass`.
- `[FAIL]` — required step failed or validation stopped execution; user replies `fail`.
- `[WARNING]` — partial completion, interruption, authorization refusal, or review required; user replies `warning`.

## Terms acceptance

Before RescueMeAI begins normal recovery operation, the current Terms must be accepted locally.

The application displays the material recovery risks and requires the user to type exactly:

```text
ACCEPT
```

Acceptance is versioned and stored locally so the same Terms are not repeatedly presented. A new material Terms version can require acceptance again.

**Important:** typing `ACCEPT` agrees to the general RescueMeAI legal terms. It does **not** authorize a destructive recovery operation. Destructive actions use a separate action-specific local authorization phrase.

See:

- `TERMS_OF_USE.md`
- `PRIVACY_POLICY.md`
- `DISCLAIMER_AND_RISK_NOTICE.md`
- `LICENSE.md`
- `TRADEMARKS.md`

## Recovery safety classes

RescueMeAI classifies actions as:

- `READ_ONLY`
- `REPAIR_WRITE`
- `DESTRUCTIVE`

The local safety engine may increase an action's risk classification but may never decrease it.

Examples of destructive operations include disk cleaning, formatting, repartitioning, destructive image application, reset/reinstall, destructive BCD or registry deletion, and comparable high-impact changes. These operations require separate explicit local authorization and cannot be approved solely through the remote command channel.

## AI Recovery agent

The development architecture uses an outbound-only recovery agent:

```text
Recovery PC
    -> authenticated outbound HTTPS
    -> recovery evidence/control backend
    -> validated allowlisted command
    -> local safety gate
    -> recovery tool
    -> result/evidence
```

There is no intended inbound remote shell, port forwarding, or arbitrary remote command execution.

The current development backend uses GitHub. The architecture is intended to allow a dedicated RescueMeAI relay/provider to replace GitHub later.

## Current active recovery

The repository is presently being used to recover a Windows 11 system experiencing `INACCESSIBLE_BOOT_DEVICE (0x7B)`.

Machine-specific recovery history belongs in the configured private evidence repository and must not be used to narrow the reusable RescueMeAI product to one computer model or one failure mode.

## Legacy compatibility path

The active recovery session currently uses:

```text
C:\WinRERepair
```

This is temporarily retained as a compatibility path so an in-progress recovery is not broken by a cosmetic rename. New production installations are intended to use a RescueMeAI-branded data path such as:

```text
C:\RescueMeAI
```

Migration must preserve existing logs, authorization journals, recovery evidence, and rollback files.

## Privacy

RescueMeAI is designed to collect only recovery-relevant technical evidence. Passwords, API secrets, BitLocker recovery keys, and personal-file contents are not intended to be routine telemetry. See `PRIVACY_POLICY.md` for the current data-handling model.

## Licence

RescueMeAI is currently distributed under the proprietary source-available licence in `LICENSE.md`. Source availability does not grant unrestricted redistribution or trademark rights.

## Trademark

`RescueMeAI™` is used as an unregistered project mark. Do not use the `®` symbol unless the mark is formally registered in the applicable jurisdiction. See `TRADEMARKS.md`.

Microsoft, Windows, WinRE, GitHub, OpenAI, ChatGPT, Intel, and other third-party names are the property of their respective owners. RescueMeAI is not represented as being sponsored or endorsed by those parties unless expressly stated.

## Disclaimer

Computer recovery carries real risk. RescueMeAI is provided subject to the warranty disclaimer, assumption-of-risk, release, and limitation-of-liability terms in the project legal documents. Mandatory rights that cannot legally be waived remain unaffected.
