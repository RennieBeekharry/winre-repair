@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Repair the persistent RescueMeAI quick reconnect launcher and inspect the stalled boot path without changing Windows system files.
rem WR_ACTION=REPAIR_RECONNECT_AND_POST_HANG_DIAGNOSTIC
rem WR_TARGET=C:\r.cmd helper plus offline Windows C:\Windows boot, servicing, BCD, and Startup Repair evidence.
rem WR_CONSEQUENCE=Repairs only the RescueMeAI helper launcher, then reads boot and servicing state. No Windows system-file, boot-store, registry, package, partition, or personal-file changes are made.
rem WR_ROLLBACK=The helper launcher can be deleted later; diagnostic reads require no rollback.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=32"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "SRT=C:\Windows\System32\LogFiles\Srt\SrtTrail.txt"
set "PKGOUT=%WORK%\diag32-packages.txt"
set "PENDINGOUT=%WORK%\diag32-pending.txt"
set "SRTFOCUS=%WORK%\diag32-srt-focus.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - QUICK RECONNECT REPAIR + POST-HANG DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows still stalls at the HP loading screen after the
echo                       successful offline SFC repair and clean verification.
echo CURRENT TASK        : Repairing C:\r.cmd first, then checking servicing, BCD,
echo                       and Startup Repair evidence from the failed boot test.
echo SAFETY              : REPAIR-WRITE - RescueMeAI helper file only; diagnostics
echo                       are read-only.
echo WINDOWS SYSTEM      : NOT BEING MODIFIED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI STEP 32
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/6] Repairing the permanent quick reconnect command C:\r.cmd...
> "C:\r.cmd" echo @echo off
>>"C:\r.cmd" echo setlocal EnableExtensions
>>"C:\r.cmd" echo if not exist C:\RescueMeAI md C:\RescueMeAI ^>nul 2^>^&1
>>"C:\r.cmd" echo C:\Windows\System32\curl.exe --ssl-no-revoke -fL "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/36b0dc7fa3b142845a066f7ab985952ef1dfb5db/reconnect.cmd" -o C:\RescueMeAI\reconnect.cmd
>>"C:\r.cmd" echo if errorlevel 1 exit /b 90
>>"C:\r.cmd" echo call C:\RescueMeAI\reconnect.cmd
>>"C:\r.cmd" echo exit /b %%errorlevel%%
set "RECONNECT=NO"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!RECONNECT!"=="YES" goto :FAIL

echo [2/6] Confirming the offline Windows target...
set "TARGET=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [3/6] Checking Windows boot-loader configuration...
set "BCD_DEVICE=UNKNOWN"
set "BCD_OSDEVICE=UNKNOWN"
"%BCDEDIT%" /enum {default} >"%WORK%\diag32-bcd.txt" 2>&1
if not errorlevel 1 (
  findstr /i /c:"device                  partition=C:" "%WORK%\diag32-bcd.txt" >nul 2>&1 && set "BCD_DEVICE=YES"
  findstr /i /c:"osdevice                partition=C:" "%WORK%\diag32-bcd.txt" >nul 2>&1 && set "BCD_OSDEVICE=YES"
)
>>"%DETAILS%" echo bcd_device_c=!BCD_DEVICE!
>>"%DETAILS%" echo bcd_osdevice_c=!BCD_OSDEVICE!

echo [4/6] Checking offline Windows servicing package state...
if exist "%PKGOUT%" del /f /q "%PKGOUT%" >nul 2>&1
if exist "%PENDINGOUT%" del /f /q "%PENDINGOUT%" >nul 2>&1
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%PKGOUT%" 2>&1
set "DISMRC=!errorlevel!"
if exist "%PKGOUT%" findstr /i /c:"Pending" "%PKGOUT%" >"%PENDINGOUT%" 2>nul
set "PENDING_ROWS=0"
if exist "%PENDINGOUT%" for /f %%N in ('find /c /v "" ^< "%PENDINGOUT%"') do set "PENDING_ROWS=%%N"
>>"%DETAILS%" echo dism_get_packages_exit=!DISMRC!
>>"%DETAILS%" echo pending_package_rows=!PENDING_ROWS!

echo [5/6] Checking pending servicing markers and Startup Repair evidence...
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

echo [6/6] Recording the reviewed diagnostic result...
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
>>"%RESULT%" echo MESSAGE=Quick reconnect launcher repaired and post-hang diagnostic completed.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; quick reconnect=!RECONNECT!; pending servicing=!SERVICING_PENDING!; pending rows=!PENDING_ROWS!; pending.xml=!PENDING_XML!; BCD device C=!BCD_DEVICE!; osdevice C=!BCD_OSDEVICE!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review this evidence before any additional repair or reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo QUICK RECONNECT     : READY  ^(future command: C:\r.cmd^)
echo SERVICING PENDING   : !SERVICING_PENDING!
echo PENDING PKG ROWS    : !PENDING_ROWS!
echo PENDING.XML         : !PENDING_XML!
echo BCD DEVICE C        : !BCD_DEVICE!
echo BCD OSDEVICE C      : !BCD_OSDEVICE!
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
>>"%RESULT%" echo MESSAGE=Step 32 stopped before diagnostics completed.
>>"%RESULT%" echo EVIDENCE=No Windows system files or personal files were modified.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED
echo WINDOWS SYSTEM      : NOT MODIFIED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
