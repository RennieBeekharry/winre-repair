# AI Recovery Public Project Manifest

Last updated: 2026-08-14 10:50 ET

This public repository contains reusable AI Recovery code, safety policy, command protocols, templates, and sanitized examples. Machine-specific recovery history, private reports, identifiers, and credentials belong only in the user's configured private evidence/control backend.

## Public user result protocol

Every recovery action must end with exactly one state:

- `[PASS]` — green — successful completion. User reply word: `pass`.
- `[FAIL]` — red — a required step failed or execution stopped fail-closed. User reply word: `fail`.
- `[WARNING]` — amber/yellow — partial completion, interrupted state, denied local approval, or review required. User reply word: `warning`.

Every final result screen must clearly show:

1. `RESULT` — plain-language outcome.
2. `WHAT YOU SHOULD DO` — exact reply word (`pass`, `fail`, or `warning`).
3. `ADDITIONAL INFORMATION REQUIRED` — explicitly `None`, `paste ...`, or `screenshot ...`.
4. `ADDITIONAL INSTRUCTIONS` — any other required user action.

If the private evidence channel works, screenshots should normally not be required. If private upload fails, the program must explicitly request paste/screenshot evidence.

## Modular runtime

Reusable responsibilities are separated from current recovery actions:

- `lib/ui.cmd` — headers, colors, result presentation and user instructions.
- `lib/network.cmd` — WinRE networking and HTTP retrieval.
- `lib/reporting.cmd` — machine-readable local/USB result evidence.
- `lib/github-auth.cmd` + `lib/github-auth.js` — configurable GitHub authorization/reporting transport.
- `lib/safety.cmd` — authoritative local risk classification and destructive-action approval gate.
- `lib/agent-core.js` — validates private queued commands; never executes arbitrary shell text.
- `lib/runtime-sync.cmd` — synchronizes and validates reusable runtime modules.
- `wr-agent.cmd` — long-running WinRE command listener/orchestrator.
- `next.cmd` — current recovery action/orchestration only; reusable framework logic should not accumulate here.

## Command-agent protocol

The command transport is intentionally **not an unrestricted remote shell**.

Protocol v1 supports only these allowlisted actions:

- `RUN_NEXT`
- `PING`
- `STOP_AGENT`

A `RUN_NEXT` request must provide:

- unique increasing numeric `command_id`;
- exact target agent ID or wildcard only for non-destructive actions;
- risk classification (`READ_ONLY`, `REPAIR_WRITE`, or `DESTRUCTIVE`);
- immutable 40-character Git commit SHA;
- repository + file path;
- SHA-256 of the exact recovery command;
- issue/expiry timestamps.

The agent validates this metadata before any action is considered.

## Destructive-action boundary

Destructive operations are never authorized solely by GitHub, AI output, or a remote queue.

Local safety policy is authoritative and may increase risk but never decrease it. The immutable command script is scanned locally for high-impact operations. If local scanning discovers destructive behavior that remote/script metadata classified lower, execution fails closed.

A destructive command must:

- be classified `DESTRUCTIVE` by both the queue and command metadata;
- target the exact local agent ID (no wildcard);
- declare local approval required;
- clearly display action, exact target, consequence/risk, and rollback limitations;
- require a one-time phrase containing the command ID and local agent suffix typed at the physical/recovery console;
- journal that local authorization before execution.

Examples of actions that must remain behind this boundary include disk formatting/cleaning, destructive partition operations, image application/reinstallation, reset, destructive BCD/registry deletion, secure erase/wipe operations, and comparable high-impact changes.

## Replay and interruption protection

Before a queued action executes, its command ID is written to an in-flight journal. Both completed and in-flight IDs are considered handled for replay prevention.

If WinRE crashes or the machine reboots with an in-flight action, the agent must **not silently replay it**. The next start returns `WARNING` and requires review of the interrupted state.

## Public/private data boundary

Public repository:

- reusable code;
- safety rules;
- protocols;
- configuration templates;
- sanitized examples;
- public documentation.

Private/user-controlled backend:

- recovery history;
- detailed diagnostic reports;
- agent IDs and active command queue;
- machine-specific state;
- private source metadata where appropriate;
- authorization material.

Never commit user credentials or machine-private evidence to this public repository.

## Authentication release requirement

The public product must use a first-party AI Recovery GitHub OAuth App/GitHub App or another first-party backend authentication mechanism. Repository/user identity and OAuth client identity are configuration, not hard-coded application state.

`config/agent.example.cfg` documents the configuration contract. Development authentication identities must not be shipped as the final public identity.

## Recovery principles

1. Prefer the least destructive valid action first.
2. Separate diagnosis from repair where practical.
3. Validate target, applicability, integrity, and rollback/evidence path before writes.
4. Never let remote automation bypass destructive local approval.
5. Do not silently repeat failed or interrupted high-impact actions.
6. Preserve machine-readable evidence for every run.
7. Tell the user exactly what result occurred and exactly what they should do next.
8. Keep `next.cmd` small; shared functionality belongs in modules.
9. Treat malformed, stale, expired, out-of-order, or integrity-failed commands as fail-closed.
10. Reset/reinstall/erase paths remain last-resort operations requiring explicit local authorization.
