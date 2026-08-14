@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Stage RescueMeAI persistent agent v2 with a simplified operator start screen.
rem WR_ACTION=START_RESCUEMEAI_AGENT_V2
rem WR_TARGET=RescueMeAI recovery tooling and private command channel only.
rem WR_CONSEQUENCE=Stages validated RescueMeAI tooling and starts only after local confirmation.
rem WR_ROLLBACK=The listener can be stopped safely while waiting. No Windows repair runs here.

set "COMMAND_VERSION=RMAI-2026.08.14-AGENT-START-3"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "DOHHOST=cloudflare-dns.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=8baa701622ecb86fe1c8b59f30f945144bde4d06"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APIIP="
set "WEBIP="
set "FAIL_RC=90"
set "FAIL_REASON=RescueMeAI could not prepare the persistent agent."
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
"%MODE%" con: cols=100 lines=50 >nul 2>&1

call :SHOW_PREPARING

if not exist "%CURL%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required curl.exe is missing from WinRE."
  goto :APP_FATAL
)
if not exist "%FINDSTR%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Required findstr.exe is missing from WinRE."
  goto :APP_FATAL
)
if not exist "%CSCRIPT%" (
  set "FAIL_RC=91"
  set "FAIL_REASON=Windows Script Host is unavailable in this WinRE environment."
  goto :APP_FATAL
)
if not exist "%TOKEN%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=The saved RescueMeAI GitHub authorization token is missing."
  goto :APP_FATAL
)
for %%Z in ("%TOKEN%") do if %%~zZ LSS 16 (
  set "FAIL_RC=96"
  set "FAIL_REASON=The saved RescueMeAI GitHub authorization token is invalid."
  goto :APP_FATAL
)

call :DOH_RESOLVE_A "%APIHOST%" APIIP
if not defined APIIP (
  set "FAIL_RC=92"
  set "FAIL_REASON=RescueMeAI could not resolve api.github.com."
  goto :APP_FATAL
)
call :TEST_HOST "%APIHOST%" "!APIIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=GitHub API HTTPS validation failed."
  goto :APP_FATAL
)

call :DOH_RESOLVE_A "%WEBHOST%" WEBIP
if not defined WEBIP (
  set "FAIL_RC=92"
  set "FAIL_REASON=RescueMeAI could not resolve github.com."
  goto :APP_FATAL
)
call :TEST_HOST "%WEBHOST%" "!WEBIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=GitHub HTTPS validation failed."
  goto :APP_FATAL
)

>"%WORK%\github-api-ip.txt" echo(!APIIP!
>"%WORK%\github-web-ip.txt" echo(!WEBIP!

call :FETCH_PINNED "wr-agent-v2.cmd" "%AGENT%" "WR-MODULE: agent-v2 2026.08.14-1508-ET"
if errorlevel 1 goto :APP_FATAL
call :FETCH_PINNED "lib/resolve.cmd" "%RUNTIME%\resolve.cmd" "WR-MODULE: resolve"
if errorlevel 1 goto :APP_FATAL
call :FETCH_PINNED "lib/runtime-sync.cmd" "%RUNTIME%\runtime-sync.cmd" "WR-MODULE: runtime-sync"
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

:START_MENU
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Internet       : [CONNECTED]
echo Status         : READY TO START
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo                         RESCUEMEAI IS READY
echo %UI_RULE%
echo.
echo Nothing is being changed on Windows right now.
echo.
echo When you start RescueMeAI:
echo   1. It stays open and waits for validated recovery instructions.
echo   2. It shows when a command is running and what risk level it has.
echo   3. It sends results to the private support channel automatically.
echo   4. A failed repair does NOT close RescueMeAI; it waits for the next step.
echo   5. Destructive actions still require separate LOCAL approval.
echo.
echo %UI_RULE%
echo.
echo   [ENTER]  START RESCUEMEAI
echo   [STOP]   RETURN TO COMMAND PROMPT
echo.
echo After starting, press S only while RescueMeAI shows WAITING to stop safely.
echo Active repair writes are never interrupted halfway.
echo.
set "START_INPUT="
set /p "START_INPUT=Your choice: "
if /i "!START_INPUT!"=="STOP" goto :USER_EXIT
if defined START_INPUT (
  echo.
  echo Invalid choice. Press ENTER to start, or type STOP and press ENTER.
  echo.
  pause >nul
  goto :START_MENU
)

call "%AGENT%"
set "AGENT_RC=!errorlevel!"
if "!AGENT_RC!"=="0" goto :STOPPED
set "FAIL_RC=!AGENT_RC!"
set "FAIL_REASON=The RescueMeAI application cannot safely continue."
goto :APP_FATAL

:STOPPED
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status         : STOPPED SAFELY
echo Windows changes: NO ACTIVE COMMAND WAS INTERRUPTED
echo %UI_BORDER%
echo.
echo RescueMeAI stopped at a safe waiting boundary.
echo.
echo Press any key to return to the Windows Recovery command prompt.
pause >nul
goto :RETURN_CMD

:USER_EXIT
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status         : START CANCELLED
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo RescueMeAI was not started.
echo.
echo Press any key to return to the Windows Recovery command prompt.
pause >nul
goto :RETURN_CMD

:APP_FATAL
cls
color 0C >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       APPLICATION FAILURE
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Status         : APP_FATAL
echo Windows changes: STOPPED - NO FURTHER ACTION WILL RUN
echo Return code    : !FAIL_RC!
echo %UI_BORDER%
echo.
echo WHAT HAPPENED
echo %UI_RULE%
echo !FAIL_REASON!
echo.
echo RescueMeAI stopped itself because it cannot safely continue.
echo Existing local/private evidence is preserved for diagnosis.
echo.
echo WHAT YOU SHOULD DO
echo %UI_RULE%
echo Reply to ChatGPT with exactly: fail
echo.
echo This screen will stay visible until you are ready.
echo Press any key to return to the Windows Recovery command prompt.
pause >nul
goto :RETURN_CMD_FAIL

:FETCH_PINNED
set "SRC_PATH=%~1"
set "DEST=%~2"
set "MARK=%~3"
set "TMP=%DEST%.tmp"
set "URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/%SRC_PATH%?ref=%SOURCE_REF%"
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%" 2>"%WORK%\AGENT_STAGE_CURL_ERROR.txt"
set "FRC=!errorlevel!"
if not "!FRC!"=="0" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Could not download required RescueMeAI component %SRC_PATH%."
  exit /b 1
)
if not exist "%TMP%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Required RescueMeAI component %SRC_PATH% was not created."
  exit /b 1
)
for %%Z in ("%TMP%") do if %%~zZ LSS 64 (
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded RescueMeAI component %SRC_PATH% was unexpectedly small."
  exit /b 1
)
"%FINDSTR%" /i /c:"%MARK%" "%TMP%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded RescueMeAI component %SRC_PATH% failed validation."
  exit /b 1
)
move /y "%TMP%" "%DEST%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated RescueMeAI component %SRC_PATH% could not be staged."
  exit /b 1
)
exit /b 0

:DOH_RESOLVE_A
set "DOH_QUERY_HOST=%~1"
set "DOH_RETURN_VAR=%~2"
set "%DOH_RETURN_VAR%="
set "DOH_LAST_STATUS=FAIL"
for %%I in (1.1.1.1 1.0.0.1) do if /i not "!DOH_LAST_STATUS!"=="PASS" call :TRY_DOH_A "%%I"
if /i "!DOH_LAST_STATUS!"=="PASS" exit /b 0
exit /b 1

:TRY_DOH_A
set "DOH_RESOLVER_IP=%~1"
set "DOH_JSON=%WORK%\agent-start-doh.json"
set "DOH_HTTP=%WORK%\agent-start-doh-http.txt"
if exist "%DOH_JSON%" del /f /q "%DOH_JSON%" >nul 2>&1
if exist "%DOH_HTTP%" del /f /q "%DOH_HTTP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 45 --resolve "%DOHHOST%:443:%DOH_RESOLVER_IP%" -H "Accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=%DOH_QUERY_HOST%&type=A" -o "%DOH_JSON%" -w "%%{http_code}" >"%DOH_HTTP%" 2>"%WORK%\agent-start-doh-error.txt"
set "DOH_CURL_RC=!errorlevel!"
set "DOH_HTTP_CODE="
if exist "%DOH_HTTP%" set /p "DOH_HTTP_CODE="<"%DOH_HTTP%"
if not "!DOH_CURL_RC!"=="0" exit /b 1
if not "!DOH_HTTP_CODE!"=="200" exit /b 1
set "DOH_JOIN="
for /f "usebackq delims=" %%L in ("%DOH_JSON%") do set "DOH_JOIN=!DOH_JOIN!%%L"
if not defined DOH_JOIN exit /b 1
set "DOH_TAIL=!DOH_JOIN:*data=!"
if "!DOH_TAIL!"=="!DOH_JOIN!" exit /b 1
set "DOH_RAW="
for /f "tokens=2 delims=:" %%A in ("!DOH_TAIL!") do set "DOH_RAW=%%A"
if not defined DOH_RAW exit /b 1
set "DOH_IP="
for /f "tokens=1 delims=,}]" %%A in ("!DOH_RAW!") do set "DOH_IP=%%A"
set "DOH_IP=!DOH_IP:"=!"
set "DOH_IP=!DOH_IP: =!"
echo(!DOH_IP!|"%FINDSTR%" /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
if errorlevel 1 exit /b 1
set "%DOH_RETURN_VAR%=!DOH_IP!"
set "DOH_LAST_STATUS=PASS"
exit /b 0

:TEST_HOST
set "TH_HOST=%~1"
set "TH_IP=%~2"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%TH_HOST%:443:%TH_IP%" -I "https://%TH_HOST%/" -o NUL >nul 2>&1
exit /b !errorlevel!

:SHOW_PREPARING
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Internet       : [CONNECTED]
echo Status         : PREPARING
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo Preparing the secure recovery agent...
echo No Windows repair action is running.
exit /b 0

:RETURN_CMD
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:RETURN_CMD_FAIL
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!
