@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture a faithful numbered raw tail of the Windows ntbtlog produced by the failed boot, without parsing driver names.
rem WR_ACTION=CAPTURE_RAW_NTBTLOG_TAIL
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI diagnostic output only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and records a bounded numbered excerpt. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=69"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "FIND=X:\Windows\System32\find.exe"
if not exist "%FIND%" set "FIND=C:\Windows\System32\find.exe"

cls
echo ================================================================================
echo RescueMeAI - RAW WINDOWS BOOT LOG TAIL
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows again stalled at the HP spinner. Boot logging
echo                       successfully produced C:\Windows\ntbtlog.txt.
echo CURRENT TASK        : Capturing the raw final boot-log lines without interpreting
echo                       or filtering driver names.
echo SAFETY              : READ-ONLY - no repair and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if not exist "%FIND%" goto :FAIL

> "%DETAILS%" echo RESCUEMEAI RAW NTBTLOG TAIL
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ
for /f %%N in ('"%FIND%" /c /v "" ^< "%LOG%"') do set "LINES=%%N"
if not defined LINES set "LINES=0"
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [1/3] Reading numbered boot-log text through Windows FIND...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RAW NTBTLOG LINES 250 THROUGH END ---
set /a N=0
set /a CAPTURED=0
for /f "delims=" %%L in ('"%FIND%" /n /v "" ^< "%LOG%"') do (
  set /a N+=1
  if !N! GEQ 250 (
    >>"%DETAILS%" echo(%%L
    set /a CAPTURED+=1
  )
)

echo [2/3] Recording bounded capture counts...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo captured_from_line=250
>>"%DETAILS%" echo captured_lines=!CAPTURED!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

echo [3/3] Completing read-only evidence capture...
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Raw numbered ntbtlog tail captured successfully.
>>"%RESULT%" echo EVIDENCE=ntbtlog lines=!LINES!; raw lines from 250 through end captured=!CAPTURED!; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will inspect the raw boot-log tail directly before choosing any further diagnostic or repair.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RAW BOOT LOG TAIL SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Raw boot-log tail capture could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - RAW BOOT LOG CAPTURE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
