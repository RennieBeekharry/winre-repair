@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Transcode the Windows boot log through FIND into numbered plain text, then capture the final 50 lines faithfully for review.
rem WR_ACTION=CAPTURE_RAW_NTBTLOG_FINAL50
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI temporary diagnostic text only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and creates a temporary numbered text copy under C:\WinRERepair for bounded reporting. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=70"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step70-ntbtlog-numbered.txt"

cls
echo ================================================================================
echo RescueMeAI - RAW BOOT LOG FINAL 50 LINES
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The failed boot produced a 42 KB ntbtlog. Earlier tail
echo                       helpers failed because of WinRE text/command compatibility.
echo CURRENT TASK        : Converting the boot log with Windows FIND, then reading the
echo                       final 50 numbered lines without driver-name filtering.
echo SAFETY              : READ-ONLY - no repair and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if exist "%NUMBERED%" del /f /q "%NUMBERED%" >nul 2>&1

> "%DETAILS%" echo RESCUEMEAI RAW NTBTLOG FINAL 50
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ

echo [1/4] Converting ntbtlog.txt to numbered plain text...
find /n /v "" < "%LOG%" > "%NUMBERED%" 2>"%WORK%\step70-find.err"
set "FINDRC=!errorlevel!"
>>"%DETAILS%" echo find_numbered_exit=!FINDRC!
if not "!FINDRC!"=="0" goto :FAIL

echo [2/4] Counting converted lines...
set "LINES="
for /f %%N in ('find /c /v "" ^< "%NUMBERED%"') do set "LINES=%%N"
if not defined LINES goto :FAIL
set /a START=LINES-49
if !START! LSS 1 set "START=1"
>>"%DETAILS%" echo numbered_lines=!LINES!
>>"%DETAILS%" echo capture_start=!START!

echo [3/4] Capturing the final 50 numbered lines verbatim...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- RAW NTBTLOG FINAL 50 ---
set /a N=0
set /a CAPTURED=0
for /f "usebackq delims=" %%L in ("%NUMBERED%") do (
  set /a N+=1
  if !N! GEQ !START! (
    >>"%DETAILS%" echo(%%L
    set /a CAPTURED+=1
  )
)
>>"%DETAILS%" echo.
>>"%DETAILS%" echo captured_lines=!CAPTURED!
if !CAPTURED! LSS 1 goto :FAIL

echo [4/4] Recording read-only result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Raw final boot-log lines captured successfully.
>>"%RESULT%" echo EVIDENCE=numbered ntbtlog lines=!LINES!; final raw lines captured=!CAPTURED!; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will inspect the actual final driver sequence before choosing another action.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RAW FINAL BOOT LOG SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Raw final boot-log capture did not produce usable evidence.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOT LOG EXTRACTION FAILED SAFELY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. ChatGPT will change collection method; do not reboot.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 90
