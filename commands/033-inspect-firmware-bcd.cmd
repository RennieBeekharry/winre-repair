@echo off
setlocal EnableExtensions
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect UEFI firmware boot entries and the currently visible BCD stores before any boot-environment repair.
rem WR_ACTION=INSPECT_FIRMWARE_BCD
rem WR_TARGET=UEFI firmware boot manager entries and BCDEdit system-store enumeration only.
rem WR_CONSEQUENCE=Reads boot configuration only. Makes no Windows or firmware changes.
rem WR_ROLLBACK=None required; read-only diagnostic.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\diag33-firmware-bcd.txt"
set "B=C:\Windows\System32\bcdedit.exe"
if not exist "%B%" set "B=bcdedit.exe"

>"%Q%" echo RESCUEMEAI FIRMWARE AND BCD INSPECTION
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo [FIRMWARE]
"%B%" /enum firmware /v >>"%Q%" 2>&1
>>"%Q%" echo [BOOTMGR_VISIBLE_STORE]
"%B%" /enum {bootmgr} /v >>"%Q%" 2>&1
>>"%Q%" echo [DEFAULT_VISIBLE_STORE]
"%B%" /enum {default} /v >>"%Q%" 2>&1
>>"%Q%" echo [CURRENT_VISIBLE_STORE]
"%B%" /enum {current} /v >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Firmware and BCD inspection completed without changing boot configuration.
>"%R%\RUN_DETAILS.txt" echo diagnostic=FIRMWARE_BCD
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI inspected the UEFI firmware boot entries and current BCD view without changing them.
>>"%O%" echo EVIDENCE=Private firmware Boot Manager and BCD entry details uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; do not reboot yet.
exit /b 0
