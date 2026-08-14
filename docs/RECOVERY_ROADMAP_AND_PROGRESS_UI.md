# RescueMeAI™ Recovery Roadmap and Progress UI

**Standard version:** 2026-08-14.1

RescueMeAI must never leave a user guessing whether recovery is progressing, stalled, waiting for ChatGPT, waiting for the user, or approaching a more invasive recovery tier.

This document defines the canonical roadmap and progress presentation for RescueMeAI.

## 1. UX principle

RescueMeAI is **autonomous, but visibly autonomous**.

At every meaningful point, the user should be able to answer these questions from the screen in a few seconds:

1. Is RescueMeAI still running?
2. What is it doing now?
3. How far through the current task is it?
4. Where are we in the overall recovery plan?
5. What is likely to happen next?
6. Is Windows being changed right now?
7. Does the user need to do anything?
8. How can the user stop safely?

## 2. Two separate progress models

RescueMeAI MUST NOT pretend that an entire repair has a deterministic completion time. Diagnosis is branching work: a failed test can add, remove, or reorder later recovery actions.

Therefore RescueMeAI displays two different progress indicators.

### 2.1 Recovery Roadmap Progress

This represents progress through the **current recovery plan**, not a guaranteed time-to-fix.

Example:

```text
RECOVERY ROADMAP                         Stage 5 of 9
Plan progress: [############--------] 60% (estimated)

  [PASS]  1. Hardware safety checks
  [PASS]  2. Logs and failure classification
  [PASS]  3. Backup readiness
  [PASS]  4. Recovery source / media readiness
  [NOW ]  5. Targeted least-invasive repair
  [NEXT]  6. Offline Windows repair
  [    ]  7. Restore / rollback
  [LOCK]  8. Reset / preserve files
  [LOCK]  9. Clean reinstall - LAST RESORT
```

The roadmap percentage is an **estimated plan-completion indicator**. It may move backward or be recalculated if new evidence changes the recovery branch. The UI must say `estimated` when displaying this percentage.

Roadmap progress must never be presented as the probability that the PC will be fixed.

### 2.2 Current Task Progress

This is exact or evidence-based progress for the operation currently executing.

When measurable, show:

- percentage;
- completed units / total units;
- bytes transferred or processed;
- elapsed time;
- current transfer/processing rate where meaningful;
- ETA derived from observed progress;
- retry count when relevant.

Example:

```text
CURRENT TASK: DOWNLOAD WINDOWS RECOVERY SOURCE

Progress : [#############-------] 67%
Files    : 29 / 43 verified
Data     : 4.83 / 7.19 GiB
Speed    : 18.4 MiB/s
Elapsed  : 00:05:42
ETA      : about 00:02:50

Windows changes: NONE
PLEASE WAIT - no action is required right now.
```

For operations whose tools provide native percentages (for example DISM or SFC), RescueMeAI should display the native operation progress where practical rather than inventing its own percentage.

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
ETA: Not available yet - waiting for diagnostic result.
```

Do not display arbitrary countdowns for diagnosis, boot testing, failure classification, or the entire recovery session.

## 4. Canonical recovery roadmap

The default RescueMeAI roadmap follows least-invasive-first escalation:

1. **Safety and hardware triage**
   - detect disks, Windows installation, firmware mode, encryption state and obvious hardware/storage problems;
   - stop repair escalation and prioritize backup if evidence suggests physical media failure.

2. **Evidence and logs**
   - collect Startup Repair, servicing, boot, driver, filesystem and other relevant evidence;
   - classify the likely subsystem before changing it.

3. **Backup readiness**
   - estimate backup requirements;
   - identify or recommend an appropriate separate backup device;
   - establish backup status before higher-risk write operations.

4. **Recovery source and media readiness**
   - identify an existing recovery USB or create one safely;
   - download and verify source files;
   - validate boot/recovery assets before relying on them.

5. **Targeted least-invasive repair**
   - make the smallest reversible change supported by evidence;
   - journal the change and test the result.

6. **Offline Windows repair**
   - component-store/system-file repair, boot repair or other supported offline repair using validated sources and targets;
   - avoid forcing incompatible sources.

7. **Restore / rollback**
   - System Restore, update rollback, driver rollback, known-good configuration or image restore when available and appropriate.

8. **Reset / preservation-oriented recovery**
   - only after targeted repair and rollback options are exhausted;
   - explicit user approval required;
   - clearly explain what is preserved and what is removed.

9. **Clean reinstall**
   - LAST RESORT;
   - backup readiness and explicit destructive local authorization required;
   - verified target selection required.

The roadmap is adaptive. RescueMeAI may mark steps `NOT NEEDED`, insert a diagnostic sub-stage, or move back to an earlier stage when new evidence justifies it.

## 5. Roadmap state labels

Use explicit text symbols so color is never required:

- `[PASS]` completed successfully;
- `[NOW ]` active stage;
- `[NEXT]` expected next stage;
- `[WAIT]` waiting on user, network, ChatGPT/support, reboot or another dependency;
- `[WARN]` completed with unresolved concern;
- `[FAIL]` stage failed and needs diagnosis;
- `[SKIP]` not applicable / not needed;
- `[LOCK]` escalation tier not yet authorized or justified.

`Reset` and `Clean reinstall` should normally remain `[LOCK]` until earlier tiers have been exhausted and the required authorization gates are satisfied.

## 6. Stable screen layout

For normal autonomous operation, the primary RescueMeAI screen should use this hierarchy:

```text
================================================================================================
                                           RESCUEMEAI
                                  AI-ASSISTED WINDOWS RECOVERY
================================================================================================
Status          : WORKING / WAITING / ACTION REQUIRED / PASS / FAIL / WARNING
Internet        : CONNECTED
Windows changes : NONE / READ ONLY / REPAIR WRITE / DESTRUCTIVE
================================================================================================

RECOVERY ROADMAP                         Stage 5 of 9
Plan progress: [############--------] 60% (estimated)

[PASS] Hardware safety       [PASS] Evidence/logs
[PASS] Backup readiness      [PASS] Recovery media
[NOW ] Targeted repair       [NEXT] Offline repair
[    ] Restore/rollback      [LOCK] Reset
[LOCK] Clean reinstall

CURRENT TASK
Repairing boot-critical storage configuration
Progress: Stage 2 of 4
Elapsed : 00:01:18
ETA     : Not available - result dependent

WHAT IS HAPPENING NOW
RescueMeAI is checking the proposed change and collecting the result.

WHAT YOU NEED TO DO
PLEASE WAIT - no action is required from you right now.
To stop safely while Status says WAITING, press S once.
================================================================================================
```

The screen should be redrawn only at meaningful state changes or reasonable progress intervals. Do not rapidly flash multiple screens for minor internal operations.

## 7. User-action footer rules

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

### LOCAL AUTHORIZATION REQUIRED

Clearly state the exact action, risk, target, consequence and authorization phrase. Never hide a destructive authorization prompt inside an ordinary progress screen.

## 8. Background/remote activity visibility

The PC should show meaningful milestones for work being coordinated remotely, without turning display messages into executable commands.

Examples:

- Reviewing the latest recovery result;
- Preparing the next recovery step;
- Waiting for the next recovery instruction;
- Command received;
- Verifying command integrity;
- Checking safety policy;
- Starting diagnostic;
- Downloading recovery source;
- Verifying downloaded files;
- Reporting result;
- Waiting for user response.

Remote activity status is **display-only** and must be isolated from the executable command channel. A status message can never authorize or execute a recovery action.

## 9. Long-running operations

For any operation expected to exceed roughly one minute, show periodic progress/heartbeat output so the user can distinguish slow work from a frozen process.

At minimum show:

- current task name;
- most recent progress value or stage;
- elapsed time;
- last activity time;
- `RescueMeAI is still running` heartbeat when there has been no visible percentage change for a reasonable interval.

Do not clear useful progress information merely to redraw an identical screen.

## 10. Progress persistence

Roadmap state and current operation state should be journaled locally so that after a safe RescueMeAI restart the UI can say, for example:

```text
Recovery session resumed.
Completed stages: 4 of 9
Last completed action: Recovery source download and SHA-1 verification
Current stage: Recovery media validation
```

A restart must not falsely reset the displayed recovery journey to 0%.

## 11. Safety interpretation

Progress indicators never override safety policy.

A user must not be encouraged to authorize a destructive operation merely because the roadmap is `90% complete` or because the application says only one stage remains.

Safety gates, backup requirements, rollback assessment and local destructive authorization remain authoritative regardless of progress presentation.
