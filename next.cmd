@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_ACTION=START_RESCUEMEAI_SESSION_TRUST_V37
rem WR_TARGET=RescueMeAI private-channel handoff only.
rem WR_CONSEQUENCE=Revalidates the already persisted GitHub credential once, installs a session-trust agent shim, then starts the existing persistent agent. No Windows recovery state is changed by this launcher.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-37"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NETSTAT=C:\Windows\System32\netstat.exe"
set "NETSH=C:\Windows\System32\netsh.exe"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "MODULE_REF=c9d2306294562e5dfe8d63191b449987ff75d1bb"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "APIIP="
set "TLS="
set "ACTIVE_ACCESS="
set "IDENTITY_HTTP=NOT_RUN"
set "REPO_HTTP=NOT_RUN"
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "LAST_SUCCESS=START-37 entered"
set "ERROR_ID=RMAI-START37-UNKNOWN"
set "ERROR_STAGE=STARTUP"
set "ERROR_COMPONENT=bootstrap"
set "ERROR_OPERATION=initialize secure session handoff"
set "FAIL_REASON=RescueMeAI could not establish the validated private recovery session."
set "FAILFILE=%WORK%\START37_FAILURE.txt"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
if exist "%FAILFILE%" del /f /q /a "%FAILFILE%" >nul 2>&1

if not exist "%CURL%" (
  set "ERROR_ID=RMAI-START37-DEP-CURL-001"
  set "FAIL_REASON=Required curl.exe is missing."
  goto :FATAL
)
if not exist "%FINDSTR%" (
  set "ERROR_ID=RMAI-START37-DEP-FINDSTR-001"
  set "FAIL_REASON=Required findstr.exe is missing."
  goto :FATAL
)
if not exist "%AGENT%" (
  set "ERROR_ID=RMAI-START37-DEP-AGENT-001"
  set "FAIL_REASON=The persistent RescueMeAI agent is missing."
  goto :FATAL
)
if not exist "%TOKEN%" (
  set "ERROR_ID=RMAI-START37-TOKEN-MISSING-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=github-logs.token"
  set "ERROR_OPERATION=load START-36 persisted credential"
  set "FAIL_REASON=The launcher-validated saved credential is missing."
  goto :FATAL
)
for %%F in (network.cmd resolve.cmd reporting.cmd safety.cmd agent-core.js ui.cmd) do (
  if not exist "%RUNTIME%\%%F" (
    set "ERROR_ID=RMAI-START37-RUNTIME-001"
    set "ERROR_STAGE=RUNTIME HANDOFF"
    set "ERROR_COMPONENT=%%F"
    set "ERROR_OPERATION=validate existing runtime"
    set "FAIL_REASON=Required runtime module %%F is missing."
    goto :FATAL
  )
)

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if not defined APIIP (
  set "ERROR_ID=RMAI-START37-ROUTE-001"
  set "ERROR_STAGE=NETWORK ROUTE"
  set "ERROR_COMPONENT=api.github.com"
  set "ERROR_OPERATION=load validated cached HTTPS route"
  set "FAIL_REASON=The validated api.github.com route cache is missing."
  goto :FATAL
)
set "LAST_SUCCESS=Local runtime and validated GitHub HTTPS route loaded"

rem Non-blocking network exposure snapshot. Never fail recovery because these tools are optional in WinRE.
>"%WORK%\NETWORK_EXPOSURE.txt" echo RESCUEMEAI NETWORK EXPOSURE SNAPSHOT
>>"%WORK%\NETWORK_EXPOSURE.txt" echo launcher=%COMMAND_VERSION%
>>"%WORK%\NETWORK_EXPOSURE.txt" echo transport=HTTPS_TLS_CERTIFICATE_VALIDATION_ENABLED
if exist "%NETSTAT%" (
  >>"%WORK%\NETWORK_EXPOSURE.txt" echo.
  >>"%WORK%\NETWORK_EXPOSURE.txt" echo --- NETSTAT -ANO ---
  "%NETSTAT%" -ano >>"%WORK%\NETWORK_EXPOSURE.txt" 2>&1
)
if exist "%NETSH%" (
  >>"%WORK%\NETWORK_EXPOSURE.txt" echo.
  >>"%WORK%\NETWORK_EXPOSURE.txt" echo --- FIREWALL STATE ---
  "%NETSH%" advfirewall show allprofiles state >>"%WORK%\NETWORK_EXPOSURE.txt" 2>&1
)

set /p "ACTIVE_ACCESS="<"%TOKEN%"
if not defined ACTIVE_ACCESS (
  set "ERROR_ID=RMAI-START37-TOKEN-EMPTY-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=github-logs.token"
  set "ERROR_OPERATION=read persisted credential"
  set "FAIL_REASON=The saved credential file is empty or unreadable."
  goto :FATAL
)

call :SCREEN "SECURE CHANNEL VALIDATION" "Revalidating the exact credential START-36 already persisted. No Windows repair is running."

set "OUT=%WORK%\start37-user.json"
set "HTTP=%WORK%\start37-user-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start37-user-curl.txt"
set "LAST_CURL=!errorlevel!"
set "IDENTITY_HTTP="
if exist "%HTTP%" set /p "IDENTITY_HTTP="<"%HTTP%"
set "LAST_HTTP=!IDENTITY_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START37-IDENTITY-NET-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=GitHub user identity"
  set "ERROR_OPERATION=validate persisted credential against GET /user"
  set "FAIL_REASON=HTTPS transport failed while validating the persisted credential."
  goto :FATAL
)
if not "!IDENTITY_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START37-IDENTITY-HTTP-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=GitHub user identity"
  set "ERROR_OPERATION=validate persisted credential against GET /user"
  set "FAIL_REASON=The persisted credential is no longer accepted by GitHub."
  goto :FATAL
)
set "LAST_SUCCESS=Persisted credential accepted by GitHub user identity"

set "OUT=%WORK%\start37-repo.json"
set "HTTP=%WORK%\start37-repo-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%OUT%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start37-repo-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_HTTP="
if exist "%HTTP%" set /p "REPO_HTTP="<"%HTTP%"
set "LAST_HTTP=!REPO_HTTP!"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START37-REPO-NET-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=private recovery repository"
  set "ERROR_OPERATION=validate private repository access"
  set "FAIL_REASON=HTTPS transport failed while validating the private recovery repository."
  goto :FATAL
)
if not "!REPO_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START37-REPO-HTTP-001"
  set "ERROR_STAGE=TOKEN VALIDATION"
  set "ERROR_COMPONENT=private recovery repository"
  set "ERROR_OPERATION=validate private repository access"
  set "FAIL_REASON=The persisted credential cannot access the private recovery repository."
  goto :FATAL
)
set "LAST_SUCCESS=Persisted credential accepted by identity and private repository"

rem Write the current session configuration.
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

rem Stage the deliberately small session-trust auth/reporting shim.
set "NEWAUTH=%WORK%\github-auth-session-trust-stage.cmd"
set "HTTP=%WORK%\start37-auth-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACTIVE_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%SOURCE_REPO%/contents/lib/github-auth-session-trust.cmd?ref=%MODULE_REF%" -o "%NEWAUTH%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\start37-auth-curl.txt"
set "LAST_CURL=!errorlevel!"
set "LAST_HTTP="
if exist "%HTTP%" set /p "LAST_HTTP="<"%HTTP%"
if not "!LAST_CURL!"=="0" (
  set "ERROR_ID=RMAI-START37-SHIM-NET-001"
  set "ERROR_STAGE=RUNTIME HANDOFF"
  set "ERROR_COMPONENT=github-auth-session-trust.cmd"
  set "ERROR_OPERATION=download session-trust auth shim"
  set "FAIL_REASON=The session-trust module could not be downloaded over validated HTTPS."
  goto :FATAL
)
if not "!LAST_HTTP!"=="200" (
  set "ERROR_ID=RMAI-START37-SHIM-HTTP-001"
  set "ERROR_STAGE=RUNTIME HANDOFF"
  set "ERROR_COMPONENT=github-auth-session-trust.cmd"
  set "ERROR_OPERATION=download session-trust auth shim"
  set "FAIL_REASON=GitHub did not return the session-trust module."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V6-SESSION-TRUST" "%NEWAUTH%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START37-SHIM-MARKER-001"
  set "ERROR_STAGE=RUNTIME HANDOFF"
  set "ERROR_COMPONENT=github-auth-session-trust.cmd"
  set "ERROR_OPERATION=validate session-trust module marker"
  set "FAIL_REASON=The downloaded session-trust module failed marker validation."
  goto :FATAL
)
copy /y "%NEWAUTH%" "%RUNTIME%\github-auth.cmd" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START37-SHIM-COPY-001"
  set "ERROR_STAGE=RUNTIME HANDOFF"
  set "ERROR_COMPONENT=github-auth.cmd"
  set "ERROR_OPERATION=install session-trust auth shim"
  set "FAIL_REASON=The session-trust module could not replace the old agent authorization module."
  goto :FATAL
)
set "LAST_SUCCESS=Session-trust agent authorization shim installed"

rem Preserve the validated local runtime. Do not synchronize older auth logic over it.
>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-37
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0

call :SCREEN "RECOVERY AGENT STARTING" "Private HTTPS channel validated. Starting the existing RescueMeAI agent."
set "ACTIVE_ACCESS="
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "ERROR_ID=RMAI-START37-AGENT-001"
set "ERROR_STAGE=AGENT START"
set "ERROR_COMPONENT=wr-agent-v2.cmd"
set "ERROR_OPERATION=start persistent recovery listener"
set "FAIL_REASON=The persistent RescueMeAI agent stopped unexpectedly with return code !ARC!."
goto :FATAL

:SCREEN
cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Transport        : HTTPS / TLS - certificate validation retained
echo Private channel  : GitHub private repository
echo Status           : %~1
echo Windows changes  : NONE BY THIS LAUNCHER
echo ====================================================================================================
echo.
echo %~2
echo.
echo Network safety snapshot: C:\WinRERepair\NETWORK_EXPOSURE.txt
echo PLEASE WAIT - no action is required unless RescueMeAI explicitly asks.
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
>>"%FAILFILE%" echo api_cached_ip=%APIIP%
>>"%FAILFILE%" echo transport=HTTPS_TLS_CERTIFICATE_VALIDATION_RETAINED
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
echo Stage            : %ERROR_STAGE%
echo Component        : %ERROR_COMPONENT%
echo Operation        : %ERROR_OPERATION%
echo Reason           : %FAIL_REASON%
echo Last success     : %LAST_SUCCESS%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status       : %LAST_HTTP%
echo curl return code  : %LAST_CURL%
echo Identity HTTP     : %IDENTITY_HTTP%
echo Repository HTTP   : %REPO_HTTP%
echo API cached IP     : %APIIP%
echo Transport         : HTTPS/TLS; certificate validation retained
echo.
echo LOCAL EVIDENCE
echo ----------------------------------------------------------------------------------------------------
echo %FAILFILE%
echo C:\WinRERepair\NETWORK_EXPOSURE.txt
echo.
echo No Windows repair action was executed by this startup failure.
echo Press a key only after you have read or photographed this screen.
echo ====================================================================================================
pause
exit /b 90
