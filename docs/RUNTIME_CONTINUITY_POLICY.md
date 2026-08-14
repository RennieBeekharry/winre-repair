# RescueMeAI Runtime Continuity Policy

**Status:** Canonical architecture decision  
**Effective:** 2026-08-14

## Objective

RescueMeAI must distinguish between a failure of the RescueMeAI application itself and a failure of a diagnostic/recovery action being performed by a healthy RescueMeAI runtime.

The user should not have to relaunch RescueMeAI merely because a diagnosis, repair attempt, network request, or remote command fails. Once the authenticated recovery agent is online, the default behavior is to remain alive, report the result, and wait for the next validated instruction.

## Failure classes

### 1. `APP_FATAL`

The RescueMeAI application cannot safely continue executing.

Examples:
- required executable/runtime component is missing or corrupt;
- required signed/validated module cannot be loaded;
- local configuration cannot be parsed or reconstructed safely;
- local safety engine is unavailable;
- runtime invariants are corrupted;
- the agent itself crashes or cannot initialize sufficiently to enforce policy.

Required behavior:
1. fail closed;
2. write local/USB/private evidence when possible;
3. clearly display `[APP_FATAL]` and the reason;
4. perform no further recovery actions;
5. restore the normal Command Prompt title/color;
6. return to the WinRE command prompt.

The user may then report `fail`; ChatGPT/RescueMeAI can publish a corrected bootstrap/application build and ask the user to run `C:\wr.cmd` again.

### 2. `SESSION_DEGRADED`

The RescueMeAI process and local safety controls are healthy, but an external dependency or active support-session component is temporarily unavailable.

Examples:
- Internet temporarily unavailable;
- GitHub/API endpoint unavailable;
- token refresh temporarily fails;
- private report upload fails;
- control queue cannot be reached;
- a remote command fails schema/integrity/target validation;
- the queue contains malformed or unsafe content.

Required behavior:
1. execute nothing that failed validation;
2. report `WARNING` or `FAIL` as appropriate;
3. preserve the agent process;
4. use bounded retry/backoff for transient conditions;
5. keep polling for a corrected/next command when safe;
6. never weaken local safety policy to restore connectivity;
7. escalate to `APP_FATAL` only if the local runtime itself can no longer enforce safety or make progress safely.

For malformed/unsafe queue content, execution is quarantined/fail-closed while the listener remains alive. A corrected higher command may be accepted only after normal replay, freshness, target, risk, and integrity validation.

### 3. `ACTION_RESULT`

A diagnostic or recovery action completed with `PASS`, `FAIL`, or `WARNING` while RescueMeAI itself remains healthy.

Examples:
- DISM diagnostic fails;
- a driver repair does not fix boot;
- an immutable recovery command cannot download;
- SFC finds corruption;
- a repair succeeds;
- local destructive authorization is declined;
- a safety gate blocks an action.

Required behavior:
1. journal the command result;
2. upload/private-report when available;
3. display `PASS`, `FAIL`, or `WARNING` clearly;
4. remain in the persistent listener loop;
5. wait for the next validated AI command;
6. do not return to the WinRE command prompt solely because the recovery action failed.

## User interaction

After the persistent agent is online, the normal user-facing protocol remains intentionally small:

- `pass`
- `fail`
- `warning`

These replies are acknowledgements/fallback communication, not triggers that restart RescueMeAI. The agent should already be alive and waiting for the next instruction.

When private reporting is healthy, ChatGPT/RescueMeAI can normally inspect the uploaded result directly. The user should only need to send a screenshot/paste evidence when the private reporting channel itself is unavailable or when explicit local authorization is required.

## Persistent screen behavior

While the agent is healthy, the console should remain owned by RescueMeAI and show one of:

- `ONLINE / WAITING FOR NEXT COMMAND`
- `RUNNING COMMAND <id>`
- `ACTION PASS / WAITING`
- `ACTION FAIL / WAITING FOR NEXT COMMAND`
- `WARNING / RETRYING`
- `LOCAL AUTHORIZATION REQUIRED`

Only `APP_FATAL`, explicit `STOP_AGENT`, intentional reboot/transition, or user-requested exit should normally return to the WinRE command prompt.

## Safety invariants

Runtime continuity must never become an excuse to retry unsafe operations automatically.

- An interrupted in-flight command is never silently replayed.
- A failed destructive authorization remains blocked.
- A malformed/unsafe queue item is never executed.
- A command failing integrity validation is never downloaded/executed repeatedly without a new validated command decision.
- Repeated transient failures use bounded backoff and produce evidence rather than tight loops.
- Local safety classification may increase risk but never decrease it.
- Remote AI/GitHub/backend instructions cannot authorize destructive actions without the existing local physical authorization boundary.

## Current implementation alignment

The existing RescueMeAI persistent agent already keeps running after normal recovery-command `PASS`, `FAIL`, and `WARNING` results and after temporary command-channel outages. This policy formalizes that behavior.

The current full-stop behavior for an invalid command queue should be evolved to a quarantine-and-wait state after the persistent channel is proven, while preserving fail-closed execution semantics.

## Recovery-session priority

During the active Windows recovery, avoid a wholesale runtime rewrite solely to implement this policy. Prefer the smallest safe change required to keep the current agent operational. Product-hardening work can complete the full state-machine implementation after the current machine is recovered.
