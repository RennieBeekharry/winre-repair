# RescueMeAI™ Console UI Standard

**UI standard version:** 2026-08-14

RescueMeAI runs in environments where the user may be under stress, working from WinRE, or reading a low-resolution console. The UI must favor clarity, consistency, and minimal interaction over decorative complexity.

## 1. Standard screen header

Every user-facing RescueMeAI screen should begin with the same compact information hierarchy:

1. Centered product name: `RESCUEMEAI`
2. Centered one-line description of the current application/context
3. Version
4. Internet connection: `CONNECTED`, `NOT CONNECTED`, or `CHECKING`
5. Current step/mode
6. Safety level: `READ ONLY`, `REPAIR WRITE`, or `DESTRUCTIVE - LOCAL APPROVAL REQUIRED`
7. Legal URL

Recommended layout:

```text
========================================================================
                              RESCUEMEAI
                    AI-ASSISTED WINDOWS RECOVERY
========================================================================
 Version     : RMAI-...
 Internet    : CONNECTED
 Current Step: Secure GitHub App Pairing
 Safety      : REPAIR WRITE - NON-DESTRUCTIVE
 Legal       : https://github.com/.../LEGAL.md
========================================================================
```

The product name and one-line description should be centered within the 72-character console layout. Metadata stays left-aligned for fast scanning.

## 2. Color model

Use native console `color` commands because ANSI support is not guaranteed in every WinRE build. Color is applied per screen rather than per individual line.

- Neutral/startup: `07`
- Information/pairing: `0B`
- Terms/caution/warning: `0E`
- PASS/success: `0A`
- FAIL/error: `0C`
- Destructive authorization: `0C` until explicit local approval succeeds

Color must never be the only way status is communicated. Always include text such as `[PASS]`, `[FAIL]`, `[WARNING]`, `[CONNECTED]`, or `[NOT CONNECTED]`.

## 3. User prompts

Prompts must describe the required action instead of using generic labels such as `Selection:`.

Examples:

- `ACCEPT TERMS OF USE: `
- `ENTER GITHUB DEVICE CODE ON PHONE: ` only if local entry is actually required
- `DESTRUCTIVE ACTION AUTHORIZATION: `
- `SELECT MENU OPTION: `

For the Terms gate, the application must state:

```text
Type exactly ACCEPT to agree and continue.
Anything else stops RescueMeAI safely.

ACCEPT TERMS OF USE:
```

## 4. Result screens

Every completed step must end in exactly one overall state:

- `[PASS]`
- `[FAIL]`
- `[WARNING]`

Every result screen must include:

- `RESULT`
- `WHAT YOU SHOULD DO`
- `ADDITIONAL INFORMATION REQUIRED`
- `ADDITIONAL INSTRUCTIONS`

When private reporting is online, screenshots should normally not be requested.

## 5. Internet status

Internet status should reflect the best evidence available, not just ICMP ping.

Priority:

1. Successful HTTPS request in the current execution path = `CONNECTED`
2. Confirmed HTTPS failure after network initialization = `NOT CONNECTED`
3. Before validation = `CHECKING`

A failed ping alone must not label the Internet disconnected when HTTPS is working.

## 6. Legal URL

All user-facing screens should point to the stable legal landing page:

`https://github.com/RennieBeekharry/winre-repair/blob/main/LEGAL.md`

Production builds should replace this repository-specific URL with the official RescueMeAI legal URL when available.

## 7. Information density

Keep the permanent header to seven short lines or fewer beneath the centered title. Detailed diagnostics belong in the body only when relevant or on FAIL screens.

Do not display internal implementation details, hashes, repository IDs, controller IDs, or stack-like diagnostics on ordinary user screens unless they are relevant to the user's immediate action.

## 8. Safety visibility

Every screen that can lead to a write action must make the current safety class visible. Destructive actions must visually distinguish themselves and must never reuse the general Terms `ACCEPT` phrase as destructive authorization.

## 9. Compatibility

The shared UI module should remain pure Windows batch where practical and avoid dependencies on PowerShell, JScript, ANSI escape handling, or external UI libraries in the WinRE bootstrap path.
