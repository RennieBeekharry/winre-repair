# RescueMeAI™ Local-First State and Support Architecture

**Status:** Canonical architecture decision  
**Effective:** 2026-08-14

## Decision

RescueMeAI recovery state is **local-first**.

GitHub is the product source/release/update channel. Raw recovery logs, machine manifests, command journals, rollback evidence, acceptance records, credentials, and per-user recovery history are not long-term Git repository content.

The user's recovery computer and designated recovery media are the source of truth for that user's recovery state.

## Why

Storing per-machine recovery evidence in Git repositories creates avoidable problems:

- unbounded repository growth;
- poor multi-user isolation;
- permanent Git history for sensitive diagnostics;
- difficult deletion and retention semantics;
- unnecessary exposure risk if repository visibility changes;
- coupling support telemetry to source control;
- operational cost and complexity as RescueMeAI scales to many users.

## Canonical local layout

New RescueMeAI installations should use:

```text
C:\RescueMeAI\
├── app\
│   └── runtime\
├── state\
│   ├── manifest.json
│   ├── current-session.json
│   ├── command-journal.jsonl
│   ├── acceptance.json
│   └── recovery-plan.json
├── logs\
│   ├── current\
│   └── archive\
├── evidence\
│   ├── diagnostics\
│   ├── rollback\
│   └── support-bundles\
├── auth\
└── cache\
```

During the current recovery, `C:\WinRERepair` remains a compatibility path. Migration to `C:\RescueMeAI` must be copy/verify/switch-first and must not destroy existing rollback evidence.

## Recovery media mirror

When a designated `REPAIRDATA` volume is available, RescueMeAI may maintain a local backup mirror such as:

```text
REPAIRDATA:\RescueMeAI\
├── state\
├── logs\
├── evidence\
└── support-bundles\
```

The mirror is local removable-media backup, not cloud telemetry.

## GitHub responsibilities

The RescueMeAI source repository may contain:

- application source code;
- signed or immutable release/update metadata;
- legal documents;
- public documentation;
- recovery workflow definitions;
- safety schemas and validators;
- non-user-specific test fixtures;
- generic diagnostic signatures;
- anonymized aggregate engineering knowledge that cannot identify a user or machine.

The repository must not normally contain:

- raw user recovery logs;
- machine-specific manifests;
- hardware serial numbers or unique machine identifiers unless they are synthetic fixtures;
- per-user command journals;
- BitLocker recovery material;
- authentication tokens or refresh tokens;
- passwords, API keys, or secrets;
- personal-file contents;
- persistent copies of support-session transcripts or raw evidence.

## Multi-user isolation

Each RescueMeAI installation/session owns its local state independently.

A randomly generated RescueMeAI installation/session identifier may be used for routing and audit correlation. It should not encode a username, email address, computer name, serial number, or other direct personal identifier.

No user's recovery history is stored in another user's workspace.

## Log retention and rotation

RescueMeAI should prevent unlimited local growth.

Recommended defaults:

- keep the active session log in `logs\current`;
- rotate completed sessions into `logs\archive`;
- enforce both age and size limits;
- preserve explicitly pinned recovery evidence and rollback artifacts even when ordinary logs rotate;
- allow the user to export a support bundle before deletion;
- never delete rollback evidence that an active recovery plan still references.

Initial product defaults should target a modest bounded footprint rather than indefinite accumulation. Exact retention values are configurable and may vary by support or enterprise policy.

## Support-session transport

ChatGPT or another support provider cannot directly browse a user's `C:\RescueMeAI` filesystem from an ordinary chat session.

A RescueMeAI support agent therefore acts as the local broker.

The preferred production flow is:

```text
Local RescueMeAI state
        ↓
Local redaction / minimization
        ↓
Outbound authenticated TLS support session
        ↓
Ephemeral RescueMeAI relay
        ↓
Authorized AI/support session
```

The relay is transport, not the canonical evidence store.

## Data minimization

The local agent should send only what the active support task needs, for example:

- current stage and result;
- return/error codes;
- relevant OS/build/driver/package metadata;
- explicitly requested bounded log excerpts;
- integrity hashes;
- command ID and safety classification;
- a concise summary of prior attempted repairs.

It should not upload an entire raw log tree by default.

Before transmission, RescueMeAI should detect/redact common secrets and reject known highly sensitive material such as authentication tokens and encryption recovery keys.

## Ephemeral remote retention

Production support-session data should default to no durable raw-log storage, or to short bounded retention strictly required for reliability/security.

If temporary server-side buffering is necessary:

- encrypt in transit and at rest;
- bind data to the exact support session;
- use a short TTL;
- delete automatically after expiry;
- do not place support payloads into Git history;
- disclose the retention behavior in the Privacy Policy.

Enterprise deployments may configure longer retention under their own policy, but local-first remains the default architecture.

## Offline operation

RescueMeAI must remain useful without Internet access.

Diagnosis, local logging, recovery manifest maintenance, safety gates, rollback evidence, and supported offline repairs must continue locally.

When connectivity returns, a user may optionally begin a support session or export a support bundle.

## Support bundles

RescueMeAI should support an explicit local export such as:

```text
RescueMeAI-Support-<session-id>-<timestamp>.zip
```

A support bundle should contain only selected recovery-relevant evidence, include a manifest of its contents and hashes, and exclude local credentials/secrets.

Support-bundle creation is not equivalent to uploading it.

## Telemetry and product improvement

Product-improvement telemetry is separate from recovery evidence.

Future telemetry should be opt-in or otherwise appropriately disclosed, privacy-minimized, aggregated where possible, and designed around event metrics such as:

- issue category;
- whether diagnosis succeeded;
- whether a repair succeeded;
- whether a rollback occurred;
- application crash/failure category;
- anonymous version/platform statistics.

Raw personal recovery logs must not be treated as ordinary product analytics.

## Current development transition

The existing `winre-repair-logs` private repository is a temporary development artifact from the early remote-reporting prototype.

Migration policy:

1. Stop adding new raw recovery evidence to Git repositories.
2. Preserve the existing private repository temporarily as historical development evidence/rollback.
3. Move the active recovery manifest/log/journal source of truth to local storage.
4. Implement the ephemeral support-session transport.
5. Verify local recovery state survives reboot and can be backed up to `REPAIRDATA`.
6. Archive the old log repository after the new architecture is proven.
7. Delete the old repository only through a separate explicit owner decision.

## Safety boundary

Changing where evidence is stored must never change the recovery risk classification of an action.

Terms acceptance remains separate from destructive-action authorization. Remote support access remains unable to authorize destructive recovery operations by itself.
