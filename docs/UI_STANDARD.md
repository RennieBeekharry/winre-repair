# RescueMeAI™ Console UI Standard

**UI standard version:** 2026-08-14.4

RescueMeAI runs in environments where the user may be under stress, working from WinRE, or reading a low-resolution console. The UI must favor clarity, consistency, and minimal interaction over decorative complexity.

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
5. Current step/mode
6. Safety level: `READ ONLY`, `REPAIR WRITE`, or `DESTRUCTIVE - LOCAL APPROVAL REQUIRED`
7. Legal repository URL
8. Legal landing filename

Recommended layout:

```text
================================================================================================
                                           RESCUEMEAI
                                  AI-ASSISTED WINDOWS RECOVERY
================================================================================================
Version      : RMAI-...
Internet     : [CONNECTED]
Current Step : TERMS AND RECOVERY RISK ACCEPTANCE
Safety       : REPAIR WRITE - NON-DESTRUCTIVE
Legal        : https://github.com/RennieBeekharry/winre-repair
Legal file   : LEGAL.md
================================================================================================
```

The shorter repository URL deliberately replaces a long direct `blob/main/LEGAL.md` URL. The next line identifies `LEGAL.md`. This keeps the legal reference readable and within the console boundary.

## 4. Central WinRE screen-theme renderer

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

The central renderer applies the selected theme with the Windows `color` command. Individual modules still communicate semantic states such as PASS, WARNING, ERROR, and INFO, but they do not embed color codes.

A future full Windows graphical/terminal UI may provide richer per-component coloring without changing the semantic message model.

Color must never be the only status signal. Text must explicitly identify `[PASS]`, `[FAIL]`, `[WARNING]`, `[CONNECTED]`, and similar states.

## 5. Output wrapping

User-facing paragraphs, warnings, instructions, paths, and diagnostic explanations must be passed through the shared wrapping function when they could exceed the configured text width.

The renderer should wrap at word boundaries where practical. Single values that cannot be broken safely should be displayed on their own line or shortened to a stable landing URL/reference.

No ordinary RescueMeAI output should rely on the console performing uncontrolled automatic wrapping.

## 6. User prompts

Prompts must describe the required action instead of generic labels such as `Selection:`.

Examples:

- `ACCEPT TERMS OF USE: `
- `DESTRUCTIVE ACTION AUTHORIZATION: `
- `SELECT MENU OPTION: `

For the Terms gate:

```text
ACTION REQUIRED
Type exactly ACCEPT to agree and continue.
Anything else stops RescueMeAI safely and returns to the command prompt.

ACCEPT TERMS OF USE:
```

The actual interactive prompt must appear **once only**. Do not render a separate duplicate prompt label immediately before `set /p` or another input primitive.

The general Terms `ACCEPT` phrase never authorizes a destructive recovery action.

## 7. Safe decline / cancellation behavior

If a user does not type the required legal-acceptance phrase, RescueMeAI must treat that as a safe decline or cancellation rather than an application failure.

The screen should clearly state:

- Terms acceptance was not recorded;
- authentication was not started;
- recovery actions were not started;
- destructive actions were not performed;
- Windows recovery state was not changed;
- ordinary RescueMeAI local logs may have been updated.

The application should then return directly to the interactive command prompt. It should not hold the screen behind an unnecessary `pause`.

## 8. Result screens

Every completed recovery step ends in exactly one overall state:

- `[PASS]`
- `[FAIL]`
- `[WARNING]`

Every result screen includes, where applicable:

- `RESULT`
- `WHAT HAPPENED`
- `WHY IT STOPPED` or `REASON`
- `WHAT YOU SHOULD DO`
- `ADDITIONAL INFORMATION REQUIRED`
- `ADDITIONAL INSTRUCTIONS`

Once authenticated private reporting is online, screenshots should normally not be requested.

## 9. Internet status

Internet status reflects the best available evidence, not just ICMP ping.

Priority:

1. Successful HTTPS request in the current execution path = `CONNECTED`
2. Confirmed HTTPS failure after network initialization = `NOT CONNECTED`
3. Before validation = `CHECKING`

A failed ping alone must not label the Internet disconnected when HTTPS is working.

## 10. Information density

Keep the permanent header compact. Detailed return codes, hashes, repository IDs, driver IDs, and internal implementation diagnostics belong on FAIL/debug screens only when they help the immediate recovery decision.

## 11. Safety visibility

Every screen that can lead to a write action must show the current safety class. Destructive operations must be visually and textually distinct and require separate local authorization.

## 12. Compatibility

The WinRE UI remains pure Windows batch where practical. It does not depend on PowerShell, JScript, ANSI/VT escape processing, or external UI frameworks for its baseline presentation.

If enhanced presentation is unavailable, text remains readable and explicit status labels remain authoritative.
