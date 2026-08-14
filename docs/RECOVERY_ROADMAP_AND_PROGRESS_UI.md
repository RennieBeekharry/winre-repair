# RescueMeAI™ Recovery Roadmap and Progress UI

**Standard version:** 2026-08-14.2

RescueMeAI must never leave a user guessing whether recovery is progressing, stalled, waiting for ChatGPT/support, waiting for the user, or approaching a more invasive recovery tier.

This document defines the canonical roadmap, readiness, progress, and user-action presentation for RescueMeAI.

## 1. UX principle

RescueMeAI is **autonomous, but visibly autonomous**.

At every meaningful point, the user should be able to answer these questions from the screen in a few seconds:

1. Is RescueMeAI still running?
2. What is it doing now?
3. How far through the current task is it?
4. Where are we in the overall recovery plan?
5. What is likely to happen next?
6. Is Windows being changed right now?
7. What is the backup status?
8. What is the recovery-media status?
9. Does the user need to do anything?
10. How can the user stop safely?

## 2. Three visible state models

RescueMeAI displays three separate but coordinated status models.

### 2.1 Recovery Roadmap Progress

This represents progress through the **current evidence-based recovery plan**, not a guaranteed time-to-fix and not a probability of success.

Canonical roadmap:

1. Hardware Safety
2. Evidence + Windows Diagnostics
3. Built-in Windows Repair
4. Boot Test / Reassess
5. Targeted Repair
6. Advanced Offline Repair
7. Restore / Rollback
8. Repair Reinstall
9. Reset Windows
10. Clean Reinstall

Example:

```text
RECOVERY ROADMAP                         Stage 3 of 10
Plan progress: [######--------------] 30% (estimated)

[PASS]  1. Hardware Safety
[PASS]  2. Evidence + Windows Diagnostics
[NOW ]  3. Built-in Windows Repair
[NEXT]  4. Boot Test / Reassess
[    ]  5. Targeted Repair
[    ]  6. Advanced Offline Repair
[    ]  7. Restore / Rollback
[LOCK]  8. Repair Reinstall
[LOCK]  9. Reset Windows
[LOCK] 10. Clean Reinstall - LAST RESORT
```

The roadmap percentage is an **estimated plan-completion indicator**. Diagnosis is branching work, so the percentage may be recalculated or move backward when new evidence changes the plan.

Roadmap progress must never be presented as:

- the probability that the PC will be fixed;
- a promise that every remaining stage will be required;
- a whole-session time estimate.

### 2.2 Safety Readiness

Backup and recovery media are adaptive gates shown alongside the roadmap rather than mandatory fixed stages.

Canonical display:

```text
SAFETY READINESS

Backup        : RECOMMENDED
Recovery USB  : NOT NEEDED YET
Windows change: NONE
```

Allowed backup states:

- `NOT REQUIRED YET`
- `RECOMMENDED`
- `STRONGLY RECOMMENDED`
- `REQUIRED`

Allowed recovery-media states:

- `NOT NEEDED YET`
- `RECOMMENDED`
- `PREPARING`
- `READY`
- `REQUIRED`

Allowed Windows change levels:

- `NONE`
- `READ ONLY`
- `REPAIR WRITE`
- `DESTRUCTIVE`

The readiness block must include a short reason whenever a state escalates to `STRONGLY RECOMMENDED` or `REQUIRED`.

Example:

```text
SAFETY READINESS

Backup        : REQUIRED BEFORE CONTINUING
Reason        : The next step can materially alter filesystem or boot-critical state.
Recovery USB  : READY
Windows change: REPAIR WRITE
```

If suspected hardware failure raises data-loss risk, backup can jump directly to `REQUIRED` even when the core roadmap is still at an early stage.

### 2.3 Current Task Progress

This is exact or evidence-based progress for the operation currently executing.

When measurable, show:

- percentage;
- completed units / total units;
- bytes transferred or processed;
- elapsed time;
- current transfer/processing rate where meaningful;
- ETA derived from observed progress;
- retry count when relevant;
- last visible activity/heartbeat for long-running work.

Example:

```text
CURRENT TASK: DOWNLOAD WINDOWS RECOVERY SOURCE

Progress : [#############-------] 67%
Files    : 29 / 43 verified
Data     : 4.83 / 7.19 GiB
Speed    : 18.4 MiB/s
Elapsed  : 00:05:42
ETA      : about 00:02:50
```

For operations that expose their own trustworthy progress, such as DISM or SFC, RescueMeAI should display the native operation progress where practical rather than inventing a separate percentage.

## 3. No fake ETA

An ETA may be shown only when RescueMeAI has enough measurable data to calculate one responsibly.

Good examples:

- download bytes remaining / observed throughput;
- files hashed / total files;
- files copied / total files;
- native DISM/SFC percentage;
- deterministic scan stages.

When an ETA cannot be supported, say so plainly:

```text
ETA: Not available yet - result dependent.
```

Do not display arbitrary countdowns for:

- diagnosis;
- boot testing;
- failure classification;
- waiting for a user response;
- waiting for a remote/AI decision;
- the entire recovery session.

## 4. Roadmap behavior

The roadmap is adaptive.

RescueMeAI may:

- mark a stage `SKIP` when evidence proves it is unnecessary;
- insert a diagnostic sub-stage;
- return to an earlier stage after a boot test produces new evidence;
- prepare backup or recovery media opportunistically without falsely marking them as completed repair stages;
- stop escalation immediately when Windows is restored to a healthy bootable state.

The system must not blindly execute all ten stages in order.

## 5. Windows-native repair visibility

Supported Windows diagnostics and repair mechanisms appear early in the roadmap.

Examples of user-facing task names:

- `Checking Windows image health`
- `Verifying protected Windows system files`
- `Checking filesystem consistency`
- `Repairing Windows component store`
- `Repairing protected Windows system files`
- `Repairing filesystem errors`

The UI should avoid exposing raw command syntax unless it helps the user's decision. Logs can retain exact commands, switches, return codes and hashes.

Behavior-specific safety remains visible:

```text
CURRENT TASK
Checking filesystem consistency

Windows change: READ ONLY
```

versus:

```text
CURRENT TASK
Repairing filesystem errors

Windows change: REPAIR WRITE
Backup status : STRONGLY RECOMMENDED
```

## 6. Roadmap state labels

Use explicit text labels so color is never required:

- `[PASS]` completed successfully;
- `[NOW ]` active stage;
- `[NEXT]` expected next stage;
- `[WAIT]` waiting on user, network, ChatGPT/support, reboot or another dependency;
- `[WARN]` completed with unresolved concern;
- `[FAIL]` stage failed and needs diagnosis;
- `[SKIP]` not applicable / not needed;
- `[LOCK]` escalation tier not yet authorized or justified.

`Repair Reinstall`, `Reset Windows`, and `Clean Reinstall` should normally remain `[LOCK]` until earlier justified repair/rollback options have been exhausted and the relevant readiness/authorization gates are satisfied.

## 7. Stable screen layout

For normal autonomous operation, the primary RescueMeAI screen should use this hierarchy:

```text
================================================================================================
                                           RESCUEMEAI
                                  AI-ASSISTED WINDOWS RECOVERY
================================================================================================
Status          : WORKING
Internet        : CONNECTED
Windows changes : READ ONLY
================================================================================================

RECOVERY ROADMAP                         Stage 2 of 10
Plan progress: [####----------------] 20% (estimated)

[PASS] Hardware Safety
[NOW ] Evidence + Windows Diagnostics
[NEXT] Built-in Windows Repair
[    ] Boot Test / Reassess
[    ] Targeted Repair
[    ] Advanced Offline Repair
[    ] Restore / Rollback
[LOCK] Repair Reinstall
[LOCK] Reset Windows
[LOCK] Clean Reinstall

SAFETY READINESS
Backup        : NOT REQUIRED YET
Recovery USB  : NOT NEEDED YET
Windows change: READ ONLY

CURRENT TASK
Checking Windows image health
Progress : 41%
Elapsed  : 00:01:18
ETA      : Not available yet - native diagnostic still running

WHAT IS HAPPENING NOW
RescueMeAI is using Windows' built-in diagnostic tools to check system health.

WHAT YOU NEED TO DO
PLEASE WAIT - no action is required from you right now.
================================================================================================
```

The screen should redraw only at meaningful state changes or reasonable progress intervals. Do not rapidly flash multiple screens for minor internal operations.

## 8. User-action footer rules

The footer depends on the state.

### WORKING

```text
PLEASE WAIT - RescueMeAI is working.
No action is required from you right now.
```

### WAITING FOR NEXT REMOTE INSTRUCTION

```text
RescueMeAI is still running and waiting for the next recovery instruction.
PLEASE WAIT - no action is required from you right now.
To stop safely while Status says WAITING, press S once.
```

### COMPLETED PASS / FAIL / WARNING

A completed result requires the user to notify the current ChatGPT conversation unless an active product relay can automatically continue the conversation.

```text
ACTION REQUIRED
On your phone, return to ChatGPT and send exactly: PASS
Leave this PC window open. RescueMeAI will remain online and wait for the next instruction.
```

Use `FAIL` or `WARNING` as appropriate.

### BACKUP OR MEDIA ACTION REQUIRED

If the next tier cannot safely proceed without user-provided hardware, say exactly what is needed and why.

Example:

```text
ACTION REQUIRED - BACKUP DRIVE NEEDED

Why:
The next repair step can materially alter filesystem state.

What you need:
A separate external HDD or SSD with at least 850 GB free space.

Do not disconnect the current recovery USB.
```

### LOCAL AUTHORIZATION REQUIRED

Clearly state the exact action, risk, target, consequence and authorization phrase. Never hide a destructive authorization prompt inside an ordinary progress screen.

## 9. Background/remote activity visibility

The PC should show meaningful milestones for work being coordinated remotely, without turning display messages into executable commands.

Examples:

- Reviewing the latest recovery result;
- Preparing the next recovery step;
- Waiting for the next recovery instruction;
- Command received;
- Verifying command integrity;
- Checking safety policy;
- Starting Windows diagnostic;
- Running built-in Windows repair;
- Preparing recovery source;
- Downloading recovery source;
- Verifying downloaded files;
- Reassessing after repair;
- Reporting result;
- Waiting for user response.

Remote activity status is **display-only** and must be isolated from the executable command channel. A status message can never authorize or execute a recovery action.

## 10. Long-running operations

For any operation expected to exceed roughly one minute, show periodic progress/heartbeat output so the user can distinguish slow work from a frozen process.

At minimum show:

- current task name;
- most recent progress value or stage;
- elapsed time;
- last activity time;
- `RescueMeAI is still running` heartbeat when there has been no visible percentage change for a reasonable interval.

Do not clear useful progress information merely to redraw an identical screen.

## 11. Progress persistence

Roadmap state, readiness state and current-operation state should be journaled locally so that after a safe RescueMeAI restart the UI can say, for example:

```text
Recovery session resumed.

Completed stages : 3 of 10
Last completed   : Built-in Windows repair
Current stage    : Boot Test / Reassess
Backup status    : RECOMMENDED
Recovery USB     : READY
Last result      : PASS
```

A restart must not falsely reset the displayed recovery journey to 0%.

Persist at minimum:

- current roadmap stage;
- stage states;
- last completed action/result;
- backup readiness;
- recovery-media readiness;
- Windows change level;
- current task/progress when resumable;
- pending user/remote dependency.

## 12. Safety interpretation

Progress indicators never override safety policy.

A user must not be encouraged to authorize a destructive operation merely because:

- the roadmap is `90% complete`;
- only one stage remains;
- the current task has reached a high percentage;
- an ETA is short.

Safety gates, backup requirements, rollback assessment, target validation and local destructive authorization remain authoritative regardless of progress presentation.
