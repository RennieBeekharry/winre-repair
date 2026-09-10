@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect installed servicing packages and focused DISM/CBS source errors before selecting the next repair.
rem WR_ACTION=ANALYZE_REPAIR_SOURCE
rem WR_TARGET=Offline Windows servicing metadata and logs only.
rem WR_CONSEQUENCE=Read-only diagnostic. No Windows, BCD, registry, package, partition, reboot, or personal-file changes.
rem WR_ROLLBACK=Not applicable.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=39"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - REPAIR SOURCE ANALYSIS
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Component store is repairable; prior RestoreHealth failed
echo                       because required repair content could not be resolved.
echo CURRENT TASK        : Checking exact installed package and servicing error evidence.
echo SAFETY              : READ-ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================

if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL
echo [1/4] Capturing installed package state...
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%WORK%\diag39-packages.txt" 2>&1
set "PKGRC=!errorlevel!"
findstr /i /c:"5121003" /c:"5043080" /c:"9168" /c:"9156" /c:"RollupFix" /c:"ServicingStack" "%WORK%\diag39-packages.txt" >"%WORK%\diag39-package-focus.txt" 2>nul
for /f %%N in ('find /c /v "" ^< "%WORK%\diag39-package-focus.txt" 2^>nul') do set "PKGLINES=%%N"
if not defined PKGLINES set "PKGLINES=0"

echo [2/4] Checking focused DISM source errors...
findstr /i /c:"0x800f0915" /c:"repair content" /c:"source files" /c:"CBS_E_SOURCE_MISSING" /c:"corrupt" "C:\Windows\Logs\DISM\dism.log" >"%WORK%\diag39-dism-focus.txt" 2>nul
for /f %%N in ('find /c /v "" ^< "%WORK%\diag39-dism-focus.txt" 2^>nul') do set "DISMLINES=%%N"
if not defined DISMLINES set "DISMLINES=0"

echo [3/4] Checking focused CBS source errors...
findstr /i /c:"0x800f0915" /c:"CBS_E_SOURCE_MISSING" /c:"CBS_E_STORE_CORRUPTION" /c:"Failed to resolve package" /c:"Failed to pin deployment" "C:\Windows\Logs\CBS\CBS.log" >"%WORK%\diag39-cbs-focus.txt" 2>nul
for /f %%N in ('find /c /v "" ^< "%WORK%\diag39-cbs-focus.txt" 2^>nul') do set "CBSLINES=%%N"
if not defined CBSLINES set "CBSLINES=0"

echo [4/4] Recording bounded result...
set "P1=NO"
set "P2=NO"
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu" set "P1=YES"
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu" set "P2=YES"
>"%DETAILS%" echo RESCUEMEAI REPAIR SOURCE ANALYSIS
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo dism_get_packages_exit=!PKGRC!
>>"%DETAILS%" echo package_focus_lines=!PKGLINES!
>>"%DETAILS%" echo dism_focus_lines=!DISMLINES!
>>"%DETAILS%" echo cbs_focus_lines=!CBSLINES!
>>"%DETAILS%" echo checkpoint_payload_present=!P1!
>>"%DETAILS%" echo cumulative_payload_present=!P2!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Repair-source analysis completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; package lines=!PKGLINES!; DISM lines=!DISMLINES!; CBS lines=!CBSLINES!; checkpoint=!P1!; LCU=!P2!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will select the least-invasive supported repair path before any write operation.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo PACKAGE FOCUS LINES : !PKGLINES!
echo DISM FOCUS LINES    : !DISMLINES!
echo CBS FOCUS LINES     : !CBSLINES!
echo REPAIR PAYLOADS     : CHECKPOINT=!P1!  LCU=!P2!
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Windows target could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
exit /b 90
