@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=START_RESCUEMEAI_ATOMIC_AUTH_HANDOFF_V36
rem WR_TARGET=RescueMeAI private-channel authorization and persistent-agent handoff only.
rem WR_CONSEQUENCE=Obtains a fresh GitHub authorization, atomically persists and revalidates it, stages detailed agent diagnostics, then starts the agent. No Windows recovery state is changed.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-36"
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
set "JOUT=%WORK%\start36-jget.txt"
set "FAILFILE=%WORK%\START36_FAILURE.txt"
set "AUTHRESULT=%WORK%\GITHUB_RESULT.txt"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "MODULE_REF=5ce199b726cda2164b6fbdaa37e35f828954a94e"
set "APIIP="
set "WEBIP="
set "TLS="
set "ACTIVE_ACCESS="
set "CANDIDATE_REFRESH="
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "IDENTITY_HTTP=NOT_RUN"
set "REPO_HTTP=NOT_RUN"
set "AUTHRC=NOT_RUN"
set "PERSIST_STATE=NOT_RUN"
set "LAST_SUCCESS=START-36 entered"
set "ERROR_ID=RMAI-START36-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialize atomic authorization handoff"
set "FAIL_REASON=RescueMeAI could not establish a validated private recovery channel."

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

for %%F in ("%CURL%" "%FINDSTR%" "%CSCRIPT%" "%PING%" "%AGENT%" "%HELPER%") do (
  if not exist %%F (
    set "ERROR_ID=RMAI-START36-DEP-001"
    set "ERROR_STAGE=STARTUP"
    set "ERROR_COMPONENT=dependencies"
    set "ERROR_OPERATION=validate local components"
    set "FAIL_REASON=Required component is missing: %%~nxF"
    goto :FATAL
  )
)
for %%F in (network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js ui.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "ERROR_ID=RMAI-START36-RUNTIME-001"
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
  set "ERROR_ID=RMAI-START36-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated api.github.com route cache is missing."
  goto :FATAL
)
if not defined WEBIP (
  set "ERROR_ID=RMAI-START36-ROUTE-002"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=github.com"
  set "ERROR_OPERATION=load validated cached route"
  set "FAIL_REASON=Validated github.com route cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Validated cached GitHub HTTPS routes loaded"

rem Prove the already-working JSON helper before contacting GitHub.
>"%WORK%\start36-selftest.json" echo {"device_code":"JSON_OK"}
call :JGET "%WORK%\start36-selftest.json" device_code SELFTEST
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-PARSER-001"
  set "ERROR_STAGE=AUTH PARSER SELF-TEST"
  set "ERROR_COMPONENT=%HELPER%"
  set "ERROR_OPERATION=parse synthetic JSON"
  set "FAIL_REASON=The local JSON parser failed its self-test."
  goto :FATAL
)
if /i not "!SELFTEST!"=="JSON_OK" (
  set "ERROR_ID=RMAI-START36-PARSER-002"
  set "FAIL_REASON=The local JSON parser returned the wrong self-test value."
  goto :FATAL
)
set "LAST_SUCCESS=Local JSON parser self-test passed"

goto :REQUEST_DEVICE

:REQUEST_DEVICE
set "ERROR_STAGE=DEVICE AUTHORIZATION"
set "ERROR_COMPONENT=GitHub device-code endpoint"
set "ERROR_OPERATION=request fresh device authorization metadata"
set "DEV=%WORK%\start36-device.json"
set "DEVHTTP=%WORK%\start36-device-http.txt"
for %%F in ("%DEV%" "%DEVHTTP%") do (
  if exist %%F del /f /q %%F >nul 2>&1
)
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%DEVHTTP%" 2>"%WORK%\start36-device-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%DEVHTTP%" set /p "LAST_HTTP="<"%DEVHTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START36-OAUTH-NET-001"
  set "FAIL_REASON=GitHub device-code request failed over HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START36-OAUTH-HTTP-001"
  set "FAIL_REASON=GitHub device-code endpoint did not return HTTP 200."
  goto :FATAL
)
call :JGET "%DEV%" device_code DEVICE_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-OAUTH-PARSE-001"
  set "ERROR_OPERATION=parse device_code"
  set "FAIL_REASON=GitHub returned HTTP 200 but device_code could not be parsed."
  goto :FATAL
)
call :JGET "%DEV%" user_code USER_CODE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-OAUTH-PARSE-002"
  set "ERROR_OPERATION=parse user_code"
  set "FAIL_REASON=GitHub returned device metadata but user_code could not be parsed."
  goto :FATAL
)
set "EXPIRES=900"
set "INTERVAL=5"
call :JGET "%DEV%" expires_in EXPIRES_TMP
if not errorlevel 1 if defined EXPIRES_TMP set "EXPIRES=!EXPIRES_TMP!"
call :JGET "%DEV%" interval INTERVAL_TMP
if not errorlevel 1 if defined INTERVAL_TMP set "INTERVAL=!INTERVAL_TMP!"
set /a MAX=(EXPIRES/INTERVAL)+4 >nul 2>&1
if !MAX! LSS 10 set "MAX=180"
set /a COUNT=0
set "POLL_STATE=Waiting for approval on your phone"
set "LAST_SUCCESS=Fresh GitHub device code ready for approval"

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
  set "ERROR_ID=RMAI-START36-WAIT-001"
  set "ERROR_STAGE=DEVICE AUTHORIZATION"
  set "ERROR_COMPONENT=ping.exe"
  set "ERROR_OPERATION=wait between authorization polls"
  set "FAIL_REASON=WinRE could not perform the authorization polling delay."
  goto :FATAL
)
set "TOK=%WORK%\start36-token.json"
set "TOKHTTP=%WORK%\start36-token-http.txt"
for %%F in ("%TOK%" "%TOKHTTP%") do (
  if exist %%F del /f /q %%F >nul 2>&1
)
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "github.com:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%TOKHTTP%" 2>"%WORK%\start36-token-curl.txt"
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
set "ACTIVE_ACCESS="
set "CANDIDATE_REFRESH="
set "OAUTH_ERROR="
call :JGET "%TOK%" access_token ACTIVE_ACCESS
if not errorlevel 1 if defined ACTIVE_ACCESS goto :TOKEN_RECEIVED
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
  set "ERROR_ID=RMAI-START36-OAUTH-DENIED-001"
  set "FAIL_REASON=GitHub device authorization was denied."
  goto :FATAL
)
set "POLL_STATE=Waiting for GitHub authorization completion"
goto :DEVICE_POLL

:TOKEN_RECEIVED
call :JGET "%TOK%" refresh_token CANDIDATE_REFRESH
set "LAST_SUCCESS=GitHub returned a candidate access credential"

rem Validate the candidate while it is still only in memory.
call :VALIDATE_ACTIVE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-CANDIDATE-VALIDATION-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=GitHub candidate credential"
  set "ERROR_OPERATION=validate in-memory credential"
  set "FAIL_REASON=GitHub returned a credential but identity or private-repository validation failed."
  goto :FATAL
)
set "LAST_SUCCESS=In-memory credential validated for identity and private repository"

rem Persist the credential atomically, then validate the exact bytes read back from disk.
call :STORE_ATOMIC
if errorlevel 1 goto :FATAL
set "ACTIVE_ACCESS="
set /p "ACTIVE_ACCESS="<"%TOKEN%"
if not defined ACTIVE_ACCESS (
  set "ERROR_ID=RMAI-START36-PERSIST-READBACK-001"
  set "ERROR_STAGE=CREDENTIAL PERSISTENCE"
  set "ERROR_COMPONENT=github-logs.token"
  set "ERROR_OPERATION=read final persisted credential"
  set "FAIL_REASON=The final credential file exists but could not be read back."
  set "PERSIST_STATE=FINAL_READ_FAILED"
  goto :FATAL
)
set "PERSIST_STATE=FINAL_READ_OK"
call :VALIDATE_ACTIVE
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-PERSIST-VALIDATION-001"
  set "ERROR_STAGE=CREDENTIAL PERSISTENCE"
  set "ERROR_COMPONENT=github-logs.token"
  set "ERROR_OPERATION=validate exact persisted credential"
  set "FAIL_REASON=The credential worked in memory but the persisted copy was rejected by GitHub."
  set "PERSIST_STATE=FINAL_VALIDATION_FAILED"
  goto :FATAL
)
set "PERSIST_STATE=FINAL_VALIDATION_PASS"
set "LAST_SUCCESS=Exact persisted credential validated for identity and private repository"

goto :AUTHORIZED

:STORE_ATOMIC
set "ERROR_STAGE=CREDENTIAL PERSISTENCE"
set "ERROR_COMPONENT=GitHub credential files"
set "ERROR_OPERATION=atomically replace hidden saved authorization"
set "PERSIST_STATE=WRITING_TEMP"
set "TOKEN_NEW=%AUTHDIR%\github-logs.token.new"
set "REFRESH_NEW=%AUTHDIR%\github-refresh.token.new"
for %%F in ("%TOKEN_NEW%" "%REFRESH_NEW%") do (
  if exist %%F attrib -h -s -r %%F >nul 2>&1
  if exist %%F del /f /q /a %%F >nul 2>&1
)
>"%TOKEN_NEW%" echo(!ACTIVE_ACCESS!
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-PERSIST-TEMP-WRITE-001"
  set "FAIL_REASON=RescueMeAI could not write the temporary access-token file."
  exit /b 1
)
set "VERIFY_ACCESS="
set /p "VERIFY_ACCESS="<"%TOKEN_NEW%"
if not defined VERIFY_ACCESS (
  set "ERROR_ID=RMAI-START36-PERSIST-TEMP-READ-001"
  set "FAIL_REASON=The temporary access-token file could not be read back."
  exit /b 1
)
if not "!VERIFY_ACCESS!"=="!ACTIVE_ACCESS!" (
  set "ERROR_ID=RMAI-START36-PERSIST-TEMP-MISMATCH-001"
  set "FAIL_REASON=The temporary access-token file did not match the validated in-memory credential."
  exit /b 1
)
if defined CANDIDATE_REFRESH (
  >"%REFRESH_NEW%" echo(!CANDIDATE_REFRESH!
  if errorlevel 1 (
    set "ERROR_ID=RMAI-START36-PERSIST-REFRESH-WRITE-001"
    set "FAIL_REASON=RescueMeAI could not write the temporary refresh-token file."
    exit /b 1
  )
)
set "PERSIST_STATE=TEMP_VERIFIED"
if exist "%TOKEN%" attrib -h -s -r "%TOKEN%" >nul 2>&1
if exist "%TOKEN%" del /f /q /a "%TOKEN%" >nul 2>&1
if exist "%TOKEN%" (
  set "ERROR_ID=RMAI-START36-PERSIST-OLD-DELETE-001"
  set "FAIL_REASON=The old hidden access-token file could not be removed."
  exit /b 1
)
move /y "%TOKEN_NEW%" "%TOKEN%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-PERSIST-MOVE-001"
  set "FAIL_REASON=The verified temporary access token could not be promoted to the live credential file."
  exit /b 1
)
if not exist "%TOKEN%" (
  set "ERROR_ID=RMAI-START36-PERSIST-MISSING-001"
  set "FAIL_REASON=The live access-token file is missing after atomic replacement."
  exit /b 1
)
attrib +h +s "%TOKEN%" >nul 2>&1
if exist "%REFRESH%" attrib -h -s -r "%REFRESH%" >nul 2>&1
if exist "%REFRESH%" del /f /q /a "%REFRESH%" >nul 2>&1
if defined CANDIDATE_REFRESH (
  move /y "%REFRESH_NEW%" "%REFRESH%" >nul 2>&1
  if errorlevel 1 (
    set "ERROR_ID=RMAI-START36-PERSIST-REFRESH-MOVE-001"
    set "FAIL_REASON=The verified refresh token could not be promoted to the live credential file."
    exit /b 1
  )
  attrib +h +s "%REFRESH%" >nul 2>&1
)
set "PERSIST_STATE=ATOMIC_REPLACE_COMPLETE"
exit /b 0

:VALIDATE_ACTIVE
set "ERROR_STAGE=TOKEN VALIDATION"
set "ERROR_COMPONENT=GitHub user identity"
set "ERROR_OPERATION=validate credential against GET /user"
set "OUT=%WORK%\start36-user-test.json"
set "HTTP=%WORK%\start36-user-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start36-user-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "IDENTITY_HTTP="
if exist "%HTTP%" set /p "IDENTITY_HTTP="<"%HTTP%"
set "LAST_HTTP=!IDENTITY_HTTP!"
if not "!LAST_CURL!"=="0" exit /b 1
if not "!IDENTITY_HTTP!"=="200" exit /b 1
set "LAST_SUCCESS=GitHub accepted credential for user identity"
set "ERROR_COMPONENT=private GitHub recovery repository"
set "ERROR_OPERATION=validate private recovery repository access"
set "OUT=%WORK%\start36-repo-test.json"
set "HTTP=%WORK%\start36-repo-test-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start36-repo-test-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_HTTP="
if exist "%HTTP%" set /p "REPO_HTTP="<"%HTTP%"
set "LAST_HTTP=!REPO_HTTP!"
if not "!LAST_CURL!"=="0" exit /b 1
if not "!REPO_HTTP!"=="200" exit /b 1
set "LAST_SUCCESS=GitHub accepted credential for private recovery repository"
exit /b 0

:AUTHORIZED
>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%MODULE_REF%
>>"%CONFIG%" echo SESSION_VERSION=%COMMAND_VERSION%
>"%WORK%\session-version.txt" echo %COMMAND_VERSION%

rem Stage the atomic-persistence agent authorization module using the validated persisted credential.
set "ERROR_STAGE=RUNTIME HANDOFF"
set "ERROR_COMPONENT=github-auth-v5-agent.cmd"
set "ERROR_OPERATION=stage atomic agent authorization module"
set "NEWAUTH=%WORK%\github-auth-v5-agent-stage.cmd"
set "HTTP=%WORK%\start36-auth-download-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth-v5-agent.cmd?ref=%MODULE_REF%" -o "%NEWAUTH%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start36-auth-download-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START36-HANDOFF-NET-001"
  set "FAIL_REASON=Atomic agent authorization module download failed over HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START36-HANDOFF-HTTP-001"
  set "FAIL_REASON=GitHub did not return HTTP 200 for the atomic agent authorization module."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V5-ATOMIC-CREDENTIALS" "%NEWAUTH%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-HANDOFF-MARKER-001"
  set "FAIL_REASON=The staged atomic authorization module failed marker validation."
  goto :FATAL
)
copy /y "%NEWAUTH%" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-HANDOFF-COPY-001"
  set "FAIL_REASON=The atomic authorization module could not replace the old runtime copy."
  goto :FATAL
)
set "LAST_SUCCESS=Atomic agent authorization module staged"

rem Preflight the exact authorize operation the persistent agent will call.
if exist "%AUTHRESULT%" del /f /q "%AUTHRESULT%" >nul 2>&1
call "%RUNTIME%\github-auth.cmd" authorize "%CONFIG%"
set "AUTHRC=!errorlevel!"
if not "!AUTHRC!"=="0" (
  call :LOAD_AUTH_RESULT
  set "ERROR_ID=RMAI-START36-AGENT-AUTH-PREFLIGHT-001"
  set "ERROR_STAGE=AGENT AUTH PREFLIGHT"
  set "ERROR_COMPONENT=!GR_COMPONENT!"
  set "ERROR_OPERATION=run exact persistent-agent authorization check against persisted credential"
  set "FAIL_REASON=!GR_REASON!"
  set "LAST_HTTP=!GR_HTTP!"
  set "LAST_CURL=!GR_CURL!"
  set "IDENTITY_HTTP=!GR_IDHTTP!"
  set "REPO_HTTP=!GR_REPOHTTP!"
  set "LAST_SUCCESS=!GR_LAST!"
  goto :FATAL
)
set "LAST_SUCCESS=Exact persistent-agent authorization preflight passed"

rem Preserve current renderer core and install detailed warning proxy.
"%FINDSTR%" /i /c:"WR-MODULE: ui-warning-proxy" "%RUNTIME%\ui.cmd" >nul 2>&1
if errorlevel 1 copy /y "%RUNTIME%\ui.cmd" "%RUNTIME%\ui-core.cmd" >nul 2>&1
if not exist "%RUNTIME%\ui-core.cmd" (
  set "ERROR_ID=RMAI-START36-UI-CORE-001"
  set "ERROR_STAGE=UI HANDOFF"
  set "ERROR_COMPONENT=ui-core.cmd"
  set "ERROR_OPERATION=preserve existing UI renderer"
  set "FAIL_REASON=RescueMeAI could not preserve the existing UI renderer."
  goto :FATAL
)
set "NEWUI=%WORK%\ui-warning-proxy-stage.cmd"
set "HTTP=%WORK%\start36-ui-download-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/ui-warning-proxy.cmd?ref=%MODULE_REF%" -o "%NEWUI%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start36-ui-download-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START36-UI-NET-001"
  set "ERROR_STAGE=UI HANDOFF"
  set "ERROR_COMPONENT=ui-warning-proxy.cmd"
  set "ERROR_OPERATION=download detailed retry UI"
  set "FAIL_REASON=The detailed retry UI could not be downloaded over validated HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START36-UI-HTTP-001"
  set "FAIL_REASON=GitHub did not return HTTP 200 for the detailed retry UI."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: ui-warning-proxy 2026.08.15-V1" "%NEWUI%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-UI-MARKER-001"
  set "FAIL_REASON=The detailed retry UI failed marker validation."
  goto :FATAL
)
copy /y "%NEWUI%" "%RUNTIME%\ui.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START36-UI-COPY-001"
  set "FAIL_REASON=The detailed retry UI could not replace the runtime UI proxy."
  goto :FATAL
)
set "LAST_SUCCESS=Detailed retry UI staged"

rem Keep the validated local runtime for this recovery session.
>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-36
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd ui-core.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "RECOVERY AGENT STARTING" "Credential persistence and exact agent authorization preflight passed. Starting RescueMeAI."
set "ACTIVE_ACCESS="
set "CANDIDATE_REFRESH="
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START36-AGENT-001"
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:JGET
set "%~3="
if exist "%JOUT%" del /f /q "%JOUT%" >nul 2>&1
"%CSCRIPT%" //nologo "%HELPER%" "%~1" "%~2" >"%JOUT%" 2>"%WORK%\start36-jget-error.txt"
set "PARSER_RC=!errorlevel!"
if not "!PARSER_RC!"=="0" exit /b 1
set "JV="
set /p "JV="<"%JOUT%"
if not defined JV exit /b 1
set "%~3=!JV!"
set "JV="
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

:LOAD_AUTH_RESULT
set "GR_COMPONENT=github-auth-v5-agent"
set "GR_REASON=Persistent-agent authorization preflight failed without a structured reason."
set "GR_HTTP=N/A"
set "GR_CURL=N/A"
set "GR_IDHTTP=N/A"
set "GR_REPOHTTP=N/A"
set "GR_LAST=Not recorded"
if exist "%AUTHRESULT%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%AUTHRESULT%") do (
    if /i "%%A"=="component" set "GR_COMPONENT=%%B"
    if /i "%%A"=="reason" set "GR_REASON=%%B"
    if /i "%%A"=="http" set "GR_HTTP=%%B"
    if /i "%%A"=="curl_return_code" set "GR_CURL=%%B"
    if /i "%%A"=="identity_http" set "GR_IDHTTP=%%B"
    if /i "%%A"=="repository_http" set "GR_REPOHTTP=%%B"
    if /i "%%A"=="last_success" set "GR_LAST=%%B"
  )
)
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
echo   RescueMeAI will validate the new credential in memory, save it atomically,
echo   read the exact saved copy back, validate that persisted copy again, then preflight the agent.
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
>>"%FAILFILE%" echo persistence_state=%PERSIST_STATE%
>>"%FAILFILE%" echo http=%LAST_HTTP%
>>"%FAILFILE%" echo curl_return_code=%LAST_CURL%
>>"%FAILFILE%" echo identity_http=%IDENTITY_HTTP%
>>"%FAILFILE%" echo repository_http=%REPO_HTTP%
>>"%FAILFILE%" echo agent_auth_return=%AUTHRC%
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
echo Stage             : %ERROR_STAGE%
echo Component         : %ERROR_COMPONENT%
echo Operation         : %ERROR_OPERATION%
echo Reason            : %FAIL_REASON%
echo Last success      : %LAST_SUCCESS%
echo Persistence state : %PERSIST_STATE%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status        : %LAST_HTTP%
echo curl return code   : %LAST_CURL%
echo Identity HTTP      : %IDENTITY_HTTP%
echo Repository HTTP    : %REPO_HTTP%
echo Agent auth return  : %AUTHRC%
echo API cached IP      : %APIIP%
echo Web cached IP      : %WEBIP%
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
