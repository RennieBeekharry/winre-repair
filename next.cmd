@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Stage RescueMeAI persistent agent v2 and wait for explicit local start confirmation.
rem WR_ACTION=START_RESCUEMEAI_AGENT_V2
rem WR_TARGET=RescueMeAI recovery tooling and private command channel only.
rem WR_CONSEQUENCE=Stages validated RescueMeAI tooling and starts the listener only after the user presses Enter.
rem WR_ROLLBACK=The listener can be stopped safely while waiting. No Windows recovery action is performed by this startup transition.

set "COMMAND_VERSION=RMAI-2026.08.14-AGENT-START-2"
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
set "FAIL_REASON=RescueMeAI persistent agent startup did not complete."
set "UI_WIDTH=96"
set "UI_TEXT_WIDTH=92"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "UI_SPACES=                                                                                                    "

title RescueMeAI - Windows Recovery
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
"%MODE%" con: cols=100 lines=50 >nul 2>&1

call :HEADER INFO "PREPARING PERSISTENT AGENT"
call :SECTION "WHAT IS HAPPENING"
call :WRAP "RescueMeAI is validating the saved private-channel authorization and staging a pinned persistent agent. No Windows repair action is running."

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
  set "FAIL_REASON=Required Windows Script Host cscript.exe is unavailable in this WinRE environment."
  goto :APP_FATAL
)
if not exist "%TOKEN%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=The saved RescueMeAI GitHub authorization token is missing."
  goto :APP_FATAL
)
for %%Z in ("%TOKEN%") do if %%~zZ LSS 16 (
  set "FAIL_RC=96"
  set "FAIL_REASON=The saved RescueMeAI GitHub authorization token is unexpectedly small."
  goto :APP_FATAL
)

call :DOH_RESOLVE_A "%APIHOST%" APIIP
if not defined APIIP (
  set "FAIL_RC=92"
  set "FAIL_REASON=DNS-over-HTTPS could not resolve api.github.com for agent staging."
  goto :APP_FATAL
)
call :TEST_HOST "%APIHOST%" "!APIIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=The resolved api.github.com address failed HTTPS validation."
  goto :APP_FATAL
)
call :DOH_RESOLVE_A "%WEBHOST%" WEBIP
if not defined WEBIP (
  set "FAIL_RC=92"
  set "FAIL_REASON=DNS-over-HTTPS could not resolve github.com for token maintenance."
  goto :APP_FATAL
)
call :TEST_HOST "%WEBHOST%" "!WEBIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=The resolved github.com address failed HTTPS validation."
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

:START_CONFIRM
call :HEADER INFO "PERSISTENT AGENT READY"
call :SECTION "YOU ARE IN CONTROL"
call :WRAP "RescueMeAI is ready but has NOT started the persistent listener yet."
call :WRAP "Press ENTER to start. Once online, RescueMeAI will remain on one stable status screen and continue automatically when validated commands arrive."
call :WRAP "While the agent is WAITING, press S to stop it safely. Active repair writes are never interrupted halfway; stop control resumes at the next safe waiting boundary."
call :WRAP "If RescueMeAI itself has a fatal application failure, the error screen will stay visible until you press a key to return to Command Prompt."
echo.
set "START_INPUT="
set /p "START_INPUT=Press ENTER to start, or type STOP and press ENTER to return to CMD: "
if /i "!START_INPUT!"=="STOP" goto :USER_EXIT
if defined START_INPUT goto :START_CONFIRM

call "%AGENT%"
set "AGENT_RC=!errorlevel!"
if "!AGENT_RC!"=="0" goto :STOPPED
set "FAIL_RC=!AGENT_RC!"
set "FAIL_REASON=The RescueMeAI persistent agent encountered an application-level failure and cannot safely continue."
goto :APP_FATAL

:STOPPED
call :HEADER WARNING "PERSISTENT AGENT STOPPED"
call :SECTION "SAFE STOP"
call :WRAP "The RescueMeAI listener stopped at a safe boundary. No active recovery command was interrupted."
call :WRAP "Run C:\wr.cmd again only when you want to restart the persistent listener."
call :SECTION "NEXT"
call :WRAP "Press any key to return to the Windows Recovery command prompt."
pause >nul
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:USER_EXIT
call :HEADER WARNING "START CANCELLED"
call :SECTION "NO AGENT STARTED"
call :WRAP "The persistent listener was not started. No Windows recovery action was performed."
call :WRAP "Press any key to return to the Windows Recovery command prompt."
pause >nul
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:APP_FATAL
call :HEADER ERROR "APP_FATAL - RESCUEMEAI CANNOT CONTINUE"
call :SECTION "[APP_FATAL] PERSISTENT AGENT STOPPED FAIL-CLOSED"
call :LINE "Return code : !FAIL_RC!"
call :SECTION "REASON"
call :WRAP "!FAIL_REASON!"
call :SECTION "SAFETY"
call :WRAP "RescueMeAI will execute no further recovery actions from this process. Existing private/local evidence is preserved for diagnosis."
call :SECTION "WHAT YOU SHOULD DO"
call :WRAP "Reply to ChatGPT with exactly: fail. The error screen will remain visible until you are ready."
call :WRAP "Press any key only when you want to return to the Windows Recovery command prompt."
call :LINE "%UI_BORDER%"
pause >nul
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!

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
  set "FAIL_REASON=Could not download pinned RescueMeAI component %SRC_PATH%."
  exit /b 1
)
if not exist "%TMP%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Pinned RescueMeAI component %SRC_PATH% was not created after download."
  exit /b 1
)
for %%Z in ("%TMP%") do if %%~zZ LSS 64 (
  set "FAIL_RC=96"
  set "FAIL_REASON=Pinned RescueMeAI component %SRC_PATH% was unexpectedly small."
  exit /b 1
)
"%FINDSTR%" /i /c:"%MARK%" "%TMP%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=96"
  set "FAIL_REASON=Pinned RescueMeAI component %SRC_PATH% failed marker validation."
  exit /b 1
)
move /y "%TMP%" "%DEST%" >nul 2>&1
if errorlevel 1 (
  set "FAIL_RC=97"
  set "FAIL_REASON=Pinned RescueMeAI component %SRC_PATH% could not be staged locally."
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

:HEADER
set "THEME=%~1"
set "STEP=%~2"
set "C=07"
if /i "!THEME!"=="INFO" set "C=0B"
if /i "!THEME!"=="PASS" set "C=0A"
if /i "!THEME!"=="WARNING" set "C=0E"
if /i "!THEME!"=="ERROR" set "C=0C"
color !C! >nul 2>&1
cls
call :LINE "%UI_BORDER%"
call :CENTER "RESCUEMEAI"
call :CENTER "%DESCRIPTION%"
call :LINE "%UI_BORDER%"
call :LINE "Version      : %COMMAND_VERSION%"
call :LINE "Internet     : [CONNECTED]"
call :LINE "Current Step : !STEP!"
call :LINE "Safety       : NO WINDOWS RECOVERY ACTION"
call :LINE "Legal        : https://github.com/RennieBeekharry/winre-repair"
call :LINE "Legal file   : LEGAL.md"
call :LINE "%UI_BORDER%"
exit /b 0

:SECTION
echo.
call :LINE "%~1"
call :LINE "%UI_RULE%"
exit /b 0

:WRAP
set "T=%~1"
set "L="
for %%W in (!T!) do (
  if not defined L (
    set "L=%%W"
  ) else (
    set "CAND=!L! %%W"
    call :STRLEN "!CAND!" N
    if !N! GTR %UI_TEXT_WIDTH% (
      call :LINE "!L!"
      set "L=%%W"
    ) else (
      set "L=!CAND!"
    )
  )
)
if defined L call :LINE "!L!"
exit /b 0

:CENTER
set "T=%~1"
call :STRLEN "!T!" N
set /a P=(UI_WIDTH-N)/2
if !P! LSS 0 set "P=0"
set "OUT=!UI_SPACES:~0,%P%!!T!"
call :LINE "!OUT!"
exit /b 0

:LINE
set "T=%~1"
call :STRLEN "!T!" N
if !N! GTR %UI_WIDTH% set "T=!T:~0,%UI_WIDTH%!"
echo(!T!
exit /b 0

:STRLEN
set "S=%~1"
set /a N=0
:STRLEN_LOOP
if not "!S:~%N%,1!"=="" (
  set /a N+=1
  if !N! LSS 512 goto :STRLEN_LOOP
)
set "%~2=%N%"
exit /b 0
