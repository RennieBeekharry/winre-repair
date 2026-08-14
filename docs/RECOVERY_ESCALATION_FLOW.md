# RescueMeAI Recovery Escalation Flow

Version: 2026-08-14.1

## Principle

RescueMeAI must always prefer the least invasive action that can reasonably restore a healthy, bootable Windows system. It must collect evidence before writing, preserve rollback paths where possible, and escalate only when the prior tier has been exhausted or is clearly inapplicable.

The default order is:

1. Safety and hardware triage
2. Evidence and failure classification
3. Backup readiness
4. Recovery-source readiness
5. Read-only Windows diagnostics
6. Reversible targeted repair
7. Offline component/system-file repair
8. Boot/recovery-environment repair
9. Restore/rollback options
10. Repair reinstall / refresh-style recovery where available
11. Reset while preserving personal files
12. Clean reinstall only as final escalation

## Gate 0 - Session Safety

Before any repair:
- Identify Windows installation(s), firmware mode, disk layout, BitLocker/encryption state, and external drives.
- Confirm the target Windows installation and never infer a destructive target by disk number alone.
- Establish logging, command journaling, replay protection, and local authorization policy.
- Destructive operations require separate explicit local authorization.

## Tier 1 - Hardware Triage

Run non-destructive checks first:
- Storage visibility and basic health indicators
- Memory diagnostics when symptoms justify it
- CPU/thermal/power indicators when available
- Filesystem readability
- Controller/device enumeration
- USB/recovery-device health

If there is strong evidence of failing hardware, stop software repair that could increase data loss and prioritize backup/recovery of data.

## Tier 2 - Evidence and Failure Classification

Collect and correlate:
- Startup Repair logs
- DISM/CBS/SFC logs
- Setup/servicing logs
- BCD/boot configuration
- Event logs when readable offline
- Driver/service configuration
- Recent updates, drivers, registry changes, and rollback state
- Bugcheck/recovery codes

Classify the incident before repair, for example:
- storage/controller/driver
- bootloader/BCD/EFI
- filesystem
- component-store/system-file corruption
- update/servicing
- registry/service configuration
- encryption/access
- hardware
- unknown/mixed

## Tier 3 - Backup Readiness

Before moderate or high-risk repair, RescueMeAI should strongly recommend a backup.

Preferred backup targets:
- Separate external HDD/SSD with enough capacity for the data being protected
- Prefer a drive with comfortably more free capacity than the estimated data set; for full-system imaging, capacity should meet or exceed the used space plus safety margin

RescueMeAI should:
- Estimate used space and backup requirement
- Detect suitable external targets by label/capacity, not blindly by disk number
- Offer file-level backup first when full imaging is not practical
- Verify copied data where feasible
- Never overwrite an existing backup without explicit approval

Backup is strongly recommended before any action that could materially alter the Windows image, boot configuration, partitions, encryption, reset state, or application state.

## Tier 4 - Recovery Source / USB Readiness

Prepare recovery media early, before it is urgently needed.

RescueMeAI should:
- Prefer an existing suitable recovery USB if present
- Otherwise advise the user to obtain a USB drive with adequate capacity
- Identify it by stable properties/label
- Download only official/validated recovery-source payloads or payloads whose final file URLs/hashes are independently validated
- Verify hashes
- Assemble bootable recovery media without repartitioning when the existing layout is already suitable
- Perform a structural boot-media validation before relying on it

Creating recovery media is preparation, not permission to reinstall Windows.

## Tier 5 - Read-Only Windows Diagnostics

Examples:
- DISM image health inspection
- SFC verification-only/offline targeted verification where appropriate
- BCD/EFI inventory
- Driver/service inventory
- Pending servicing state
- Registry inspection
- Filesystem read-only checks

No write should occur until the evidence supports a repair hypothesis.

## Tier 6 - Reversible Targeted Repairs

Prefer narrowly scoped repairs with a rollback path, for example:
- Correct a known bad service/driver binding
- Restore a missing known-good boot/storage driver
- Reverse a recent known-bad configuration change
- Repair a specific BCD/boot entry
- Roll back a failed recent update/driver where supported

Each attempt should be journaled and tested before moving higher.

## Tier 7 - Offline Image / System-File Repair

If corruption is supported by evidence:
- DISM health/repair against the offline Windows image
- Use an appropriate repair source when required
- SFC offline repair after component-store health is acceptable
- Re-verify after each repair

Do not force an inapplicable or mismatched source simply to make DISM proceed.

## Tier 8 - Boot Environment Repair

When evidence points to boot-environment corruption:
- Identify the actual EFI/System partition safely
- Repair/recreate boot files with supported Windows tooling
- Preserve existing boot configuration where practical
- Do not format the EFI/System partition as a routine repair step

## Tier 9 - Restore / Rollback

Before reset/reinstall, evaluate:
- System Restore
- Update uninstall/rollback
- Driver rollback
- Known-good registry/configuration backup
- OEM or user-created recovery image, if trusted and appropriate

Prefer the option that preserves the most user state and has the clearest rollback path.

## Tier 10 - Repair Reinstall / Refresh-Style Recovery

If targeted repairs are exhausted but Windows can still support a non-destructive reinstall path, prefer it before reset or clean installation.

Goal:
- Replace Windows system components while preserving as much user data and application state as the supported method allows.

The exact option depends on whether Windows can boot and which recovery features are available.

## Tier 11 - Reset While Preserving Personal Files

Use only after prior repair/restore options are exhausted or clearly unsuitable.

Requirements:
- Backup warning
- Explicit explanation that applications/settings can be removed even when personal files are retained
- Separate local confirmation
- Verify BitLocker/recovery-key readiness where relevant

## Tier 12 - Clean Reinstall

Final escalation only.

Requirements:
- Confirm backup or explicit acceptance of data-loss risk
- Confirm target disk/partition by multiple stable identifiers
- Explicit local destructive authorization
- Preserve/export recovery evidence before reinstall
- Never silently repartition or erase disks

## Runtime Continuity

Repair result PASS/FAIL/WARNING is not an application failure.

- PASS/FAIL/WARNING: report result, keep RescueMeAI online, wait for next instruction
- Recoverable network/control issue: remain alive, quarantine unsafe work, retry at safe intervals
- APP_FATAL: fail closed, retain evidence, return control to CMD after user acknowledgment

## User Experience Rule

Every screen must answer:
1. What is RescueMeAI doing?
2. Is Windows being changed right now?
3. Does the user need to do anything?
4. How can the user stop safely?

Technical detail belongs in logs unless it is necessary for a user decision.
