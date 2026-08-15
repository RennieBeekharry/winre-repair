@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume RescueMeAI using the already-proven local OAuth parser with self-test and structured diagnostics.
rem WR_ACTION=START_RESCUEMEAI_PROVEN_PARSER_V25
rem WR_TARGET=RescueMeAI authentication and persistent agent only.
rem WR_CONSEQUENCE=Validates or renews the private recovery-channel token and starts the existing agent. No Windows recovery state is changed.
rem WR_ROLLBACK=Runtime-only startup operation.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-25"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "REFRESH=%AUTHDIR%\github-refresh.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
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
set "HELPER=%WORK%\start23-json.js"
set "JOUT=%WORK%\start25-jget.txt"
set "SELFTEST=%WORK%\start25-parser-selftest.json"
set "FAILFILE=%WORK%\START25_FAILURE.txt"
set "APIIP="
set "WEBIP="
set "TLS="
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "PARSER_RC=NOT_RUN"
set "PARSER_SELFTEST=NOT_RUN"
set "BODY_HAS_DEVICE=UNKNOWN"
set "CONTENT_TYPE=UNKNOWN"
set "POLL_COUNT=0"
set "POLL_STATE=Waiting for GitHub approval"
set "ERROR_ID=RMAI-START25-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialization"
set "FAIL_REASON=RescueMeAI could not establish the private recovery channel."
set "LAST_SUCCESS=START-25 entered"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1

set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=dependencies"
set "ERROR_OPERATION=validate required WinRE tools and staged runtime"
for %%F in ("%CURL%" "%FINDSTR%" "%CSCRIPT%" "%PING%" "%AGENT%") do if not exist %%F (
  set "ERROR_ID=RMAI-START25-DEP-001"
  set "FAIL_REASON=Required startup dependency is missing: %%~nxF"
  goto :FATAL
)
for %%F in (ui.cmd network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js github-auth.cmd) do if not exist "%RUNTIME%\%%F" (
  set "ERROR_ID=RMAI-START25-RUNTIME-001"
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
  set "ERROR_ID=RMAI-START25-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached IP"
  set "FAIL_REASON=Validated api.github.com address cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START25-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached IP"
  set "FAIL_REASON=Validated github.com address cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

set "ERROR_STAGE=AUTH PARSER SELF-TEST"
set "ERROR_COMPONENT=%HELPER%"
set "ERROR_OPERATION=validate proven START-23 JSON parser using synthetic local JSON"
if not exist "%HELPER%" (
  set "ERROR_ID=RMAI-START25-PARSER-001"
  set "FAIL_REASON=The proven START-23 parser is not present locally."
  goto :FATAL
)
>"%SELFTEST%" echo {"device_code":"SELFTEST_OK","expires_in":900}
call :JGET "%SELFTEST%" device_code SELFTEST_VALUE
if errorlevel 1 (
  set "PARSER_SELFTEST=FAIL"
  set "ERROR_ID=RMAI-START25-PARSER-002"
  set "FAIL_REASON=The proven local parser failed its synthetic JSON self-test."
  goto :FATAL
)
if /i not "!SELFTEST_VALUE!"=="SELFTEST_OK" (
  set "PARSER_SELFTEST=WRONG_VALUE"
  set "ERROR_ID=RMAI-START25-PARSER-003"
  set "FAIL_REASON=The local parser returned the wrong value during self-test."
  goto :FATAL
)
set "PARSER_SELFTEST=PASS"
set "LAST_SUCCESS=Local JSON parser self-test passed"

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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-25
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "SECURE AUTHORIZATION" "Local parser self-test passed. Validating the private GitHub authorization."
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
  set "ERROR_ID=RMAI-START25-TOKEN-002"
  set "FAIL_REASON=The newly issued GitHub token could not access the private recovery repository."
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
set "ERROR_ID=RMAI-START25-AGENT-001"
set "FAIL_REASON=The RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:TEST_TOKEN
if not exist "%TOKEN%" exit /b 1
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS exit /b 1
set "OUT=%WORK%\start25-token-test.json"
set "HTTP=%WORK%\start25-token-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start25-token-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "ACCESS="
if not "!LAST_CURL!"=="0" exit /b 1
if not "!LAST_HTTP!"=="200" exit /b 1
exit /b 0

:DEVICE_FLOW
set "OUT=%WORK%\start25-device.json"
set "HTTP=%WORK%\start25-device-http.txt"
set "HEAD=%WORK%\start25-device-headers.txt"
for %%F in ("%OUT%" "%HTTP%" "%HEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" -D "%HEAD%" "https://github.com/login/device/code" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start25-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
set "CONTENT_TYPE=UNKNOWN"
for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /b /c:"Content-Type:" "%HEAD%" 2^>nul') do set "CONTENT_TYPE=%%B"
"%FINDSTR%" /i /c:"device_code" "%OUT%" >nul 2>&1
if errorlevel 1 (set "BODY_HAS_DEVICE=NO") else set "BODY_HAS_DEVICE=YES"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START25-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device authorization request failed over HTTPS."
  exit /b 1
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START25-OAUTH-HTTP-002"
  set "FAIL_REASON=GitHub device authorization endpoint did not return HTTP 200."
  exit /b 1
)
set "LAST_SUCCESS=GitHub device endpoint returned HTTP 200"
call :JGET "%OUT%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START25-OAUTH-PARSE-001"
  set "FAIL_REASON=GitHub returned device metadata, but device_code could not be parsed."
  exit /b 1
)
call :JGET "%OUT%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START25-OAUTH-PARSE-002"
  set "FAIL_REASON=GitHub returned device metadata, but user_code could not be parsed."
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
  set "ERROR_ID=RMAI-START25-OAUTH-EXPIRED-001"
  set "FAIL_REASON=GitHub device authorization code expired before approval completed."
  exit /b 1
)
set "POLL_COUNT=!COUNT! / !MAX!"
call :SHOW_DEVICE_SCREEN
call :WAIT_SECONDS !INTERVAL!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START25-WAIT-001"
  set "ERROR_STAGE=DEVICE AUTHORIZATION"
  set "ERROR_COMPONENT=ping.exe wait mechanism"
  set "ERROR_OPERATION=wait between GitHub approval polls"
  set "FAIL_REASON=WinRE could not perform the safe authorization polling delay."
  exit /b 1
)
set "TOK=%WORK%\start25-device-token.json"
set "TOKHTTP=%WORK%\start25-device-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start25-device-token-curl.txt"
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
  set "ERROR_ID=RMAI-START25-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was denied."
  exit /b 1
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "ERROR_ID=RMAI-START25-OAUTH-EXPIRED-002"
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
echo   The code remains fixed on screen while RescueMeAI polls quietly.
echo.
echo PLEASE LEAVE THIS WINDOW OPEN.
exit /b 0

:JGET
set "%~3="
set "PARSER_RC="
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start25-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
set "JV="
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
>>"%FAILFILE%" echo helper_path=%HELPER%
>>"%FAILFILE%" echo parser_selftest=%PARSER_SELFTEST%
>>"%FAILFILE%" echo parser_return=%PARSER_RC%
>>"%FAILFILE%" echo api_cached_ip=%APIIP%
>>"%FAILFILE%" echo web_cached_ip=%WEBIP%
>>"%FAILFILE%" echo http=%LAST_HTTP%
>>"%FAILFILE%" echo curl_return_code=%LAST_CURL%
>>"%FAILFILE%" echo body_has_device_code=%BODY_HAS_DEVICE%
>>"%FAILFILE%" echo content_type=%CONTENT_TYPE%
>>"%FAILFILE%" echo wait_mechanism=ping.exe
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
echo Helper path      : %HELPER%
echo Parser self-test : %PARSER_SELFTEST%
echo Parser return    : %PARSER_RC%
echo HTTP status      : %LAST_HTTP%
echo curl return code : %LAST_CURL%
echo Body had key     : device_code=%BODY_HAS_DEVICE%
echo Content-Type     : %CONTENT_TYPE%
echo API cached IP    : %APIIP%
echo Web cached IP    : %WEBIP%
echo Wait mechanism   : ping.exe
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %FAILFILE%
echo.
echo WHAT YOU NEED TO DO
echo ----------------------------------------------------------------------------------------------------
echo Take one photo of this entire screen and send it to ChatGPT.
echo The Error ID and exact failure location identify where to investigate.
echo Do NOT post token files, device secrets, refresh tokens, or access tokens.
echo.
echo No Windows repair action was executed by this startup failure.
echo This screen will remain until you press a key.
echo ====================================================================================================
pause
exit /b 90
