@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the 50 boot-log lines immediately preceding the final tail from the failed Windows startup.
rem WR_ACTION=CAPTURE_RAW_NTBTLOG_PRETAIL50
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI temporary diagnostic text only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and captures numbered lines 247 through 296. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=72"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step72-ntbtlog-numbered.txt"

cls
echo ================================================================================
echo RescueMeAI - RAW BOOT LOG PRECEDING 50 LINES
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The final 50 boot-log lines show Windows reached late device
echo                       initialization, but they do not prove which earlier display
echo                       or platform driver successfully loaded.
echo CURRENT TASK        : Capturing raw ntbtlog lines 247 through 296 immediately
echo                       before the final sequence.
echo SAFETY              : READ-ONLY - no repair and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if exist "%NUMBERED%" del /f /q "%NUMBERED%" >nul 2>&1

> "%DETAILS%" echo RESCUEMEAI RAW NTBTLOG PRETAIL 50
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ

echo [1/3] Converting ntbtlog.txt to numbered plain text...
find /n /v "" < "%LOG%" > "%NUMBERED%" 2>"%WORK%\step72-find.err"
if errorlevel 1 goto :FAIL
for /f %%N in ('find /c /v "" ^< "%NUMBERED%"') do set "LINES=%%N"
if not defined LINES goto :FAIL
>>"%DETAILS%" echo numbered_lines=!LINES!

echo [2/3] Capturing raw lines 247 through 296...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RAW NTBTLOG LINES 247-296 ---
set /a N=0
set /a CAPTURED=0
for /f "usebackq delims=" %%L in ("%NUMBERED%") do (
  set /a N+=1
  if !N! GEQ 247 if !N! LEQ 296 (
    >>"%DETAILS%" echo(%%L
    set /a CAPTURED+=1
  )
)
>>"%DETAILS%" echo.
>>"%DETAILS%" echo captured_lines=!CAPTURED!
if !CAPTURED! LSS 1 goto :FAIL

echo [3/3] Recording read-only result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Raw preceding boot-log lines captured successfully.
>>"%RESULT%" echo EVIDENCE=ntbtlog lines=!LINES!; raw lines 247-296 captured=!CAPTURED!; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will compare this sequence with the final 50 lines before deciding whether a controlled Safe Mode test is useful.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - PRECEDING BOOT LOG SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Preceding boot-log capture could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOT LOG EXTRACTION FAILED SAFELY
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. ChatGPT will review the collection method.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 90
