@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=START_RESCUEMEAI_JSON_AUTH_AUTO_RENEW_V34
rem WR_TARGET=RescueMeAI private recovery-channel authentication and persistent agent only.
rem WR_CONSEQUENCE=Renews authorization, validates identity/repository access, stages corrected agent auth, and starts the agent. No Windows recovery state is changed.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-34"
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
set "JOUT=%WORK%\start34-jget.txt"
set "FAILFILE=%WORK%\START34_FAILURE.txt"
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
set "TOKEN_TYPE=UNKNOWN"
set "PARSER_RC=NOT_RUN"
set "CONTENT_TYPE=UNKNOWN"
set "BODY_BYTES=0"
set "BODY_HAS_DEVICE=UNKNOWN"
set "AUTH_CYCLE=0"
set "LAST_SUCCESS=START-34 entered"
set "ERROR_ID=RMAI-START34-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialize recovery-channel launcher"
set "FAIL_REASON=RescueMeAI could not establish the private recovery channel."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

for %%F in ("%CURL%" "%FINDSTR%" "%CSCRIPT%" "%PING%" "%AGENT%" "%HELPER%") do (
  if not exist %%F (
    set "ERROR_ID=RMAI-START34-DEP-001"
    set "ERROR_STAGE=STARTUP"
    set "ERROR_COMPONENT=dependencies"
    set "ERROR_OPERATION=validate required local components"
    set "FAIL_REASON=Required component is missing: %%~nxF"
    goto :FATAL
  )
)
for %%F in (network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js ui.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "ERROR_ID=RMAI-START34-RUNTIME-001"
    set "ERROR_STAGE=STARTUP"
    set "ERROR_COMPONENT=runtime"
    set "ERROR_OPERATION=validate staged runtime"
    set "FAIL_REASON=Required runtime module %%F is missing."
    goto :FATAL
  )
)
set "LAST_SUCCESS=Local dependencies validated"

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if exist "%WORK%\github-web-ip.txt" set /p "WEBIP="<"%WORK%\github-web-ip.txt"
if not defined APIIP (
  set "ERROR_ID=RMAI-START34-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated api.github.com route cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START34-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated github.com route cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

rem Only test the JSON parser. START-31 already proved GitHub returns JSON on this WinRE path.
set "ERROR_STAGE=AUTH PARSER SELF-TEST"
set "ERROR_COMPONENT=%HELPER%"
set "ERROR_OPERATION=parse synthetic JSON response"
>"%WORK%\start34-selftest.json" echo {"device_code":"JSON_OK"}
call :JGET "%WORK%\start34-selftest.json" device_code SELFTEST
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-PARSER-001"
  set "FAIL_REASON=The local JSON parser failed its self-test."
  goto :FATAL
)
if /i not "!SELFTEST!"=="JSON_OK" (
  set "ERROR_ID=RMAI-START34-PARSER-002"
  set "FAIL_REASON=The local JSON parser returned the wrong self-test value."
  goto :FATAL
)
set "LAST_SUCCESS=Local JSON parser self-test passed"

goto :REQUEST_DEVICE

:REQUEST_DEVICE
set /a AUTH_CYCLE+=1
set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub device-code endpoint"
set "ERROR_OPERATION=request fresh device authorization metadata"
set "DEV=%WORK%\start34-device.json"
set "DEVHTTP=%WORK%\start34-device-http.txt"
set "DEVHEAD=%WORK%\start34-device-headers.txt"
for %%F in ("%DEV%" "%DEVHTTP%" "%DEVHEAD%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" -D "%DEVHEAD%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%DEVHTTP%" 2>"%WORK%\start34-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%DEVHTTP%" set /p "LAST_HTTP="<"%DEVHTTP%"
call :INSPECT_RESPONSE "%DEV%" "%DEVHEAD%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START34-OAUTH-NET-001"
  set "FAIL_REASON=GitHub device-code request failed over HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START34-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device-code endpoint did not return HTTP 200."
  goto :FATAL
)
call :JGET "%DEV%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-OAUTH-PARSE-001"
  set "ERROR_COMPONENT=GitHub JSON device-code response"
  set "ERROR_OPERATION=parse device_code"
  set "FAIL_REASON=GitHub returned HTTP 200 but device_code could not be extracted from the JSON response."
  goto :FATAL
)
call :JGET "%DEV%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-OAUTH-PARSE-002"
  set "ERROR_OPERATION=parse user_code"
  set "FAIL_REASON=GitHub returned device metadata but user_code could not be extracted."
  goto :FATAL
)
set "EXPIRES=900"
set "INTERVAL=5"
call :JGET "%DEV%" expires_in EXPIRES_TMP
if not errorlevel 1 if defined EXPIRES_TMP set "EXPIRES=!EXPIRES_TMP!"
call :JGET "%DEV%" interval INTERVAL_TMP
if not errorlevel 1 if defined INTERVAL_TMP set "INTERVAL=!INTERVAL_TMP!"
set "LAST_SUCCESS=Fresh GitHub device code parsed successfully"
set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
set "POLL_STATE=Waiting for approval on your phone"

goto :DEVICE_POLL

:DEVICE_POLL
set /a COUNT+=1
if !COUNT! GTR !MAX! (
  set "POLL_STATE=Previous code expired; generating a fresh code automatically"
  goto :REQUEST_DEVICE
)
call :SHOW_DEVICE
call :WAIT_SECONDS !INTERVAL!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-WAIT-001"
  set "ERROR_STAGE=DEVICE AUTHORIZATION"
  set "ERROR_COMPONENT=ping.exe wait mechanism"
  set "ERROR_OPERATION=wait between authorization polls"
  set "FAIL_REASON=WinRE could not perform the safe polling delay."
  goto :FATAL
)

set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub access-token endpoint"
set "ERROR_OPERATION=poll device authorization status"
set "TOK=%WORK%\start34-token.json"
set "TOKHTTP=%WORK%\start34-token-http.txt"
for %%F in ("%TOK%" "%TOKHTTP%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start34-token-curl.txt"
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

set "CANDIDATE_ACCESS="
set "CANDIDATE_REFRESH="
set "OAUTH_ERROR="
set "TOKEN_TYPE=UNKNOWN"
call :JGET "%TOK%" access_token CANDIDATE_ACCESS
if not errorlevel 1 if defined CANDIDATE_ACCESS goto :TOKEN_RECEIVED
call :JGET "%TOK%" error OAUTH_ERROR
if /i "!OAUTH_ERROR!"=="authorization_pending" goto :DEVICE_POLL
if /i "!OAUTH_ERROR!"=="slow_down" (
  set /a INTERVAL+=5
  set "POLL_STATE=GitHub requested slower polling; interval increased"
  goto :DEVICE_POLL
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "POLL_STATE=GitHub expired the previous code; generating a new code"
  goto :REQUEST_DEVICE
)
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "ERROR_ID=RMAI-START34-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was denied."
  goto :FATAL
)
set "POLL_STATE=Waiting for GitHub authorization completion"
goto :DEVICE_POLL

:TOKEN_RECEIVED
call :JGET "%TOK%" token_type TOKEN_TYPE_TMP
if not errorlevel 1 if defined TOKEN_TYPE_TMP set "TOKEN_TYPE=!TOKEN_TYPE_TMP!"
call :JGET "%TOK%" refresh_token CANDIDATE_REFRESH
set "LAST_SUCCESS=GitHub returned a candidate access credential"

set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=GitHub user identity"
set "ERROR_OPERATION=validate candidate credential with GET /user"
set "OUT=%WORK%\start34-user-test.json"
set "HTTP=%WORK%\start34-user-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start34-user-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "IDENTITY_HTTP="
if exist "%HTTP%" set /p "IDENTITY_HTTP="<"%HTTP%"
set "LAST_HTTP=!IDENTITY_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START34-IDENTITY-NET-001"
  set "FAIL_REASON=Candidate credential identity validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!IDENTITY_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START34-IDENTITY-001"
  set "FAIL_REASON=GitHub rejected the candidate credential during GET /user validation."
  goto :FATAL
)
set "LAST_SUCCESS=Candidate credential authenticated successfully against GitHub user identity"

set "ERROR_COMPONENT=private GitHub recovery repository"
set "ERROR_OPERATION=verify private recovery repository access"
set "OUT=%WORK%\start34-repo-test.json"
set "HTTP=%WORK%\start34-repo-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start34-repo-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_HTTP="
if exist "%HTTP%" set /p "REPO_HTTP="<"%HTTP%"
set "LAST_HTTP=!REPO_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START34-REPO-NET-001"
  set "FAIL_REASON=Private repository validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!REPO_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START34-REPO-001"
  set "FAIL_REASON=GitHub accepted the user identity, but the credential cannot access the private recovery repository."
  goto :FATAL
)
set "LAST_SUCCESS=Candidate credential validated for identity and private recovery repository"

set "ERROR_STAGE=RUNTIME HANDOFF"
set "ERROR_COMPONENT=github-auth.cmd"
set "ERROR_OPERATION=stage corrected launcher-to-agent authentication module"
set "NEWAUTH=%WORK%\github-auth-v3-stage.cmd"
set "AUTHHTTP=%WORK%\start34-auth-stage-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth.cmd?ref=%AUTH_REF%" -o "%NEWAUTH%" -w "%%{http_code}" >"%AUTHHTTP%" 2>"%WORK%\start34-auth-stage-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%AUTHHTTP%" set /p "LAST_HTTP="<"%AUTHHTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START34-HANDOFF-DOWNLOAD-001"
  set "FAIL_REASON=The corrected agent authorization module could not be downloaded over validated HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START34-HANDOFF-DOWNLOAD-002"
  set "FAIL_REASON=GitHub did not return HTTP 200 for the corrected agent authorization module."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V3-LAUNCHER-HANDOFF" "%NEWAUTH%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-HANDOFF-MARKER-001"
  set "FAIL_REASON=The staged agent authorization module failed marker validation."
  goto :FATAL
)
copy /y "%NEWAUTH%" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START34-HANDOFF-COPY-001"
  set "FAIL_REASON=The corrected agent authorization module could not replace the old runtime copy."
  goto :FATAL
)
set "LAST_SUCCESS=Corrected agent authorization handoff staged"

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
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-34
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "RECOVERY AGENT STARTING" "Authorization and private repository access are validated. Starting RescueMeAI."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START34-AGENT-001"
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:JGET
set "%~3="
set "PARSER_RC=NOT_RUN"
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start34-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
set "JV="
exit /b 0

:INSPECT_RESPONSE
set "CONTENT_TYPE=UNKNOWN"
set "BODY_BYTES=0"
set "BODY_HAS_DEVICE=UNKNOWN"
if exist "%~1" (
  for %%Z in ("%~1") do set "BODY_BYTES=%%~zZ"
  "%FINDSTR%" /i /c:"device_code" "%~1" >nul 2>&1
  if errorlevel 1 (
    set "BODY_HAS_DEVICE=NO"
  ) else (
    set "BODY_HAS_DEVICE=YES"
  )
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
echo Authorization    : cycle !AUTH_CYCLE!
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
echo   Poll attempt: !COUNT! / !MAX!
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI detects approval automatically.
echo   If this code expires, RescueMeAI will generate a fresh code automatically.
echo   A returned credential must pass GitHub identity and private-repository validation before storage.
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
>>"%FAILFILE%" echo content_type=%CONTENT_TYPE%
>>"%FAILFILE%" echo body_bytes=%BODY_BYTES%
>>"%FAILFILE%" echo body_has_device_code=%BODY_HAS_DEVICE%
>>"%FAILFILE%" echo token_type=%TOKEN_TYPE%
>>"%FAILFILE%" echo parser_return=%PARSER_RC%
>>"%FAILFILE%" echo auth_cycle=%AUTH_CYCLE%
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
echo HTTP status      : %LAST_HTTP%
echo curl return code : %LAST_CURL%
echo Identity HTTP    : %IDENTITY_HTTP%
echo Repository HTTP  : %REPO_HTTP%
echo Content-Type     : %CONTENT_TYPE%
echo Body bytes       : %BODY_BYTES%
echo Body had key     : device_code=%BODY_HAS_DEVICE%
echo Token type       : %TOKEN_TYPE%
echo Parser return    : %PARSER_RC%
echo Auth cycle       : %AUTH_CYCLE%
echo API cached IP    : %APIIP%
echo Web cached IP    : %WEBIP%
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
