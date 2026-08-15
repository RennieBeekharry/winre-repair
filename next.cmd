@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI with WinRE-safe device authorization and structured diagnostics.
rem WR_ACTION=START_RESCUEMEAI_DIAGNOSTIC_AUTH_V24
rem WR_TARGET=RescueMeAI authentication and persistent agent only.
rem WR_CONSEQUENCE=Renews the private recovery-channel token if needed and starts the existing agent. No Windows repair state is changed.
rem WR_ROLLBACK=Runtime-only startup operation.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-24"
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
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
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
set "ERROR_ID=RMAI-START24-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialization"
set "LAST_SUCCESS=START-24 entered"
set "HELPER=%WORK%\start24-json.js"
set "HELPERB64=%WORK%\start24-json.b64"
set "JOUT=%WORK%\start24-jget.txt"
set "FAILFILE=%WORK%\START24_FAILURE.txt"
set "POLL_COUNT=0"
set "POLL_STATE=Waiting for GitHub approval"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=dependencies"
set "ERROR_OPERATION=validate required WinRE tools"
for %%F in ("%CURL%" "%FINDSTR%" "%CERTUTIL%" "%CSCRIPT%" "%PING%" "%AGENT%") do if not exist %%F (
  set "ERROR_ID=RMAI-START24-DEP-001"
  set "FAIL_REASON=Required startup dependency is missing: %%~nxF"
  goto :FATAL
)
for %%F in (ui.cmd network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do if not exist "%RUNTIME%\%%F" (
  set "ERROR_ID=RMAI-START24-RUNTIME-001"
  set "ERROR_COMPONENT=runtime"
  set "ERROR_OPERATION=validate staged runtime modules"
  set "FAIL_REASON=Required staged runtime module %%F is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Required WinRE tools and staged runtime validated"

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if exist "%WORK%\github-web-ip.txt" set /p "WEBIP="<"%WORK%\github-web-ip.txt"
if not defined APIIP (
  set "ERROR_ID=RMAI-START24-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached IP"
  set "FAIL_REASON=Validated api.github.com address cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START24-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached IP"
  set "FAIL_REASON=Validated github.com address cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

set "ERROR_STAGE=AUTH PARSER"
set "ERROR_COMPONENT=start24-json.js"
set "ERROR_OPERATION=build local JSON value parser"
call :BUILD_HELPER
if errorlevel 1 (
  set "ERROR_ID=RMAI-START24-PARSER-001"
  set "FAIL_REASON=Could not prepare the local GitHub response parser."
  goto :FATAL
)
set "LAST_SUCCESS=Local GitHub response parser prepared"

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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-24
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Using cached validated GitHub routes. No DNS lookup or secondary download is required."

set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=private GitHub repository"
set "ERROR_OPERATION=test saved access token"
call :TEST_TOKEN
if not errorlevel 1 goto :START_AGENT

set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub OAuth device flow"
set "ERROR_OPERATION=request and poll one-time authorization code"
call :DEVICE_FLOW
if errorlevel 1 goto :FATAL
set "LAST_SUCCESS=GitHub device authorization returned a token"

set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=private GitHub repository"
set "ERROR_OPERATION=verify newly issued access token"
call :TEST_TOKEN
if errorlevel 1 (
  set "ERROR_ID=RMAI-START24-TOKEN-002"
  set "FAIL_REASON=The new GitHub token could not access the private recovery repository."
  goto :FATAL
)

:START_AGENT
set "LAST_SUCCESS=Private GitHub token validated"
call :SCREEN "RECOVERY AGENT ONLINE" "Private command transport is ready. Starting RescueMeAI automatically."
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START24-AGENT-001"
set "FAIL_REASON=The RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:TEST_TOKEN
if not exist "%TOKEN%" exit /b 1
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS exit /b 1
set "OUT=%WORK%\start24-token-test.json"
set "HTTP=%WORK%\start24-token-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start24-token-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "ACCESS="
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
exit /b 0

:DEVICE_FLOW
set "OUT=%WORK%\start24-device.json"
set "HTTP=%WORK%\start24-device-http.txt"
set "HEAD=%WORK%\start24-device-headers.txt"
for %%F in ("%OUT%" "%HTTP%" "%HEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" -D "%HEAD%" "https://github.com/login/device/code" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start24-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "CONTENT_TYPE=UNKNOWN"
for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /b /c:"Content-Type:" "%HEAD%" 2^>nul') do set "CONTENT_TYPE=%%B"
"%FINDSTR%" /i /c:"device_code" "%OUT%" >nul 2>&1
if errorlevel 1 (set "BODY_HAS_DEVICE=NO") else set "BODY_HAS_DEVICE=YES"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START24-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device authorization request failed over HTTPS."
  exit /b 1
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START24-OAUTH-HTTP-002"
  set "FAIL_REASON=GitHub device authorization endpoint did not return HTTP 200."
  exit /b 1
)
set "LAST_SUCCESS=GitHub device endpoint returned HTTP 200"
call :JGET "%OUT%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START24-OAUTH-PARSE-001"
  set "FAIL_REASON=GitHub responded, but the local parser could not extract device_code."
  exit /b 1
)
call :JGET "%OUT%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START24-OAUTH-PARSE-002"
  set "FAIL_REASON=GitHub responded, but the local parser could not extract user_code."
  exit /b 1
)
call :JGET "%OUT%" expires_in EXPIRES
if errorlevel 1 set "EXPIRES=900"
call :JGET "%OUT%" interval INTERVAL
if errorlevel 1 set "INTERVAL=5"
set "LAST_SUCCESS=GitHub one-time device code parsed successfully"

set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
:DEVICE_POLL
set /a COUNT+=1
if !COUNT! GTR !MAX! (
  set "ERROR_ID=RMAI-START24-OAUTH-EXPIRED-001"
  set "FAIL_REASON=GitHub device authorization code expired before approval completed."
  exit /b 1
)
set "POLL_COUNT=!COUNT! / !MAX!"
call :SHOW_DEVICE_SCREEN
call :WAIT_SECONDS !INTERVAL!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START24-WAIT-001"
  set "ERROR_STAGE=DEVICE AUTHORIZATION"
  set "ERROR_COMPONENT=WinRE wait mechanism"
  set "ERROR_OPERATION=wait between GitHub approval polls"
  set "FAIL_REASON=WinRE could not perform the safe authorization polling delay."
  exit /b 1
)
set "TOK=%WORK%\start24-device-token.json"
set "TOKHTTP=%WORK%\start24-device-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" --data-urlencode "repository_id=%LOG_REPO_ID%" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start24-device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
if not "!LAST_CURL!"=="0" (
  set "POLL_STATE=Temporary HTTPS polling failure; retrying automatically"
  goto :DEVICE_POLL
)
if not "!LAST_HTTP!"=="200" (
  set "POLL_STATE=GitHub poll returned HTTP !LAST_HTTP!; retrying automatically"
  goto :DEVICE_POLL
)
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
  set "LAST_SUCCESS=GitHub approval detected and token stored"
  exit /b 0
)
call :JGET "%TOK%" error OAUTH_ERROR
if /i "!OAUTH_ERROR!"=="authorization_pending" (
  set "POLL_STATE=Waiting for approval on your phone"
  goto :DEVICE_POLL
)
if /i "!OAUTH_ERROR!"=="slow_down" (
  set /a INTERVAL+=5
  set "POLL_STATE=GitHub requested slower polling; interval increased automatically"
  goto :DEVICE_POLL
)
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "ERROR_ID=RMAI-START24-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was denied."
  exit /b 1
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "ERROR_ID=RMAI-START24-OAUTH-EXPIRED-002"
  set "FAIL_REASON=GitHub device authorization code expired."
  exit /b 1
)
set "POLL_STATE=Waiting for GitHub authorization result"
goto :DEVICE_POLL

:WAIT_SECONDS
set "WAIT_SEC=%~1"
if not defined WAIT_SEC set "WAIT_SEC=5"
set /a WAIT_SEC+=0
if !WAIT_SEC! LSS 1 set "WAIT_SEC=1"
set /a PING_COUNT=WAIT_SEC+1
"%PING%" 127.0.0.1 -n !PING_COUNT! >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:SHOW_DEVICE_SCREEN
cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Windows changes : NONE
echo Status          : WAITING FOR GITHUB APPROVAL
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
echo CURRENT STATE
echo ----------------------------------------------------------------------------------------------------
echo   !POLL_STATE!
echo   Poll attempt: !POLL_COUNT!
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI will detect approval automatically and continue.
echo   No Windows repair runs during authorization.
echo   This screen is redrawn automatically so the one-time code remains visible.
echo.
echo PLEASE LEAVE THIS WINDOW OPEN.
exit /b 0

:JGET
set "%~3="
set "PARSER_RC="
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start24-jget-error.txt"
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
>"%FAILFILE%" echo RESCUEMEAI STRUCTURED FAILURE REPORT
>>"%FAILFILE%" echo ===================================
>>"%FAILFILE%" echo error_id=%ERROR_ID%
>>"%FAILFILE%" echo version=%COMMAND_VERSION%
>>"%FAILFILE%" echo stage=%ERROR_STAGE%
>>"%FAILFILE%" echo component=%ERROR_COMPONENT%
>>"%FAILFILE%" echo operation=%ERROR_OPERATION%
>>"%FAILFILE%" echo reason=%FAIL_REASON%
>>"%FAILFILE%" echo last_success=%LAST_SUCCESS%
>>"%FAILFILE%" echo windows_changes=NONE
>>"%FAILFILE%" echo transport=HTTPS/TLS
>>"%FAILFILE%" echo api_cached_ip=%APIIP%
>>"%FAILFILE%" echo web_cached_ip=%WEBIP%
>>"%FAILFILE%" echo http=%LAST_HTTP%
>>"%FAILFILE%" echo curl_return_code=%LAST_CURL%
>>"%FAILFILE%" echo parser_return=%PARSER_RC%
>>"%FAILFILE%" echo body_has_device_code=%BODY_HAS_DEVICE%
>>"%FAILFILE%" echo content_type=%CONTENT_TYPE%
>>"%FAILFILE%" echo local_log=%FAILFILE%
>>"%FAILFILE%" echo date=%date%
>>"%FAILFILE%" echo time=%time%
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                      APPLICATION FAILURE
echo ====================================================================================================
echo Version         : %COMMAND_VERSION%
echo Transport       : HTTPS / TLS
echo Windows changes : STOPPED - NO WINDOWS REPAIR EXECUTED
echo Error ID        : %ERROR_ID%
echo ====================================================================================================
echo.
echo EXACT FAILURE LOCATION
echo ----------------------------------------------------------------------------------------------------
echo Stage           : %ERROR_STAGE%
echo Component       : %ERROR_COMPONENT%
echo Operation       : %ERROR_OPERATION%
echo Reason          : %FAIL_REASON%
echo Last success    : %LAST_SUCCESS%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status      : %LAST_HTTP%
echo curl return code : %LAST_CURL%
echo Parser return   : %PARSER_RC%
echo Body had key    : device_code=%BODY_HAS_DEVICE%
echo Content-Type    : %CONTENT_TYPE%
echo API cached IP   : %APIIP%
echo Web cached IP   : %WEBIP%
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %FAILFILE%
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo Take one photo of this entire screen and send it to ChatGPT.
echo The Error ID and exact failure location are sufficient to identify where to investigate.
echo Do NOT post any token files or authorization secrets.
echo.
echo No Windows repair action was executed by this startup failure.
echo This screen will remain until you press a key.
echo ====================================================================================================
pause
exit /b 90
