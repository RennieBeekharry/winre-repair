# RescueMeAI™ Windows-Native Diagnostics and Repair Policy

Version: 2026-08-14.1

## Purpose

RescueMeAI should use supported Windows-native diagnostic and repair mechanisms early when they are appropriate. These tools are often the least invasive way to identify or correct Windows corruption and can prevent unnecessary custom repair, backup preparation, recovery-media creation, reset, or reinstall.

The governing rule is:

**diagnose first → repair only when evidence justifies it → verify → boot test/reassess → escalate only when needed**

Tool names alone do not determine risk. The exact operation, target, switches and current hardware/data condition determine risk.

## 1. General ordering

For an otherwise stable machine, prefer this sequence where applicable:

1. Read-only filesystem/status checks
2. Windows image health inspection
3. Protected system-file verification
4. Evidence classification
5. Evidence-supported Windows-native repair
6. Re-verification
7. Boot test / reassessment
8. Only then targeted/custom or advanced offline repair

If hardware/storage failure is suspected, backup/data preservation can preempt this sequence.

## 2. CHKDSK policy

### Diagnostic use

A CHKDSK invocation that does not request filesystem repair should be treated as a diagnostic/read-only operation for RescueMeAI policy purposes.

Use it to establish:

- filesystem consistency;
- volume readability;
- whether repair is indicated;
- evidence for or against filesystem involvement.

### `/f`

`chkdsk /f` is a repair-write operation because it fixes filesystem errors.

Before using it RescueMeAI should consider:

- current hardware/storage health evidence;
- backup readiness;
- whether filesystem corruption is actually demonstrated;
- whether the target volume is correctly identified;
- whether the environment can safely obtain the required volume access.

### `/r`

`chkdsk /r` is not a routine first-line repair.

It performs substantially heavier media checking/readable-data recovery work and should be reserved for evidence that justifies sector-level examination, such as:

- suspected bad sectors;
- I/O/read failures;
- storage/media symptoms consistent with physical damage;
- prior diagnostic evidence indicating the need.

If physical storage failure is plausible, backup/data recovery takes priority over repeatedly stressing the device with broad scans.

## 3. SFC policy

### Verification

Use SFC verification-only modes where supported when RescueMeAI needs to determine whether protected Windows files are corrupt without initiating repair.

For offline Windows, RescueMeAI must identify the correct Windows and boot directories rather than assuming drive letters.

### Repair

SFC repair is a `REPAIR WRITE` action.

Use it when:

- protected system-file corruption is demonstrated or strongly supported;
- the correct Windows target has been established;
- the component store/source state is suitable enough for repair;
- any required backup/readiness gate is satisfied.

After SFC repair, collect the result/log evidence and reassess before escalating.

## 4. DISM policy

### Health inspection

Use DISM health inspection early where the target/environment supports it.

Examples include health checking/scanning operations intended to determine component-store corruption without repairing the image.

### `/RestoreHealth`

DISM `/RestoreHealth` is `REPAIR WRITE`.

Use it when component-store corruption is demonstrated and the target/source relationship is valid.

Rules:

- do not force a mismatched or inapplicable repair source simply to make DISM run;
- validate edition, architecture, build family and source applicability as needed;
- account for servicing/update level differences;
- capture DISM/CBS evidence before and after repair;
- re-run relevant verification afterward.

A recovery source being valid and hash-verified does not automatically prove it is a valid `/Source` for the currently serviced Windows image.

## 5. Startup Repair and boot-native tools

Use Startup Repair and boot-native Windows tooling when evidence points to boot-environment problems.

For BCDBoot or similar boot-file repair:

- positively identify the actual EFI/System partition;
- preserve existing boot configuration where practical;
- do not hard-code a system-partition drive letter in the general product;
- do not format the EFI/System partition as a routine repair step;
- formatting/repartitioning remains destructive and requires separate local authorization.

## 6. Update and servicing repair

When servicing evidence points to a failed/pending/recent Windows update:

- inspect installed/pending package state first;
- prefer supported rollback/reapplication mechanisms;
- validate package applicability;
- account for prerequisites/checkpoint updates when applicable;
- avoid forcing inapplicable packages;
- re-verify component/system-file health after servicing repair.

## 7. Backup risk integration

Windows-native tools do not bypass RescueMeAI's adaptive backup gate.

Typical guidance:

- read-only CHKDSK / DISM health inspection / SFC verify-only → `NOT REQUIRED YET` or `RECOMMENDED` depending on hardware condition;
- SFC repair / DISM `/RestoreHealth` → usually `RECOMMENDED` or `STRONGLY RECOMMENDED` depending on uncertainty and scope;
- CHKDSK `/f` → consider `STRONGLY RECOMMENDED` when user-data filesystem state could be affected;
- CHKDSK `/r` with possible failing media → backup/data preservation may become `REQUIRED` before further stress when feasible;
- Reset/reinstall → backup normally `REQUIRED` or an explicit informed exception.

Hardware risk can always raise the backup requirement.

## 8. Recovery-media integration

Recovery media is not required merely because RescueMeAI wants to run a basic Windows-native diagnostic.

Recovery media should move from `NOT NEEDED YET` toward `REQUIRED` when:

- the current WinRE environment lacks required repair assets;
- an appropriate DISM source is needed;
- a fresh recovery environment is necessary;
- boot/recovery assets need replacement;
- later preservation/reinstall tiers require it.

Downloaded source files must be integrity-verified, and bootable media must be structurally validated before RescueMeAI labels the recovery USB `READY`.

## 9. Result interpretation

A tool command returning success does not automatically mean the PC is fixed.

RescueMeAI should distinguish:

- tool execution success;
- corruption found/not found;
- repair performed/not performed;
- repair verified/not verified;
- boot test passed/failed;
- overall recovery stage result.

Likewise, a diagnostic finding is not necessarily a repair failure.

## 10. Progress and user visibility

For long-running Windows-native operations, RescueMeAI should expose meaningful progress without flooding the console.

Show where practical:

- task name in plain language;
- native percentage/progress;
- elapsed time;
- ETA only when supportable;
- heartbeat when native progress pauses;
- current Windows change level;
- current backup and recovery-media readiness;
- explicit user-action footer.

Prefer user-facing text such as:

```text
Checking Windows image health
```

instead of forcing novice users to interpret raw DISM syntax.

Exact commands/switches remain in logs/evidence.

## 11. Do not shotgun repairs

RescueMeAI must not run CHKDSK repair, SFC repair, DISM repair, boot repair and registry repair indiscriminately as a generic bundle.

Each write operation must have an evidence-supported hypothesis or a clearly justified supported recovery role.

After a meaningful repair, reassess before executing the next repair tier.

## 12. Final escalation boundary

Windows-native repair belongs near the beginning of the software-repair ladder because it is usually less invasive than custom configuration changes, restore/reset or reinstall.

However, failure of a Windows-native tool does not by itself justify Reset or clean reinstall.

RescueMeAI must continue through evidence-supported targeted repair, advanced offline repair and restore/rollback options before preservation-oriented reset/reinstall tiers are unlocked.
