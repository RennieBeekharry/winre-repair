@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the successful raw boot-log capture for graphics/display driver transitions around the HP-spinner hang.
rem WR_ACTION=GRAPHICS_BOOT_PATH_DIAGNOSTIC
rem WR_TARGET=C:\Windows\ntbtlog.txt, selected graphics driver files, and bounded RescueMeAI diagnostic text only.
rem WR_CONSEQUENCE=Reads boot-log text and checks selected graphics driver file presence. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=71"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step71-ntbtlog-numbered.txt"
set "MATCHES=%WORK%\step71-graphics-matches.txt"

cls
echo ================================================================================
echo RescueMeAI - GRAPHICS BOOT-PATH DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The boot log reaches late device initialization. Its final
echo                       entries include BasicRender and dxgkrnl not-loaded records.
echo CURRENT TASK        : Checking whether graphics/display drivers loaded earlier,
echo                       and verifying the referenced core/AMD driver files exist.
echo SAFETY              : READ-ONLY - no repair and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if exist "%NUMBERED%" del /f /q "%NUMBERED%" >nul 2>&1
if exist "%MATCHES%" del /f /q "%MATCHES%" >nul 2>&1

> "%DETAILS%" echo RESCUEMEAI GRAPHICS BOOT-PATH DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Producing a plain-text numbered copy of ntbtlog.txt...
find /n /v "" < "%LOG%" > "%NUMBERED%" 2>"%WORK%\step71-find.err"
if errorlevel 1 goto :FAIL
for /f %%N in ('find /c /v "" ^< "%NUMBERED%"') do set "LINES=%%N"
if not defined LINES goto :FAIL
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [2/4] Locating graphics/display-related boot-log entries...
findstr /i /c:"dxgkrnl" /c:"BasicDisplay" /c:"BasicRender" /c:"amdkmdag" /c:"amdwddmg" /c:"atikmdag" /c:"amdfendr" /c:"amdfendrmgr" /c:"watchdog" /c:"display" "%NUMBERED%" > "%MATCHES%" 2>nul
set "MATCHCOUNT=0"
if exist "%MATCHES%" for /f %%N in ('find /c /v "" ^< "%MATCHES%"') do set "MATCHCOUNT=%%N"
>>"%DETAILS%" echo graphics_match_lines=!MATCHCOUNT!
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- GRAPHICS/DISPLAY BOOT-LOG MATCHES ---
if exist "%MATCHES%" type "%MATCHES%" >>"%DETAILS%"

echo [3/4] Checking selected graphics driver files...
call :FILE dxgkrnl.sys
call :FILE BasicDisplay.sys
call :FILE BasicRender.sys
call :FILE watchdog.sys
call :FILE amdkmdag.sys
call :FILE amdwddmg.sys
call :FILE amdfendr.sys
call :FILE amdfendrmgr.sys

echo [4/4] Recording read-only result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Graphics boot-path diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=graphics/display boot-log matches=!MATCHCOUNT!; selected graphics driver file presence captured; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether a one-time Safe Mode test is justified by the graphics boot-path evidence.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - GRAPHICS BOOT EVIDENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FILE
set "FN=%~1"
if exist "C:\Windows\System32\drivers\%FN%" (
  for %%Z in ("C:\Windows\System32\drivers\%FN%") do >>"%DETAILS%" echo driver_file=%FN%;present=YES;size=%%~zZ
) else (
  >>"%DETAILS%" echo driver_file=%FN%;present=NO
)
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Graphics boot-path diagnostic could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - GRAPHICS DIAGNOSTIC FAILED SAFELY
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. ChatGPT will review the collection method.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 90
