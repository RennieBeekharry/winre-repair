@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Retry the UEFI boot-file refresh with BCDBoot using the firmware-identified system partition and syntax supported by this WinRE build.
rem WR_ACTION=REFRESH_UEFI_BOOT_FILES_SUPPORTED_SYNTAX
rem WR_TARGET=Firmware-identified EFI System Partition boot files and Windows Boot Manager BCD only.
rem WR_CONSEQUENCE=Uses the existing BCD backup, then copies fresh boot-environment files from C:\Windows to the firmware-selected system partition. Personal files and partitions are not changed.
rem WR_ROLLBACK=BCD backup remains at C:\WinRERepair\BCD.before-bcdboot.bak. No partition formatting or deletion is performed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair35-bcdboot.txt"
set "BCD=C:\Windows\System32\bcdedit.exe"
set "BOOT=C:\Windows\System32\bcdboot.exe"
set "BAK=%R%\BCD.before-bcdboot.bak"
if not exist "%BCD%" set "BCD=bcdedit.exe"
if not exist "%BOOT%" set "BOOT=bcdboot.exe"
if not exist "%BAK%" goto :BAD

>"%Q%" echo RESCUEMEAI UEFI BOOT FILE REFRESH - SUPPORTED SYNTAX
>>"%Q%" echo risk=REPAIR_WRITE
>>"%Q%" echo source=C:\Windows
>>"%Q%" echo bcd_backup=%BAK%

>>"%Q%" echo [BCDBOOT]
"%BOOT%" C:\Windows /l en-us /v >>"%Q%" 2>&1
set "BRC=%errorlevel%"
>>"%Q%" echo bcdboot_return_code=%BRC%
if not "%BRC%"=="0" goto :BAD

>>"%Q%" echo [BOOTMGR_AFTER]
"%BCD%" /enum {bootmgr} /v >>"%Q%" 2>&1
>>"%Q%" echo [DEFAULT_AFTER]
"%BCD%" /enum {default} /v >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=BCDBoot refreshed the firmware-selected Windows boot environment successfully.
>"%R%\RUN_DETAILS.txt" echo repair=REFRESH_UEFI_BOOT_FILES_SUPPORTED_SYNTAX
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=%BAK%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Windows UEFI boot files were refreshed successfully using the firmware-selected system partition.
>>"%O%" echo EVIDENCE=BCDBoot returned 0; post-repair Windows Boot Manager and loader entries uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; next step is controlled reboot.
exit /b 0

:BAD
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=BCDBoot still could not refresh the firmware-selected boot environment.
>"%R%\RUN_DETAILS.txt" echo repair=REFRESH_UEFI_BOOT_FILES_SUPPORTED_SYNTAX
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=BCDBoot did not complete. RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=Private BCDBoot output uploaded; existing BCD backup remains available.
>>"%O%" echo INSTRUCTION=Reply warning. Do not reboot.
exit /b 0
