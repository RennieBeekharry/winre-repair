# AI Recovery Public Onboarding Architecture

Status: design baseline
Updated: 2026-08-14

## Product goal

A normal user should need as little as possible to begin an AI-assisted Windows recovery session.

Target minimum dependencies:

1. Internet connectivity from WinRE or the recovery environment.
2. A ChatGPT account.
3. One paired recovery backend that both the recovery agent and ChatGPT can communicate through.

GitHub is the first development/reference backend. The architecture must not make GitHub mandatory forever; a future AI Recovery relay/service or another compatible provider may implement the same control/evidence contract.

## Critical continuity principle

AI Recovery must NOT depend on ChatGPT conversation memory to remember recovery progress.

The durable source of truth is the external recovery state:

- recovery manifest;
- attempted-action ledger;
- completed/failed/warning results;
- do-not-repeat entries;
- current machine/recovery state;
- current command sequence;
- next-planned actions;
- selected diagnostic evidence.

A new ChatGPT conversation can therefore resume safely after loading the current external state. Conversation memory is an optional convenience, not a correctness dependency.

## Desired first-use experience

### On the recovery PC

The user starts one small bootstrap/agent command.

The agent:

1. initializes WinRE networking;
2. generates a random local agent/session identifier;
3. contacts the configured recovery backend over outbound HTTPS;
4. displays a short one-time pairing code and phone URL;
5. waits for authorization;
6. receives a narrowly scoped session credential;
7. creates/opens the private recovery manifest and evidence channel;
8. uploads an ONLINE/PAIRING-COMPLETE report;
9. enters LISTENING mode.

The user should never have to manually type a long API token.

### On the user's phone

The user:

1. opens the displayed pairing URL;
2. signs in to the chosen backend/provider;
3. enters the short one-time code;
4. reviews the requested permissions;
5. approves the recovery session.

The pairing code must be short-lived and single-use.

### In ChatGPT

The user connects or invokes AI Recovery and says what they need help with.

AI Recovery reads the private recovery manifest/evidence, proposes or writes the next validated command through the paired backend, and waits for the recovery agent result.

The user-facing response loop is standardized:

- `pass`
- `fail`
- `warning`

The program may additionally request `paste ...`, `screenshot ...`, or another explicit instruction only when the machine-readable evidence channel is insufficient.

## Result protocol

Every recovery action ends with exactly one state:

- `[PASS]` — green — reply `pass`.
- `[FAIL]` — red — reply `fail`.
- `[WARNING]` — amber/yellow — reply `warning`.

Every terminal result must include:

1. RESULT
2. WHAT YOU SHOULD DO
3. ADDITIONAL INFORMATION REQUIRED
4. ADDITIONAL INSTRUCTIONS

When automatic private reporting succeeds, `ADDITIONAL INFORMATION REQUIRED` should normally be `None`.

## Backend abstraction

Define a backend interface rather than hard-coding GitHub throughout the product.

Required logical operations:

- pair/start session;
- authenticate/re-authenticate;
- read current control command;
- write run report;
- read/write recovery manifest;
- append immutable/timestamped history evidence;
- revoke session;
- report provider/network errors.

Reference providers:

### Provider A: GitHub

Use a dedicated private repository as the control/evidence store during development.

Suggested logical paths:

- `control/current-command.json`
- `RECOVERY_MANIFEST.md`
- `reports/LATEST_RUN_REPORT.txt`
- `reports/history/...`
- `reports/inbox/...`

The public reusable code must not hard-code a developer username, repository name, token, or machine identifier.

### Provider B: AI Recovery Relay (future preferred public UX)

A first-party relay can reduce GitHub-specific setup and make the user experience closer to:

Internet + ChatGPT + one-time pairing code.

The relay should expose only the narrow AI Recovery protocol, not an arbitrary remote shell.

## ChatGPT integration boundary

The recovery agent must not assume that a particular ChatGPT plan provides persistent memory or unrestricted GitHub write access.

The product should instead expose a dedicated AI Recovery app/action surface capable of:

- reading the recovery manifest and selected reports;
- writing only validated command-envelope objects;
- updating the planned-next-action state;
- never bypassing local destructive authorization.

Where direct write actions are unavailable, the product may fall back to a guided/manual mode, but automatic agent control requires a write-capable paired integration.

## Free-plan compatibility target

AI Recovery should be architected so that premium ChatGPT memory/context features are not required for correctness.

External manifest/evidence is the source of truth. A smaller-context or new ChatGPT session can reconstruct the recovery state by reading:

1. current manifest;
2. latest run report;
3. current command state;
4. only the minimal historical evidence needed for the next decision.

This also reduces token/context usage for paid plans.

Actual app/plugin availability may vary by ChatGPT plan, geography, or platform. Therefore Free compatibility is a product target, not something the recovery agent should assume without capability detection.

## Command channel is not a remote shell

The backend may request only allowlisted protocol actions.

Protocol v1 currently allows:

- `RUN_NEXT`
- `PING`
- `STOP_AGENT`

`RUN_NEXT` references immutable recovery code and integrity metadata. It does not contain arbitrary shell commands.

Required fields include:

- monotonically increasing command ID;
- exact or allowed target agent;
- risk classification;
- immutable source commit;
- file path;
- SHA-256;
- issued/expiry time.

The recovery PC independently verifies the command before execution.

## Destructive-action security boundary

Remote AI/backend authorization is insufficient for destructive operations.

Destructive actions require local human authorization at the recovery console after the program displays:

- exact proposed action;
- exact target;
- why it is being proposed;
- expected consequences;
- what data may be lost;
- rollback limitations;
- command/session identity;
- one-time local authorization phrase.

The user must type the exact phrase locally.

The local safety module may increase a command's risk classification, but may never decrease it.

If local analysis detects destructive behavior that was classified lower by the backend or recovery script metadata, the command fails closed.

## Credential design

Do not require users to manually enter long personal-access tokens.

Preferred properties:

- one-time device/pairing code;
- short expiry;
- narrowly scoped backend access;
- revocable session;
- no credential in logs or reports;
- no credential committed to source control;
- no credential echoed to the terminal;
- automatic reauthorization when expired/revoked;
- clear reason on authorization failure.

## Crash/replay protection

A command is journaled as in-flight before execution.

An in-flight command is never automatically replayed after WinRE restart/crash. The next session reports WARNING and requires recovery-state review.

Completed and in-flight command IDs are treated as already handled for replay prevention.

## Public/private separation

Public repository:

- code;
- protocol definitions;
- safety policy;
- generic documentation;
- examples/templates.

Private recovery store:

- machine-specific diagnostic evidence;
- current and historical recovery manifest;
- agent/session identifiers;
- queued command state;
- sensitive environment details;
- private reports.

## Long-term ideal UX

The eventual public experience should approach:

1. User boots into recovery.
2. User launches AI Recovery once.
3. Terminal displays a one-time pairing code.
4. User enters code on phone and approves.
5. User opens ChatGPT and connects/invokes AI Recovery.
6. AI Recovery loads the external manifest automatically.
7. Agent and ChatGPT exchange validated commands/results through the paired backend.
8. User normally responds only `pass`, `fail`, or `warning`.
9. Destructive actions always stop for explicit local explanation + authorization.
10. Recovery can resume in a new ChatGPT conversation by reloading the external state.

That is the public onboarding target. GitHub is an implementation provider, not the product's conceptual center.
