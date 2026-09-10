@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the offline component-store health flag and installed cumulative/servicing-stack package state before any further repair.
rem WR_ACTION=INSPECT_COMPONENT_STORE_AND_ROLLUP_STATE
rem WR_TARGET=Offline Windows C:\Windows DISM package metadata and component-store health only.
rem WR_CONSEQUENCE=Reads servicing metadata and writes bounded diagnostic text under C:\WinRERepair. No package install, removal, Windows repair, boot change, disk operation, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=37"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "PKGLIST=%WORK%\diag37-packages.txt"
set "ROLLUPS=%WORK%\diag37-rollups.txt"
set "HEALTH=%WORK%\diag37-health.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - COMPONENT STORE + UPDATE STATE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : BCD is structurally normal, no servicing action is pending,
echo                       and the three key boot binaries were unchanged by SFC.
echo CURRENT TASK        : Checking whether the component store is still marked
echo                       repairable and identifying the installed rollup/SSU state.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI COMPONENT STORE AND UPDATE STATE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/4] Verifying Windows and the permanent quick reconnect...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/4] Reading the component-store health flag...
if exist "%HEALTH%" del /f /q "%HEALTH%" >nul 2>&1
"%DISM%" /Image:C:\ /Cleanup-Image /CheckHealth /English >"%HEALTH%" 2>&1
set "HEALTHRC=!errorlevel!"
set "HEALTH_STATE=UNKNOWN"
findstr /i /c:"The component store is repairable" "%HEALTH%" >nul 2>&1 && set "HEALTH_STATE=REPAIRABLE"
findstr /i /c:"No component store corruption detected" "%HEALTH%" >nul 2>&1 && set "HEALTH_STATE=HEALTHY"
findstr /i /c:"The component store cannot be repaired" "%HEALTH%" >nul 2>&1 && set "HEALTH_STATE=NOT_REPAIRABLE"
>>"%DETAILS%" echo dism_checkhealth_exit=!HEALTHRC!
>>"%DETAILS%" echo component_store_state=!HEALTH_STATE!

echo [3/4] Reading installed package metadata...
if exist "%PKGLIST%" del /f /q "%PKGLIST%" >nul 2>&1
if exist "%ROLLUPS%" del /f /q "%ROLLUPS%" >nul 2>&1
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%PKGLIST%" 2>&1
set "PKGRC=!errorlevel!"
if exist "%PKGLIST%" findstr /i /c:"RollupFix" /c:"ServicingStack" "%PKGLIST%" >"%ROLLUPS%" 2>nul
set "ROLLUP_LINES=0"
if exist "%ROLLUPS%" for /f %%N in ('find /c /v "" ^< "%ROLLUPS%"') do set "ROLLUP_LINES=%%N"
>>"%DETAILS%" echo dism_get_packages_exit=!PKGRC!
>>"%DETAILS%" echo rollup_ssu_rows=!ROLLUP_LINES!

echo [4/4] Recording the bounded servicing evidence...
if exist "%HEALTH%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- COMPONENT STORE HEALTH ---
  type "%HEALTH%" >>"%DETAILS%"
)
if exist "%ROLLUPS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- ROLLUP / SERVICING STACK ROWS ---
  type "%ROLLUPS%" >>"%DETAILS%"
)
>>"%DETAILS%" echo downloaded_checkpoint_present=NO
>>"%DETAILS%" echo downloaded_lcu_present=NO
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu" >>"%DETAILS%" echo downloaded_checkpoint_present=YES
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu" >>"%DETAILS%" echo downloaded_lcu_present=YES
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Component-store and installed update-state diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; component store=!HEALTH_STATE!; CheckHealth rc=!HEALTHRC!; rollup/SSU rows=!ROLLUP_LINES!; package query rc=!PKGRC!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether a targeted servicing repair or boot-driver isolation test is safer.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo COMPONENT STORE     : !HEALTH_STATE!
echo ROLLUP / SSU ROWS   : !ROLLUP_LINES!
echo QUICK RECONNECT     : !RECONNECT!  (future command: C:\r.cmd)
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Component-store diagnostic stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
