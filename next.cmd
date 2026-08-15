@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI with minimal cached-route GitHub device authorization.
rem WR_ACTION=START_RESCUEMEAI_MINIMAL_DEVICE_AUTH_V23
rem WR_TARGET=RescueMeAI authentication and persistent agent only.
rem WR_CONSEQUENCE=Renews the private recovery-channel token if needed and starts the existing agent. No Windows repair state is changed.
rem WR_ROLLBACK=Runtime-only startup operation.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-23"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "REFRESH=%AUTHDIR%\github-refresh.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
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
set "PARSER_RC="
set "BODY_HAS_DEVICE=UNKNOWN"
set "CONTENT_TYPE=UNKNOWN"
set "FAIL_REASON=RescueMeAI could not establish the private recovery channel."
set "HELPER=%WORK%\start23-json.js"
set "HELPERB64=%WORK%\start23-json.b64"
set "JOUT=%WORK%\start23-jget.txt"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1

for %%F in ("%CURL%" "%FINDSTR%" "%CERTUTIL%" "%CSCRIPT%" "%AGENT%") do if not exist %%F (
  set "FAIL_REASON=Required startup dependency is missing: %%~nxF"
  goto :FATAL
)
for %%F in (ui.cmd network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do if not exist "%RUNTIME%\%%F" (
  set "FAIL_REASON=Required staged runtime module %%F is missing."
  goto :FATAL
)

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if exist "%WORK%\github-web-ip.txt" set /p "WEBIP="<"%WORK%\github-web-ip.txt"
if not defined APIIP (
  set "FAIL_REASON=Validated api.github.com address cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "FAIL_REASON=Validated github.com address cache is missing."
  goto :FATAL
)

call :BUILD_HELPER
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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-23
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Using cached validated GitHub routes. No DNS lookup or secondary download is required."

call :TEST_TOKEN
if not errorlevel 1 goto :START_AGENT
call :DEVICE_FLOW
if errorlevel 1 goto :FATAL
call :TEST_TOKEN
if errorlevel 1 (
  set "FAIL_REASON=The new GitHub token could not access the private recovery repository."
  goto :FATAL
)

:START_AGENT
call :SCREEN "RECOVERY AGENT ONLINE" "Private command transport is ready. Starting RescueMeAI automatically."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "FAIL_REASON=The RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:TEST_TOKEN
if not exist "%TOKEN%" exit /b 1
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS exit /b 1
set "OUT=%WORK%\start23-token-test.json"
set "HTTP=%WORK%\start23-token-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start23-token-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "ACCESS="
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
exit /b 0

:DEVICE_FLOW
set "OUT=%WORK%\start23-device.json"
set "HTTP=%WORK%\start23-device-http.txt"
set "HEAD=%WORK%\start23-device-headers.txt"
for %%F in ("%OUT%" "%HTTP%" "%HEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" -D "%HEAD%" "https://github.com/login/device/code" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start23-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "CONTENT_TYPE=UNKNOWN"
for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /b /c:"Content-Type:" "%HEAD%" 2^>nul') do set "CONTENT_TYPE=%%B"
"%FINDSTR%" /i /c:"device_code" "%OUT%" >nul 2>&1
if errorlevel 1 (set "BODY_HAS_DEVICE=NO") else set "BODY_HAS_DEVICE=YES"
if not "!LAST_CURL!"=="0" (
  set "FAIL_REASON=GitHub device authorization request failed over HTTPS."
  exit /b 1
)
if not "!LAST_HTTP!"=="200" (
  set "FAIL_REASON=GitHub device authorization endpoint did not return HTTP 200."
  exit /b 1
)
call :JGET "%OUT%" device_code DEVICE_CODE
if errorlevel 1 (
  set "FAIL_REASON=GitHub responded, but the local parser could not extract device_code."
  exit /b 1
)
call :JGET "%OUT%" user_code USER_CODE
if errorlevel 1 (
  set "FAIL_REASON=GitHub responded, but the local parser could not extract user_code."
  exit /b 1
)
call :JGET "%OUT%" expires_in EXPIRES
if errorlevel 1 set "EXPIRES=900"
call :JGET "%OUT%" interval INTERVAL
if errorlevel 1 set "INTERVAL=5"

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
set "TOK=%WORK%\start23-device-token.json"
set "TOKHTTP=%WORK%\start23-device-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" --data-urlencode "repository_id=%LOG_REPO_ID%" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start23-device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
if not "!LAST_CURL!"=="0" goto :DEVICE_POLL
if not "!LAST_HTTP!"=="200" goto :DEVICE_POLL
call :JGET "%TOK%" access_token NEW_ACCESS
if not errorlevel 1 if defined NEW_ACCESS (
  call :JGET "%TOK%" refresh_token NEW_REFRESH
  >"%TOKEN%" echo(!NEW_ACCESS!
  attrib +h +s "%TOKEN%" >nul 2>&1
  if defined NEW_REFRESH (
    >"%REFRESH%" echo(!NEW_REFRESH!
    attrib +h +s "%REFRESH%" >nul 2>&1
  )
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
goto :DEVICE_POLL

:JGET
set "%~3="
set "PARSER_RC="
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start23-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
set "JV="
exit /b 0

:BUILD_HELPER
if exist "%HELPERB64%" del /f /q "%HELPERB64%" >nul 2>&1
if exist "%HELPER%" del /f /q "%HELPER%" >nul 2>&1
>"%HELPERB64%" echo KGZ1bmN0aW9uICgpIHsKICBpZiAoV1NjcmlwdC5Bcmd1bWVudHMubGVuZ3RoIDwgMikgV1Njcmlw
>>"%HELPERB64%" echo dC5RdWl0KDY0KTsKICB2YXIgcGF0aCA9IFdTY3JpcHQuQXJndW1lbnRzLkl0ZW0oMCk7CiAgdmFy
>>"%HELPERB64%" echo IGtleSA9IFdTY3JpcHQuQXJndW1lbnRzLkl0ZW0oMSk7CiAgdHJ5IHsKICAgIHZhciBmc28gPSBu
>>"%HELPERB64%" echo ZXcgQWN0aXZlWE9iamVjdCgiU2NyaXB0aW5nLkZpbGVTeXN0ZW1PYmplY3QiKTsKICAgIGlmICgh
>>"%HELPERB64%" echo ZnNvLkZpbGVFeGlzdHMocGF0aCkpIFdTY3JpcHQuUXVpdCgyKTsKICAgIHZhciB0cyA9IGZzby5P
>>"%HELPERB64%" echo cGVuVGV4dEZpbGUocGF0aCwgMSwgZmFsc2UsIC0yKTsKICAgIHZhciB0ZXh0ID0gdHMuUmVhZEFs
>>"%HELPERB64%" echo bCgpOwogICAgdHMuQ2xvc2UoKTsKICAgIHZhciBzYWZlID0ga2V5LnJlcGxhY2UoLyhbXFwuXiQq
>>"%HELPERB64%" echo Kz8oKVxbXF17fXxdKS9nLCAiXFwkMSIpOwogICAgdmFyIHJzID0gbmV3IFJlZ0V4cCgnIicgKyBz
>>"%HELPERB64%" echo YWZlICsgJyJcXHMqOlxccyoiKFteIl0qKSInLCAnaScpOwogICAgdmFyIHJuID0gbmV3IFJlZ0V4
>>"%HELPERB64%" echo cCgnIicgKyBzYWZlICsgJyJcXHMqOlxccyooLT9cXGQrKD86XFwuXFxkKyk/KScsICdpJyk7CiAg
>>"%HELPERB64%" echo ICB2YXIgbSA9IHJzLmV4ZWModGV4dCk7CiAgICBpZiAobSkgeyBXU2NyaXB0LkVjaG8obVsxXSk7
>>"%HELPERB64%" echo IFdTY3JpcHQuUXVpdCgwKTsgfQogICAgbSA9IHJuLmV4ZWModGV4dCk7CiAgICBpZiAobSkgeyBX
>>"%HELPERB64%" echo U2NyaXB0LkVjaG8obVsxXSk7IFdTY3JpcHQuUXVpdCgwKTsgfQogICAgV1NjcmlwdC5RdWl0KDMp
>>"%HELPERB64%" echo OwogIH0gY2F0Y2ggKGUpIHsKICAgIFdTY3JpcHQuUXVpdCg0KTsKICB9Cn0pKCk7
"%CERTUTIL%" -f -decode "%HELPERB64%" "%HELPER%" >nul 2>&1
if errorlevel 1 exit /b 1
del /f /q "%HELPERB64%" >nul 2>&1
"%FINDSTR%" /i /c:"Scripting.FileSystemObject" "%HELPER%" >nul 2>&1
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
echo parser_return    : %PARSER_RC%
echo body_has_device  : %BODY_HAS_DEVICE%
echo content_type     : %CONTENT_TYPE%
echo.
echo No Windows repair action was executed by this startup failure.
echo A screenshot is required only because the private channel is unavailable.
echo.
pause
exit /b 90
