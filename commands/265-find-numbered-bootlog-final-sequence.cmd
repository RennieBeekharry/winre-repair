@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture the final loaded-driver sequence from the Windows boot log using FIND, which supports this boot-log encoding in WinRE.
rem WR_ACTION=FIND_NUMBERED_BOOTLOG_FINAL_SEQUENCE
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI diagnostic output only.
rem WR_CONSEQUENCE=Reads the generated Windows boot log and writes bounded diagnostic text under C:\WinRERepair. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=69"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step69-find-numbered.txt"
set "FIND=X:\Windows\System32\find.exe"
if not exist "%FIND%" set "FIND=C:\Windows\System32\find.exe"

cls
echo ================================================================================
echo RescueMeAI - BOOT LOG DRIVER SEQUENCE / FIND COMPATIBILITY PASS
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : ntbtlog.txt exists and has 346 lines, but FINDSTR did not
echo                       decode its loaded-driver text correctly in this WinRE build.
echo CURRENT TASK        : Using Windows FIND /N to extract late successfully loaded
echo                       drivers from the failed startup.
echo SAFETY              : READ-ONLY - no repair or reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if not exist "%FIND%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI FIND NUMBERED BOOT LOG FINAL SEQUENCE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ
for /f %%N in ('"%FIND%" /c /v "" "%LOG%"') do set "LINES=%%N"
if not defined LINES set "LINES=UNKNOWN"
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [1/3] Extracting and numbering Loaded driver entries...
if exist "%NUMBERED%" del /f /q "%NUMBERED%" >nul 2>&1
"%FIND%" /n /i "Loaded driver" "%LOG%" >"%NUMBERED%" 2>nul
set "FINDRC=!errorlevel!"
>>"%DETAILS%" echo find_loaded_driver_exit=!FINDRC!
if not exist "%NUMBERED%" goto :FAIL

echo [2/3] Capturing the late-driver sequence...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- LATE BOOT LOADED DRIVER SEQUENCE ---
set /a COUNT=0
set "LASTLINE=0"
set "LASTDRIVER=UNSET"
for /f "usebackq tokens=1,* delims=[]" %%A in ("%NUMBERED%") do (
  set "RAW=%%A"
  echo(!RAW!| "%FIND%" /v "----------" >nul 2>&1
  if not errorlevel 1 (
    set /a LN=RAW+0 >nul 2>&1
    if !LN! GEQ 220 if !COUNT! LSS 120 (
      >>"%DETAILS%" echo line=!LN!;%%B
      set /a COUNT+=1
      set "LASTLINE=!LN!"
      set "LASTDRIVER=%%B"
    )
  )
)
>>"%DETAILS%" echo captured_late_driver_lines=!COUNT!
>>"%DETAILS%" echo last_loaded_line=!LASTLINE!
>>"%DETAILS%" echo last_loaded_driver=!LASTDRIVER!

echo [3/3] Recording result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=FIND-compatible boot-log driver sequence capture completed.
>>"%RESULT%" echo EVIDENCE=late loaded-driver entries=!COUNT!; last loaded line=!LASTLINE!; FIND exit=!FINDRC!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the late-driver sequence before any further repair or reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BOOT DRIVER SEQUENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=FIND-compatible boot-log sequence capture could not complete safely.
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
