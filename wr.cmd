@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0922-ET"
set "BUILD_TIME=2026-08-14 09:22 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"
set "REPORT=C:\WinRERepair\LAST_RUN_REPORT.txt"

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" (
  set "RC=91"
  goto :RESULT
)
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if errorlevel 1 "%WPEUTIL%" InitializeNetwork >nul 2>&1

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

set "APIIP="
for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "APIIP=!CAND!"
)

if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  set "RC=90"
  goto :RESULT
)
"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  set "RC=90"
  goto :RESULT
)
move /y "%TMP%" "%OUT%" >nul
call "%OUT%"
set "RC=!errorlevel!"

:RESULT
set "RUNVERSION=UNKNOWN"
if exist "%OUT%" (
  for /f "tokens=2 delims==" %%V in ('"%FINDSTR%" /b /i /c:"set \"COMMAND_VERSION=" "%OUT%" 2^>nul') do set "RUNVERSION=%%~V"
  set "RUNVERSION=!RUNVERSION:\"=!"
  set "RUNVERSION=!RUNVERSION:"=!"
)

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

if not exist "C:\WinRERepair" md "C:\WinRERepair" >nul 2>&1
>"%REPORT%" echo status=!WRSTATUS!
>>"%REPORT%" echo return_code=!RC!
>>"%REPORT%" echo launcher_version=%LAUNCHER_VERSION%
>>"%REPORT%" echo command_version=!RUNVERSION!
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=!STATUSMESSAGE!

rem Best-effort copy of the compact report to the existing REPAIRDATA volume.
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

color !STATUSCOLOR! >nul 2>&1
echo.
echo ================================================================
echo [!WRSTATUS!]  WINRE-REPAIR RESULT
echo ================================================================
echo !STATUSMESSAGE!
echo Return code: !RC!
echo Launcher:    %LAUNCHER_VERSION%
echo Command:     !RUNVERSION!
echo Report:      %REPORT%
if defined REPORTVOL echo USB report:  !REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt
echo ---------------------------------------------------------------
echo Reply to ChatGPT with one word only: !REPLYWORD!
echo ================================================================
exit /b !RC!
