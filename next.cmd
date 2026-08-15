@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=START_RESCUEMEAI_AUTH_AUTO_RENEW_V32
rem WR_TARGET=RescueMeAI authentication and persistent agent only.
rem WR_CONSEQUENCE=Renews private recovery-channel authorization and stages corrected agent auth. No Windows recovery state is changed.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-32"
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
set "HELPER=%WORK%\start23-json.js"
set "JOUT=%WORK%\start32-jget.txt"
set "FAILFILE=%WORK%\START32_FAILURE.txt"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "AUTH_REF=825b988ca2cafe20e97856c391f6d02bcc0b6c6a"
set "APIIP="
set "WEBIP="
set "TLS="
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "IDENTITY_HTTP=NOT_RUN"
set "REPO_HTTP=NOT_RUN"
set "TOKEN_PREFIX=NOT_CHECKED"
set "TOKEN_TYPE=UNKNOWN"
set "PARSER_RC=NOT_RUN"
set "RESPONSE_FORMAT=UNKNOWN"
set "CONTENT_TYPE=UNKNOWN"
set "BODY_BYTES=0"
set "BODY_HAS_DEVICE=UNKNOWN"
set "AUTH_CYCLE=0"
set "LAST_SUCCESS=START-32 entered"
set "ERROR_ID=RMAI-START32-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialization"
set "FAIL_REASON=RescueMeAI could not establish the private recovery channel."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

for %%F in ("%CURL%" "%FINDSTR%" "%CSCRIPT%" "%PING%" "%AGENT%" "%HELPER%") do if not exist %%F (
  set "ERROR_ID=RMAI-START32-DEP-001"
  set "ERROR_STAGE=STARTUP"
  set "ERROR_COMPONENT=dependencies"
  set "ERROR_OPERATION=validate required local components"
  set "FAIL_REASON=Required component is missing: %%~nxF"
  goto :FATAL
)
for %%F in (network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js ui.cmd) do if not exist "%RUNTIME%\%%F" (
  set "ERROR_ID=RMAI-START32-RUNTIME-001"
  set "ERROR_STAGE=STARTUP"
  set "ERROR_COMPONENT=runtime"
  set "ERROR_OPERATION=validate staged runtime"
  set "FAIL_REASON=Required runtime module %%F is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Local dependencies validated"

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if exist "%WORK%\github-web-ip.txt" set /p "WEBIP="<"%WORK%\github-web-ip.txt"
if not defined APIIP (
  set "ERROR_ID=RMAI-START32-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated api.github.com route cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START32-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated github.com route cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

rem Prove both response parser paths locally before contacting GitHub.
set "ERROR_STAGE=AUTH PARSER SELF-TEST"
set "ERROR_COMPONENT=%HELPER%"
set "ERROR_OPERATION=parse synthetic JSON response"
>"%WORK%\start32-selftest.json" echo {"device_code":"JSON_OK"}
call :GET_VALUE "%WORK%\start32-selftest.json" device_code SELFTEST
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-PARSER-JSON-001"
  set "FAIL_REASON=The JSON parser failed its local self-test."
  goto :FATAL
)
if /i not "!SELFTEST!"=="JSON_OK" (
  set "ERROR_ID=RMAI-START32-PARSER-JSON-002"
  set "FAIL_REASON=The JSON parser returned the wrong self-test value."
  goto :FATAL
)
set "ERROR_COMPONENT=CMD form parser"
set "ERROR_OPERATION=parse synthetic form-encoded response"
>"%WORK%\start32-selftest.form" echo device_code=FORM_OK^&user_code=ABCD-EFGH^&expires_in=900^&interval=5
call :FORM_GET "%WORK%\start32-selftest.form" device_code SELFTEST_FORM
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-PARSER-FORM-001"
  set "FAIL_REASON=The form parser failed its local self-test."
  goto :FATAL
)
if /i not "!SELFTEST_FORM!"=="FORM_OK" (
  set "ERROR_ID=RMAI-START32-PARSER-FORM-002"
  set "FAIL_REASON=The form parser returned the wrong self-test value."
  goto :FATAL
)
set "LAST_SUCCESS=JSON and form-encoded parser self-tests passed"

goto :REQUEST_DEVICE

:REQUEST_DEVICE
set /a AUTH_CYCLE+=1
set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub device-code endpoint"
set "ERROR_OPERATION=request fresh device authorization metadata"
set "DEV=%WORK%\start32-device-response.txt"
set "DEVHTTP=%WORK%\start32-device-http.txt"
set "DEVHEAD=%WORK%\start32-device-headers.txt"
for %%F in ("%DEV%" "%DEVHTTP%" "%DEVHEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" -D "%DEVHEAD%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%DEVHTTP%" 2>"%WORK%\start32-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%DEVHTTP%" set /p "LAST_HTTP="<"%DEVHTTP%"
call :INSPECT_RESPONSE "%DEV%" "%DEVHEAD%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START32-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device-code request failed over HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START32-OAUTH-HTTP-002"
  set "FAIL_REASON=GitHub device-code endpoint did not return HTTP 200."
  goto :FATAL
)
call :GET_VALUE "%DEV%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-OAUTH-PARSE-001"
  set "ERROR_COMPONENT=GitHub device-code response"
  set "ERROR_OPERATION=parse device_code from JSON or form response"
  set "FAIL_REASON=GitHub returned HTTP 200, but neither supported response parser found device_code."
  goto :FATAL
)
set "DEVICE_FORMAT=!RESPONSE_FORMAT!"
call :GET_VALUE "%DEV%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-OAUTH-PARSE-002"
  set "FAIL_REASON=GitHub returned device metadata, but user_code could not be parsed."
  goto :FATAL
)
set "EXPIRES=900"
set "INTERVAL=5"
call :GET_VALUE "%DEV%" expires_in EXPIRES_TMP
if not errorlevel 1 if defined EXPIRES_TMP set "EXPIRES=!EXPIRES_TMP!"
call :GET_VALUE "%DEV%" interval INTERVAL_TMP
if not errorlevel 1 if defined INTERVAL_TMP set "INTERVAL=!INTERVAL_TMP!"
set "RESPONSE_FORMAT=!DEVICE_FORMAT!"
set "LAST_SUCCESS=Fresh GitHub device code parsed successfully as !DEVICE_FORMAT!"
set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
set "POLL_STATE=Waiting for approval on your phone"

goto :DEVICE_POLL

:DEVICE_POLL
set /a COUNT+=1
if !COUNT! GTR !MAX! (
  set "POLL_STATE=Previous code expired. Generating a fresh code automatically."
  goto :REQUEST_DEVICE
)
set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub OAuth token polling"
set "ERROR_OPERATION=wait for local device-code approval"
call :SHOW_DEVICE
call :WAIT_SECONDS !INTERVAL!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-WAIT-001"
  set "ERROR_COMPONENT=ping.exe wait mechanism"
  set "ERROR_OPERATION=wait between authorization polls"
  set "FAIL_REASON=WinRE could not perform the safe polling delay."
  goto :FATAL
)
set "TOK=%WORK%\start32-token-response.txt"
set "TOKHTTP=%WORK%\start32-token-http.txt"
set "TOKHEAD=%WORK%\start32-token-headers.txt"
for %%F in ("%TOK%" "%TOKHTTP%" "%TOKHEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" -D "%TOKHEAD%" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start32-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
call :INSPECT_RESPONSE "%TOK%" "%TOKHEAD%"
if not "!LAST_CURL!"=="0" (
  set "POLL_STATE=Temporary HTTPS polling failure; retrying automatically"
  goto :DEVICE_POLL
)
if not "!LAST_HTTP!"=="200" (
  set "POLL_STATE=GitHub poll returned HTTP !LAST_HTTP!; retrying automatically"
  goto :DEVICE_POLL
)
set "CANDIDATE_ACCESS="
set "CANDIDATE_REFRESH="
set "OAUTH_ERROR="
set "TOKEN_TYPE=UNKNOWN"
call :GET_VALUE "%TOK%" access_token CANDIDATE_ACCESS
if not errorlevel 1 if defined CANDIDATE_ACCESS goto :TOKEN_RECEIVED
call :GET_VALUE "%TOK%" error OAUTH_ERROR
if /i "!OAUTH_ERROR!"=="authorization_pending" goto :DEVICE_POLL
if /i "!OAUTH_ERROR!"=="slow_down" (
  set /a INTERVAL+=5
  set "POLL_STATE=GitHub requested slower polling; interval increased"
  goto :DEVICE_POLL
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "POLL_STATE=Previous code expired. Generating a fresh code automatically."
  goto :REQUEST_DEVICE
)
if /i "!OAUTH_ERROR!"=="incorrect_device_code" (
  set "POLL_STATE=GitHub rejected the old device code. Generating a fresh code automatically."
  goto :REQUEST_DEVICE
)
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "ERROR_ID=RMAI-START32-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was explicitly denied."
  goto :FATAL
)
set "POLL_STATE=GitHub response received; waiting for authorization completion"
goto :DEVICE_POLL

:TOKEN_RECEIVED
set "TOKEN_RESPONSE_FORMAT=!RESPONSE_FORMAT!"
call :GET_VALUE "%TOK%" token_type TOKEN_TYPE_TMP
if not errorlevel 1 if defined TOKEN_TYPE_TMP set "TOKEN_TYPE=!TOKEN_TYPE_TMP!"
call :GET_VALUE "%TOK%" refresh_token CANDIDATE_REFRESH
set "RESPONSE_FORMAT=!TOKEN_RESPONSE_FORMAT!"
set "TOKEN_PREFIX=OTHER"
if /i "!CANDIDATE_ACCESS:~0,4!"=="ghu_" set "TOKEN_PREFIX=GHU"
set "LAST_SUCCESS=GitHub returned a candidate credential parsed as !TOKEN_RESPONSE_FORMAT!"

set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=GitHub user identity"
set "ERROR_OPERATION=authenticate candidate credential against GET /user"
set "OUT=%WORK%\start32-user-test.json"
set "HTTP=%WORK%\start32-user-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start32-user-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "IDENTITY_HTTP="
if exist "%HTTP%" set /p "IDENTITY_HTTP="<"%HTTP%"
set "LAST_HTTP=!IDENTITY_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START32-IDENTITY-NET-001"
  set "FAIL_REASON=Candidate credential identity validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!IDENTITY_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START32-IDENTITY-001"
  set "FAIL_REASON=GitHub rejected the candidate credential during GET /user validation."
  goto :FATAL
)
set "LAST_SUCCESS=Candidate credential authenticated successfully against GitHub user identity"

set "ERROR_COMPONENT=private GitHub recovery repository"
set "ERROR_OPERATION=verify private recovery repository access"
set "OUT=%WORK%\start32-repo-test.json"
set "HTTP=%WORK%\start32-repo-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start32-repo-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_HTTP="
if exist "%HTTP%" set /p "REPO_HTTP="<"%HTTP%"
set "LAST_HTTP=!REPO_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START32-REPO-NET-001"
  set "FAIL_REASON=Private repository validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!REPO_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START32-REPO-001"
  set "FAIL_REASON=GitHub accepted the user identity, but the credential cannot access the private recovery repository."
  goto :FATAL
)
set "LAST_SUCCESS=Candidate credential validated for identity and private recovery repository"

set "ERROR_STAGE=RUNTIME HANDOFF"
set "ERROR_COMPONENT=github-auth.cmd"
set "ERROR_OPERATION=stage corrected launcher-to-agent authentication module"
set "NEWAUTH=%WORK%\github-auth-v3-stage.cmd"
set "AUTHHTTP=%WORK%\start32-auth-stage-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth.cmd?ref=%AUTH_REF%" -o "%NEWAUTH%" -w "%%{http_code}" >"%AUTHHTTP%" 2>"%WORK%\start32-auth-stage-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%AUTHHTTP%" set /p "LAST_HTTP="<"%AUTHHTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START32-HANDOFF-DOWNLOAD-001"
  set "FAIL_REASON=The corrected agent authorization module could not be downloaded over validated HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START32-HANDOFF-DOWNLOAD-002"
  set "FAIL_REASON=GitHub did not return HTTP 200 for the corrected agent authorization module."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V3-LAUNCHER-HANDOFF" "%NEWAUTH%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-HANDOFF-MARKER-001"
  set "FAIL_REASON=The staged agent authorization module failed marker validation."
  goto :FATAL
)
copy /y "%NEWAUTH%" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START32-HANDOFF-COPY-001"
  set "FAIL_REASON=The corrected agent authorization module could not replace the old runtime copy."
  goto :FATAL
)
set "LAST_SUCCESS=Corrected agent authorization handoff staged"

rem Save only the credential that GitHub has accepted for identity and private-repo access.
if exist "%TOKEN%" copy /y "%TOKEN%" "%TOKEN%.previous" >nul 2>&1
if exist "%REFRESH%" copy /y "%REFRESH%" "%REFRESH%.previous" >nul 2>&1
>"%TOKEN%" echo(!CANDIDATE_ACCESS!
attrib +h +s "%TOKEN%" >nul 2>&1
if defined CANDIDATE_REFRESH (
  >"%REFRESH%" echo(!CANDIDATE_REFRESH!
  attrib +h +s "%REFRESH%" >nul 2>&1
)
set "CANDIDATE_ACCESS="
set "CANDIDATE_REFRESH="
set "LAST_SUCCESS=Validated GitHub credential stored locally"

>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%AUTH_REF%
>>"%CONFIG%" echo SESSION_VERSION=%COMMAND_VERSION%
>"%WORK%\session-version.txt" echo %COMMAND_VERSION%
>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-32
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "RECOVERY AGENT STARTING" "Authorization and private repository access are validated. Starting RescueMeAI."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START32-AGENT-001"
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:GET_VALUE
set "%~3="
call :JGET "%~1" "%~2" "%~3"
if not errorlevel 1 (
  set "RESPONSE_FORMAT=JSON"
  exit /b 0
)
call :FORM_GET "%~1" "%~2" "%~3"
if not errorlevel 1 (
  set "RESPONSE_FORMAT=FORM"
  exit /b 0
)
set "RESPONSE_FORMAT=UNKNOWN"
exit /b 1

:JGET
set "%~3="
set "PARSER_RC=NOT_RUN"
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start32-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
set "JV="
exit /b 0

:FORM_GET
set "%~3="
if not exist "%~1" exit /b 1
set "FG_LINE="
set /p "FG_LINE="<"%~1"
if not defined FG_LINE exit /b 1
set "FG_LINE=!FG_LINE:&= !"
set "FG_VALUE="
for %%P in (!FG_LINE!) do (
  for /f "tokens=1,* delims==" %%A in ("%%P") do if /i "%%A"=="%~2" set "FG_VALUE=%%B"
)
if not defined FG_VALUE exit /b 1
set "%~3=!FG_VALUE!"
exit /b 0

:INSPECT_RESPONSE
set "CONTENT_TYPE=UNKNOWN"
set "BODY_BYTES=0"
set "BODY_HAS_DEVICE=UNKNOWN"
if exist "%~1" (
  for %%Z in ("%~1") do set "BODY_BYTES=%%~zZ"
  "%FINDSTR%" /i /c:"device_code" "%~1" >nul 2>&1
  if errorlevel 1 (set "BODY_HAS_DEVICE=NO") else set "BODY_HAS_DEVICE=YES"
)
if exist "%~2" (
  for /f "tokens=1,* delims=:" %%A in ('"%FINDSTR%" /i /b /c:"Content-Type:" "%~2" 2^>nul') do set "CONTENT_TYPE=%%B"
)
exit /b 0

:WAIT_SECONDS
set "WAIT_SEC=%~1"
if not defined WAIT_SEC set "WAIT_SEC=5"
set /a WAIT_SEC+=0
if !WAIT_SEC! LSS 1 set "WAIT_SEC=1"
set /a PING_COUNT=WAIT_SEC+1
"%PING%" 127.0.0.1 -n !PING_COUNT! >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:SHOW_DEVICE
cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Transport        : HTTPS / TLS
echo Windows changes  : NONE
echo Status           : WAITING FOR GITHUB APPROVAL
echo ====================================================================================================
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
echo   Authorization cycle: !AUTH_CYCLE!
echo   Poll attempt       : !COUNT! / !MAX!
echo   Code lifetime      : approximately !EXPIRES! seconds
echo   Response format    : !DEVICE_FORMAT!
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI detects approval automatically.
echo   If this code expires, RescueMeAI generates a fresh code automatically and keeps waiting.
echo   A returned credential is validated against GitHub identity and the private recovery repository
echo   BEFORE it is stored or handed to the recovery agent.
echo   No Windows repair runs during authorization.
echo.
echo PLEASE LEAVE THIS WINDOW OPEN.
exit /b 0

:SCREEN
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Transport        : HTTPS / TLS
echo Status           : %~1
echo Windows changes  : NONE
echo ====================================================================================================
echo.
echo %~2
echo.
echo PLEASE WAIT - no action is required unless RescueMeAI displays LOCAL ACTION REQUIRED.
exit /b 0

:FATAL
>"%FAILFILE%" echo RESCUEMEAI STRUCTURED FAILURE REPORT
>>"%FAILFILE%" echo error_id=%ERROR_ID%
>>"%FAILFILE%" echo launcher_session=%COMMAND_VERSION%
>>"%FAILFILE%" echo stage=%ERROR_STAGE%
>>"%FAILFILE%" echo component=%ERROR_COMPONENT%
>>"%FAILFILE%" echo operation=%ERROR_OPERATION%
>>"%FAILFILE%" echo reason=%FAIL_REASON%
>>"%FAILFILE%" echo last_success=%LAST_SUCCESS%
>>"%FAILFILE%" echo http=%LAST_HTTP%
>>"%FAILFILE%" echo curl_return_code=%LAST_CURL%
>>"%FAILFILE%" echo identity_http=%IDENTITY_HTTP%
>>"%FAILFILE%" echo repository_http=%REPO_HTTP%
>>"%FAILFILE%" echo response_format=%RESPONSE_FORMAT%
>>"%FAILFILE%" echo content_type=%CONTENT_TYPE%
>>"%FAILFILE%" echo body_bytes=%BODY_BYTES%
>>"%FAILFILE%" echo body_has_device_code=%BODY_HAS_DEVICE%
>>"%FAILFILE%" echo token_prefix_class=%TOKEN_PREFIX%
>>"%FAILFILE%" echo token_type=%TOKEN_TYPE%
>>"%FAILFILE%" echo parser_return=%PARSER_RC%
>>"%FAILFILE%" echo authorization_cycle=%AUTH_CYCLE%
>>"%FAILFILE%" echo api_cached_ip=%APIIP%
>>"%FAILFILE%" echo web_cached_ip=%WEBIP%
>>"%FAILFILE%" echo windows_changes=NONE
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                       APPLICATION FAILURE
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Windows changes  : STOPPED - NO WINDOWS REPAIR EXECUTED
echo Error ID         : %ERROR_ID%
echo ====================================================================================================
echo.
echo EXACT FAILURE LOCATION
echo ----------------------------------------------------------------------------------------------------
echo Stage       : %ERROR_STAGE%
echo Component   : %ERROR_COMPONENT%
echo Operation   : %ERROR_OPERATION%
echo Reason      : %FAIL_REASON%
echo Last success: %LAST_SUCCESS%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status       : %LAST_HTTP%
echo curl return code  : %LAST_CURL%
echo Identity HTTP     : %IDENTITY_HTTP%
echo Repository HTTP   : %REPO_HTTP%
echo Response format   : %RESPONSE_FORMAT%
echo Content-Type      : %CONTENT_TYPE%
echo Body bytes        : %BODY_BYTES%
echo Body had key      : device_code=%BODY_HAS_DEVICE%
echo Token prefix class: %TOKEN_PREFIX%
echo Token type        : %TOKEN_TYPE%
echo Parser return     : %PARSER_RC%
echo Auth cycle        : %AUTH_CYCLE%
echo API cached IP     : %APIIP%
echo Web cached IP     : %WEBIP%
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %FAILFILE%
echo.
echo No Windows repair action was executed by this startup failure.
echo Press a key only after you have read or photographed this screen.
echo ====================================================================================================
pause
exit /b 90