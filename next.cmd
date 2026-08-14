@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Restart the paired RescueMeAI agent with visible startup activity, safe source fallback, clear result instructions, and the DoH resolver.
rem WR_ACTION=START_RESCUEMEAI_AGENT_VISIBLE_RUNTIME
rem WR_TARGET=RescueMeAI runtime modules and private command channel only.
rem WR_CONSEQUENCE=Refreshes RescueMeAI application modules. It does not modify Windows recovery state.
rem WR_ROLLBACK=Stop RescueMeAI safely while waiting and return to Command Prompt.

set "COMMAND_VERSION=RMAI-2026.08.14-AGENT-START-7"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "TOKENFILE=%WORK%\.auth\github-logs.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "APIHOST=api.github.com"
set "DOHHOST=cloudflare-dns.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=7fa6b98369c2f2db6c01bf96555d07b3be048281"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APIIP="
set "AUTH_TOKEN="
set "FAIL_RC=91"
set "FAIL_REASON=RescueMeAI could not stage its corrected recovery runtime."
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"

title RescueMeAI - Windows Recovery
"%MODE%" con: cols=100 lines=50 >nul 2>&1
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1

call :SHOW_ACTIVITY "Checking saved authorization" "RescueMeAI is preparing the recovery session."
if not exist "%TOKENFILE%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Saved GitHub authorization is missing."
  goto :APP_FATAL
)
if not exist "%CURL%" goto :APP_FATAL
if not exist "%FINDSTR%" goto :APP_FATAL
if not exist "%AGENT%" goto :APP_FATAL
set /p "AUTH_TOKEN="<"%TOKENFILE%"
if not defined AUTH_TOKEN (
  set "FAIL_RC=96"
  set "FAIL_REASON=Saved GitHub authorization is empty."
  goto :APP_FATAL
)

call :SHOW_ACTIVITY "Checking GitHub connection" "Resolving and validating the GitHub API connection."
if exist "%WORK%\github-api-ip.txt" set /p "APIIP="<"%WORK%\github-api-ip.txt"
if defined APIIP call :TEST_API
if not errorlevel 1 goto :API_READY
set "APIIP="
call :DOH_RESOLVE_A "%APIHOST%" APIIP
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=RescueMeAI could not resolve api.github.com."
  goto :APP_FATAL
)
call :TEST_API
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=GitHub API HTTPS validation failed."
  goto :APP_FATAL
)
:API_READY
>"%WORK%\github-api-ip.txt" echo(!APIIP!

call :SHOW_ACTIVITY "Loading interface" "Updating the RescueMeAI result and status screens."
call :FETCH_SOURCE "lib/ui.cmd" "%RUNTIME%\ui.cmd" "WR-MODULE: ui 2026.08.14-1545-ET"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading network module" "Preparing resilient GitHub and recovery-source downloads."
call :FETCH_SOURCE "lib/network.cmd" "%RUNTIME%\network.cmd" "WR-MODULE: network 2026.08.14-1605-ET"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading DNS resolver" "Preparing DNS-over-HTTPS fallback for WinRE."
call :FETCH_SOURCE "lib/resolve.cmd" "%RUNTIME%\resolve.cmd" "WR-MODULE: resolve 2026.08.14-1552-ET"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading safety policy" "Refreshing local command risk and authorization checks."
call :FETCH_SOURCE "lib/safety.cmd" "%RUNTIME%\safety.cmd" "WR-MODULE: safety 2026.08.14-1527-ET"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading reporting channel" "Preparing private recovery result reporting."
call :FETCH_SOURCE "lib/reporting.cmd" "%RUNTIME%\reporting.cmd" "WR-MODULE: reporting"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading GitHub authorization" "Reusing the paired GitHub App session."
call :FETCH_SOURCE "lib/github-auth.cmd" "%RUNTIME%\github-auth.cmd" "WR-MODULE: github-auth"
if errorlevel 1 goto :APP_FATAL
call :SHOW_ACTIVITY "Loading command listener" "Preparing the private recovery command channel."
call :FETCH_SOURCE "lib/agent-core.js" "%RUNTIME%\agent-core.js" "WR-MODULE: agent-core-js"
if errorlevel 1 goto :APP_FATAL
call :FETCH_SOURCE "lib/runtime-local-ready.cmd" "%RUNTIME%\runtime-sync.cmd" "WR-MODULE: runtime-local-ready 2026.08.14-1555-ET"
if errorlevel 1 goto :APP_FATAL

>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%GITHUB_APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%GITHUB_APP_CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%SOURCE_REF%

:MENU
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Internet       : [CONNECTED]
echo Status         : READY TO CONTINUE
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo                              ACTION REQUIRED
echo %UI_RULE%
echo.
echo RescueMeAI is ready to continue the recovery-media workflow.
echo Nothing is being changed on Windows right now.
echo.
echo TO CONTINUE:
echo.
echo        PRESS THE ENTER KEY ONCE
echo        Do NOT type the word ENTER.
echo.
echo TO CANCEL:
echo.
echo        TYPE: STOP
echo        THEN press the ENTER key.
echo.
echo After starting, leave this window open. RescueMeAI will show each meaningful
echo recovery stage so you can see that work is continuing.
echo.
set "START_INPUT="
set /p "START_INPUT=Waiting for you: "
if /i "!START_INPUT!"=="STOP" goto :USER_EXIT
if defined START_INPUT goto :MENU

call :SHOW_ACTIVITY "Starting persistent agent" "Connecting to the private recovery command channel."
call "%AGENT%"
set "AGENT_RC=!errorlevel!"
if "!AGENT_RC!"=="0" goto :STOPPED
set "FAIL_RC=!AGENT_RC!"
set "FAIL_REASON=RescueMeAI could not safely keep the persistent agent online."
goto :APP_FATAL

:FETCH_SOURCE
set "SRC=%~1"
set "DEST=%~2"
set "MARK=%~3"
set "TMP=%DEST%.tmp"
set "URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/%SRC%?ref=%SOURCE_REF%"
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer %AUTH_TOKEN%" -H "X-GitHub-Api-Version: 2022-11-28" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%" 2>"%WORK%\START7_CURL_ERROR.txt"
if errorlevel 1 (
  if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%" 2>"%WORK%\START7_CURL_ERROR.txt"
)
if errorlevel 1 (
  set "FAIL_RC=90"
  set "FAIL_REASON=Source download failed for %SRC%."
  exit /b 1
)
if not exist "%TMP%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Source download did not create %SRC%."
  exit /b 1
)
"%FINDSTR%" /i /c:"%MARK%" "%TMP%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded RescueMeAI module %SRC% failed marker validation."
  exit /b 1
)
move /y "%TMP%" "%DEST%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated RescueMeAI module %SRC% could not be staged."
  exit /b 1
)
exit /b 0

:DOH_RESOLVE_A
set "DOH_QUERY_HOST=%~1"
set "DOH_RETURN_VAR=%~2"
set "%DOH_RETURN_VAR%="
for %%I in (1.1.1.1 1.0.0.1) do if not defined %DOH_RETURN_VAR% call :TRY_DOH_A "%%I"
if defined %DOH_RETURN_VAR% exit /b 0
exit /b 1

:TRY_DOH_A
set "DOHIP=%~1"
set "DOHJSON=%WORK%\start7-doh.json"
set "DOHHTTP=%WORK%\start7-doh-http.txt"
if exist "%DOHJSON%" del /f /q "%DOHJSON%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 45 --resolve "%DOHHOST%:443:%DOHIP%" -H "Accept: application/dns-json" "https://%DOHHOST%/dns-query?name=%DOH_QUERY_HOST%&type=A" -o "%DOHJSON%" -w "%%{http_code}" >"%DOHHTTP%" 2>nul
if errorlevel 1 exit /b 0
set "HC="
if exist "%DOHHTTP%" set /p "HC="<"%DOHHTTP%"
if not "!HC!"=="200" exit /b 0
set "JOIN="
for /f "usebackq delims=" %%L in ("%DOHJSON%") do set "JOIN=!JOIN!%%L"
set "TAIL=!JOIN:*data=!"
if "!TAIL!"=="!JOIN!" exit /b 0
set "RAW="
for /f "tokens=2 delims=:" %%A in ("!TAIL!") do set "RAW=%%A"
for /f "tokens=1 delims=,}]" %%A in ("!RAW!") do set "IP=%%A"
set "IP=!IP:"=!"
set "IP=!IP: =!"
echo(!IP!|"%FINDSTR%" /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
if errorlevel 1 exit /b 0
set "%DOH_RETURN_VAR%=!IP!"
exit /b 0

:TEST_API
if not defined APIIP exit /b 1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%APIHOST%:443:%APIIP%" -H "Authorization: Bearer %AUTH_TOKEN%" "https://%APIHOST%/" -o NUL >nul 2>&1
if not errorlevel 1 exit /b 0
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%APIHOST%:443:%APIIP%" "https://%APIHOST%/" -o NUL >nul 2>&1
exit /b !errorlevel!

:SHOW_ACTIVITY
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Status         : WORKING
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo CURRENT ACTIVITY
echo %UI_RULE%
echo   %~1
echo.
echo   %~2
echo.
echo PLEASE WAIT. No action is required while this screen says WORKING.
echo RescueMeAI will move to the next stage automatically.
exit /b 0

:STOPPED
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status         : STOPPED SAFELY
echo Windows changes: NO ACTIVE COMMAND WAS INTERRUPTED
echo %UI_BORDER%
echo RescueMeAI stopped at a safe waiting boundary.
echo Press any key to return to Command Prompt.
pause >nul
goto :RETURN_CMD

:USER_EXIT
cls
color 0E >nul 2>&1
echo RescueMeAI start cancelled. No Windows changes were made.
echo Press any key to return to Command Prompt.
pause >nul
goto :RETURN_CMD

:APP_FATAL
cls
color 0C >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                         APPLICATION FAILURE
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Return code    : !FAIL_RC!
echo Windows changes: STOPPED
echo %UI_BORDER%
echo !FAIL_REASON!
echo.
echo ACTION REQUIRED: return to ChatGPT and send exactly: fail
echo This screen will remain until you press a key.
pause >nul
goto :RETURN_CMD_FAIL

:RETURN_CMD
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:RETURN_CMD_FAIL
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!
