@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform one final guarded offline DISM component-store repair attempt against C:\Windows, then run offline SFC, before deciding on clean reinstall.
rem WR_ACTION=FINAL_OFFLINE_DISM_AND_SFC
rem WR_TARGET=Offline Windows installation at C:\Windows only.
rem WR_CONSEQUENCE=DISM may repair the offline Windows component store and SFC may replace corrupted protected Windows system files. No personal files, partitions, EFI/BCD settings, or reboot are touched.
rem WR_ROLLBACK=This is standard Windows servicing and system-file repair. No personal files are targeted. If servicing fails or Windows still cannot boot, stop and proceed to hardware validation / clean-install planning rather than repeat repairs.

set "FIX_VERSION=RMAI-FIX-2026.09.10.4"
set "STEP=83"
set "WORK=C:\WinRERepair"
set "SCRATCH=C:\RescueMeAI\scratch"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "SFC=X:\Windows\System32\sfc.exe"
if not exist "%SFC%" set "SFC=C:\Windows\System32\sfc.exe"

cls
echo ================================================================================
echo RescueMeAI - FINAL WINDOWS SERVICING ATTEMPT
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : PRE-FLIGHT CHECK
echo CURRENT DIAGNOSIS   : Normal boot and Safe Mode both stall after prior Reset/
echo                       reinstall activity. EFI, BCD, storage, and SFC were already
echo                       checked. This is the final servicing attempt before reinstall.
echo CURRENT TASK        : Run OFFLINE DISM against C:\Windows, then OFFLINE SFC.
echo IMPORTANT           : /Online is NOT used because WinRE is the running OS.
echo SAFETY              : WINDOWS REPAIR ONLY - NO PERSONAL FILES OR REBOOT.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL_PRE
if not exist "%DISM%" goto :FAIL_PRE
if not exist "%SFC%" goto :FAIL_PRE

>"%DETAILS%" echo RESCUEMEAI FINAL OFFLINE DISM AND SFC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%
>>"%DETAILS%" echo windows_target=C:\Windows
>>"%DETAILS%" echo online_switch_used=NO

echo [1/4] Checking component-store health...
"%DISM%" /Image:C:\ /Cleanup-Image /CheckHealth /ScratchDir:"%SCRATCH%" >"%WORK%\step83-dism-checkhealth.txt" 2>&1
set "CHECKRC=!errorlevel!"
>>"%DETAILS%" echo dism_checkhealth_exit=!CHECKRC!

echo [2/4] Running one final OFFLINE DISM RestoreHealth attempt...
"%DISM%" /Image:C:\ /Cleanup-Image /RestoreHealth /ScratchDir:"%SCRATCH%" >"%WORK%\step83-dism-restorehealth.txt" 2>&1
set "DISMRC=!errorlevel!"
>>"%DETAILS%" echo dism_restorehealth_exit=!DISMRC!
findstr /i /c:"The restore operation completed successfully" /c:"The component store corruption was repaired" /c:"source files could not be found" /c:"0x800f0915" /c:"Error:" "%WORK%\step83-dism-restorehealth.txt" >>"%DETAILS%" 2>nul

echo [3/4] Running OFFLINE SFC against C:\Windows...
"%SFC%" /scannow /offbootdir=C:\ /offwindir=C:\Windows >"%WORK%\step83-sfc.txt" 2>&1
set "SFCRC=!errorlevel!"
>>"%DETAILS%" echo sfc_scannow_exit=!SFCRC!
findstr /i /c:"Windows Resource Protection did not find any integrity violations" /c:"Windows Resource Protection found corrupt files and successfully repaired them" /c:"Windows Resource Protection found corrupt files but was unable to fix some of them" /c:"Windows Resource Protection could not perform the requested operation" "%WORK%\step83-sfc.txt" >>"%DETAILS%" 2>nul

echo [4/4] Recording final servicing result...
>>"%DETAILS%" echo windows_changes_possible=YES_STANDARD_SERVICING
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo partition_changes=NO
>>"%DETAILS%" echo bcd_efi_changes=NO
>>"%DETAILS%" echo reboot_performed=NO

set "FINALSTATUS=PASS"
set "FINALMSG=Final offline DISM and SFC servicing pass completed."
set "FINALEVIDENCE=DISM RestoreHealth exit !DISMRC!; SFC exit !SFCRC!. Review captured servicing summaries before any reboot."
if not "!DISMRC!"=="0" set "FINALSTATUS=WARNING"
if not "!DISMRC!"=="0" set "FINALMSG=Final offline servicing pass completed, but DISM RestoreHealth did not succeed; do not repeat it blindly."
if !SFCRC! GEQ 2 set "FINALSTATUS=WARNING"

>"%RESULT%" echo STATUS=!FINALSTATUS!
>>"%RESULT%" echo MESSAGE=!FINALMSG!
>>"%RESULT%" echo EVIDENCE=!FINALEVIDENCE!
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review this one final servicing attempt. No reboot until the result is reviewed.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - FINAL SERVICING RESULT SENT FOR REVIEW
echo DISM EXIT           : !DISMRC!
echo SFC EXIT            : !SFCRC!
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not reboot yet.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL_PRE
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Final servicing attempt stopped because the offline Windows target or required WinRE servicing tools could not be verified.
>>"%RESULT%" echo EVIDENCE=No DISM RestoreHealth, SFC repair, personal-file action, partition action, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - PRE-FLIGHT FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
