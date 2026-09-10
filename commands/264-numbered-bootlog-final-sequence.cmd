@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the final loaded-driver sequence from the generated Windows boot log using numbered FINDSTR output.
rem WR_ACTION=NUMBERED_BOOTLOG_FINAL_SEQUENCE
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI diagnostic output only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and writes bounded diagnostic text under C:\WinRERepair. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=68"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step68-loaded-numbered.txt"
set "FINDSTR=X:\Windows\System32\findstr.exe"
if not exist "%FINDSTR%" set "FINDSTR=C:\Windows\System32\findstr.exe"

cls
echo ================================================================================
echo RescueMeAI - NUMBERED BOOT LOG FINAL SEQUENCE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Boot logging produced 346 lines with no explicit
echo                       "Did not load driver" entries. The previous tail utility
echo                       was incompatible with this WinRE environment.
echo CURRENT TASK        : Extracting the final successfully loaded drivers by line
echo                       number without changing the Windows installation.
echo SAFETY              : READ-ONLY - no repair or reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if not exist "%FINDSTR%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI NUMBERED BOOT LOG FINAL SEQUENCE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ
for /f %%N in ('find /c /v "" ^< "%LOG%"') do set "LINES=%%N"
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [1/3] Numbering all successfully loaded-driver entries...
if exist "%NUMBERED%" del /f /q "%NUMBERED%" >nul 2>&1
"%FINDSTR%" /n /i /c:"Loaded driver" "%LOG%" >"%NUMBERED%" 2>nul
if not exist "%NUMBERED%" goto :FAIL

echo [2/3] Capturing only late-boot loaded-driver entries...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LATE BOOT LOADED DRIVER SEQUENCE ---
set /a COUNT=0
set "LASTLINE=0"
set "LASTDRIVER=UNSET"
for /f "usebackq tokens=1,* delims=:" %%A in ("%NUMBERED%") do (
  set /a LN=%%A >nul 2>&1
  if !LN! GEQ 240 if !COUNT! LSS 110 (
    >>"%DETAILS%" echo line=!LN!;%%B
    set /a COUNT+=1
    set "LASTLINE=!LN!"
    set "LASTDRIVER=%%B"
  )
)
>>"%DETAILS%" echo captured_late_driver_lines=!COUNT!
>>"%DETAILS%" echo last_loaded_line=!LASTLINE!
>>"%DETAILS%" echo last_loaded_driver=!LASTDRIVER!

echo [3/3] Recording result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Numbered final boot-driver sequence captured successfully.
>>"%RESULT%" echo EVIDENCE=ntbtlog lines=!LINES!; late loaded-driver entries=!COUNT!; last loaded boot-log line=!LASTLINE!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the final successfully loaded driver sequence before any further boot change.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - FINAL DRIVER SEQUENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Numbered boot-log sequence capture could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOT LOG SEQUENCE CAPTURE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
