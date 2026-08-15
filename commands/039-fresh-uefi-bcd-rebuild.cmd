@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Back up the current Windows BCD store and rebuild a fresh UEFI BCD store from C:\Windows using BCDBoot /c, then verify the resulting boot paths.
rem WR_ACTION=FRESH_UEFI_BCD_REBUILD
rem WR_TARGET=Firmware-selected EFI System Partition boot files and Windows Boot Manager BCD only.
rem WR_CONSEQUENCE=Recreates Windows boot configuration from the offline Windows BCD template. Personal files, partitions, and storage-driver configuration are not changed.
rem WR_ROLLBACK=Current BCD is exported to C:\WinRERepair\BCD.before-fresh-rebuild2.bak before the rebuild. No DiskPart, formatting, partition deletion, reset, or reinstall is performed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair39-fresh-bcd.txt"
set "BCD=C:\Windows\System32\bcdedit.exe"
set "BOOT=C:\Windows\System32\bcdboot.exe"
set "BAK=%R%\BCD.before-fresh-rebuild2.bak"
if not exist "%BCD%" set "BCD=bcdedit.exe"
if not exist "%BOOT%" set "BOOT=bcdboot.exe"

if not exist C:\Windows\System32\winload.efi goto :PRECHECK_FAIL
if not exist C:\Windows\System32\Config\BCD-Template goto :PRECHECK_FAIL

cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  FRESH UEFI / BCD REBUILD
echo ====================================================================================================
echo.
echo CURRENT TASK
echo ----------------------------------------------------------------------------------------------------
echo   1. Backing up the current BCD store.
echo   2. Rebuilding a fresh Windows UEFI BCD store from BCD-Template.
echo   3. Verifying Boot Manager and Windows loader paths.
echo.
echo Windows changes : BOOT CONFIGURATION ONLY
echo Personal files  : NOT MODIFIED
echo Partitions      : NOT MODIFIED
echo.
echo PLEASE WAIT - no action is required.
echo.

>"%Q%" echo RESCUEMEAI FRESH UEFI BCD REBUILD
>>"%Q%" echo source=C:\Windows
>>"%Q%" echo backup=%BAK%

"%BCD%" /export "%BAK%" >>"%Q%" 2>&1
set "ERC=!errorlevel!"
>>"%Q%" echo export_return_code=!ERC!
if not "!ERC!"=="0" goto :FAIL

>>"%Q%" echo [BCDBOOT_C]
"%BOOT%" C:\Windows /l en-us /c /v >>"%Q%" 2>&1
set "BRC=!errorlevel!"
>>"%Q%" echo bcdboot_return_code=!BRC!
if not "!BRC!"=="0" goto :FAIL

"%BCD%" /enum {bootmgr} /v >"%R%\repair39-bootmgr.txt" 2>&1
"%BCD%" /enum {default} /v >"%R%\repair39-default.txt" 2>&1
>>"%Q%" echo [BOOTMGR_AFTER]
type "%R%\repair39-bootmgr.txt" >>"%Q%"
>>"%Q%" echo [DEFAULT_AFTER]
type "%R%\repair39-default.txt" >>"%Q%"

findstr /i /c:"\EFI\Microsoft\Boot\bootmgfw.efi" "%R%\repair39-bootmgr.txt" >nul 2>&1
if errorlevel 1 goto :VERIFY_FAIL
findstr /i /c:"device                  partition=C:" "%R%\repair39-default.txt" >nul 2>&1
if errorlevel 1 goto :VERIFY_FAIL
findstr /i /c:"osdevice                partition=C:" "%R%\repair39-default.txt" >nul 2>&1
if errorlevel 1 goto :VERIFY_FAIL
findstr /i /c:"\Windows\system32\winload.efi" "%R%\repair39-default.txt" >nul 2>&1
if errorlevel 1 goto :VERIFY_FAIL

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh UEFI BCD rebuild completed and verified.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=%BAK%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=Fresh UEFI BCD rebuild completed and the expected Windows boot paths were verified.
>>"%O%" echo EVIDENCE=BCD backup saved at C:\WinRERepair\BCD.before-fresh-rebuild2.bak; private post-rebuild evidence uploaded.
>>"%O%" echo INSTRUCTION=No user relay is required. RescueMeAI remains online for the controlled boot test.
exit /b 0

:VERIFY_FAIL
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh BCD rebuild returned success but post-rebuild verification failed.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD_VERIFY_FAILED
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Fresh BCD rebuild could not be fully verified; RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=The pre-rebuild BCD backup remains available.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI online for automatic review.
exit /b 0

:PRECHECK_FAIL
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Fresh BCD rebuild was not started because required Windows boot source files are missing.
>>"%O%" echo EVIDENCE=No boot configuration changes were made.
>>"%O%" echo INSTRUCTION=No user relay is required. Automatic review is required.
exit /b 90

:FAIL
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh UEFI BCD rebuild did not complete.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD_FAILED
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Fresh BCD rebuild did not complete; RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=Review private BCDBoot evidence; the BCD backup remains available if export succeeded.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI online for automatic review.
exit /b 0
