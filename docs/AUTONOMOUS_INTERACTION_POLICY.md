# RescueMeAI Autonomous Interaction Policy

RescueMeAI should minimize human relay work. The private recovery channel and local evidence journal are the normal control and reporting paths.

## Default behavior

- PASS, FAIL, and WARNING results are uploaded automatically and must not require the user to type or relay those words to ChatGPT.
- WORKING screens tell the user what is happening and show measurable progress when available.
- WAITING screens state that RescueMeAI is online, waiting for the next validated command, and that no action is required.
- Normal recovery results remain visible long enough to be understandable, but the agent continues its safe command-listener lifecycle without a human acknowledgement handshake.

## Human interruption boundary

A human prompt is justified only when the next safe step depends on information or a physical/local action RescueMeAI cannot safely infer or perform itself. Examples include:

- inserting or removing recovery media when presence cannot be changed by software;
- connecting a backup drive;
- entering a BitLocker recovery key or other secret locally;
- choosing between genuinely ambiguous physical devices when automatic identification is insufficient;
- approving a destructive action through the existing exact local typed authorization phrase;
- responding to APP_FATAL when the private reporting/control channel itself is unavailable.

Whenever a local action is required, RescueMeAI should verify completion automatically when technically possible. Example: after asking the user to remove a recovery USB, poll for verified media removal and continue automatically instead of asking the user to type `pass`.

## Screenshots

Screenshots are fallback evidence, not the normal reporting mechanism. Request one only when:

- private evidence upload is unavailable or incomplete;
- the relevant state is visual/firmware-only and cannot be collected programmatically;
- APP_FATAL prevents automatic reporting;
- the user needs to show an unexpected boot/firmware/BSOD screen that the running agent cannot observe.

## Safety invariants

Automation does not weaken safety boundaries. Destructive operations still require explicit local authorization. Remote metadata cannot downgrade risk. Interrupted commands are never silently replayed. APP_FATAL remains fail-closed. Physical actions that affect boot safety must be verified before automatic continuation when possible.
