# RescueMeAI™ Console UI Standard

**UI standard version:** 2026-08-14.5

RescueMeAI runs in environments where the user may be under stress, working from WinRE, or reading a low-resolution console. The UI must favor clarity, consistency, visible progress, and minimal interaction over decorative complexity.

RescueMeAI is **autonomous, but visibly autonomous**. A user must never have to guess whether the application is still running, what it is doing, how far the current task has progressed, whether Windows is being changed, or whether user action is required.

## 1. Display geometry

The WinRE console should attempt a lightweight display setup of approximately **100 columns x 50 lines**. If the environment refuses the resize, RescueMeAI continues without treating that as a recovery failure.

The RescueMeAI visual boundary is **96 columns**. Normal body text is wrapped to **92 characters or fewer** so that user-facing output does not spill beyond the boundary.

Do not manually print long unbounded diagnostic strings on ordinary screens. Long content must go through the shared wrapping renderer.

## 2. Console title ownership

Every RescueMeAI entry point should explicitly set the Windows console title while it owns the workflow, for example:

```text
RescueMeAI - Windows Recovery
```

Do not allow repeated launcher command lines such as `C:\wr.cmd - C:\wr.cmd ...` to accumulate in the title bar.

When RescueMeAI intentionally returns control to an interactive recovery command prompt, it should restore a neutral title such as:

```text
Command Prompt
```

## 3. Standard screen header

Every user-facing RescueMeAI screen should begin with the same compact information hierarchy:

1. Centered product name: `RESCUEMEAI`
2. Centered one-line application description
3. Version
4. Internet connection: `CONNECTED`, `NOT CONNECTED`, or `CHECKING`
5. Runtime status: `WORKING`, `WAITING`, `ACTION REQUIRED`, `PASS`, `FAIL`, or `WARNING`
6. Windows change level: `NONE`, `READ ONLY`, `REPAIR WRITE`, or `DESTRUCTIVE`
7. Legal repository URL
8. Legal landing filename

Recommended layout:

```text
================================================================================================
                                           RESCUEMEAI
                                  AI-ASSISTED WINDOWS RECOVERY
================================================================================================
Version         : RMAI-...
Internet        : [CONNECTED]
Status          : WORKING
Windows changes : READ ONLY
Legal           : https://github.com/RennieBeekharry/winre-repair
Legal file      : LEGAL.md
================================================================================================
```

The shorter repository URL deliberately replaces a long direct `blob/main/LEGAL.md` URL. The next line identifies `LEGAL.md`.

## 4. Required recovery-status blocks

Normal recovery screens should expose four distinct blocks where applicable.

### 4.1 Recovery Roadmap

Shows where the user is in the evidence-based least-invasive-to-most-invasive plan.

Canonical stages:

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

The roadmap may include an **estimated** plan-completion percentage. It must never be described as a probability of success or a guaranteed time-to-fix.

### 4.2 Safety Readiness

Shows adaptive backup and recovery-media gates alongside the roadmap.

Example:

```text
SAFETY READINESS
Backup        : RECOMMENDED
Recovery USB  : READY
Windows change: REPAIR WRITE
```

Backup states:

- `NOT REQUIRED YET`
- `RECOMMENDED`
- `STRONGLY RECOMMENDED`
- `REQUIRED`

Recovery-media states:

- `NOT NEEDED YET`
- `RECOMMENDED`
- `PREPARING`
- `READY`
- `REQUIRED`

When a readiness state escalates to `STRONGLY RECOMMENDED` or `REQUIRED`, the screen should give a short reason.

### 4.3 Current Task Progress

Shows exact or evidence-based progress for the operation currently running.

When measurable, show:

- percentage;
- units completed / total;
- bytes processed/transferred;
- elapsed time;
- rate when useful;
- ETA when supportable;
- retry count when relevant.

For tools that expose trustworthy native progress such as DISM or SFC, prefer the tool's native progress rather than inventing an independent percentage.

If an ETA is not supportable, say so plainly:

```text
ETA: Not available yet - result dependent.
```

Never invent a whole-recovery-session ETA.

### 4.4 User Action

Every screen must explicitly say one of:

- `PLEASE WAIT - no action is required from you right now.`
- `ACTION REQUIRED - return to ChatGPT and send exactly: PASS/FAIL/WARNING.`
- `ACTION REQUIRED - connect/provide the specified backup or recovery device.`
- `LOCAL AUTHORIZATION REQUIRED - review the exact destructive action below.`
- `STOPPED SAFELY - press any key to return to Command Prompt.`

Do not force the user to infer the next step from technical output.

## 5. Central WinRE screen-theme renderer

Individual screens and recovery modules must **not choose hexadecimal console colors**.

RescueMeAI maintains one central semantic screen-theme mapping for WinRE. Callers request a screen meaning and the renderer chooses the native console color.

Current themes:

- `INFO` → light aqua
- `PASS` / `SUCCESS` → light green
- `WARNING` → light yellow
- `ERROR` / `FAIL` → light red
- `NEUTRAL` → normal white

### Why WinRE uses screen-level themes

The active recovery environment established that two native per-line approaches—`findstr /a:<colorattribute>` and child `cmd.exe /t:<colorattribute>` output—both rendered as monochrome on the actual WinRE console.

RescueMeAI therefore uses a simpler native screen-level theme in WinRE. This is deliberately more conservative than repeatedly trying fragile per-line techniques during an active recovery.

Color must never be the only status signal. Text must explicitly identify `[PASS]`, `[FAIL]`, `[WARNING]`, `[CONNECTED]`, and similar states.

## 6. Output wrapping

User-facing paragraphs, warnings, instructions, paths, and diagnostic explanations must be passed through the shared wrapping function when they could exceed the configured text width.

The renderer should wrap at word boundaries where practical. Single values that cannot be broken safely should be displayed on their own line or shortened to a stable landing URL/reference.

No ordinary RescueMeAI output should rely on uncontrolled console wrapping.

## 7. User prompts

Prompts must describe the required action instead of generic labels such as `Selection:` or `Your choice:` when the action is actually a physical key press.

Examples:

- `ACCEPT TERMS OF USE: `
- `DESTRUCTIVE ACTION AUTHORIZATION: `
- `SELECT MENU OPTION: `

For a physical Enter-key action, say:

```text
PRESS THE ENTER KEY ONCE
Do NOT type the word ENTER.
```

For a typed stop command, say:

```text
TYPE: STOP
THEN press the ENTER key.
```

Do not visually present a physical key press and a typed command as if they are equivalent menu entries.

For the Terms gate:

```text
ACTION REQUIRED
Type exactly ACCEPT to agree and continue.
Anything else stops RescueMeAI safely and returns to the command prompt.

ACCEPT TERMS OF USE:
```

The actual interactive prompt must appear **once only**.

The general Terms `ACCEPT` phrase never authorizes a destructive recovery action.

## 8. Safe decline / cancellation behavior

If a user does not type the required legal-acceptance phrase, RescueMeAI must treat that as a safe decline/cancellation rather than an application failure.

The screen should clearly state:

- Terms acceptance was not recorded;
- authentication was not started;
- recovery actions were not started;
- destructive actions were not performed;
- Windows recovery state was not changed;
- ordinary RescueMeAI local logs may have been updated.

The application should then return directly to the interactive command prompt. It should not hold the screen behind an unnecessary `pause`.

## 9. Result screens

Every completed recovery step ends in exactly one overall state:

- `[PASS]`
- `[FAIL]`
- `[WARNING]`

Every result screen includes, where applicable:

- `RESULT`
- `WHAT HAPPENED`
- `WHY IT STOPPED` or `REASON`
- `WHAT YOU SHOULD DO`
- `WHAT HAPPENS NEXT`
- `ADDITIONAL INFORMATION REQUIRED`
- `ADDITIONAL INSTRUCTIONS`

When the active ChatGPT conversation is the continuation mechanism, a completed result must explicitly tell the user to send exactly `pass`, `fail`, or `warning` and then leave the PC window open.

Once authenticated private reporting is online, screenshots should normally not be requested.

## 10. Waiting and working screens

### WORKING

```text
PLEASE WAIT - RescueMeAI is working.
No action is required from you right now.
```

For long-running operations, also show progress/heartbeat information.

### WAITING

```text
RescueMeAI is still running and waiting for the next recovery instruction.
PLEASE WAIT - no action is required from you right now.
To stop safely while Status says WAITING, press S once.
```

Do not use this footer on a completed PASS/FAIL/WARNING result because those states require the user to notify the active conversation unless a future relay can continue automatically.

## 11. Background/remote activity visibility

The PC should show meaningful milestones for work coordinated remotely, for example:

- Reviewing the latest recovery result;
- Preparing the next recovery step;
- Waiting for the next recovery instruction;
- Command received;
- Verifying command integrity;
- Checking safety policy;
- Starting Windows diagnostic;
- Running built-in Windows repair;
- Preparing/downloading recovery source;
- Verifying files;
- Reassessing after repair;
- Reporting result;
- Waiting for user response.

Remote activity status is **display-only** and must remain isolated from the executable command channel. A status message can never authorize or execute a recovery action.

## 12. Long-running operations

For any operation expected to exceed roughly one minute, show periodic progress/heartbeat output so the user can distinguish slow work from a frozen process.

At minimum show:

- current task name;
- most recent progress value or stage;
- elapsed time;
- last activity time;
- `RescueMeAI is still running` heartbeat when there has been no visible percentage change for a reasonable interval.

Do not rapidly clear/redraw multiple screens for minor internal operations.

## 13. Progress persistence

Roadmap, readiness and current-operation state should be journaled locally so that after a safe RescueMeAI restart the UI can resume the visible journey instead of resetting to 0%.

Example:

```text
Recovery session resumed.
Completed stages : 3 of 10
Last completed   : Built-in Windows Repair
Current stage    : Boot Test / Reassess
Backup status    : RECOMMENDED
Recovery USB     : READY
```

## 14. Internet status

Internet status reflects the best available evidence, not just ICMP ping.

Priority:

1. Successful HTTPS request in the current execution path = `CONNECTED`
2. Confirmed HTTPS failure after network initialization = `NOT CONNECTED`
3. Before validation = `CHECKING`

A failed ping alone must not label the Internet disconnected when HTTPS is working.

## 15. Information density

Keep the permanent header compact. Detailed return codes, hashes, repository IDs, driver IDs, raw DISM/SFC/CHKDSK syntax, and internal implementation diagnostics belong in logs or dedicated FAIL/debug detail unless they help the immediate user decision.

The normal user-facing task should say what the tool is doing, for example `Checking Windows image health`, rather than forcing a novice user to interpret raw command-line syntax.

## 16. Safety visibility

Every screen that can lead to a write action must show the current Windows change level.

Tool risk is classified by exact operation, not merely executable name. For example, a read-only CHKDSK status check and a CHKDSK `/F` repair must not share the same risk label.

Destructive operations must be visually and textually distinct and require separate local authorization.

## 17. Compatibility

The WinRE UI remains pure Windows batch where practical. It does not depend on PowerShell, ANSI/VT escape processing, or external UI frameworks for its baseline presentation.

Optional helpers may be used when pinned/validated and when failure leaves the baseline UI functional.

If enhanced presentation is unavailable, text remains readable and explicit status labels remain authoritative.
