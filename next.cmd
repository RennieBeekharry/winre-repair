@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Repair RescueMeAI launcher-to-agent authorization handoff and expose session version.
rem WR_ACTION=START_RESCUEMEAI_AGENT_HANDOFF_V27
rem WR_TARGET=RescueMeAI runtime authentication and UI handoff only.
rem WR_CONSEQUENCE=Stages a corrected runtime auth module and starts the existing agent. No Windows recovery state is changed.
rem WR_ROLLBACK=Runtime-only startup operation.

set "COMMAND_VERSION=RMAI-2026.08.15-AGENT-START-27"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "APIIP="
set "TLS="
set "ACCESS="
set "HTTP=NOT_RUN"
set "CURLRC=NOT_RUN"
set "FAIL_REASON=RescueMeAI could not repair the agent authorization handoff."
set "ERROR_ID=RMAI-START27-UNKNOWN"
set "STAGE=STARTUP"
set "COMPONENT=handoff"
set "OPERATION=initialize"
set "LAST_SUCCESS=START-27 entered"
set "AUTH_REF=825b988ca2cafe20e97856c391f6d02bcc0b6c6a"
set "AUTH_TMP=%WORK%\github-auth-v3.new.cmd"
set "AUTH_DST=%RUNTIME%\github-auth.cmd"
set "UI=%RUNTIME%\ui.cmd"
set "UIBASE=%RUNTIME%\ui-base.cmd"
set "FAILFILE=%WORK%\START27_FAILURE.txt"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if exist "%FAILFILE%" del /f /q "%FAILFILE%" >nul 2>&1
if exist "%WORK%\GITHUB_RESULT.txt" del /f /q /a "%WORK%\GITHUB_RESULT.txt" >nul 2>&1

set "STAGE=DEPENDENCY CHECK"
set "COMPONENT=WinRE runtime"
set "OPERATION=validate required local files"
for %%F in ("%CURL%" "%FINDSTR%" "%TOKEN%" "%CONFIG%" "%AGENT%" "%UI%") do if not exist %%F (
  set "ERROR_ID=RMAI-START27-DEP-001"
  set "FAIL_REASON=Required local dependency is missing: %%~fF"
  goto :FATAL
)
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if not defined APIIP (
  set "ERROR_ID=RMAI-START27-ROUTE-001"
  set "FAIL_REASON=Validated api.github.com route cache is missing."
  goto :FATAL
)
"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
set "LAST_SUCCESS=Local runtime and cached HTTPS route validated"

set "STAGE=TOKEN VALIDATION"
set "COMPONENT=private GitHub repository"
set "OPERATION=verify launcher-issued saved token"
set /p "ACCESS="<"%TOKEN%"
if not defined ACCESS (
  set "ERROR_ID=RMAI-START27-TOKEN-001"
  set "FAIL_REASON=Saved GitHub access token file is empty."
  goto :FATAL
)
set "TESTOUT=%WORK%\start27-token-test.json"
set "TESTHTTP=%WORK%\start27-token-http.txt"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/1333818657" -o "%TESTOUT%" -w "%%{http_code}" >"%TESTHTTP%" 2>"%WORK%\start27-token-curl.txt"
set "CURLRC=!errorlevel!"
set "HTTP="
if exist "%TESTHTTP%" set /p "HTTP="<"%TESTHTTP%"
if not "!CURLRC!"=="0" (
  set "ERROR_ID=RMAI-START27-TOKEN-TRANSPORT-001"
  set "FAIL_REASON=Saved token validation could not reach GitHub over the cached TLS route."
  goto :FATAL
)
if not "!HTTP!"=="200" (
  set "ERROR_ID=RMAI-START27-TOKEN-HTTP-001"
  set "FAIL_REASON=Saved launcher token no longer has validated access to the private recovery repository."
  goto :FATAL
)
set "LAST_SUCCESS=Saved launcher token validated against private recovery repository"

set "STAGE=RUNTIME PATCH"
set "COMPONENT=github-auth.cmd"
set "OPERATION=stage corrected launcher-to-agent auth module"
if exist "%AUTH_TMP%" del /f /q "%AUTH_TMP%" >nul 2>&1
"%CURL%" %TLS% --fail --silent --show-error --connect-timeout 15 --max-time 120 --resolve "api.github.com:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/RennieBeekharry/winre-repair/contents/lib/github-auth.cmd?ref=%AUTH_REF%" -o "%AUTH_TMP%" 2>"%WORK%\start27-auth-download-curl.txt"
set "CURLRC=!errorlevel!"
if not "!CURLRC!"=="0" (
  set "ERROR_ID=RMAI-START27-AUTH-DOWNLOAD-001"
  set "FAIL_REASON=Corrected runtime authorization module could not be staged over HTTPS."
  goto :FATAL
)
"%FINDSTR%" /i /c:"WR-MODULE: github-auth 2026.08.15-V3-LAUNCHER-HANDOFF" "%AUTH_TMP%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START27-AUTH-MARKER-001"
  set "FAIL_REASON=Corrected runtime authorization module failed marker validation."
  goto :FATAL
)
copy /y "%AUTH_TMP%" "%AUTH_DST%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START27-AUTH-INSTALL-001"
  set "FAIL_REASON=Corrected runtime authorization module could not replace the old local module."
  goto :FATAL
)
set "LAST_SUCCESS=Corrected agent authorization module installed locally"

set "STAGE=UI HANDOFF"
set "COMPONENT=ui.cmd"
set "OPERATION=add launcher/session version to persistent agent screens"
if not exist "%UIBASE%" (
  copy /y "%UI%" "%UIBASE%" >nul 2>&1
  if errorlevel 1 (
    set "ERROR_ID=RMAI-START27-UI-BACKUP-001"
    set "FAIL_REASON=Could not preserve the existing RescueMeAI UI renderer."
    goto :FATAL
  )
)
>"%UI%" echo @echo off
>>"%UI%" echo setlocal EnableExtensions EnableDelayedExpansion
>>"%UI%" echo set "BASE=C:\WinRERepair\runtime\ui-base.cmd"
>>"%UI%" echo set "SESSION=UNKNOWN"
>>"%UI%" echo if exist "C:\WinRERepair\agent.cfg" for /f "usebackq tokens=1,* delims==" %%%%A in ^("C:\WinRERepair\agent.cfg"^) do if /i "%%%%A"=="SESSION_VERSION" set "SESSION=%%%%B"
>>"%UI%" echo call "%%BASE%%" %%*
>>"%UI%" echo set "RC=!errorlevel!"
>>"%UI%" echo if /i "%%~1"=="screen" echo Launcher/session: !SESSION!
>>"%UI%" echo exit /b !RC!
"%FINDSTR%" /i /c:"Launcher/session" "%UI%" >nul 2>&1
if errorlevel 1 (
  set "ERROR_ID=RMAI-START27-UI-WRAP-001"
  set "FAIL_REASON=Launcher/session version UI wrapper failed validation."
  goto :FATAL
)
set "LAST_SUCCESS=Persistent agent UI now exposes launcher/session version"

set "STAGE=CONFIGURATION"
set "COMPONENT=agent.cfg"
set "OPERATION=record START-27 session and source settings"
>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=4595411
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=1333818657
>>"%CONFIG%" echo SOURCE_REPO=RennieBeekharry/winre-repair
>>"%CONFIG%" echo SOURCE_REF=%AUTH_REF%
>>"%CONFIG%" echo SESSION_VERSION=%COMMAND_VERSION%
>"%RUNTIME%\runtime-sync.cmd" echo @echo off
>>"%RUNTIME%\runtime-sync.cmd" echo setlocal EnableExtensions
>>"%RUNTIME%\runtime-sync.cmd" echo rem WR-MODULE: runtime-local-ready 2026.08.15-START-27
>>"%RUNTIME%\runtime-sync.cmd" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%RUNTIME%\runtime-sync.cmd" echo for %%%%F in ^(ui.cmd ui-base.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%RUNTIME%\runtime-sync.cmd" echo exit /b 0
set "ACCESS="
set "LAST_SUCCESS=START-27 runtime handoff prepared"

cls
color 0B >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                    AI-ASSISTED WINDOWS RECOVERY
echo ====================================================================================================
echo Launcher/session : %COMMAND_VERSION%
echo Agent runtime    : RMAI-AGENT-V2-2026.08.14-1508-ET
echo Status           : STARTING PERSISTENT AGENT
echo Windows changes  : NONE
echo ====================================================================================================
echo.
echo Corrected private-channel authorization has been staged.
echo RescueMeAI is starting the persistent recovery listener automatically.
echo.
call "%AGENT%"
set "ARC=!errorlevel!"
if "!ARC!"=="0" exit /b 0
set "STAGE=AGENT START"
set "COMPONENT=wr-agent-v2.cmd"
set "OPERATION=start persistent recovery listener"
set "ERROR_ID=RMAI-START27-AGENT-001"
set "FAIL_REASON=Persistent RescueMeAI agent stopped with return code !ARC!."
goto :FATAL

:FATAL
>"%FAILFILE%" echo RESCUEMEAI STRUCTURED FAILURE REPORT
>>"%FAILFILE%" echo error_id=%ERROR_ID%
>>"%FAILFILE%" echo version=%COMMAND_VERSION%
>>"%FAILFILE%" echo stage=%STAGE%
>>"%FAILFILE%" echo component=%COMPONENT%
>>"%FAILFILE%" echo operation=%OPERATION%
>>"%FAILFILE%" echo reason=%FAIL_REASON%
>>"%FAILFILE%" echo last_success=%LAST_SUCCESS%
>>"%FAILFILE%" echo http=%HTTP%
>>"%FAILFILE%" echo curl_return_code=%CURLRC%
>>"%FAILFILE%" echo api_cached_ip=%APIIP%
>>"%FAILFILE%" echo windows_changes=NONE
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
echo Stage        : %STAGE%
echo Component    : %COMPONENT%
echo Operation    : %OPERATION%
echo Reason       : %FAIL_REASON%
echo Last success : %LAST_SUCCESS%
echo.
echo TECHNICAL DIAGNOSTICS - SAFE TO PHOTOGRAPH
echo ----------------------------------------------------------------------------------------------------
echo HTTP status      : %HTTP%
echo curl return code : %CURLRC%
echo API cached IP   : %APIIP%
echo Local evidence  : %FAILFILE%
echo.
echo No Windows repair action was executed by this startup failure.
echo Press a key only after you have read or photographed this screen.
echo ====================================================================================================
pause
exit /b 90
