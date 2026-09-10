@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the boot path after the stalled controlled boot test without changing Windows.
rem WR_ACTION=POST_HANG_BOOT_PATH_DIAGNOSTIC
rem WR_TARGET=Offline Windows C:\Windows boot, servicing, BCD, and Startup Repair evidence only.
rem WR_CONSEQUENCE=Reads boot and servicing state and writes diagnostic text only under C:\WinRERepair. No Windows repair, registry change, package install, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=31"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "SRT=C:\Windows\System32\LogFiles\Srt\SrtTrail.txt"
set "PKGOUT=%WORK%\diag31-packages.txt"
set "PENDINGOUT=%WORK%\diag31-pending.txt"
set "SRTFOCUS=%WORK%\diag31-srt-focus.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - POST-HANG BOOT PATH DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : System-file repair verified clean, but Windows stalled
echo                       at the HP loading screen during the controlled boot test.
echo CURRENT TASK        : Checking servicing state, BCD, and Startup Repair evidence.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI POST-HANG BOOT PATH DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/5] Confirming Windows and the permanent quick-reconnect helper...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/5] Checking Windows boot-loader configuration...
set "BCD_DEVICE=UNKNOWN"
set "BCD_OSDEVICE=UNKNOWN"
"%BCDEDIT%" /enum {default} >"%WORK%\diag31-bcd.txt" 2>&1
if not errorlevel 1 (
  findstr /i /c:"device                  partition=C:" "%WORK%\diag31-bcd.txt" >nul 2>&1 && set "BCD_DEVICE=YES"
  findstr /i /c:"osdevice                partition=C:" "%WORK%\diag31-bcd.txt" >nul 2>&1 && set "BCD_OSDEVICE=YES"
)
>>"%DETAILS%" echo bcd_device_c=!BCD_DEVICE!
>>"%DETAILS%" echo bcd_osdevice_c=!BCD_OSDEVICE!

echo [3/5] Checking offline Windows servicing package state...
if exist "%PKGOUT%" del /f /q "%PKGOUT%" >nul 2>&1
if exist "%PENDINGOUT%" del /f /q "%PENDINGOUT%" >nul 2>&1
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%PKGOUT%" 2>&1
set "DISMRC=!errorlevel!"
if exist "%PKGOUT%" findstr /i /c:"Pending" "%PKGOUT%" >"%PENDINGOUT%" 2>nul
set "PENDING_ROWS=0"
if exist "%PENDINGOUT%" for /f %%N in ('find /c /v "" ^< "%PENDINGOUT%"') do set "PENDING_ROWS=%%N"
>>"%DETAILS%" echo dism_get_packages_exit=!DISMRC!
>>"%DETAILS%" echo pending_package_rows=!PENDING_ROWS!

echo [4/5] Checking pending servicing markers and Startup Repair evidence...
set "PENDING_XML=NO"
set "REBOOT_XML=NO"
if exist "C:\Windows\WinSxS\pending.xml" set "PENDING_XML=YES"
if exist "C:\Windows\WinSxS\reboot.xml" set "REBOOT_XML=YES"
>>"%DETAILS%" echo pending_xml_present=!PENDING_XML!
>>"%DETAILS%" echo reboot_xml_present=!REBOOT_XML!
set "SRT_PRESENT=NO"
set "SRT_LINES=0"
if exist "%SRT%" (
  set "SRT_PRESENT=YES"
  findstr /i /c:"Root cause" /c:"corrupt" /c:"error code" /c:"repair action" /c:"boot critical" "%SRT%" >"%SRTFOCUS%" 2>nul
  if exist "%SRTFOCUS%" for /f %%N in ('find /c /v "" ^< "%SRTFOCUS%"') do set "SRT_LINES=%%N"
)
>>"%DETAILS%" echo startup_repair_log_present=!SRT_PRESENT!
>>"%DETAILS%" echo startup_repair_focus_lines=!SRT_LINES!

echo [5/5] Recording the reviewed diagnostic result...
set "SERVICING_PENDING=NO"
if not "!PENDING_ROWS!"=="0" set "SERVICING_PENDING=YES"
if /i "!PENDING_XML!"=="YES" set "SERVICING_PENDING=YES"
>>"%DETAILS%" echo servicing_pending_detected=!SERVICING_PENDING!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
if exist "%PENDINGOUT%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- PENDING PACKAGE ROWS ---
  for /f "usebackq delims=" %%L in ("%PENDINGOUT%") do >>"%DETAILS%" echo %%L
)
if exist "%SRTFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STARTUP REPAIR FOCUS ---
  for /f "usebackq delims=" %%L in ("%SRTFOCUS%") do >>"%DETAILS%" echo %%L
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Post-hang boot-path diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; pending servicing=!SERVICING_PENDING!; pending rows=!PENDING_ROWS!; pending.xml=!PENDING_XML!; BCD device C=!BCD_DEVICE!; osdevice C=!BCD_OSDEVICE!; quick reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review this evidence before any additional repair or reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - DIAGNOSTIC SENT FOR REVIEW
echo SERVICING PENDING   : !SERVICING_PENDING!
echo PENDING PKG ROWS    : !PENDING_ROWS!
echo PENDING.XML         : !PENDING_XML!
echo BCD DEVICE C        : !BCD_DEVICE!
echo BCD OSDEVICE C      : !BCD_OSDEVICE!
echo QUICK RECONNECT     : !RECONNECT!  ^(future command: C:\r.cmd^)
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
>>"%RESULT%" echo MESSAGE=Post-hang diagnostic stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
