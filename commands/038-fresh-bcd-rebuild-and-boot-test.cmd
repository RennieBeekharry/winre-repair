@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform one stronger UEFI boot repair by backing up the current BCD, rebuilding it fresh with BCDBoot /c from C:\Windows, verifying the resulting boot entries, then rebooting only if verification passes.
rem WR_ACTION=FRESH_UEFI_BCD_REBUILD_AND_BOOT_TEST
rem WR_TARGET=Firmware-selected EFI System Partition boot files and Windows Boot Manager BCD only.
rem WR_CONSEQUENCE=Rebuilds the Windows BCD store from BCD-Template using BCDBoot /c. Personal files, partitions, and storage-driver configuration are not changed.
rem WR_ROLLBACK=Current BCD is exported to C:\WinRERepair\BCD.before-fresh-rebuild.bak before any rebuild. No DiskPart, formatting, partition deletion, reset, or reinstall is performed.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "Q=%R%\repair38-fresh-bcd.txt"
set "BCD=C:\Windows\System32\bcdedit.exe"
set "BOOT=C:\Windows\System32\bcdboot.exe"
set "BAK=%R%\BCD.before-fresh-rebuild.bak"
set "USB="
if not exist "%BCD%" set "BCD=bcdedit.exe"
if not exist "%BOOT%" set "BOOT=bcdboot.exe"

if not exist C:\Windows\System32\winload.efi goto :BAD_PRECHECK
if not exist C:\Windows\System32\Config\BCD-Template goto :BAD_PRECHECK

>"%Q%" echo RESCUEMEAI FRESH UEFI BCD REBUILD
>>"%Q%" echo risk=REPAIR_WRITE
>>"%Q%" echo source=C:\Windows
>>"%Q%" echo backup=%BAK%
>>"%Q%" echo mode=BCDBOOT_C_FRESH_STORE

cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  FRESH UEFI / BCD REBUILD
echo ====================================================================================================
echo.
echo WHAT IS HAPPENING NOW
echo ----------------------------------------------------------------------------------------------------
echo   1. Backing up the current BCD store.
echo   2. Rebuilding Windows boot configuration from a fresh BCD template.
echo   3. Verifying Windows Boot Manager and Windows loader paths.
echo   4. Rebooting only if all verification checks pass.
echo.
echo Windows changes : BOOT CONFIGURATION ONLY
echo Personal files  : NOT MODIFIED
echo Partitions      : NOT MODIFIED
 echo.
echo PLEASE WAIT - no action is required right now.
echo.

"%BCD%" /export "%BAK%" >>"%Q%" 2>&1
set "ERC=%errorlevel%"
>>"%Q%" echo export_return_code=%ERC%
if not "%ERC%"=="0" goto :BAD

>>"%Q%" echo [BCDBOOT_FRESH_REBUILD]
"%BOOT%" C:\Windows /l en-us /c /v >>"%Q%" 2>&1
set "BRC=%errorlevel%"
>>"%Q%" echo bcdboot_return_code=%BRC%
if not "%BRC%"=="0" goto :BAD

"%BCD%" /enum {bootmgr} /v >"%R%\repair38-bootmgr.txt" 2>&1
"%BCD%" /enum {default} /v >"%R%\repair38-default.txt" 2>&1
>>"%Q%" echo [BOOTMGR_AFTER]
type "%R%\repair38-bootmgr.txt" >>"%Q%"
>>"%Q%" echo [DEFAULT_AFTER]
type "%R%\repair38-default.txt" >>"%Q%"

findstr /i /c:"\EFI\Microsoft\Boot\bootmgfw.efi" "%R%\repair38-bootmgr.txt" >nul 2>&1
if errorlevel 1 goto :BAD_VERIFY
findstr /i /c:"partition=C:" "%R%\repair38-default.txt" >nul 2>&1
if errorlevel 1 goto :BAD_VERIFY
findstr /i /c:"\Windows\system32\winload.efi" "%R%\repair38-default.txt" >nul 2>&1
if errorlevel 1 goto :BAD_VERIFY
findstr /i /c:"systemroot              \Windows" "%R%\repair38-default.txt" >nul 2>&1
if errorlevel 1 goto :BAD_VERIFY

>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh UEFI BCD rebuild completed and post-repair boot entries verified.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD
>>"%R%\RUN_DETAILS.txt" echo bcd_backup=%BAK%
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1

goto :LOCAL_BOOT_TEST

:LOCAL_BOOT_TEST
call :LOCATE_USB
if errorlevel 1 goto :REBOOT_NOW
cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo.
echo Fresh UEFI / BCD rebuild: VERIFIED PASS
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo   Physically remove the RescueMeAI / Windows recovery USB from this PC.
echo.
echo   Do NOT type pass, fail, or warning.
echo   Do NOT reboot manually.
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI is watching drive !USB! for removal.
echo   When removal is verified, the PC will reboot automatically.
echo.
:WAIT_USB
if not exist "!USB!\" goto :REBOOT_NOW
timeout /t 2 /nobreak >nul
goto :WAIT_USB

:REBOOT_NOW
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    CONTROLLED BOOT TEST
echo ====================================================================================================
echo.
echo Fresh UEFI / BCD rebuild : VERIFIED PASS
echo Recovery USB             : REMOVED / NOT PRESENT
echo Windows changes now      : NONE ADDITIONAL
echo.
echo Rebooting automatically in 4 seconds.
echo PLEASE WAIT - no action is required.
echo.
timeout /t 4 /nobreak >nul
wpeutil reboot
shutdown /r /t 0
exit /b 0

:LOCATE_USB
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist "%%D:\RescueMeAI\Media\." (
    set "USB=%%D:"
    exit /b 0
  )
)
exit /b 1

:BAD_PRECHECK
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=Fresh BCD rebuild was not started because required Windows boot source files are missing.
>>"%O%" echo EVIDENCE=No boot configuration changes were made.
>>"%O%" echo INSTRUCTION=RescueMeAI remains online. Automatic review required.
exit /b 90

:BAD_VERIFY
>>"%Q%" echo verification=FAILED
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh BCD rebuild returned success but post-repair verification did not match the expected Windows UEFI paths.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD_VERIFY_FAILED
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Fresh BCD rebuild could not be fully verified. RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=BCD backup remains at C:\WinRERepair\BCD.before-fresh-rebuild.bak.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI running for automatic review.
exit /b 0

:BAD
>"%R%\LAST_RUN_REPORT.txt" echo status=WARNING
>>"%R%\LAST_RUN_REPORT.txt" echo message=Fresh UEFI BCD rebuild did not complete successfully.
>"%R%\RUN_DETAILS.txt" echo repair=FRESH_UEFI_BCD_REBUILD_FAILED
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Fresh BCD rebuild did not complete. RescueMeAI will not reboot.
>>"%O%" echo EVIDENCE=Review the private BCDBoot report. Existing BCD backup remains available if export succeeded.
>>"%O%" echo INSTRUCTION=No user relay is required. Leave RescueMeAI running for automatic review.
exit /b 0
