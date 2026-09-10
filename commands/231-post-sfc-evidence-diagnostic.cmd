@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect post-SFC CBS, Startup Repair, and driver-setup evidence to identify what was repaired and what may still block boot.
rem WR_ACTION=POST_SFC_REPAIR_EVIDENCE_DIAGNOSTIC
rem WR_TARGET=Offline Windows C:\Windows servicing, Startup Repair, and setup logs only.
rem WR_CONSEQUENCE=Reads Windows recovery logs and writes bounded diagnostic text only under C:\WinRERepair. No Windows system, boot, registry, package, disk, or personal-file changes are made.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=35"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "CBS=C:\Windows\Logs\CBS\CBS.log"
set "SRT=C:\Windows\System32\LogFiles\Srt\SrtTrail.txt"
set "SETUPAPI=C:\Windows\INF\setupapi.dev.log"
set "CBSFOCUS=%WORK%\diag35-cbs-focus.txt"
set "SRTFOCUS=%WORK%\diag35-srt-focus.txt"
set "SETUPFOCUS=%WORK%\diag35-setupapi-focus.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - POST-SFC REPAIR EVIDENCE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The BCD raw capture is structurally normal. Windows still
echo                       stalls at the HP loading screen after offline SFC repair.
echo CURRENT TASK        : Identifying exactly what SFC repaired and checking for
echo                       remaining servicing or driver-installation failures.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI POST-SFC REPAIR EVIDENCE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/5] Verifying Windows and the quick reconnect helper...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/5] Reading SFC/CBS repair evidence...
if exist "%CBSFOCUS%" del /f /q "%CBSFOCUS%" >nul 2>&1
set "CBS_PRESENT=NO"
set "CBS_LINES=0"
if exist "%CBS%" (
  set "CBS_PRESENT=YES"
  findstr /i /c:"Repairing corrupted file" /c:"Cannot repair member file" /c:"Repair complete" /c:"Verify and Repair Transaction completed" "%CBS%" >"%CBSFOCUS%" 2>nul
  if exist "%CBSFOCUS%" for /f %%N in ('find /c /v "" ^< "%CBSFOCUS%"') do set "CBS_LINES=%%N"
)
>>"%DETAILS%" echo cbs_log_present=!CBS_PRESENT!
>>"%DETAILS%" echo cbs_focus_lines=!CBS_LINES!

echo [3/5] Reading Startup Repair evidence...
if exist "%SRTFOCUS%" del /f /q "%SRTFOCUS%" >nul 2>&1
set "SRT_PRESENT=NO"
set "SRT_LINES=0"
if exist "%SRT%" (
  set "SRT_PRESENT=YES"
  findstr /i /c:"Root cause" /c:"corrupt" /c:"error code" /c:"repair action" /c:"boot critical" /c:"recently serviced" "%SRT%" >"%SRTFOCUS%" 2>nul
  if exist "%SRTFOCUS%" for /f %%N in ('find /c /v "" ^< "%SRTFOCUS%"') do set "SRT_LINES=%%N"
)
>>"%DETAILS%" echo startup_repair_log_present=!SRT_PRESENT!
>>"%DETAILS%" echo startup_repair_focus_lines=!SRT_LINES!

echo [4/5] Checking driver/setup failure markers...
if exist "%SETUPFOCUS%" del /f /q "%SETUPFOCUS%" >nul 2>&1
set "SETUP_PRESENT=NO"
set "SETUP_LINES=0"
if exist "%SETUPAPI%" (
  set "SETUP_PRESENT=YES"
  findstr /c:"!!!" "%SETUPAPI%" >"%SETUPFOCUS%" 2>nul
  if exist "%SETUPFOCUS%" for /f %%N in ('find /c /v "" ^< "%SETUPFOCUS%"') do set "SETUP_LINES=%%N"
)
>>"%DETAILS%" echo setupapi_log_present=!SETUP_PRESENT!
>>"%DETAILS%" echo setupapi_error_marker_lines=!SETUP_LINES!

echo [5/5] Building a bounded evidence summary...
if exist "%CBSFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- LAST CBS/SFC FOCUS LINES ---
  set /a START=1
  if !CBS_LINES! GTR 25 set /a START=CBS_LINES-24
  more +!START! "%CBSFOCUS%" >>"%DETAILS%" 2>nul
)
if exist "%SRTFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STARTUP REPAIR FOCUS ---
  type "%SRTFOCUS%" >>"%DETAILS%"
)
if exist "%SETUPFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- LAST SETUPAPI ERROR MARKERS ---
  set /a START2=1
  if !SETUP_LINES! GTR 15 set /a START2=SETUP_LINES-14
  more +!START2! "%SETUPFOCUS%" >>"%DETAILS%" 2>nul
)
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Post-SFC repair evidence diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; CBS focus lines=!CBS_LINES!; Startup Repair focus lines=!SRT_LINES!; SetupAPI error marker lines=!SETUP_LINES!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review what SFC repaired and decide whether boot logging, Safe Mode, or targeted servicing is the safest next test.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - EVIDENCE SENT FOR REVIEW
echo CBS/SFC FOCUS LINES : !CBS_LINES!
echo STARTUP REPAIR LINES: !SRT_LINES!
echo SETUPAPI ERRORS     : !SETUP_LINES!
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
>>"%RESULT%" echo MESSAGE=Post-SFC diagnostic stopped because C:\Windows could not be verified.
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
