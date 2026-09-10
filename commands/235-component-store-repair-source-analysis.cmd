@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Identify the component-store corruption and installed servicing package state before choosing a repair source.
rem WR_ACTION=ANALYZE_COMPONENT_STORE_REPAIR_SOURCE
rem WR_TARGET=Offline Windows DISM/CBS servicing metadata and installed package list only.
rem WR_CONSEQUENCE=Reads servicing logs and package state and writes only bounded diagnostic text under C:\WinRERepair. No Windows repair, package install, BCD change, registry change, reboot, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=39"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"
set "DISMLOG=C:\Windows\Logs\DISM\dism.log"
set "CBSLOG=C:\Windows\Logs\CBS\CBS.log"
set "PKGOUT=%WORK%\diag39-packages.txt"
set "PKGFOCUS=%WORK%\diag39-package-focus.txt"
set "DISMFOCUS=%WORK%\diag39-dism-focus.txt"
set "CBSFOCUS=%WORK%\diag39-cbs-focus.txt"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - COMPONENT STORE REPAIR-SOURCE ANALYSIS
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows component store is confirmed repairable, while
echo                       the prior RestoreHealth attempt could not find repair content.
echo CURRENT TASK        : Identifying the exact servicing/package evidence needed
echo                       to choose the safest supported repair source.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI COMPONENT STORE REPAIR SOURCE ANALYSIS
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/5] Verifying the offline Windows target and repair payloads...
set "TARGET=NO"
set "RECONNECT=NO"
set "P1=NO"
set "P2=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu" set "P1=YES"
if exist "C:\RescueMeAI\packages\KB5121003\windows11.0-kb5121003-x64_dc58f03fef04b4c611e0db0ab3fadfb301194113.msu" set "P2=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
>>"%DETAILS%" echo checkpoint_payload_present=!P1!
>>"%DETAILS%" echo cumulative_payload_present=!P2!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/5] Capturing installed servicing package identities...
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%PKGOUT%" 2>&1
set "PKGRC=!errorlevel!"
if exist "%PKGFOCUS%" del /f /q "%PKGFOCUS%" >nul 2>&1
if exist "%PKGOUT%" findstr /i /c:"KB5043080" /c:"KB5121003" /c:"9168" /c:"9156" /c:"RollupFix" /c:"ServicingStack" "%PKGOUT%" >"%PKGFOCUS%" 2>nul
set "PKGLINES=0"
if exist "%PKGFOCUS%" for /f %%N in ('find /c /v "" ^< "%PKGFOCUS%"') do set "PKGLINES=%%N"
>>"%DETAILS%" echo dism_get_packages_exit=!PKGRC!
>>"%DETAILS%" echo servicing_package_focus_lines=!PKGLINES!

echo [3/5] Reading focused DISM repair-source evidence...
if exist "%DISMFOCUS%" del /f /q "%DISMFOCUS%" >nul 2>&1
if exist "%DISMLOG%" findstr /i /c:"0x800f0915" /c:"repair content" /c:"source files" /c:"source" /c:"corrupt" /c:"missing" "%DISMLOG%" >"%DISMFOCUS%" 2>nul
set "DISMLINES=0"
if exist "%DISMFOCUS%" for /f %%N in ('find /c /v "" ^< "%DISMFOCUS%"') do set "DISMLINES=%%N"
>>"%DETAILS%" echo dism_log_present=YES
if not exist "%DISMLOG%" >>"%DETAILS%" echo dism_log_present=NO
>>"%DETAILS%" echo dism_focus_lines=!DISMLINES!

echo [4/5] Reading focused CBS corruption/source evidence...
if exist "%CBSFOCUS%" del /f /q "%CBSFOCUS%" >nul 2>&1
if exist "%CBSLOG%" findstr /i /c:"0x800f0915" /c:"CBS_E_SOURCE_MISSING" /c:"CBS_E_STORE_CORRUPTION" /c:"repair content" /c:"Failed to resolve package" /c:"Failed to pin deployment" "%CBSLOG%" >"%CBSFOCUS%" 2>nul
set "CBSLINES=0"
if exist "%CBSFOCUS%" for /f %%N in ('find /c /v "" ^< "%CBSFOCUS%"') do set "CBSLINES=%%N"
>>"%DETAILS%" echo cbs_log_present=YES
if not exist "%CBSLOG%" >>"%DETAILS%" echo cbs_log_present=NO
>>"%DETAILS%" echo cbs_focus_lines=!CBSLINES!

echo [5/5] Recording the bounded repair-source evidence...
if exist "%PKGFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- SERVICING PACKAGE FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%PKGFOCUS%") do if !N! LSS 40 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
if exist "%DISMFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- DISM SOURCE/CORRUPTION FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%DISMFOCUS%") do if !N! LSS 30 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
if exist "%CBSFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- CBS SOURCE/CORRUPTION FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%CBSFOCUS%") do if !N! LSS 30 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Component-store repair-source analysis completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; package focus lines=!PKGLINES!; DISM focus lines=!DISMLINES!; CBS focus lines=!CBSLINES!; checkpoint=!P1!; LCU=!P2!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will select the least-invasive supported repair path from this evidence before any write operation.

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
echo HOW TO REPLY        : No reply needed unless an unexpected error appears.
echo                       If that happens, reply FAILED and attach a photo.
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Repair-source analysis stopped because C:\Windows could not be verified.
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
