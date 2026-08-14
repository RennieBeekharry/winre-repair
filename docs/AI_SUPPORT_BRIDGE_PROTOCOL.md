# RescueMeAI™ AI Support Bridge Protocol

**Status:** Canonical architecture decision  
**Effective:** 2026-08-14

## Purpose

RescueMeAI keeps full recovery logs, manifests, journals, rollback evidence, and machine history on the user's computer or designated recovery media while still allowing an authorized AI/support session to inspect the information needed to diagnose and repair the machine.

The AI does **not** directly mount or browse the user's filesystem. A local RescueMeAI agent is the controlled bridge.

## Architecture

```text
OpenAI model / RescueMeAI support session
                |
                | authenticated structured requests
                v
        RescueMeAI Support Relay
        (ephemeral session transport)
                |
                | outbound TLS session
                v
       Local RescueMeAI Agent
                |
                | reads only requested data
                v
 C:\RescueMeAI\state / logs / evidence
```

The user's local state remains authoritative. The relay is not a permanent log repository.

## Product integration

The production RescueMeAI application should use the OpenAI API from a trusted RescueMeAI backend/relay rather than embedding an OpenAI API key in the recovery client.

The local recovery agent authenticates to the RescueMeAI relay with a short-lived session credential obtained through pairing. The relay holds provider credentials and invokes the configured AI model.

This makes the feature independent of whether an end user has a particular consumer ChatGPT subscription or supports custom ChatGPT connectors.

## Support session lifecycle

1. User starts RescueMeAI support/AI recovery.
2. Local agent creates a random session identifier and ephemeral key material.
3. User approves a short pairing code when required.
4. Local agent opens an outbound authenticated TLS connection to the RescueMeAI relay.
5. AI receives an initial **manifest summary**, not the full raw log tree.
6. AI requests additional evidence through allowlisted tools.
7. Local agent validates the request, reads the requested local information, redacts secrets, and returns a bounded response.
8. AI proposes or requests the next diagnostic/repair action.
9. Local safety engine validates the action independently.
10. Agent executes only allowed actions and writes the result to local state.
11. Relevant result/status is returned to the active AI session.
12. When the support session ends, relay session state expires automatically. Full recovery history remains local.

## Read-only AI tools

The initial protocol should expose small, purpose-built operations rather than arbitrary filesystem access:

### `get_recovery_status`
Returns:
- current recovery stage;
- last result;
- Windows build/edition/architecture;
- current known boot error;
- active recovery-plan identifier;
- whether Internet and recovery media are available.

### `get_manifest_summary`
Returns the compact current machine/recovery manifest without raw historical logs.

### `get_attempt_history`
Returns prior attempted fixes, outcomes, rollback status, and do-not-repeat markers.

### `search_local_logs`
Inputs:
- bounded search terms;
- allowed log categories;
- maximum results/bytes.

Returns only matching excerpts with source path, timestamp, and line/range metadata.

### `read_log_excerpt`
Inputs:
- exact allowlisted log identifier;
- start offset/line;
- maximum byte/line count.

The protocol must reject arbitrary path traversal.

### `get_diagnostic_artifact`
Returns an explicitly requested small diagnostic artifact or summary, subject to size and sensitivity checks.

### `list_available_evidence`
Returns metadata only: evidence type, timestamp, size, hash, and classification.

## Diagnostic execution tools

### `run_diagnostic`
Runs only a named diagnostic from RescueMeAI's signed/allowlisted diagnostic catalog.

Examples:
- storage/controller inventory;
- offline DISM package inventory;
- boot configuration inspection;
- driver/service inspection;
- SFC verification;
- filesystem health read-only checks.

Results are stored locally first, then the relevant summary is returned to the AI session.

## Repair tools

### `propose_repair`
AI describes the intended repair, evidence, expected effect, risk class, rollback strategy, and required source package/driver.

### `execute_repair`
Permitted only after:
- immutable action package validation;
- local safety classification;
- target validation;
- prerequisite checks;
- rollback/evidence preparation where applicable.

The AI/relay cannot reduce risk classification.

## Destructive actions

Destructive actions remain a separate local authorization boundary.

The support relay, OpenAI model, ChatGPT session, GitHub, remote command queue, or other remote service cannot independently authorize:

- disk clean/format/repartition;
- destructive image application;
- reset/reinstall that removes user data;
- destructive registry/BCD deletion;
- equivalent high-impact operations.

A physically present user must enter the action-specific local authorization phrase.

## Data returned to AI

Default responses should be structured summaries rather than entire logs.

Example:

```json
{
  "stage": "boot_storage_diagnosis",
  "windows_build": "26100.9168",
  "boot_error": "INACCESSIBLE_BOOT_DEVICE",
  "storage_controller": "Intel 100 Series/C230 SATA AHCI",
  "active_driver": "iaStorA",
  "recent_attempts": [
    {"action":"bind iaStorAC","result":"failed_0x7b","rolled_back":true},
    {"action":"inject Intel 16.7.1.1012","result":"installed_no_boot_fix"}
  ],
  "requested_excerpt": {
    "source":"startup-repair.log",
    "lines":25,
    "redacted":true
  }
}
```

## Redaction and secret handling

Before transmission, the local agent must inspect outgoing evidence for:

- access/refresh tokens;
- API keys;
- passwords;
- BitLocker/encryption recovery keys;
- cookies/session secrets;
- private keys;
- unrelated personal-file contents.

Known secret classes must be removed or replaced with redaction markers.

The AI should receive the existence/state of a secret when diagnostically relevant, not the secret value itself.

## Bounded transport

Every read request has limits:

- maximum lines;
- maximum bytes;
- allowed source category;
- exact session ID;
- expiration;
- request ID;
- risk/read classification.

Large logs are searched locally first. Only relevant matching fragments are transmitted.

## Relay retention

The relay should keep only enough transient state to deliver requests/responses reliably.

Default production policy:
- raw recovery logs: no durable relay storage;
- transient request/response buffers: short TTL;
- session routing metadata: TTL-bound;
- audit/security events: minimal metadata, not raw user logs;
- user may explicitly create/upload a support bundle if longer retention is needed.

## Offline fallback

If Internet is unavailable, RescueMeAI continues local diagnosis and logging.

The user can later:
- resume the same AI support session when connectivity returns; or
- export a redacted RescueMeAI support bundle and provide it manually.

## Current ChatGPT development limitation

An ordinary ChatGPT conversation cannot directly open `C:\RescueMeAI` on the user's recovery computer.

Until the RescueMeAI support bridge is deployed, development requires a temporary transport such as:
- the existing private development evidence repository;
- an explicitly uploaded support bundle;
- manually supplied diagnostic output.

The private GitHub evidence repository is therefore a temporary development transport only. It is no longer the target production architecture and must not be treated as the canonical machine state.

## GitHub after migration

GitHub remains suitable for:
- RescueMeAI source;
- releases and immutable source commits;
- signed update metadata;
- generic diagnostic definitions;
- documentation and legal files.

GitHub should not be the production store for individual users' raw recovery logs or manifests.
