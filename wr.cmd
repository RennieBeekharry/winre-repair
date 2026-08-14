@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "LAUNCHER_VERSION=RMAI-LAUNCHER-2026.08.14-1235-ET"
set "PRODUCT=RescueMeAI"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "LEGAL_URL=https://github.com/RennieBeekharry/winre-repair/blob/main/LEGAL.md"
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
set "WORK=C:\WinRERepair"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "INTERNET_STATUS=CHECKING"
set "APIIP="

if not exist "%WORK%" md "%WORK%" >nul 2>&1

call :HEADER 0B "STARTING RESCUEMEAI" "READ ONLY"
echo.
echo [INFO] Checking the recovery environment and Internet connection...

if not exist "%CURL%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required curl.exe was not found in the recovery environment."
  goto :LAUNCHER_FAIL
)
if not exist "%FINDSTR%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required findstr.exe was not found in the recovery environment."
  goto :LAUNCHER_FAIL
)

if exist "%PING%" (
  "%PING%" -n 1 -w 1500 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

rem Preserve the recovery environment's currently proven resolver behavior.
if exist "%NSLOOKUP%" call :RESOLVE %APIHOST% APIIP
call :FETCHPUBLIC "%URL%" "%TMP%"
if errorlevel 1 (
  set "INTERNET_STATUS=NOT CONNECTED"
  set "FAIL_RC=90"
  set "FAIL_REASON=RescueMeAI could not download the current recovery workflow from GitHub."
  goto :LAUNCHER_FAIL
)

"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  set "INTERNET_STATUS=CONNECTED"
  set "FAIL_RC=96"
  set "FAIL_REASON=The downloaded RescueMeAI workflow failed basic content validation."
  goto :LAUNCHER_FAIL
)

move /y "%TMP%" "%OUT%" >nul 2>&1
if errorlevel 1 (
  set "INTERNET_STATUS=CONNECTED"
  set "FAIL_RC=97"
  set "FAIL_REASON=The validated RescueMeAI workflow could not be staged locally."
  goto :LAUNCHER_FAIL
)

set "INTERNET_STATUS=CONNECTED"
call :HEADER 0B "LOADING CURRENT RECOVERY WORKFLOW" "READ ONLY"
echo.
echo [CONNECTED] Latest RescueMeAI workflow downloaded and validated.
echo [INFO] Starting the recovery workflow now...

rem The child workflow owns all normal PASS / FAIL / WARNING result UI.
rem Avoid printing a second legacy launcher result over the workflow screen.
call "%OUT%"
set "RC=!errorlevel!"
exit /b !RC!

:LAUNCHER_FAIL
>"%REPORT%" echo product=%PRODUCT%
>>"%REPORT%" echo status=FAIL
>>"%REPORT%" echo return_code=!FAIL_RC!
>>"%REPORT%" echo launcher_version=%LAUNCHER_VERSION%
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=!FAIL_REASON!
call :HEADER 0C "LAUNCHER / UPDATE FAILURE" "NO RECOVERY ACTION"
call :CENTER "[FAIL] RESCUEMEAI COULD NOT START"
echo.
echo RESULT
echo ------------------------------------------------------------------------
echo !FAIL_REASON!
echo.
echo WHAT YOU SHOULD DO
echo   Reply to ChatGPT with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED
echo   Screenshot this screen if private reporting is not yet online.
echo.
echo Nothing destructive was attempted.
echo ========================================================================
pause >nul
exit /b !FAIL_RC!

:FETCHPUBLIC
set "FETCHURL=%~1"
set "FETCHOUT=%~2"
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
) else (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCHURL%" -o "%FETCHOUT%"
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

:HEADER
set "UI_COLOR=%~1"
set "UI_STEP=%~2"
set "UI_SAFETY=%~3"
color %UI_COLOR% >nul 2>&1
cls
echo ========================================================================
call :CENTER "RESCUEMEAI"
call :CENTER "%DESCRIPTION%"
echo ========================================================================
echo  Version      : %LAUNCHER_VERSION%
echo  Internet     : [%INTERNET_STATUS%]
echo  Current Step : %UI_STEP%
echo  Safety       : %UI_SAFETY%
echo  Legal        : %LEGAL_URL%
echo ========================================================================
exit /b 0

:CENTER
set "CENTER_TEXT=%~1"
set /a CENTER_LEN=0
:CENTER_LEN_LOOP
if not "!CENTER_TEXT:~%CENTER_LEN%,1!"=="" (
  set /a CENTER_LEN+=1
  if !CENTER_LEN! LSS 72 goto :CENTER_LEN_LOOP
)
set /a CENTER_PAD=(72-CENTER_LEN)/2
if !CENTER_PAD! LSS 0 set "CENTER_PAD=0"
set "CENTER_SPACES=                                                                        "
echo !CENTER_SPACES:~0,%CENTER_PAD%!!CENTER_TEXT!
exit /b 0
