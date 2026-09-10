@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inspect active storage-filter drivers referenced by the offline registry after the HP-logo hang.
rem WR_ACTION=BOOT_STORAGE_FILTER_DIAGNOSTIC
rem WR_TARGET=Offline Windows SYSTEM hive, referenced storage filter driver files, and bounded RescueMeAI diagnostic text only.
rem WR_CONSEQUENCE=Temporarily loads the offline SYSTEM hive for read-only service queries and checks file presence/sizes for referenced storage filters. No Windows setting, BCD, EFI file, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Temporary offline-hive mount is unloaded before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=62"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "TMP=%WORK%\step62-regquery.txt"
set "REG=X:\Windows\System32\reg.exe"
if not exist "%REG%" set "REG=C:\Windows\System32\reg.exe"
set "HIVEKEY=HKLM\RMAI_OFFLINE_SYSTEM"
set "HIVE=C:\Windows\System32\config\SYSTEM"

cls
echo ================================================================================
echo RescueMeAI - STORAGE FILTER DRIVER DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Core storage drivers are present and active ControlSet001
echo                       has normal boot-start values; storage class filters remain.
echo CURRENT TASK        : Checking the referenced volume/disk filter drivers and their
echo                       service start configuration before any boot-log test.
echo SAFETY              : READ-ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%REG%" goto :FAIL
if not exist "%HIVE%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI STORAGE FILTER DRIVER DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Loading offline SYSTEM hive...
"%REG%" unload "%HIVEKEY%" >nul 2>&1
"%REG%" load "%HIVEKEY%" "%HIVE%" >nul 2>&1
if errorlevel 1 goto :FAIL
set "LOADED=YES"

echo [2/4] Resolving active ControlSet...
set "CURRENT=UNSET"
call :READVAL "%HIVEKEY%\Select" Current CURRENT
set "ACTIVE=UNKNOWN"
if /i "!CURRENT!"=="0x1" set "ACTIVE=ControlSet001"
if /i "!CURRENT!"=="0x2" set "ACTIVE=ControlSet002"
if /i "!CURRENT!"=="0x3" set "ACTIVE=ControlSet003"
>>"%DETAILS%" echo select_current=!CURRENT!
>>"%DETAILS%" echo active_controlset=!ACTIVE!
if /i "!ACTIVE!"=="UNKNOWN" goto :UNLOADFAIL

echo [3/4] Checking referenced filter-driver services and files...
for %%S in (EhStorClass volsnap fvevol iorate rdyboost partmgr) do call :SERVICE %%S

echo [4/4] Recording result and unloading temporary hive mount...
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%REG%" unload "%HIVEKEY%" >nul 2>&1
set "LOADED=NO"
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Storage filter-driver diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Referenced disk/volume filters were checked for service configuration and driver-file presence without changing Windows.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the filter stack and, if it is intact, prepare a one-time boot-logging test without rebooting until reviewed.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - FILTER STACK SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:READVAL
set "KEY=%~1"
set "VALUE=%~2"
set "OUTVAR=%~3"
set "READ=UNSET"
"%REG%" query "%KEY%" /v "%VALUE%" >"%TMP%" 2>nul
if not errorlevel 1 (
  for /f "usebackq tokens=3,*" %%A in ("%TMP%") do set "READ=%%A %%B"
)
for /f "tokens=* delims= " %%A in ("!READ!") do set "READ=%%A"
if /i "%VALUE%"=="Current" for /f "tokens=1" %%A in ("!READ!") do set "READ=%%A"
set "%OUTVAR%=!READ!"
exit /b 0

:SERVICE
set "SVC=%~1"
set "BASE=%HIVEKEY%\!ACTIVE!\Services\%SVC%"
"%REG%" query "!BASE!" >nul 2>&1
if errorlevel 1 (
  >>"%DETAILS%" echo service=%SVC%;present=NO
  exit /b 0
)
set "START=UNSET"
set "GROUP=UNSET"
set "IMAGE=UNSET"
set "OVERRIDE0=NONE"
call :READVAL "!BASE!" Start START
call :READVAL "!BASE!" Group GROUP
call :READVAL "!BASE!" ImagePath IMAGE
call :READVAL "!BASE!\StartOverride" 0 OVERRIDE0
set "DRVFILE=UNKNOWN"
set "DRVSIZE=0"
if exist "C:\Windows\System32\drivers\%SVC%.sys" (
  set "DRVFILE=YES"
  for %%Z in ("C:\Windows\System32\drivers\%SVC%.sys") do set "DRVSIZE=%%~zZ"
) else (
  set "DRVFILE=NO"
)
>>"%DETAILS%" echo service=%SVC%;present=YES;start=!START!;startoverride0=!OVERRIDE0!;group=!GROUP!;image=!IMAGE!;driver_file=!DRVFILE!;size=!DRVSIZE!
exit /b 0

:UNLOADFAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
:FAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Storage filter-driver diagnostic could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows configuration or personal files were changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - FILTER DIAGNOSTIC FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
