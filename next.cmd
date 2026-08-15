@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI without secondary downloads or DNS-dependent bootstrap operations.
rem WR_ACTION=START_RESCUEMEAI_SELF_CONTAINED_AUTH_V20
rem WR_TARGET=RescueMeAI authentication and persistent command channel only.
rem WR_CONSEQUENCE=Validates or renews the GitHub App token using previously validated cached GitHub IPs, then starts the existing agent. It does not modify Windows recovery state.
rem WR_ROLLBACK=Runtime-only startup operation; no Windows recovery rollback is required.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-20"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "REFRESH=%AUTHDIR%\github-refresh.token"
set "META=%AUTHDIR%\github-token.meta"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=41b232f3abc3a123fe61627040bf936aa658b516"
set "APIIP="
set "WEBIP="
set "TLS="
set "LAST_HTTP="
set "LAST_CURL="
set "FAIL_REASON=RescueMeAI could not resume the secure recovery session."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1

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
for %%F in (resolve.cmd network.cmd ui.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "FAIL_REASON=Required staged runtime module %%F is missing."
    goto :FATAL
  )
)

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"

rem Reuse the addresses that were validated earlier in this same recovery session.
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if exist "%WORK%\github-web-ip.txt" set /p "WEBIP="<"%WORK%\github-web-ip.txt"
if not defined APIIP (
  set "FAIL_REASON=The validated api.github.com address cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "FAIL_REASON=The validated github.com address cache is missing."
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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-20
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Using the previously validated GitHub routes. No runtime download or DNS lookup is required."

call :TEST_TOKEN
if not errorlevel 1 goto :AUTH_READY

call :TRY_REFRESH
if not errorlevel 1 (
  call :TEST_TOKEN
  if not errorlevel 1 goto :AUTH_READY
)

call :DEVICE_FLOW
if errorlevel 1 goto :FATAL
call :TEST_TOKEN
if errorlevel 1 (
  set "FAIL_REASON=GitHub authorization completed, but the new token could not access the private recovery repository."
  goto :FATAL
)

:AUTH_READY
call :SCREEN "RECOVERY AGENT ONLINE" "Secure command transport is ready. Starting the persistent recovery agent automatically."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:TEST_TOKEN
if not exist "%TOKEN%" exit /b 1
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS exit /b 1
set "OUT=%WORK%\start20-token-test.json"
set "HTTP=%WORK%\start20-token-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start20-token-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "ACCESS="
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
exit /b 0

:TRY_REFRESH
if not exist "%REFRESH%" exit /b 1
set "SAVED_REFRESH="
set /p "SAVED_REFRESH="<"%REFRESH%"
if not defined SAVED_REFRESH exit /b 1
set "OUT=%WORK%\start20-refresh.txt"
set "HTTP=%WORK%\start20-refresh-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start20-refresh-curl.txt"
set "LAST_CURL=!errorlevel!"
set "SAVED_REFRESH="
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
call :FORM_GET "%OUT%" access_token NEW_ACCESS
if not defined NEW_ACCESS exit /b 1
call :FORM_GET "%OUT%" refresh_token NEW_REFRESH
call :STORE_TOKEN "!NEW_ACCESS!" "!NEW_REFRESH!" REFRESH
set "NEW_ACCESS="
set "NEW_REFRESH="
exit /b 0

:DEVICE_FLOW
set "OUT=%WORK%\start20-device.txt"
set "HTTP=%WORK%\start20-device-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start20-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" (
  set "FAIL_REASON=GitHub device authorization request failed over the cached HTTPS route."
  exit /b 1
)
if not "!LAST_HTTP!"=="200" (
  set "FAIL_REASON=GitHub device authorization endpoint did not return HTTP 200."
  exit /b 1
)
call :FORM_GET "%OUT%" device_code DEVICE_CODE
call :FORM_GET "%OUT%" user_code USER_CODE
call :FORM_GET "%OUT%" expires_in EXPIRES
call :FORM_GET "%OUT%" interval INTERVAL
if not defined DEVICE_CODE (
  set "FAIL_REASON=GitHub returned HTTP 200 but no form-encoded device_code was found."
  exit /b 1
)
if not defined USER_CODE (
  set "FAIL_REASON=GitHub returned a device code but no user_code was found."
  exit /b 1
)
if not defined EXPIRES set "EXPIRES=900"
if not defined INTERVAL set "INTERVAL=5"

cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo.
echo Secure GitHub authorization needs renewal.
echo.
echo ON YOUR PHONE
echo ----------------------------------------------------------------------------------------------------
echo   Open: https://github.com/login/device
echo   Enter this one-time code:
echo.
echo                                    !USER_CODE!
echo.
echo   Approve the RescueMeAI GitHub App.
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI will detect approval automatically and continue.
echo   No Windows repair runs during authorization.
echo.

set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
:DEVICE_POLL
set /a COUNT+=1
if !COUNT! GTR !MAX! (
  set "FAIL_REASON=GitHub device authorization code expired before approval completed."
  exit /b 1
)
timeout /t !INTERVAL! /nobreak >nul
set "TOK=%WORK%\start20-device-token.txt"
set "TOKHTTP=%WORK%\start20-device-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start20-device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
if not "!LAST_CURL!"=="0" goto :DEVICE_POLL
if not "!LAST_HTTP!"=="200" goto :DEVICE_POLL
call :FORM_GET "%TOK%" access_token NEW_ACCESS
if defined NEW_ACCESS (
  call :FORM_GET "%TOK%" refresh_token NEW_REFRESH
  call :STORE_TOKEN "!NEW_ACCESS!" "!NEW_REFRESH!" DEVICE
  set "NEW_ACCESS="
  set "NEW_REFRESH="
  exit /b 0
)
call :FORM_GET "%TOK%" error OAUTH_ERROR
if /i "!OAUTH_ERROR!"=="authorization_pending" goto :DEVICE_POLL
if /i "!OAUTH_ERROR!"=="slow_down" (
  set /a INTERVAL+=5
  goto :DEVICE_POLL
)
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "FAIL_REASON=GitHub device authorization was denied."
  exit /b 1
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "FAIL_REASON=GitHub device authorization code expired."
  exit /b 1
)
goto :DEVICE_POLL

:FORM_GET
set "%~3="
set "LINE="
if not exist "%~1" exit /b 1
set /p "LINE="<"%~1"
if not defined LINE exit /b 1
set "SCAN=!LINE:&= !"
for %%P in (!SCAN!) do (
  set "PAIR=%%~P"
  for /f "tokens=1,* delims==" %%A in ("!PAIR!") do (
    if /i "%%A"=="%~2" set "%~3=%%B"
  )
)
set "LINE="
set "SCAN="
set "PAIR="
exit /b 0

:STORE_TOKEN
set "A=%~1"
set "R=%~2"
set "SRC=%~3"
if not defined A exit /b 1
>"%TOKEN%" echo(!A!
attrib +h +s "%TOKEN%" >nul 2>&1
if defined R (
  >"%REFRESH%" echo(!R!
  attrib +h +s "%REFRESH%" >nul 2>&1
)
>"%META%" echo auth_type=github_app_user_access_token
>>"%META%" echo source=!SRC!
>>"%META%" echo app_id=%APP_ID%
>>"%META%" echo repository=%LOG_REPO%
>>"%META%" echo repository_id=%LOG_REPO_ID%
>>"%META%" echo stored_date=%date%
>>"%META%" echo stored_time=%time%
attrib +h +s "%META%" >nul 2>&1
set "A="
set "R="
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
echo STARTUP DETAIL
echo ----------------------------------------------------------------------------------------------------
echo api_cached_ip   : %APIIP%
echo web_cached_ip   : %WEBIP%
echo http            : %LAST_HTTP%
echo curl_return_code: %LAST_CURL%
echo.
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
