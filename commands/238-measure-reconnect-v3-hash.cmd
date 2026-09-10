@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Measure the downloaded reconnect-v3 helper hash after the integrity mismatch.
rem WR_ACTION=MEASURE_RECONNECT_V3_HASH
rem WR_TARGET=C:\WinRERepair\reconnect-v3.download.cmd only.
rem WR_CONSEQUENCE=Reads one RescueMeAI helper file and records its SHA-256. No Windows or personal-file changes.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=41"
set "WORK=C:\WinRERepair"
set "FILE=%WORK%\reconnect-v3.download.cmd"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CERT=C:\Windows\System32\certutil.exe"

cls
echo ================================================================================
echo RescueMeAI - RECONNECT INTEGRITY DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Measuring the downloaded reconnect helper SHA-256.
echo SAFETY              : READ-ONLY
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "%FILE%" goto :FAIL
set "ACTUAL="
for /f "skip=1 delims=" %%H in ('"%CERT%" -hashfile "%FILE%" SHA256 2^>nul') do if not defined ACTUAL set "ACTUAL=%%H"
set "ACTUAL=!ACTUAL: =!"
if not defined ACTUAL goto :FAIL

>"%DETAILS%" echo RESCUEMEAI RECONNECT HASH DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo reconnect_v3_actual_sha256=!ACTUAL!
>>"%DETAILS%" echo windows_changes_performed=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Reconnect-v3 downloaded-file SHA-256 measured successfully.
>>"%RESULT%" echo EVIDENCE=Actual SHA-256 is !ACTUAL!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will correct the pinned helper hash and reinstall it.

echo STATUS              : COMPLETE - HASH SENT FOR REVIEW
echo ACTUAL SHA-256      : !ACTUAL!
echo WHAT YOU SHOULD DO  : WAIT.
echo SCREENSHOT REQUIRED : NO
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Reconnect-v3 downloaded file or SHA-256 result was unavailable.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED
echo SCREENSHOT REQUIRED : YES
exit /b 90
