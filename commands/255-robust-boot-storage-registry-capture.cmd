@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Read the offline SYSTEM Select key and boot-storage service values without relying on brittle ControlSet parsing.
rem WR_ACTION=ROBUST_BOOT_STORAGE_REGISTRY_CAPTURE
rem WR_TARGET=Offline Windows SYSTEM hive read-only plus RescueMeAI diagnostic text.
rem WR_CONSEQUENCE=Temporarily loads the offline SYSTEM hive, reads Select and storage boot-service values from available ControlSets, then unloads it. No Windows setting, BCD, EFI file, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Temporary offline-hive mount is unloaded before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=59"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REG=X:\Windows\System32\reg.exe"
if not exist "%REG%" set "REG=C:\Windows\System32\reg.exe"
set "HIVEKEY=HKLM\RMAI_OFFLINE_SYSTEM"
set "HIVE=C:\Windows\System32\config\SYSTEM"

cls
echo ================================================================================
echo RescueMeAI - ROBUST BOOT STORAGE REGISTRY CAPTURE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Reading the offline SYSTEM Select key and boot-storage
echo                       service configuration without modifying Windows.
echo SAFETY              : READ-ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%REG%" goto :FAIL
if not exist "%HIVE%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI ROBUST BOOT STORAGE REGISTRY CAPTURE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Loading offline SYSTEM hive...
"%REG%" unload "%HIVEKEY%" >nul 2>&1
"%REG%" load "%HIVEKEY%" "%HIVE%" >"%WORK%\step59-regload.txt" 2>&1
if errorlevel 1 goto :FAIL
set "LOADED=YES"

echo [2/4] Capturing Select key verbatim...
>>"%DETAILS%" echo.
>>"%DETAILS%" echo --- OFFLINE SYSTEM SELECT ---
"%REG%" query "%HIVEKEY%\Select" >>"%DETAILS%" 2>&1

echo [3/4] Capturing boot-storage services from available ControlSets...
for %%C in (ControlSet001 ControlSet002 ControlSet003) do call :CONTROLSET %%C

echo [4/4] Unloading temporary hive mount and recording result...
"%REG%" unload "%HIVEKEY%" >"%WORK%\step59-regunload.txt" 2>&1
set "LOADED=NO"
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Robust offline boot/storage registry capture completed successfully.
>>"%RESULT%" echo EVIDENCE=Select and available ControlSet storage-service values were captured verbatim without changing Windows.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will determine whether storage boot-start configuration is valid before enabling any one-time boot diagnostic.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - BOOT STORAGE CONFIG SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:CONTROLSET
set "CS=%~1"
"%REG%" query "%HIVEKEY%\%CS%" >nul 2>&1
if errorlevel 1 (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo controlset=%CS%;present=NO
  exit /b 0
)
>>"%DETAILS%" echo.
>>"%DETAILS%" echo === %CS% ===
for %%S in (storahci stornvme disk partmgr volmgr volmgrx fvevol mountmgr spaceport iaStorV iaStorAVC iaStorVD iaStorAC iaStorAfs) do call :SERVICE "%CS%" %%S
call :FILTER "%CS%" "{4d36e967-e325-11ce-bfc1-08002be10318}" "DiskDrive"
call :FILTER "%CS%" "{4d36e97b-e325-11ce-bfc1-08002be10318}" "SCSIAdapter"
call :FILTER "%CS%" "{71a27cdd-812a-11d0-bec7-08002be2092f}" "Volume"
exit /b 0

:SERVICE
set "CS=%~1"
set "SVC=%~2"
set "BASE=%HIVEKEY%\%CS%\Services\%SVC%"
"%REG%" query "%BASE%" >nul 2>&1
if errorlevel 1 (
  >>"%DETAILS%" echo service=%CS%\%SVC%;present=NO
  exit /b 0
)
>>"%DETAILS%" echo service=%CS%\%SVC%;present=YES
"%REG%" query "%BASE%" /v Start >>"%DETAILS%" 2>nul
"%REG%" query "%BASE%" /v Group >>"%DETAILS%" 2>nul
"%REG%" query "%BASE%" /v ImagePath >>"%DETAILS%" 2>nul
"%REG%" query "%BASE%\StartOverride" >>"%DETAILS%" 2>nul
exit /b 0

:FILTER
set "CS=%~1"
set "GUID=%~2"
set "LABEL=%~3"
set "KEY=%HIVEKEY%\%CS%\Control\Class\%GUID%"
>>"%DETAILS%" echo class_filter=%CS%\%LABEL%
"%REG%" query "%KEY%" /v UpperFilters >>"%DETAILS%" 2>nul
"%REG%" query "%KEY%" /v LowerFilters >>"%DETAILS%" 2>nul
exit /b 0

:FAIL
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Robust boot/storage registry capture could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows configuration or personal files were changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - REGISTRY CAPTURE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
