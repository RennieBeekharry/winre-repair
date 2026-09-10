@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect the Windows boot log produced by the failed one-time boot-log startup and record bounded evidence for review.
rem WR_ACTION=COLLECT_ONE_TIME_BOOTLOG_EVIDENCE
rem WR_TARGET=C:\Windows\ntbtlog.txt, RescueMeAI boot-test markers, and bounded diagnostic output only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and local RescueMeAI state. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=66"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "FAILS=%WORK%\step66-ntbt-fail.txt"

cls
echo ================================================================================
echo RescueMeAI - BOOT LOG COLLECTION AFTER STALLED STARTUP
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The one-time boot-log startup reached the HP spinner and
echo                       stalled again. This step collects the generated boot log.
echo CURRENT TASK        : Reading C:\Windows\ntbtlog.txt and bounded boot evidence.
echo SAFETY              : READ-ONLY - no repair or reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
>"%DETAILS%" echo RESCUEMEAI BOOT LOG COLLECTION
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Verifying failed boot-test marker and Windows target...
set "MARKER=NO"
if exist "C:\RescueMeAI\state\bootlog-test-65.started" set "MARKER=YES"
>>"%DETAILS%" echo bootlog_test_65_marker=!MARKER!
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

echo [2/4] Checking for the generated Windows boot log...
set "PRESENT=NO"
set "SIZE=0"
set "LINES=0"
if exist "%LOG%" (
  set "PRESENT=YES"
  for %%Z in ("%LOG%") do set "SIZE=%%~zZ"
  for /f %%N in ('find /c /v "" ^< "%LOG%"') do set "LINES=%%N"
)
>>"%DETAILS%" echo ntbtlog_present=!PRESENT!
>>"%DETAILS%" echo ntbtlog_size=!SIZE!
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [3/4] Capturing bounded failed-driver and end-of-log evidence...
if exist "%FAILS%" del /f /q "%FAILS%" >nul 2>&1
set "FAILCOUNT=0"
if exist "%LOG%" (
  findstr /i /c:"Did not load driver" "%LOG%" >"%FAILS%" 2>nul
  if exist "%FAILS%" for /f %%N in ('find /c /v "" ^< "%FAILS%"') do set "FAILCOUNT=%%N"
)
>>"%DETAILS%" echo did_not_load_driver_lines=!FAILCOUNT!
if exist "%FAILS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- FIRST BOUNDED DID-NOT-LOAD LINES ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%FAILS%") do if !N! LSS 20 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
if exist "%LOG%" (
  set /a SKIP=LINES-45
  if !SKIP! LSS 0 set "SKIP=0"
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- LAST BOUNDED BOOT-LOG LINES ---
  call :TAIL !SKIP!
)

echo [4/4] Recording result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=One-time boot-log evidence collection completed.
>>"%RESULT%" echo EVIDENCE=bootlog-test-65 marker=!MARKER!; ntbtlog=!PRESENT!; size=!SIZE!; lines=!LINES!; did-not-load=!FAILCOUNT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the captured boot-log evidence before any further reboot or repair.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BOOT LOG SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:TAIL
set /a TAILN=0
for /f "usebackq skip=%~1 delims=" %%L in ("%LOG%") do if !TAILN! LSS 45 (
  >>"%DETAILS%" echo %%L
  set /a TAILN+=1
)
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot-log evidence collection could not verify the offline Windows target.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
