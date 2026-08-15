@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=START_RESCUEMEAI_FRESH_AUTH_HANDOFF_V29
rem WR_TARGET=RescueMeAI authentication and persistent agent only.
rem WR_CONSEQUENCE=Renews the private recovery-channel token and stages corrected agent auth. No Windows recovery state is changed.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-29"
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
set "JOUT=%WORK%\start29-jget.txt"
set "FAILFILE=%WORK%\START29_FAILURE.txt"
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
set "LAST_SUCCESS=START-29 entered"
set "ERROR_ID=RMAI-START29-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialization"
set "FAIL_REASON=RescueMeAI could not establish the private recovery channel."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

for %%F in ("%CURL%" "%FINDSTR%" "%CSCRIPT%" "%PING%" "%AGENT%" "%HELPER%") do if not exist %%F (
  set "ERROR_ID=RMAI-START29-DEP-001"
  set "ERROR_STAGE=STARTUP"
  set "ERROR_COMPONENT=dependencies"
  set "ERROR_OPERATION=validate required local components"
  set "FAIL_REASON=Required component is missing: %%~nxF"
  goto :FATAL
)
for %%F in (network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js ui.cmd) do if not exist "%RUNTIME%\%%F" (
  set "ERROR_ID=RMAI-START29-RUNTIME-001"
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
  set "ERROR_ID=RMAI-START29-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated api.github.com route cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START29-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated github.com route cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

rem Parser self-test before contacting GitHub.
>"%WORK%\start29-selftest.json" echo {"device_code":"SELFTEST_OK"}
call :JGET "%WORK%\start29-selftest.json" device_code SELFTEST
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-PARSER-001"
  set "ERROR_STAGE=AUTH PARSER"
  set "ERROR_COMPONENT=%HELPER%"
  set "ERROR_OPERATION=synthetic parser self-test"
  set "FAIL_REASON=The proven local parser failed its self-test."
  goto :FATAL
)
if /i not "!SELFTEST!"=="SELFTEST_OK" (
  set "ERROR_ID=RMAI-START29-PARSER-002"
  set "ERROR_STAGE=AUTH PARSER"
  set "ERROR_COMPONENT=%HELPER%"
  set "ERROR_OPERATION=synthetic parser self-test"
  set "FAIL_REASON=The parser returned the wrong self-test value."
  goto :FATAL
)
set "LAST_SUCCESS=Local JSON parser self-test passed"

rem Always request a fresh device authorization; do not reuse the bad saved token.
set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub OAuth device flow"
set "ERROR_OPERATION=request fresh device code"
set "DEV=%WORK%\start29-device.json"
set "DEVHTTP=%WORK%\start29-device-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%DEVHTTP%" 2>"%WORK%\start29-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%DEVHTTP%" set /p "LAST_HTTP="<"%DEVHTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START29-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device-code request failed over HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START29-OAUTH-HTTP-002"
  set "FAIL_REASON=GitHub device-code endpoint did not return HTTP 200."
  goto :FATAL
)
call :JGET "%DEV%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-OAUTH-PARSE-001"
  set "FAIL_REASON=GitHub returned HTTP 200 but device_code could not be parsed."
  goto :FATAL
)
call :JGET "%DEV%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-OAUTH-PARSE-002"
  set "FAIL_REASON=GitHub returned device metadata but user_code could not be parsed."
  goto :FATAL
)
call :JGET "%DEV%" expires_in EXPIRES
if errorlevel 1 set "EXPIRES=900"
call :JGET "%DEV%" interval INTERVAL
if errorlevel 1 set "INTERVAL=5"
set "LAST_SUCCESS=Fresh GitHub device code parsed successfully"
set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
set "POLL_STATE=Waiting for approval on your phone"

:DEVICE_POLL
set /a COUNT+=1
if !COUNT! GTR !MAX! (
  set "ERROR_ID=RMAI-START29-OAUTH-EXPIRED-001"
  set "FAIL_REASON=GitHub device authorization expired before approval completed."
  goto :FATAL
)
call :SHOW_DEVICE
call :WAIT_SECONDS !INTERVAL!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-WAIT-001"
  set "ERROR_STAGE=DEVICE AUTHORIZATION"
  set "ERROR_COMPONENT=ping.exe wait mechanism"
  set "ERROR_OPERATION=wait between authorization polls"
  set "FAIL_REASON=WinRE could not perform the safe polling delay."
  goto :FATAL
)
set "TOK=%WORK%\start29-token.json"
set "TOKHTTP=%WORK%\start29-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start29-token-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%TOKHTTP%" set /p "LAST_HTTP="<"%TOKHTTP%"
if not "!LAST_CURL!"=="0" (
  set "POLL_STATE=Temporary HTTPS polling failure; retrying"
  goto :DEVICE_POLL
)
if not "!LAST_HTTP!"=="200" (
  set "POLL_STATE=GitHub poll returned HTTP !LAST_HTTP!; retrying"
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
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "ERROR_ID=RMAI-START29-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was denied."
  goto :FATAL
)
if /i "!OAUTH_ERROR!"=="expired_token" (
  set "ERROR_ID=RMAI-START29-OAUTH-EXPIRED-002"
  set "FAIL_REASON=GitHub device authorization code expired."
  goto :FATAL
)
set "POLL_STATE=Waiting for GitHub authorization result"
goto :DEVICE_POLL

:TOKEN_RECEIVED
call :JGET "%TOK%" token_type TOKEN_TYPE
call :JGET "%TOK%" refresh_token CANDIDATE_REFRESH
set "TOKEN_PREFIX=UNEXPECTED"
if /i "!CANDIDATE_ACCESS:~0,4!"=="ghu_" set "TOKEN_PREFIX=EXPECTED_GHU"
if /i not "!TOKEN_PREFIX!"=="EXPECTED_GHU" (
  set "ERROR_ID=RMAI-START29-TOKEN-FORMAT-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=GitHub device-flow token"
  set "ERROR_OPERATION=validate token prefix"
  set "FAIL_REASON=GitHub returned a credential without the expected ghu_ user-token prefix."
  goto :FATAL
)
if /i not "!TOKEN_TYPE!"=="bearer" (
  set "ERROR_ID=RMAI-START29-TOKEN-FORMAT-002"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=GitHub device-flow token"
  set "ERROR_OPERATION=validate token_type"
  set "FAIL_REASON=GitHub returned an unexpected token_type."
  goto :FATAL
)
set "LAST_SUCCESS=GitHub returned an expected-format user access token"

rem Validate identity before storing the token.
set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=GitHub user identity"
set "ERROR_OPERATION=authenticate fresh token against GET /user"
set "OUT=%WORK%\start29-user-test.json"
set "HTTP=%WORK%\start29-user-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start29-user-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "IDENTITY_HTTP="
if exist "%HTTP%" set /p "IDENTITY_HTTP="<"%HTTP%"
set "LAST_HTTP=!IDENTITY_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START29-IDENTITY-NET-001"
  set "FAIL_REASON=Fresh token identity validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!IDENTITY_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START29-IDENTITY-001"
  set "FAIL_REASON=GitHub rejected the fresh device-flow token during GET /user validation."
  goto :FATAL
)
set "LAST_SUCCESS=Fresh token authenticated successfully against GitHub user identity"

rem Validate private repository access separately.
set "ERROR_COMPONENT=private GitHub repository"
set "ERROR_OPERATION=verify private recovery repository access"
set "OUT=%WORK%\start29-repo-test.json"
set "HTTP=%WORK%\start29-repo-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !CANDIDATE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start29-repo-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_HTTP="
if exist "%HTTP%" set /p "REPO_HTTP="<"%HTTP%"
set "LAST_HTTP=!REPO_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START29-REPO-NET-001"
  set "FAIL_REASON=Private repository validation failed at the HTTPS transport layer."
  goto :FATAL
)
if not "!REPO_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START29-REPO-001"
  set "FAIL_REASON=GitHub accepted the user identity, but the token could not access the private recovery repository."
  goto :FATAL
)
set "LAST_SUCCESS=Fresh token validated for identity and private repository access"

rem Store only the validated token.
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
set "LAST_SUCCESS=Validated token stored locally"

rem Stage the corrected agent-side auth module.
set "ERROR_STAGE=RUNTIME HANDOFF"
set "ERROR_COMPONENT=github-auth.cmd"
set "ERROR_OPERATION=stage corrected launcher-to-agent auth module"
set "NEWAUTH=%WORK%\start29-github-auth.cmd"
set "AUTHHTTP=%WORK%\start29-auth-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth.cmd?ref=%AUTH_REF%" -o "%NEWAUTH%" -w "%%{http_code}" >"%AUTHHTTP%" 2>"%WORK%\start29-auth-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%AUTHHTTP%" set /p "LAST_HTTP="<"%AUTHHTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START29-HANDOFF-NET-001"
  set "FAIL_REASON=Corrected agent auth module download failed over validated HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START29-HANDOFF-HTTP-001"
  set "FAIL_REASON=GitHub did not return HTTP 200 for the corrected agent auth module."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V3-LAUNCHER-HANDOFF" "%NEWAUTH%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-HANDOFF-MARKER-001"
  set "FAIL_REASON=Corrected agent auth module failed marker validation."
  goto :FATAL
)
copy /y "%NEWAUTH%" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START29-HANDOFF-COPY-001"
  set "FAIL_REASON=Corrected agent auth module could not replace the old runtime copy."
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
>>"%CONFIG%" echo SOURCE_REF=%AUTH_REF%
>>"%CONFIG%" echo SESSION_VERSION=%COMMAND_VERSION%
>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-29
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0
set "LAST_SUCCESS=Corrected agent authorization handoff staged"

call :SCREEN "RECOVERY AGENT STARTING" "Fresh GitHub authorization passed identity and repository validation. Starting RescueMeAI."
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START29-AGENT-001"
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:JGET
set "%~3="
set "PARSER_RC="
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start29-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
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
echo   Poll attempt: !COUNT! / !MAX!
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI will detect approval automatically.
echo   It will validate the new token against GitHub identity and the private recovery repository
echo   BEFORE storing it or handing it to the recovery agent.
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
>"%FAILFILE%" echo error_id=%ERROR_ID%
>>"%FAILFILE%" echo launcher_session=%COMMAND_VERSION%
>>"%FAILFILE%" echo stage=%ERROR_STAGE%
>>"%FAILFILE%" echo component=%ERROR_COMPONENT%
>>"%FAILFILE%" echo operation=%ERROR_OPERATION%
>>"%FAILFILE%" echo reason=%FAIL_REASON%
>>"%FAILFILE%" echo last_success=%LAST_SUCCESS%
>>"%FAILFILE%" echo windows_changes=NONE
>>"%FAILFILE%" echo http=%LAST_HTTP%
>>"%FAILFILE%" echo curl_return_code=%LAST_CURL%
>>"%FAILFILE%" echo identity_http=%IDENTITY_HTTP%
>>"%FAILFILE%" echo repository_http=%REPO_HTTP%
>>"%FAILFILE%" echo token_prefix=%TOKEN_PREFIX%
>>"%FAILFILE%" echo token_type=%TOKEN_TYPE%
>>"%FAILFILE%" echo parser_return=%PARSER_RC%
cls
color 0C >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                      APPLICATION FAILURE
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Windows changes  : STOPPED - NO WINDOWS REPAIR EXECUTED
echo Error ID         : %ERROR_ID%
echo ====================================================================================================
echo.
echo EXACT FAILURE LOCATION
echo ----------------------------------------------------------------------------------------------------
echo Stage            : %ERROR_STAGE%
echo Component        : %ERROR_COMPONENT%
echo Operation        : %ERROR_OPERATION%
echo Reason           : %FAIL_REASON%
echo Last success     : %LAST_SUCCESS%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status       : %LAST_HTTP%
echo curl return code : %LAST_CURL%
echo Identity HTTP    : %IDENTITY_HTTP%
echo Repository HTTP  : %REPO_HTTP%
echo Token prefix     : %TOKEN_PREFIX%
echo Token type       : %TOKEN_TYPE%
echo Parser return    : %PARSER_RC%
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
