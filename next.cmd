@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI by fetching only the v4 authorization module from the same api.github.com path already proven by C:\wr.cmd.
rem WR_ACTION=START_RESCUEMEAI_API_BOOTSTRAP_V19
rem WR_TARGET=RescueMeAI runtime/authentication only.
rem WR_CONSEQUENCE=Updates only the local authorization module and reconnects the private command channel. It does not modify Windows recovery state.
rem WR_ROLLBACK=Runtime-only startup update; no Windows recovery rollback is required.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-19"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=3e4cb97607632259457839e63aea72400a0567fc"
set "AUTH_URL=https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth-v4.cmd?ref=%SOURCE_REF%"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "APP_ID=4595411"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "BOOT_TLS="
set "FAIL_REASON=RescueMeAI could not resume the secure recovery session."
set "FETCH_HTTP="
set "FETCH_RC="

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1
if exist "%WORK%\START19_FETCH_RESULT.txt" del /f /q /a "%WORK%\START19_FETCH_RESULT.txt" >nul 2>&1
if not exist "%CURL%" (
  set "FAIL_REASON=Required curl.exe is missing."
  goto :FATAL
)
if not exist "%FINDSTR%" (
  set "FAIL_REASON=Required findstr.exe is missing."
  goto :FATAL
)
if not exist "%AGENT%" (
  set "FAIL_REASON=The persistent RescueMeAI agent is missing."
  goto :FATAL
)

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "BOOT_TLS=--ssl-revoke-best-effort"

call :SCREEN "SECURE STARTUP" "Reusing the staged runtime and updating only authorization through api.github.com."

for %%F in (resolve.cmd network.cmd ui.cmd reporting.cmd safety.cmd agent-core.js) do (
  if not exist "%RUNTIME%\%%F" (
    set "FAIL_REASON=Required staged runtime module %%F is missing."
    goto :FATAL
  )
)

rem Always replace the old v3 authorization module with v4.
call :FETCH_AUTH_API
if errorlevel 1 (
  set "FAIL_REASON=Could not stage github-auth-v4.cmd from api.github.com after automatic retries."
  goto :FATAL
)

"%FINDSTR%" /i /c:"WR-MODULE: github-auth-v4 2026.08.15-FORM-OAUTH-TLS" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=The downloaded START-19 authorization module failed marker validation."
  goto :FATAL
)

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

>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-19
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Validating the saved GitHub authorization or renewing it with device flow."
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

:FETCH_AUTH_API
set "OUT=%RUNTIME%\github-auth.cmd"
set "TMP=%RUNTIME%\github-auth.cmd.tmp"
set "HTTP=%WORK%\START19_FETCH_HTTP.txt"
set /a TRY=0
:FETCH_AUTH_RETRY
set /a TRY+=1
if exist "%TMP%" del /f /q /a "%TMP%" >nul 2>&1
if exist "%HTTP%" del /f /q /a "%HTTP%" >nul 2>&1
"%CURL%" %BOOT_TLS% --location --silent --show-error --connect-timeout 15 --max-time 120 --retry 2 --retry-delay 2 --retry-all-errors -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" -o "%TMP%" -w "%%{http_code}" "%AUTH_URL%" >"%HTTP%" 2>"%WORK%\START19_FETCH_CURL.txt"
set "FETCH_RC=!errorlevel!"
set "FETCH_HTTP="
if exist "%HTTP%" set /p "FETCH_HTTP="<"%HTTP%"
if "!FETCH_RC!"=="0" if "!FETCH_HTTP!"=="200" if exist "%TMP%" (
  "%FINDSTR%" /i /c:"WR-MODULE: github-auth-v4 2026.08.15-FORM-OAUTH-TLS" "%TMP%" >nul 2>&1
  if not errorlevel 1 (
    move /y "%TMP%" "%OUT%" >nul 2>&1
    if not errorlevel 1 exit /b 0
  )
)
if !TRY! LSS 3 (
  timeout /t 3 /nobreak >nul
  goto :FETCH_AUTH_RETRY
)
>"%WORK%\START19_FETCH_RESULT.txt" echo status=FAIL
>>"%WORK%\START19_FETCH_RESULT.txt" echo url_host=api.github.com
>>"%WORK%\START19_FETCH_RESULT.txt" echo http=!FETCH_HTTP!
>>"%WORK%\START19_FETCH_RESULT.txt" echo curl_return_code=!FETCH_RC!
exit /b 1

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
if exist "%WORK%\START19_FETCH_RESULT.txt" (
  echo STARTUP DOWNLOAD DETAIL
  echo ----------------------------------------------------------------------------------------------------
  type "%WORK%\START19_FETCH_RESULT.txt"
  echo.
)
if exist "%WORK%\GITHUB_RESULT.txt" (
  echo LOCAL GITHUB DETAIL
  echo ----------------------------------------------------------------------------------------------------
  type "%WORK%\GITHUB_RESULT.txt"
  echo.
)
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
