@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Confirm full-log load/not-load occurrences for the graphics stack and read the AMD display driver package metadata used by the failed boot.
rem WR_ACTION=CONFIRM_GRAPHICS_BOOT_AND_AMD_PACKAGE
rem WR_TARGET=C:\Windows\ntbtlog.txt, the referenced AMD display DriverStore package, and bounded RescueMeAI diagnostic text only.
rem WR_CONSEQUENCE=Reads boot-log occurrences and offline driver package metadata. No Windows setting, BCD, EFI file, registry, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=73"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "AMDINF=C:\Windows\System32\DriverStore\FileRepository\u0407196.inf_amd64_4f30592185b667eb\u0407196.inf"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"

cls
echo ================================================================================
echo RescueMeAI - GRAPHICS BOOT CONFIRMATION
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Raw boot evidence shows BasicDisplay and AMD amdkmdag load,
echo                       while dxgkrnl records appear as NOT_LOADED late in startup.
echo CURRENT TASK        : Confirming every full-log occurrence and reading the exact
echo                       AMD display package metadata before considering Safe Mode.
echo SAFETY              : READ-ONLY - no repair and no reboot.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LOG%" goto :FAIL

> "%DETAILS%" echo RESCUEMEAI GRAPHICS BOOT CONFIRMATION
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Counting full boot-log status records...
call :COUNT "BOOTLOG_LOADED" loaded_records
call :COUNT "BOOTLOG_NOT_LOADED" not_loaded_records
call :COUNT "dxgkrnl.sys" dxgkrnl_occurrences
call :COUNT "amdkmdag.sys" amdkmdag_occurrences
call :COUNT "BasicDisplay.sys" basicdisplay_occurrences
call :COUNT "BasicRender.sys" basicrender_occurrences
call :COUNT "tapexpressvpn.sys" expressvpn_tap_occurrences
call :COUNT "expressvpn-wintun.sys" expressvpn_wintun_occurrences

echo [2/4] Capturing exact graphics-stack occurrences from the full log...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- DXGKRNL OCCURRENCES ---
find /i "dxgkrnl.sys" < "%LOG%" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BASICDISPLAY OCCURRENCES ---
find /i "BasicDisplay.sys" < "%LOG%" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- BASICRENDER OCCURRENCES ---
find /i "BasicRender.sys" < "%LOG%" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- AMDKMDAG OCCURRENCES ---
find /i "amdkmdag.sys" < "%LOG%" >>"%DETAILS%" 2>nul

echo [3/4] Reading the exact AMD display DriverStore package metadata...
if exist "%AMDINF%" (
  >>"%DETAILS%" echo amd_display_inf_present=YES
  >>"%DETAILS%" echo amd_display_inf=%AMDINF%
  if exist "%DISM%" (
    "%DISM%" /English /Image:C:\ /Get-DriverInfo /Driver:"%AMDINF%" >"%WORK%\step73-amd-driverinfo.txt" 2>&1
    set "DISMRC=!errorlevel!"
    >>"%DETAILS%" echo amd_driverinfo_exit=!DISMRC!
    if exist "%WORK%\step73-amd-driverinfo.txt" type "%WORK%\step73-amd-driverinfo.txt" >>"%DETAILS%"
  ) else (
    >>"%DETAILS%" echo amd_driverinfo_exit=DISM_NOT_FOUND
  )
) else (
  >>"%DETAILS%" echo amd_display_inf_present=NO
)

echo [4/4] Recording read-only result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Graphics boot occurrence and AMD package diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Full ntbtlog graphics occurrences and AMD display package metadata were captured; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether to prepare a reversible one-time Safe Mode boot test.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - GRAPHICS BOOT/PACKAGE EVIDENCE SENT
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:COUNT
set "TERM=%~1"
set "OUTVAR=%~2"
set "CNT=0"
for /f %%N in ('find /i /c "%TERM%" ^< "%LOG%"') do set "CNT=%%N"
>>"%DETAILS%" echo %OUTVAR%=!CNT!
exit /b 0

:FAIL
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Graphics boot confirmation could not verify the generated boot log.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - GRAPHICS CONFIRMATION FAILED SAFELY
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. ChatGPT will review the evidence path.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 90
