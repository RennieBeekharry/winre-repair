@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI with self-contained JSON OAuth parsing over cached validated GitHub routes.
rem WR_ACTION=START_RESCUEMEAI_SELF_CONTAINED_JSON_AUTH_V21
rem WR_TARGET=RescueMeAI authentication and persistent command channel only.
rem WR_CONSEQUENCE=Validates or renews the GitHub App token and starts the existing agent. It does not modify Windows recovery state.
rem WR_ROLLBACK=Runtime-only startup operation; no Windows recovery rollback is required.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-21"
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
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "JSONHELPER=%WORK%\start21-json-value.js"
set "JSONB64=%WORK%\start21-json-value.b64"
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

for %%F in ("%CURL%" "%FINDSTR%" "%CERTUTIL%" "%CSCRIPT%" "%AGENT%") do (
  if not exist %%F (
    set "FAIL_REASON=Required RescueMeAI startup dependency is missing: %%~nxF"
    goto :FATAL
  )
)
for %%F in (resolve.cmd network.cmd ui.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "FAIL_REASON=Required staged runtime module %%F is missing."
    goto :FATAL
  )
)

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"

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

call :BUILD_JSON_HELPER
if errorlevel 1 (
  set "FAIL_REASON=Could not prepare the local GitHub response parser."
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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-21
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Using cached validated GitHub routes and explicit JSON responses. No DNS lookup or secondary download is required."

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
set "OUT=%WORK%\start21-token-test.json"
set "HTTP=%WORK%\start21-token-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start21-token-test-curl.txt"
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
set "OUT=%WORK%\start21-refresh.json"
set "HTTP=%WORK%\start21-refresh-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start21-refresh-curl.txt"
set "LAST_CURL=!errorlevel!"
set "SAVED_REFRESH="
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
call :JGET "%OUT%" access_token NEW_ACCESS
if not defined NEW_ACCESS exit /b 1
call :JGET "%OUT%" refresh_token NEW_REFRESH
call :STORE_TOKEN "!NEW_ACCESS!" "!NEW_REFRESH!" REFRESH
set "NEW_ACCESS="
set "NEW_REFRESH="
exit /b 0

:DEVICE_FLOW
set "OUT=%WORK%\start21-device.json"
set "HTTP=%WORK%\start21-device-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start21-device-curl.txt"
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
call :JGET "%OUT%" device_code DEVICE_CODE
call :JGET "%OUT%" user_code USER_CODE
call :JGET "%OUT%" expires_in EXPIRES
call :JGET "%OUT%" interval INTERVAL
if not defined DEVICE_CODE (
  set "FAIL_REASON=GitHub returned HTTP 200 but the JSON device_code could not be extracted."
  exit /b 1
)
if not defined USER_CODE (
  set "FAIL_REASON=GitHub returned a device code but the JSON user_code could not be extracted."
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
set "TOK=%WORK%\start21-device-token.json"
set "TOKHTTP=%WORK%\start21-device-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" --data-urlencode "repository_id=%LOG_REPO_ID%" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start21-device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
if not "!LAST_CURL!"=="0" goto :DEVICE_POLL
if not "!LAST_HTTP!"=="200" goto :DEVICE_POLL
call :JGET "%TOK%" access_token NEW_ACCESS
if defined NEW_ACCESS (
  call :JGET "%TOK%" refresh_token NEW_REFRESH
  call :STORE_TOKEN "!NEW_ACCESS!" "!NEW_REFRESH!" DEVICE
  set "NEW_ACCESS="
  set "NEW_REFRESH="
  exit /b 0
)
call :JGET "%TOK%" error OAUTH_ERROR
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
if defined OAUTH_ERROR (
  set "FAIL_REASON=GitHub device authorization returned OAuth error !OAUTH_ERROR!."
  exit /b 1
)
goto :DEVICE_POLL

:JGET
set "%~3="
for /f "delims=" %%V in ('"%CSCRIPT%" //nologo "%JSONHELPER%" "%~1" "%~2" 2^>nul') do set "%~3=%%V"
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

:BUILD_JSON_HELPER
if exist "%JSONB64%" del /f /q "%JSONB64%" >nul 2>&1
if exist "%JSONHELPER%" del /f /q "%JSONHELPER%" >nul 2>&1
>"%JSONB64%" echo KGZ1bmN0aW9uICgpIHsKICBpZiAoV1NjcmlwdC5Bcmd1bWVudHMubGVuZ3RoIDwgMikgV1Njcmlw
>>"%JSONB64%" echo dC5RdWl0KDY0KTsKICB2YXIgcGF0aCA9IFdTY3JpcHQuQXJndW1lbnRzLkl0ZW0oMCk7CiAgdmFy
>>"%JSONB64%" echo IGtleSA9IFdTY3JpcHQuQXJndW1lbnRzLkl0ZW0oMSk7CiAgdHJ5IHsKICAgIHZhciBmc28gPSBu
>>"%JSONB64%" echo ZXcgQWN0aXZlWE9iamVjdCgiU2NyaXB0aW5nLkZpbGVTeXN0ZW1PYmplY3QiKTsKICAgIGlmICgh
>>"%JSONB64%" echo ZnNvLkZpbGVFeGlzdHMocGF0aCkpIFdTY3JpcHQuUXVpdCgyKTsKICAgIHZhciB0cyA9IGZzby5P
>>"%JSONB64%" echo cGVuVGV4dEZpbGUocGF0aCwgMSwgZmFsc2UsIC0yKTsKICAgIHZhciB0ZXh0ID0gdHMuUmVhZEFs
>>"%JSONB64%" echo bCgpOwogICAgdHMuQ2xvc2UoKTsKICAgIGZ1bmN0aW9uIGVzYyhzKSB7CiAgICAgIHJldHVybiBz
>>"%JSONB64%" echo LnJlcGxhY2UoLyhbXFwuXiQqKz8oKVxbXF17fXxdKS9nLCAiXFwkMSIpOwogICAgfQogICAgdmFy
>>"%JSONB64%" echo IHJlID0gbmV3IFJlZ0V4cCgnIicgKyBlc2Moa2V5KSArICciXFxzKjpcXHMqKD86IigoPzpcXFxc
>>"%JSONB64%" echo LnxbXiJcXFxcXSkqKSJ8KC0/XFxkKyg/OlxcLlxcZCspPyl8KHRydWV8ZmFsc2V8bnVsbCkpJywg
>>"%JSONB64%" echo J2knKTsKICAgIHZhciBtID0gcmUuZXhlYyh0ZXh0KTsKICAgIGlmICghbSkgV1NjcmlwdC5RdWl0
>>"%JSONB64%" echo KDMpOwogICAgdmFyIHY7CiAgICBpZiAodHlwZW9mIG1bMV0gIT09ICJ1bmRlZmluZWQiICYmIG1b
>>"%JSONB64%" echo MV0gIT09IHVuZGVmaW5lZCkgewogICAgICB2ID0gbVsxXS5yZXBsYWNlKC9cXCIvZywgJyInKS5y
>>"%JSONB64%" echo ZXBsYWNlKC9cXFxcL2csICJcXCIpLnJlcGxhY2UoL1xcXC8vZywgIi8iKTsKICAgIH0gZWxzZSBp
>>"%JSONB64%" echo ZiAodHlwZW9mIG1bMl0gIT09ICJ1bmRlZmluZWQiICYmIG1bMl0gIT09IHVuZGVmaW5lZCkgewog
>>"%JSONB64%" echo ICAgICB2ID0gbVsyXTsKICAgIH0gZWxzZSB7CiAgICAgIHYgPSBtWzNdOwogICAgfQogICAgaWYg
>>"%JSONB64%" echo KFN0cmluZyh2KS50b0xvd2VyQ2FzZSgpID09PSAibnVsbCIpIFdTY3JpcHQuUXVpdCgzKTsKICAg
>>"%JSONB64%" echo IFdTY3JpcHQuRWNobyhTdHJpbmcodikpOwogICAgV1NjcmlwdC5RdWl0KDApOwogIH0gY2F0Y2gg
>>"%JSONB64%" echo KGUpIHsKICAgIFdTY3JpcHQuUXVpdCg0KTsKICB9Cn0pKCk7
"%CERTUTIL%" -f -decode "%JSONB64%" "%JSONHELPER%" >nul 2>&1
if errorlevel 1 exit /b 1
del /f /q "%JSONB64%" >nul 2>&1
"%FINDSTR%" /i /c:"WScript.Arguments.length" "%JSONHELPER%" >nul 2>&1
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
echo STARTUP DETAIL
echo ----------------------------------------------------------------------------------------------------
echo api_cached_ip    : %APIIP%
echo web_cached_ip    : %WEBIP%
echo http             : %LAST_HTTP%
echo curl_return_code : %LAST_CURL%
echo.
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
