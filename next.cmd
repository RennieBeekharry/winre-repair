@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI with robust local JSON parsing, secure HTTPS transport, and self-healing GitHub App authorization.
rem WR_ACTION=START_RESCUEMEAI_SECURE_AUTONOMOUS_V13
rem WR_TARGET=RescueMeAI runtime and private command channel only.
rem WR_CONSEQUENCE=Updates RescueMeAI runtime modules and reconnects secure command transport. It does not modify Windows recovery state.
rem WR_ROLLBACK=Runtime-only startup update; no Windows recovery rollback is required.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-13"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=d5d3e09e2fa44d39f73121937df80267c4cda1bf"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "APP_ID=4595411"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APIIP="
set "BOOT_TLS="
set "FAIL_REASON=RescueMeAI could not resume the secure recovery session."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%CURL%" goto :FATAL
if not exist "%FINDSTR%" goto :FATAL
if not exist "%AGENT%" goto :FATAL

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "BOOT_TLS=--ssl-revoke-best-effort"

call :SCREEN "SECURE STARTUP" "Staging hardened runtime and robust authorization modules."

rem Bootstrap using the last validated resolver/cache. HTTPS certificate validation remains enabled.
if exist "%RUNTIME%\resolve.cmd" call "%RUNTIME%\resolve.cmd" resolve api.github.com APIIP
if not defined APIIP if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if not defined APIIP (
  set "FAIL_REASON=No validated api.github.com route is available."
  goto :FATAL
)

call :FETCH_MODULE "lib/resolve.cmd" "%RUNTIME%\resolve.cmd"
if errorlevel 1 goto :STAGE_FAIL
call :FETCH_MODULE "lib/network.cmd" "%RUNTIME%\network.cmd"
if errorlevel 1 goto :STAGE_FAIL
call :FETCH_MODULE "lib/github-auth-v3.cmd" "%RUNTIME%\github-auth.cmd"
if errorlevel 1 goto :STAGE_FAIL
call :FETCH_MODULE "lib/json-value-v1.js" "%RUNTIME%\json-value-v1.js"
if errorlevel 1 goto :STAGE_FAIL
for %%F in (ui.cmd reporting.cmd safety.cmd agent-core.js) do (
  call :FETCH_MODULE "lib/%%F" "%RUNTIME%\%%F"
  if errorlevel 1 goto :STAGE_FAIL
)

"%FINDSTR%" /i /c:"WR-MODULE: github-auth-v3 2026.08.15-CSCRIPT-JSON-TLS" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=Robust authorization module failed marker validation."
  goto :FATAL
)

>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-13
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js json-value-v1.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%SOURCE_REF%

call :SCREEN "SECURE AUTHORIZATION" "Validating the saved GitHub authorization or renewing it if necessary."
call "%RUNTIME%\github-auth.cmd" authorize
if errorlevel 1 (
  set "FAIL_REASON=Secure GitHub authorization could not be established."
  goto :FATAL
)

call :SCREEN "RECOVERY AGENT ONLINE" "Secure command transport is ready. Starting the persistent recovery agent automatically."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:STAGE_FAIL
set "FAIL_REASON=Could not stage one of the START-13 runtime modules over validated HTTPS."
goto :FATAL

:FETCH_MODULE
set "FM_PATH=%~1"
set "FM_OUT=%~2"
set "FM_TMP=%FM_OUT%.tmp"
if exist "%FM_TMP%" del /f /q "%FM_TMP%" >nul 2>&1
"%CURL%" %BOOT_TLS% --fail --location --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "https://api.github.com/repos/%SOURCE_REPO%/contents/%FM_PATH%?ref=%SOURCE_REF%" -o "%FM_TMP%"
if errorlevel 1 exit /b 1
move /y "%FM_TMP%" "%FM_OUT%" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:SCREEN
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Status          : %~1
echo Windows changes : NONE
echo ====================================================================================================
echo.
echo %~2
echo.
echo PLEASE WAIT - no action is required unless RescueMeAI displays LOCAL ACTION REQUIRED.
exit /b 0

:FATAL
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                      APPLICATION FAILURE
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Windows changes : STOPPED
echo ====================================================================================================
echo.
echo %FAIL_REASON%
echo.
if exist "%WORK%\GITHUB_RESULT.txt" (
  echo LOCAL GITHUB DETAIL
  echo ----------------------------------------------------------------------------------------------------
  type "%WORK%\GITHUB_RESULT.txt"
)
echo.
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
