@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture a compact tail of the Windows boot log produced by the stalled one-time boot-log test.
rem WR_ACTION=COMPACT_BOOTLOG_TAIL
rem WR_TARGET=C:\Windows\ntbtlog.txt and bounded RescueMeAI diagnostic output only.
rem WR_CONSEQUENCE=Reads the generated boot log and writes only bounded diagnostic text under C:\WinRERepair. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=67"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "TAIL=%WORK%\step67-ntbt-tail.txt"
set "MORE=X:\Windows\System32\more.com"
if not exist "%MORE%" set "MORE=C:\Windows\System32\more.com"

cls
echo ================================================================================
echo RescueMeAI - COMPACT BOOT LOG TAIL
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Boot logging succeeded and produced ntbtlog.txt, but the
echo                       previous bounded tail parser did not return its end lines.
echo CURRENT TASK        : Capturing only the final portion of the failed startup log.
echo SAFETY              : READ-ONLY - no repair or reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL
if not exist "%MORE%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI COMPACT BOOT LOG TAIL
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
for %%Z in ("%LOG%") do >>"%DETAILS%" echo ntbtlog_size=%%~zZ
for /f %%N in ('find /c /v "" ^< "%LOG%"') do set "LINES=%%N"
>>"%DETAILS%" echo ntbtlog_lines=!LINES!

echo [1/3] Reading the final portion of ntbtlog.txt...
if exist "%TAIL%" del /f /q "%TAIL%" >nul 2>&1
"%MORE%" +280 "%LOG%" >"%TAIL%" 2>nul
if errorlevel 1 goto :FAIL

echo [2/3] Capturing final loaded-driver sequence...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- NTBTLOG FINAL PORTION ---
set /a N=0
for /f "usebackq delims=" %%L in ("%TAIL%") do if !N! LSS 80 (
  >>"%DETAILS%" echo %%L
  set /a N+=1
)
>>"%DETAILS%" echo captured_tail_lines=!N!

echo [3/3] Recording result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Compact boot-log tail captured successfully.
>>"%RESULT%" echo EVIDENCE=ntbtlog lines=!LINES!; compact final lines=!N!; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the final driver sequence and identify the next safest targeted diagnostic.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - FINAL BOOT-LOG SEQUENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Compact boot-log tail capture could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - BOOT LOG TAIL CAPTURE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
