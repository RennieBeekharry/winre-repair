@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Capture active boot-storage registry values using direct REG query output files to avoid WinRE command-parser limitations.
rem WR_ACTION=FILE_PARSED_BOOT_STORAGE_REGISTRY_SUMMARY
rem WR_TARGET=Offline Windows SYSTEM hive read-only plus bounded RescueMeAI diagnostic text.
rem WR_CONSEQUENCE=Temporarily loads the offline SYSTEM hive, reads a compact set of boot-storage values through temporary text files, then unloads it. No Windows setting, BCD, EFI file, package, partition, reboot, or personal file is changed.
rem WR_ROLLBACK=Temporary offline-hive mount is unloaded before exit.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=61"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "TMP=%WORK%\step61-regquery.txt"
set "REG=X:\Windows\System32\reg.exe"
if not exist "%REG%" set "REG=C:\Windows\System32\reg.exe"
set "HIVEKEY=HKLM\RMAI_OFFLINE_SYSTEM"
set "HIVE=C:\Windows\System32\config\SYSTEM"

cls
echo ================================================================================
echo RescueMeAI - BOOT STORAGE REGISTRY SUMMARY
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT TASK        : Reading active boot-storage registry values using a
echo                       WinRE-compatible file-parsing method.
echo SAFETY              : READ-ONLY
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%REG%" goto :FAIL
if not exist "%HIVE%" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI BOOT STORAGE REGISTRY SUMMARY
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Loading offline SYSTEM hive...
"%REG%" unload "%HIVEKEY%" >nul 2>&1
"%REG%" load "%HIVEKEY%" "%HIVE%" >nul 2>&1
if errorlevel 1 goto :FAIL
set "LOADED=YES"

echo [2/4] Resolving active ControlSet...
set "CURRENT=UNSET"
set "DEFAULT=UNSET"
set "FAILED=UNSET"
set "LASTGOOD=UNSET"
call :READVAL "%HIVEKEY%\Select" Current CURRENT
call :READVAL "%HIVEKEY%\Select" Default DEFAULT
call :READVAL "%HIVEKEY%\Select" Failed FAILED
call :READVAL "%HIVEKEY%\Select" LastKnownGood LASTGOOD
set "ACTIVE=UNKNOWN"
if /i "!CURRENT!"=="0x1" set "ACTIVE=ControlSet001"
if /i "!CURRENT!"=="0x2" set "ACTIVE=ControlSet002"
if /i "!CURRENT!"=="0x3" set "ACTIVE=ControlSet003"
>>"%DETAILS%" echo select_current=!CURRENT!
>>"%DETAILS%" echo select_default=!DEFAULT!
>>"%DETAILS%" echo select_failed=!FAILED!
>>"%DETAILS%" echo select_last_known_good=!LASTGOOD!
>>"%DETAILS%" echo active_controlset=!ACTIVE!
if /i "!ACTIVE!"=="UNKNOWN" goto :UNLOADFAIL

echo [3/4] Reading active boot-storage services and class filters...
for %%S in (storahci stornvme disk partmgr volmgr volmgrx fvevol mountmgr spaceport iaStorV iaStorAVC iaStorVD iaStorAC iaStorAfs) do call :SERVICE %%S
call :FILTER "{4d36e967-e325-11ce-bfc1-08002be10318}" "DiskDrive"
call :FILTER "{4d36e97b-e325-11ce-bfc1-08002be10318}" "SCSIAdapter"
call :FILTER "{71a27cdd-812a-11d0-bec7-08002be2092f}" "Volume"

echo [4/4] Unloading temporary hive mount and recording result...
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%REG%" unload "%HIVEKEY%" >nul 2>&1
set "LOADED=NO"
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Active boot/storage registry summary completed successfully.
>>"%RESULT%" echo EVIDENCE=Active !ACTIVE! storage Start/StartOverride and class-filter values were captured for review without changing Windows.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will use the storage boot configuration to choose the next bounded boot diagnostic.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - STORAGE CONFIG SENT FOR REVIEW
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
for /f "tokens=1" %%A in ("!READ!") do if /i "%VALUE%"=="Current" set "READ=%%A"
for /f "tokens=1" %%A in ("!READ!") do if /i "%VALUE%"=="Default" set "READ=%%A"
for /f "tokens=1" %%A in ("!READ!") do if /i "%VALUE%"=="Failed" set "READ=%%A"
for /f "tokens=1" %%A in ("!READ!") do if /i "%VALUE%"=="LastKnownGood" set "READ=%%A"
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
set "OVERRIDE0=NONE"
set "GROUP=UNSET"
call :READVAL "!BASE!" Start START
call :READVAL "!BASE!\StartOverride" 0 OVERRIDE0
call :READVAL "!BASE!" Group GROUP
>>"%DETAILS%" echo service=%SVC%;present=YES;start=!START!;startoverride0=!OVERRIDE0!;group=!GROUP!
exit /b 0

:FILTER
set "GUID=%~1"
set "LABEL=%~2"
set "KEY=%HIVEKEY%\!ACTIVE!\Control\Class\%GUID%"
set "UPPER=NONE"
set "LOWER=NONE"
call :READVAL "!KEY!" UpperFilters UPPER
call :READVAL "!KEY!" LowerFilters LOWER
>>"%DETAILS%" echo class=%LABEL%;upper=!UPPER!;lower=!LOWER!
exit /b 0

:UNLOADFAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
:FAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if /i "%LOADED%"=="YES" "%REG%" unload "%HIVEKEY%" >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot/storage registry summary could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows configuration or personal files were changed; no reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - STORAGE SUMMARY FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
