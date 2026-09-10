@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect the offline SYSTEM hive for boot-start storage services and storage class filters after the HP-logo hang.
rem WR_ACTION=BOOT_STORAGE_REGISTRY_DIAGNOSTIC
rem WR_TARGET=Offline Windows SYSTEM hive read-only plus RescueMeAI diagnostic text.
rem WR_CONSEQUENCE=Temporarily loads the offline SYSTEM hive for read-only queries, records bounded storage boot configuration, then unloads it. No Windows setting, BCD, EFI file, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=The temporary offline-hive mount is unloaded before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=57"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REG=X:\Windows\System32\reg.exe"
if not exist "%REG%" set "REG=C:\Windows\System32\reg.exe"
set "FINDSTR=X:\Windows\System32\findstr.exe"
if not exist "%FINDSTR%" set "FINDSTR=C:\Windows\System32\findstr.exe"
set "HIVEKEY=HKLM\RMAI_OFFLINE_SYSTEM"
set "HIVE=C:\Windows\System32\config\SYSTEM"

cls
echo ================================================================================
echo RescueMeAI - BOOT STORAGE REGISTRY DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows reaches the HP spinner but stalls after the verified
echo                       EFI repair; native storage driver files are present.
echo CURRENT TASK        : Checking offline boot-start storage service configuration
echo                       and storage class filters before changing boot behavior.
echo SAFETY              : READ-ONLY - offline registry queries only.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%REG%" goto :FAIL
if not exist "%HIVE%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI BOOT STORAGE REGISTRY DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/5] Loading the offline SYSTEM hive read-only for inspection...
"%REG%" unload "%HIVEKEY%" >nul 2>&1
"%REG%" load "%HIVEKEY%" "%HIVE%" >"%WORK%\step57-regload.txt" 2>&1
if errorlevel 1 goto :FAIL
set "LOADED=YES"

echo [2/5] Resolving the active offline ControlSet...
set "CURHEX="
for /f "tokens=3" %%A in ('"%REG%" query "%HIVEKEY%\Select" /v Current 2^>nul ^| "%FINDSTR%" /i "Current"') do set "CURHEX=%%A"
if not defined CURHEX goto :UNLOADFAIL
set /a CURDEC=%CURHEX% >nul 2>&1
if errorlevel 1 goto :UNLOADFAIL
set "PAD=00%CURDEC%"
set "CS=ControlSet%PAD:~-3%"
>>"%DETAILS%" echo current_controlset=%CS%

echo [3/5] Reading boot-critical storage service configuration...
for %%S in (storahci stornvme disk partmgr volmgr volmgrx fvevol mountmgr spaceport iaStorV iaStorAVC iaStorVD iaStorAC iaStorAfs) do call :SERVICE %%S

echo [4/5] Reading storage class filter configuration...
call :CLASSFILTER "{4d36e967-e325-11ce-bfc1-08002be10318}" "DiskDrive"
call :CLASSFILTER "{4d36e97b-e325-11ce-bfc1-08002be10318}" "SCSIAdapter"
call :CLASSFILTER "{71a27cdd-812a-11d0-bec7-08002be2092f}" "Volume"

echo [5/5] Recording result and unloading the temporary hive mount...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%REG%" unload "%HIVEKEY%" >"%WORK%\step57-regunload.txt" 2>&1
set "LOADED=NO"

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Offline boot/storage registry diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Active %CS% storage service Start/StartOverride values and DiskDrive/SCSIAdapter/Volume class filters were captured for review; no Windows setting was changed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the boot-start driver configuration before deciding whether to run a one-time boot-logging or Safe Mode test.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - STORAGE BOOT CONFIG SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : No reply needed unless an unexpected error appears.
echo ================================================================================
exit /b 0

:SERVICE
set "SVC=%~1"
set "BASE=%HIVEKEY%\%CS%\Services\%SVC%"
"%REG%" query "%BASE%" >nul 2>&1
if errorlevel 1 (
  >>"%DETAILS%" echo service=%SVC%;present=NO
  exit /b 0
)
set "START=UNSET"
set "GROUP=UNSET"
set "IMAGE=UNSET"
for /f "tokens=1,2,*" %%A in ('"%REG%" query "%BASE%" /v Start 2^>nul ^| "%FINDSTR%" /i /r "^ *Start " ') do set "START=%%C"
for /f "tokens=1,2,*" %%A in ('"%REG%" query "%BASE%" /v Group 2^>nul ^| "%FINDSTR%" /i /r "^ *Group " ') do set "GROUP=%%C"
for /f "tokens=1,2,*" %%A in ('"%REG%" query "%BASE%" /v ImagePath 2^>nul ^| "%FINDSTR%" /i /r "^ *ImagePath " ') do set "IMAGE=%%C"
>>"%DETAILS%" echo service=%SVC%;present=YES;start=!START!;group=!GROUP!;image=!IMAGE!
"%REG%" query "%BASE%\StartOverride" >>"%DETAILS%" 2>nul
exit /b 0

:CLASSFILTER
set "GUID=%~1"
set "LABEL=%~2"
set "KEY=%HIVEKEY%\%CS%\Control\Class\%GUID%"
>>"%DETAILS%" echo.
>>"%DETAILS%" echo class_filter=%LABEL%;guid=%GUID%
"%REG%" query "%KEY%" /v UpperFilters >>"%DETAILS%" 2>nul
"%REG%" query "%KEY%" /v LowerFilters >>"%DETAILS%" 2>nul
exit /b 0

:UNLOADFAIL
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
:FAIL
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot/storage registry diagnostic could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows configuration or personal files were changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - REGISTRY DIAGNOSTIC FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
