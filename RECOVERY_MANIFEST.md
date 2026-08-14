# Windows Recovery Manifest

Last updated: 2026-08-14 09:05 ET

## Current failure

- Primary boot failure: `INACCESSIBLE_BOOT_DEVICE (0x7B)`.
- Offline Windows: Windows 11 Home/Core 24H2 x64.
- Current offline build after servicing work: 26100.9168.
- Internal storage controller: Intel 100 Series/C230 Chipset Family SATA AHCI Controller, `PCI\VEN_8086&DEV_A102`.
- Current controller service binding after rollback: `iaStorA`.

## Current hardware/storage evidence

- Internal HDD remains online and readable from WinRE.
- Direct binary reads of `ntoskrnl.exe`, `disk.sys`, and the offline SYSTEM hive passed.
- NTFS dirty bit: clean.
- Read-only CHKDSK: clean.
- SMART / PhysicalDisk health were unavailable in the current WinRE environment, not failed.
- Current assessment: no obvious drive failure; hardware failure remains possible but is not presently the leading explanation.

## Attempts already performed

| Status | Attempt | Result / evidence | Repeat? |
|---|---|---|---|
| PASS | Hardware safety/readability triage | Disk online, Windows volume readable, boot-critical files readable, CHKDSK clean | Only if new hardware evidence appears |
| PASS | Offline Windows servicing/update repair | KB5121003 installed offline; Windows now reports build 26100.9168 | Do not repeat unless servicing evidence changes |
| FAIL | Prior storage-service / ReadyBoost / filter / controlled iaStorA experiments | Did not resolve 0x7B | Do not repeat unchanged |
| PASS | Intel HDC 16.7.1.1012 package acquisition and validation | Microsoft Catalog package validated for DEV_A102 / AMD64 | No need to reacquire unless package is damaged |
| PASS | Intel 16.7.1.1012 offline driver staging | DISM successfully added the signed package; `iaStorAC.sys` present; metadata matched DEV_A102 | Do not restage unchanged |
| FAIL | Reversible controller binding test `iaStorA -> iaStorAC` | Binding applied and verified, but reboot still produced 0x7B | Do not repeat unchanged |
| PASS | Binding rollback | Controller restored to `iaStorA` | Current baseline |
| PASS | USB identity verification | USB positively identified separately from Windows disk | Completed |
| PASS | USB media layout/format | `WIN11MEDIA` FAT32 boot partition + `REPAIRDATA` NTFS data partition created successfully; Windows disk not targeted | COMPLETE; no further disk formatting/cleaning code allowed in active workflow |
| FAIL | UUP website `get.php?...&aria2=2` manifest retrieval | Endpoint did not return the aria2 manifest format the script expected; no disk/filesystem operation occurred | Do not repeat; endpoint choice was wrong |

## Current recovery USB state

- `WIN11MEDIA`: FAT32, approximately 8 GB, reserved for bootable recovery/setup files.
- `REPAIRDATA`: NTFS, remaining USB capacity, reserved for Windows source files, tools, and recovery evidence.
- Active workflow policy: **no disk clean, format, repartition, filesystem creation, or disk-number write operations**.

## Next planned actions

1. Use the official UUP dump JSON API at `api.uupdump.net/get.php` for the selected Windows 11 24H2 x64 Home/Core en-US build.
2. Validate API response build = 26100.8894 and architecture = amd64 before downloading any source file.
3. Download UUP files only to `REPAIRDATA` and verify each file against the API-provided SHA-1.
4. Make downloads resumable/restartable; already-verified files must be reused on later runs.
5. Convert the verified UUP set into usable Windows setup/recovery source files using Windows-compatible conversion tooling.
6. Copy only the required boot/setup files to `WIN11MEDIA`; keep oversized image payloads on `REPAIRDATA` if needed.
7. Boot the fresh Microsoft-derived recovery environment and use it as a known-good repair source.
8. From fresh recovery media, re-evaluate the storage stack and perform targeted repair only: DISM component repair/source validation, offline SFC, storage-driver comparison, and BCDBoot refresh if evidence supports it.
9. Escalate to reset/reinstall only after targeted recovery-source repair is exhausted and only with explicit approval.

## Explicit do-not-repeat / do-not-do list

- Do not repeat the failed `iaStorA -> iaStorAC` binding test unchanged.
- Do not repeat prior ReadyBoost/storage-service/filter experiments unchanged.
- Do not use the UUP website aria2 endpoint as an automated manifest API.
- Do not run disk clean, format, repartition, or filesystem-creation commands in the active recovery workflow.
- Do not erase or reinstall Windows as part of the current targeted recovery phase.
- Do not use unsigned storage drivers or `/ForceUnsigned`.
- Do not change BIOS storage mode automatically.

## Recovery workflow principle

Use least-destructive, evidence-driven actions first. Every write to the offline Windows installation should have a defined target, validation gate, and rollback/evidence path. The user-facing script should finish with a compact recovery snapshot so one photo is sufficient for the next decision.
