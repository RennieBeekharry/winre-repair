# winre-repair

One-shot WinRE repair helper for the Intel SATA AHCI boot path already identified on this PC:

- Intel 100 Series/C230 SATA AHCI controller
- hardware ID `PCI\VEN_8086&DEV_A102&CC_0106`
- Windows boot service `iaStorA`
- target Microsoft Update Catalog driver: Intel HDC `16.7.1.1012`

The script is intentionally narrow. It does **not** reset Windows, delete personal files, change BIOS/UEFI storage mode, remove the existing Intel storage driver, or install unsigned drivers.

## What `repair.cmd` does

1. Finds the offline Windows installation automatically.
2. Verifies the expected `DEV_A102` controller and `iaStorA` binding in the offline SYSTEM hive.
3. Backs up the current `iaStorA.sys` and service configuration.
4. Initializes WinRE networking.
5. Retrieves the exact driver from Microsoft Update Catalog / Microsoft download infrastructure.
6. Extracts the CAB and verifies that the INF explicitly supports `PCI\VEN_8086&DEV_A102&CC_0106` and is version `16.7.1.1012`.
7. Adds only that verified signed INF to the offline Windows image with DISM.
8. Verifies the new version appears in the offline driver inventory.
9. Copies a consolidated log to the `WINREPAIR` USB (`RepairLogs`) when available.
10. Reboots only after the driver operation succeeds.

## Run from WinRE

At the WinRE Command Prompt, use this single command:

```cmd
C:\Windows\System32\curl.exe -L "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/repair.cmd" -o X:\repair.cmd && X:\repair.cmd
```

If WinRE says it cannot resolve `raw.githubusercontent.com`, report that exact error; a short DNS-bypass launcher can be used without changing the repair script.

## Logs

The main log is saved under the detected Windows drive:

```text
C:\WinRERepair\logs\winre-repair-latest.log
```

When the `WINREPAIR` USB is present, the script also copies:

```text
<WINREPAIR>:\RepairLogs\winre-repair-latest.log
<WINREPAIR>:\RepairLogs\dism-add-driver.log
<WINREPAIR>:\RepairLogs\drivers-after.txt
```

If Windows still fails to boot, upload `winre-repair-latest.log` to ChatGPT for review.

Automatic log upload to GitHub is deliberately not used because that would require putting a GitHub write credential/token into WinRE. Keeping credentials out of a public recovery script is safer.

## Safety boundary

This script performs only the targeted Intel storage-driver attempt. If the same `INACCESSIBLE_BOOT_DEVICE (0x7B)` remains afterward, stop repeating driver surgery and move to a repair/reset/reinstall strategy that preserves personal files where possible.
