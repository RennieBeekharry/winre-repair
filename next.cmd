@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "COMMAND_VERSION=WR-2026.08.14-0928-ET"
set "BUILD_TIME=2026-08-14 09:28 ET"
set "CORE_VERSION=WR-2026.08.14-0918-ET"
set "CORE_COMMIT=7df588b172b552e4a237d83926aeae67beb63b48"
set "CURL=C:\Windows\System32\curl.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "COREURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=%CORE_COMMIT%"
set "LAUNCHERURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/wr.cmd?ref=main"
set "CORE=X:\next-core-0918.cmd"
set "CORETMP=X:\next-core-0918.tmp"
set "NEWLAUNCHER=C:\wr.new.cmd"
set "REPORT=C:\WinRERepair\LAST_RUN_REPORT.txt"
set "UPGRADE=X:\wr-upgrade.cmd"

cls
echo ================================================================
echo WINRE-REPAIR - STATUS PROTOCOL TRANSITION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo This run preserves the existing 0918 recovery-download logic.
echo It also installs the permanent PASS / FAIL / WARNING launcher.
echo Disk/filesystem management operations in this build: NONE
echo ================================================================

if not exist "C:\WinRERepair" md "C:\WinRERepair" >nul 2>&1
if not exist "%CURL%" (
  set "RC=91"
  goto :RESULT
)

call :RESOLVE %APIHOST% APIIP

rem Fetch immutable 0918 recovery command.
if exist "%CORETMP%" del /f /q "%CORETMP%" >nul 2>&1
if exist "%CORE%" del /f /q "%CORE%" >nul 2>&1
call :FETCHAPI "%COREURL%" "%CORETMP%"
if errorlevel 1 (
  set "RC=90"
  goto :RESULT
)
"%FINDSTR%" /i /c:"COMMAND_VERSION=WR-2026.08.14-0918-ET" "%CORETMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%CORETMP%" >nul 2>&1
  set "RC=90"
  goto :RESULT
)
move /y "%CORETMP%" "%CORE%" >nul 2>&1

rem Stage the current permanent launcher. It is not activated until this run ends.
if exist "%NEWLAUNCHER%" del /f /q "%NEWLAUNCHER%" >nul 2>&1
call :FETCHAPI "%LAUNCHERURL%" "%NEWLAUNCHER%"
set "LAUNCHERSTAGED=NO"
if not errorlevel 1 (
  "%FINDSTR%" /i /c:"WR-LAUNCHER-2026.08.14-0922-ET" "%NEWLAUNCHER%" >nul 2>&1
  if not errorlevel 1 set "LAUNCHERSTAGED=YES"
)

call "%CORE%"
set "RC=!errorlevel!"

:RESULT
set "WRSTATUS=WARNING"
set "STATUSCOLOR=0E"
set "STATUSMESSAGE=Run completed with a condition that needs review."
set "REPLYWORD=warning"
if "!RC!"=="0" (
  set "WRSTATUS=PASS"
  set "STATUSCOLOR=0A"
  set "STATUSMESSAGE=Run completed successfully."
  set "REPLYWORD=pass"
) else (
  if !RC! GEQ 80 (
    set "WRSTATUS=FAIL"
    set "STATUSCOLOR=0C"
    set "STATUSMESSAGE=Run stopped because a required step failed."
    set "REPLYWORD=fail"
  )
)

>"%REPORT%" echo status=!WRSTATUS!
>>"%REPORT%" echo return_code=!RC!
>>"%REPORT%" echo transition_version=%COMMAND_VERSION%
>>"%REPORT%" echo recovery_command=%CORE_VERSION%
>>"%REPORT%" echo launcher_upgrade=!LAUNCHERSTAGED!
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=!STATUSMESSAGE!

set "REPORTVOL="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"C:\WinRERepair\vol-report-%%D.txt" 2>&1
    "%FINDSTR%" /i /c:"REPAIRDATA" "C:\WinRERepair\vol-report-%%D.txt" >nul 2>&1
    if not errorlevel 1 set "REPORTVOL=%%D:"
  )
)
if defined REPORTVOL (
  if not exist "!REPORTVOL!\RecoverySource" md "!REPORTVOL!\RecoverySource" >nul 2>&1
  copy /y "%REPORT%" "!REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt" >nul 2>&1
)

rem Replace the persistent launcher only after the currently-running old launcher exits.
if /i "!LAUNCHERSTAGED!"=="YES" (
  >"%UPGRADE%" echo @echo off
  >>"%UPGRADE%" echo ping -n 5 127.0.0.1 ^>nul
  >>"%UPGRADE%" echo copy /y "C:\wr.new.cmd" "C:\wr.cmd" ^>nul 2^>^&1
  >>"%UPGRADE%" echo del /f /q "C:\wr.new.cmd" ^>nul 2^>^&1
  start "" /b cmd.exe /c call "%UPGRADE%" >nul 2>&1
)

color !STATUSCOLOR! >nul 2>&1
echo.
echo ================================================================
echo [!WRSTATUS!]  WINRE-REPAIR RESULT
echo ================================================================
echo !STATUSMESSAGE!
echo Return code      : !RC!
echo Recovery command : %CORE_VERSION%
echo Launcher upgrade : !LAUNCHERSTAGED!
echo Report            : %REPORT%
if defined REPORTVOL echo USB report        : !REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt
echo ---------------------------------------------------------------
echo Reply to ChatGPT with one word only: !REPLYWORD!
echo ================================================================
exit /b !RC!

:FETCHAPI
set "FETCHURL=%~1"
set "FETCHOUT=%~2"
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
) else (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 180 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
)
if errorlevel 1 exit /b 1
if not exist "%FETCHOUT%" exit /b 1
for %%Z in ("%FETCHOUT%") do if %%~zZ LSS 32 exit /b 1
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %~1 %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
