@echo off
setlocal EnableExtensions
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Refresh the UEFI Windows boot files from the current offline Windows installation using Microsoft BCDBoot after storage-driver paths were exhausted.
rem WR_ACTION=REFRESH_UEFI_BOOT_FILES
rem WR_TARGET=Firmware-identified EFI System Partition boot files and Windows Boot Manager BCD only.
rem WR_CONSEQUENCE=Exports the current BCD store, then BCDBoot copies fresh boot-environment files from C:\Windows and refreshes the Windows Boot Manager entry. Personal files and partitions are not changed.
rem WR_ROLLBACK=BCD backup is saved at C:\WinRERepair\BCD.before-bcdboot.bak. No partition formatting or deletion is performed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair34-bcdboot.txt"
set "BCD=C:\Windows\System32\bcdedit.exe"
set "BOOT=C:\Windows\System32\bcdboot.exe"
set "BAK=%R%\BCD.before-bcdboot.bak"
if not exist "%BCD%" set "BCD=bcdedit.exe"
if not exist "%BOOT%" set "BOOT=bcdboot.exe"
if not exist C:\Windows\System32\winload.efi goto :BAD

>"%Q%" echo RESCUEMEAI UEFI BOOT FILE REFRESH
>>"%Q%" echo risk=REPAIR_WRITE
>>"%Q%" echo source=C:\Windows
>>"%Q%" echo backup=%BAK%

"%BCD%" /export "%BAK%" >>"%Q%" 2>&1
if errorlevel 1 goto :BAD

>>"%Q%" echo [BCDBOOT]
"%BOOT%" C:\Windows /l en-us /f UEFI /v >>"%Q%" 2>&1
set "BRC=%errorlevel%"
>>"%Q%" echo bcdboot_return_code=%BRC%
if not "%BRC%"=="0" goto :BAD

>>"%Q%" echo [BOOTMGR_AFTER]
"%BCD%" /enum {bootmgr} /v >>"%Q%" 2>&1
>>"%Q%" echo [DEFAULT_AFTER]
"%BCD%" /enum {default} /v >>"%Q%" 2>&1

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=UEFI Windows boot files were refreshed with BCDBoot.
>"%R%\RUN_DETAILS.txt" echo repair=REFRESH_UEFI_BOOT_FILES
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=%BAK%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=BCDBoot refreshed the Windows UEFI boot files successfully.
>>"%O%" echo EVIDENCE=BCD backup saved at C:\WinRERepair\BCD.before-bcdboot.bak; post-repair boot entries uploaded.
>>"%O%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; next step is a controlled boot test.
exit /b 0

:BAD
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=BCDBoot could not complete the UEFI boot-file refresh.
>"%R%\RUN_DETAILS.txt" echo repair=REFRESH_UEFI_BOOT_FILES
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=The UEFI boot-file refresh did not complete successfully. RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=Review the private BCDBoot report; the saved BCD backup remains available if export succeeded.
>>"%O%" echo INSTRUCTION=Reply warning. Do not reboot.
exit /b 0
