@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the exact active BCD configuration and boot-status evidence after the stalled Windows boot without changing Windows.
rem WR_ACTION=CAPTURE_EXACT_BCD_AND_BOOT_STATUS
rem WR_TARGET=Active BCD store and offline Windows C:\Windows boot-status evidence only.
rem WR_CONSEQUENCE=Reads boot configuration and boot-status files and writes diagnostic text only under C:\WinRERepair. No Windows repair, BCD change, registry change, package install, reboot, partition operation, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=34"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - EXACT BOOT CONFIGURATION CAPTURE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows still stalls at the HP loading screen after SFC
echo                       repaired system files and verification passed.
echo CURRENT TASK        : Capturing the exact BCD entries and boot-status evidence
echo                       before deciding whether a controlled BCD repair/test is safe.
echo SAFETY              : READ-ONLY - no boot settings are being changed.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI EXACT BOOT CONFIGURATION CAPTURE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/5] Verifying the offline Windows target and quick reconnect...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/5] Capturing the complete active BCD store...
"%BCDEDIT%" /enum all /v >"%WORK%\diag34-bcd-all.txt" 2>&1
set "BCD_ALL_RC=!errorlevel!"
>>"%DETAILS%" echo bcd_enum_all_exit=!BCD_ALL_RC!

echo [3/5] Capturing boot manager and default loader entries...
"%BCDEDIT%" /enum {bootmgr} >"%WORK%\diag34-bcd-bootmgr.txt" 2>&1
set "BOOTMGR_RC=!errorlevel!"
"%BCDEDIT%" /enum {default} >"%WORK%\diag34-bcd-default.txt" 2>&1
set "DEFAULT_RC=!errorlevel!"
>>"%DETAILS%" echo bcd_bootmgr_exit=!BOOTMGR_RC!
>>"%DETAILS%" echo bcd_default_exit=!DEFAULT_RC!

echo [4/5] Checking key loader fields and boot-status evidence...
set "WINLOAD=NO"
set "SYSTEMROOT=NO"
set "DEVICE_FIELD=NO"
set "OSDEVICE_FIELD=NO"
set "RECOVERYSEQ=NO"
set "SAFEBOOT=NO"
if exist "%WORK%\diag34-bcd-default.txt" (
  findstr /i /c:"winload.efi" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "WINLOAD=YES"
  findstr /i /c:"systemroot" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "SYSTEMROOT=YES"
  findstr /i /b /c:"device" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "DEVICE_FIELD=YES"
  findstr /i /b /c:"osdevice" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "OSDEVICE_FIELD=YES"
  findstr /i /c:"recoverysequence" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "RECOVERYSEQ=YES"
  findstr /i /c:"safeboot" "%WORK%\diag34-bcd-default.txt" >nul 2>&1 && set "SAFEBOOT=YES"
)
set "BOOTSTAT=NO"
set "NTBTLOG=NO"
if exist "C:\Windows\bootstat.dat" set "BOOTSTAT=YES"
if exist "C:\Windows\ntbtlog.txt" set "NTBTLOG=YES"
>>"%DETAILS%" echo bcd_winload_efi=!WINLOAD!
>>"%DETAILS%" echo bcd_systemroot_field=!SYSTEMROOT!
>>"%DETAILS%" echo bcd_device_field=!DEVICE_FIELD!
>>"%DETAILS%" echo bcd_osdevice_field=!OSDEVICE_FIELD!
>>"%DETAILS%" echo bcd_recoverysequence=!RECOVERYSEQ!
>>"%DETAILS%" echo bcd_safeboot_present=!SAFEBOOT!
>>"%DETAILS%" echo bootstat_present=!BOOTSTAT!
>>"%DETAILS%" echo ntbtlog_present=!NTBTLOG!

echo [5/5] Recording bounded BCD evidence for review...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BCD BOOT MANAGER ---
if exist "%WORK%\diag34-bcd-bootmgr.txt" for /f "usebackq delims=" %%L in ("%WORK%\diag34-bcd-bootmgr.txt") do >>"%DETAILS%" echo %%L
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BCD DEFAULT LOADER ---
if exist "%WORK%\diag34-bcd-default.txt" for /f "usebackq delims=" %%L in ("%WORK%\diag34-bcd-default.txt") do >>"%DETAILS%" echo %%L
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Exact BCD and boot-status capture completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; BCD all rc=!BCD_ALL_RC!; default rc=!DEFAULT_RC!; winload=!WINLOAD!; device field=!DEVICE_FIELD!; osdevice field=!OSDEVICE_FIELD!; safeboot=!SAFEBOOT!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the exact loader entry before any BCD write or reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BCD EVIDENCE SENT FOR REVIEW
echo BCD DEFAULT EXIT    : !DEFAULT_RC!
echo WINLOAD.EFI FIELD   : !WINLOAD!
echo DEVICE FIELD        : !DEVICE_FIELD!
echo OSDEVICE FIELD      : !OSDEVICE_FIELD!
echo SAFEBOOT PRESENT    : !SAFEBOOT!
echo QUICK RECONNECT     : !RECONNECT!  (future command: C:\r.cmd)
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : No reply needed unless an unexpected error appears.
echo                       If that happens, reply FAILED and attach a photo.
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Exact BCD diagnostic stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
exit /b 90
