# RescueMeAI™ Console UI Standard

**UI standard version:** 2026-08-14.3

RescueMeAI runs in environments where the user may be under stress, working from WinRE, or reading a low-resolution console. The UI must favor clarity, consistency, and minimal interaction over decorative complexity.

## 1. Display geometry

The WinRE console should attempt a lightweight display setup of approximately **100 columns x 50 lines**. If the environment refuses the resize, RescueMeAI continues without treating that as a recovery failure.

The RescueMeAI visual boundary is **96 columns**. Normal body text is wrapped to **92 characters or fewer** so that user-facing output does not spill beyond the boundary.

Do not manually print long unbounded diagnostic strings on ordinary screens. Long content must go through the shared wrapping renderer.

## 2. Standard screen header

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

## 3. Central semantic color renderer

Individual screens and recovery modules must **not choose hexadecimal console colors**.

All user-facing output goes through one semantic UI renderer. Callers identify the meaning of the output and the renderer maps it to a color centrally.

Supported semantic types:

- `HEADER` → light aqua
- `INFO` → light blue
- `PASS` / `SUCCESS` → light green
- `WARNING` → yellow
- `ERROR` / `FAIL` → light red
- `INSTRUCTION` → bright white
- `PROMPT` → light purple
- `LABEL` → normal white
- `MUTED` → gray

### WinRE rendering backend

Pairing-6 established that `findstr /a:<colorattribute>` rendered as monochrome in the active WinRE console even though the text itself displayed correctly. RescueMeAI therefore no longer relies on `findstr /a` for the primary semantic color path.

The primary renderer now emits each semantic line through a short child `cmd.exe` process using `cmd /t:<colorattribute>`. The semantic mapping remains centralized in one function; callers never embed the color code themselves.

If the environment cannot render enhanced color, RescueMeAI must remain fully understandable in monochrome. Color is supplemental, never authoritative.

Color must never be the only status signal. Text must still explicitly identify `[PASS]`, `[FAIL]`, `[WARNING]`, `[CONNECTED]`, and similar states.

## 4. Output wrapping

User-facing paragraphs, warnings, instructions, paths, and diagnostic explanations must be passed through the shared wrapping function when they could exceed the configured text width.

The renderer should wrap at word boundaries where practical. Single values that cannot be broken safely should be displayed on their own line or shortened to a stable landing URL/reference.

No ordinary RescueMeAI output should rely on the console performing uncontrolled automatic wrapping.

## 5. User prompts

Prompts must describe the required action instead of generic labels such as `Selection:`.

Examples:

- `ACCEPT TERMS OF USE: `
- `DESTRUCTIVE ACTION AUTHORIZATION: `
- `SELECT MENU OPTION: `

For the Terms gate:

```text
[ACTION REQUIRED]
Type exactly ACCEPT to agree and continue.
Anything else stops RescueMeAI safely.

ACCEPT TERMS OF USE:
```

The actual interactive prompt must appear **once only**. Do not render a separate duplicate prompt label immediately before `set /p` or another input primitive.

The general Terms `ACCEPT` phrase never authorizes a destructive recovery action.

## 6. Result screens

Every completed step ends in exactly one overall state:

- `[PASS]`
- `[FAIL]`
- `[WARNING]`

Every result screen includes:

- `RESULT`
- `WHAT YOU SHOULD DO`
- `ADDITIONAL INFORMATION REQUIRED`
- `ADDITIONAL INSTRUCTIONS`

Once authenticated private reporting is online, screenshots should normally not be requested.

## 7. Internet status

Internet status reflects the best available evidence, not just ICMP ping.

Priority:

1. Successful HTTPS request in the current execution path = `CONNECTED`
2. Confirmed HTTPS failure after network initialization = `NOT CONNECTED`
3. Before validation = `CHECKING`

A failed ping alone must not label the Internet disconnected when HTTPS is working.

## 8. Information density

Keep the permanent header compact. Detailed return codes, hashes, repository IDs, driver IDs, and internal implementation diagnostics belong on FAIL/debug screens only when they help the immediate recovery decision.

## 9. Safety visibility

Every screen that can lead to a write action must show the current safety class. Destructive operations must be visually and textually distinct and require separate local authorization.

## 10. Compatibility

The WinRE UI remains pure Windows batch where practical. It does not depend on PowerShell, JScript, ANSI/VT escape processing, or external UI frameworks.

The shared renderer uses Windows-native `cmd.exe` and console facilities already expected in the RescueMeAI recovery environment. If enhanced coloring cannot be rendered, text remains readable and status labels remain authoritative.
