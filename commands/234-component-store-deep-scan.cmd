@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Run an offline component-store ScanHealth with an adequate scratch directory and capture bounded corruption evidence without repairing Windows.
rem WR_ACTION=SCAN_COMPONENT_STORE_WITH_SAFE_SCRATCH
rem WR_TARGET=Offline Windows C:\Windows component-store health plus RescueMeAI scratch and diagnostic files only.
rem WR_CONSEQUENCE=Scans component-store health and writes diagnostic/scratch files under C:\RescueMeAI and C:\WinRERepair. No component repair, package install/removal, boot change, disk operation, or personal-file operation is performed.
rem WR_ROLLBACK=Diagnostic and scratch files can be deleted later; Windows components are not repaired by this step.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=38"
set "WORK=C:\WinRERepair"
set "SCRATCH=C:\RescueMeAI\scratch"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DLOG=%WORK%\diag38-dism-scanhealth.log"
set "FOCUS=%WORK%\diag38-dism-focus.txt"
set "HEALTH=%WORK%\diag38-checkhealth.txt"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - COMPONENT STORE DEEP SCAN
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : The component store is confirmed REPAIRABLE. Earlier DISM
echo                       also warned that the WinRE scratch area was too small.
echo CURRENT TASK        : Re-scanning the component store using C: as a large scratch
echo                       workspace so the corruption state can be measured reliably.
echo SAFETY              : READ-ONLY SCAN - Windows components are NOT being repaired.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. DISM may take several minutes and shows live progress.
echo SCREENSHOT REQUIRED : NO - unless the final status explicitly says YES.
echo ================================================================================
echo.

>"%DETAILS%" echo RESCUEMEAI COMPONENT STORE DEEP SCAN
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Verifying Windows, DISM, scratch space, and quick reconnect...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo dism_binary=%DISM%
>>"%DETAILS%" echo scratch_dir=%SCRATCH%
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL
if not exist "%DISM%" goto :FAIL

echo [2/4] Running DISM ScanHealth with the large C: scratch directory...
echo       Do not power off the laptop while DISM is scanning.
if exist "%DLOG%" del /f /q "%DLOG%" >nul 2>&1
"%DISM%" /Image:C:\ /Cleanup-Image /ScanHealth /ScratchDir:"%SCRATCH%" /LogPath:"%DLOG%" /LogLevel:3 /English
set "SCANRC=!errorlevel!"
>>"%DETAILS%" echo scanhealth_exit=!SCANRC!

echo [3/4] Re-reading the component-store health state...
if exist "%HEALTH%" del /f /q "%HEALTH%" >nul 2>&1
"%DISM%" /Image:C:\ /Cleanup-Image /CheckHealth /ScratchDir:"%SCRATCH%" /English >"%HEALTH%" 2>&1
set "CHECKRC=!errorlevel!"
set "STATE=UNKNOWN"
findstr /i /c:"component store is repairable" "%HEALTH%" >nul 2>&1 && set "STATE=REPAIRABLE"
findstr /i /c:"No component store corruption detected" "%HEALTH%" >nul 2>&1 && set "STATE=HEALTHY"
findstr /i /c:"component store cannot be repaired" "%HEALTH%" >nul 2>&1 && set "STATE=NOT_REPAIRABLE"
>>"%DETAILS%" echo checkhealth_exit=!CHECKRC!
>>"%DETAILS%" echo component_store_state=!STATE!

echo [4/4] Building a bounded corruption summary...
if exist "%FOCUS%" del /f /q "%FOCUS%" >nul 2>&1
set "FOCUS_LINES=0"
if exist "%DLOG%" (
  findstr /i /c:"corrupt" /c:"repair" /c:"0x800f" /c:"error" /c:"payload" /c:"manifest" "%DLOG%" >"%FOCUS%" 2>nul
  if exist "%FOCUS%" for /f %%N in ('find /c /v "" ^< "%FOCUS%"') do set "FOCUS_LINES=%%N"
)
>>"%DETAILS%" echo dism_focus_lines=!FOCUS_LINES!
if exist "%HEALTH%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- CHECKHEALTH RESULT ---
  type "%HEALTH%" >>"%DETAILS%"
)
if exist "%FOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- LAST DISM CORRUPTION FOCUS LINES ---
  set /a START=1
  if !FOCUS_LINES! GTR 30 set /a START=FOCUS_LINES-29
  more +!START! "%FOCUS%" >>"%DETAILS%" 2>nul
)
>>"%DETAILS%" echo windows_repair_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

if "!SCANRC!"=="0" (
  >"%RESULT%" echo STATUS=PASS
  >>"%RESULT%" echo MESSAGE=Component-store deep scan completed successfully with a dedicated C: scratch directory.
  >>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; ScanHealth rc=!SCANRC!; state=!STATE!; focused DISM lines=!FOCUS_LINES!; reconnect=!RECONNECT!.
  >>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
  >>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the corruption evidence before choosing a repair source or boot-driver isolation test.
  echo.
  echo ================================================================================
  echo RECOVERY FIX        : %FIX_VERSION%
  echo STEP                : %STEP%
  echo STATUS              : COMPLETE - SCAN SENT FOR REVIEW
  echo COMPONENT STORE     : !STATE!
  echo DISM FOCUS LINES    : !FOCUS_LINES!
  echo WINDOWS REPAIR      : NOT PERFORMED
  echo REBOOT              : NO
  echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
  echo SCREENSHOT REQUIRED : NO
  echo ================================================================================
  exit /b 0
)

>"%RESULT%" echo STATUS=WARNING
>>"%RESULT%" echo MESSAGE=Component-store deep scan returned a nonzero code and needs review before any repair.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; ScanHealth rc=!SCANRC!; state=!STATE!; focused DISM lines=!FOCUS_LINES!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : SCAN NEEDS REVIEW
echo DISM EXIT CODE      : !SCANRC!
echo WINDOWS REPAIR      : NOT PERFORMED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 40

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Component-store deep scan could not start because the target or DISM was unavailable.
>>"%RESULT%" echo EVIDENCE=No Windows repair was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED BEFORE SCAN
echo WINDOWS REPAIR      : NOT PERFORMED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
