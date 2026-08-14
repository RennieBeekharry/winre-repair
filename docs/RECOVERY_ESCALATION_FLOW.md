# RescueMeAI Recovery Escalation Flow

Version: 2026-08-14.2

## Principle

RescueMeAI must always prefer the least invasive action that can reasonably restore a healthy, bootable Windows system. It must collect evidence before writing, prefer supported Windows-native diagnostics and repair mechanisms before custom intervention, preserve rollback paths where practical, and escalate only when the current tier is exhausted, inapplicable, or contradicted by evidence.

Backup and recovery-media preparation are **adaptive readiness gates**, not mandatory fixed stages that every user must complete before Windows receives a chance to repair itself.

The default core repair ladder is:

1. Safety and hardware triage
2. Evidence and Windows-native diagnostics
3. Windows-native low-risk repair
4. Boot test and reassessment
5. Targeted reversible repair
6. Advanced offline Windows repair
7. Restore / rollback
8. Repair reinstall / preservation-oriented recovery
9. Reset while preserving personal files
10. Clean reinstall only as final escalation

Alongside that ladder RescueMeAI continuously tracks:

- Backup status: `NOT REQUIRED YET`, `RECOMMENDED`, `STRONGLY RECOMMENDED`, or `REQUIRED`
- Recovery-media status: `NOT NEEDED YET`, `RECOMMENDED`, `PREPARING`, `READY`, or `REQUIRED`
- Windows change level: `NONE`, `READ ONLY`, `REPAIR WRITE`, or `DESTRUCTIVE`

## Gate 0 - Session Safety

Before any repair:

- Identify Windows installation(s), firmware mode, disk layout, BitLocker/encryption state, storage controller, and external drives.
- Confirm the intended Windows target and never infer a destructive target by disk number alone.
- Establish logging, command journaling, replay protection, integrity validation, and local authorization policy.
- Classify operations by their exact behavior, not merely by executable name.
- Destructive operations require separate explicit local authorization.

Examples of behavior-based classification:

- `chkdsk` without repair switches: diagnostic / read-only
- `chkdsk /f`: filesystem repair-write
- `chkdsk /r`: heavier filesystem/media repair and readable-data recovery; use only when evidence justifies sector-level work
- SFC `/verifyonly`: diagnostic / read-only
- SFC `/scannow`: repair-write
- DISM `/CheckHealth` or `/ScanHealth`: diagnostic / read-only with respect to the target image
- DISM `/RestoreHealth`: repair-write

The local safety engine may always increase a risk classification. It must never lower one merely because remote metadata says an action is safer.

## Tier 1 - Safety and Hardware Triage

Run non-destructive checks first:

- Storage visibility and basic health indicators
- Filesystem readability and dirty-bit state
- Controller/device enumeration
- Memory diagnostics when symptoms justify it
- CPU/thermal/power indicators when available
- USB/recovery-device health
- Basic access to critical Windows files and registry hives

If evidence suggests failing storage or other hardware that could threaten data, stop extended software repair and promote backup/data recovery to priority #1.

Hardware uncertainty is not automatically hardware failure. Unavailable SMART/health telemetry in WinRE should be recorded as unknown/neutral rather than converted into a failure claim.

## Tier 2 - Evidence and Windows-Native Diagnostics

Collect and correlate evidence before changing Windows:

- Startup Repair logs
- CBS, DISM and SFC logs
- Setup and servicing logs
- BCD/EFI inventory
- Event logs when readable offline
- Driver and service configuration
- Pending servicing state
- Recent updates, drivers, registry changes and rollback state
- Bugcheck/recovery codes
- Read-only filesystem status

Use supported Windows-native diagnostics early where applicable, for example:

- DISM health inspection (`/CheckHealth`, `/ScanHealth` where supported)
- SFC verification-only / offline verification where appropriate
- CHKDSK without repair parameters
- Dirty-bit checks
- BCD/EFI inventory
- Driver/service inventory
- Registry inspection

Classify the incident before repair, for example:

- hardware
- storage/controller/driver
- bootloader/BCD/EFI
- filesystem
- component-store/system-file corruption
- update/servicing
- registry/service configuration
- encryption/access
- unknown/mixed

Repairs should follow evidence, not a generic sequence of commands.

## Tier 3 - Windows-Native Low-Risk Repair

If Tier 2 evidence supports a repair, prefer supported Windows repair mechanisms before custom fixes.

Examples:

- SFC repair against the correct online/offline Windows target
- DISM `/RestoreHealth` when component-store corruption is demonstrated and an appropriate source is available when required
- Startup Repair when the failure class is appropriate
- CHKDSK `/f` when actual filesystem inconsistency warrants a repair
- Supported pending-servicing or update rollback mechanisms when evidence points there

Rules:

- Do not run every native repair tool merely because it exists.
- Do not automatically run CHKDSK `/r`; reserve it for evidence suggesting bad sectors or readable-data recovery needs.
- Do not force an inapplicable or mismatched DISM source merely to make `/RestoreHealth` proceed.
- Capture before/after evidence and journal any write action.

## Tier 4 - Boot Test and Reassessment

After a meaningful repair attempt:

1. verify the repair result;
2. attempt the least disruptive supported boot test when appropriate;
3. if Windows boots, stop escalation and perform post-repair validation;
4. if Windows still fails, collect the new evidence and recalculate the recovery branch.

A failed repair is evidence, not a reason to blindly run the next command in a fixed script.

## Adaptive Gate A - Backup Readiness

Backup is continuously reassessed rather than treated as a one-time roadmap stage.

### `NOT REQUIRED YET`

Appropriate for low-risk read-only diagnostics when hardware appears stable.

### `RECOMMENDED`

Use when continuing without a backup is reasonable but protection would improve resilience, for example before narrowly reversible changes.

### `STRONGLY RECOMMENDED`

Use before moderate-risk writes such as uncertain boot-critical configuration changes, filesystem repairs with meaningful data exposure, or broader offline image work.

### `REQUIRED`

Use when:

- hardware/storage failure is suspected;
- the next operation can materially threaten personal data;
- an image restore may overwrite current state;
- Reset/reinstall is being considered;
- a destructive disk/partition operation is proposed.

RescueMeAI should:

- estimate data/used-space requirements;
- identify suitable external HDD/SSD targets by stable properties and capacity;
- recommend enough free capacity plus safety margin;
- offer file-level backup when full imaging is impractical;
- verify copied data where feasible;
- never overwrite an existing backup without explicit approval.

If no backup target is available, RescueMeAI may continue read-only or narrowly reversible work when justified, but it must not silently weaken higher-risk backup requirements.

## Adaptive Gate B - Recovery Source / Media Readiness

Recovery media is also conditional rather than mandatory for every incident.

### `NOT NEEDED YET`

Use when built-in diagnostics/repairs can proceed safely without external media.

### `RECOMMENDED`

Use when the current path is still repairable locally but external recovery capability would materially improve resilience.

### `PREPARING`

RescueMeAI is identifying media, downloading source files, verifying hashes, or assembling boot/recovery assets.

### `READY`

The source and boot/recovery assets have passed the required integrity/structural checks.

### `REQUIRED`

Use when the next justified repair needs an external source or a fresh recovery environment.

RescueMeAI should:

- prefer an existing suitable recovery USB if present;
- otherwise advise the user what capacity/type is appropriate;
- identify it by stable properties/labels, never blindly by disk number;
- download only validated recovery-source payloads;
- verify hashes;
- assemble bootable recovery media without repartitioning when the existing layout is already suitable;
- structurally validate boot assets before relying on them.

Creating recovery media is preparation, not permission to reinstall Windows.

## Tier 5 - Targeted Reversible Repair

When Windows-native repair is insufficient, make the smallest evidence-supported change with the clearest rollback path.

Examples:

- correct a known bad service/driver binding;
- restore a missing known-good boot/storage driver;
- reverse a recent known-bad registry/configuration change;
- repair a specific BCD/boot entry;
- roll back a failed recent update or driver where supported.

Requirements:

- journal the exact before state;
- record the proposed change and risk;
- preserve a rollback path when practical;
- make one hypothesis-driven change at a time where possible;
- test/reassess before moving higher.

## Tier 6 - Advanced Offline Windows Repair

Use when evidence demonstrates corruption or when the machine cannot be repaired adequately from the current environment.

Examples:

- offline DISM component-store repair;
- offline SFC repair;
- servicing repair using a validated compatible source;
- targeted boot-environment repair;
- supported BCDBoot operations when boot-environment corruption is demonstrated.

Boot rules:

- identify the actual EFI/System partition safely;
- preserve existing boot configuration where practical;
- do not format the EFI/System partition as a routine repair step;
- formatting/repartitioning remains destructive and requires separate local authorization.

## Tier 7 - Restore / Rollback

Before reset/reinstall, evaluate the most state-preserving available rollback mechanism:

- System Restore;
- update uninstall/rollback;
- driver rollback;
- known-good registry/configuration backup;
- trusted OEM or user-created recovery image when appropriate.

Prefer the option that preserves the most user state and has the clearest rollback path.

## Tier 8 - Repair Reinstall / Preservation-Oriented Recovery

If targeted repairs and rollback options are exhausted, prefer a supported repair/reinstall path that preserves the maximum possible state before Reset or clean installation.

The exact option depends on whether Windows can boot and which recovery features are actually supported by the current environment.

RescueMeAI must not advertise preservation that the chosen recovery method cannot actually provide.

## Tier 9 - Reset While Preserving Personal Files

Use only after prior repair/restore options are exhausted or clearly unsuitable.

Requirements:

- Backup status normally `REQUIRED` or an explicit informed exception;
- clear explanation that applications/settings can be removed even when personal files are retained;
- BitLocker/recovery-key readiness where relevant;
- explicit local confirmation;
- post-reset validation plan.

## Tier 10 - Clean Reinstall

Final escalation only.

Requirements:

- confirmed backup or explicit acceptance of data-loss risk;
- exact target disk/partition verified by multiple stable identifiers;
- separate explicit local destructive authorization;
- recovery evidence exported/preserved where possible;
- never silently repartition or erase disks.

## Runtime Continuity

Repair result `PASS`, `FAIL`, or `WARNING` is not an application failure.

- `PASS/FAIL/WARNING`: report result, keep RescueMeAI online, wait for the next instruction
- recoverable network/control issue: remain alive, quarantine unsafe work, retry at safe intervals
- invalid/unsafe command: execute nothing, quarantine/report it, remain online for a corrected command
- `APP_FATAL`: fail closed, retain evidence, return control to CMD after user acknowledgment

## Session Resume Rule

A RescueMeAI restart must resume the existing recovery journey rather than resetting displayed progress to zero.

Persist at minimum:

- completed roadmap stages;
- current stage;
- last completed action/result;
- backup readiness state;
- recovery-media readiness state;
- current Windows change level;
- pending user/remote dependency.

## User Experience Rule

Every screen must answer in a few seconds:

1. Is RescueMeAI still running?
2. What is it doing now?
3. Where are we in the overall recovery plan?
4. How far through the current task are we?
5. Is Windows being changed right now?
6. What is the backup status?
7. What is the recovery-media status?
8. Does the user need to do anything?
9. How can the user stop safely?

Technical detail belongs in logs unless it is necessary for a user decision.
