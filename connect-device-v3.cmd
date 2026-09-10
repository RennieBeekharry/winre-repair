@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Secure Device Connection v3

set "CONNECT_VERSION=2026.09.10-v3"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "AGENTDIR=%WORK%\agent"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "REFRESH=%AUTHDIR%\github-refresh.token"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "RUNTIME_REF=6eaddd8b0c286fb7bd4a87c7c00fa965937b95a5"
set "LAST_STAGE=STARTUP"
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "LAST_ERROR=NONE"

for %%D in ("%WORK%" "%RUNTIME%" "%AUTHDIR%" "%AGENTDIR%") do if not exist %%D md %%D >nul 2>&1
if not exist "%CURL%" goto :DEPFAIL
if not exist "%FINDSTR%" goto :DEPFAIL

set "SESSION_ID="
if exist "C:\RescueMeAI\state\session-id.txt" set /p "SESSION_ID="<"C:\RescueMeAI\state\session-id.txt"
if not defined SESSION_ID set "SESSION_ID=RMAI-%RANDOM%%RANDOM%%RANDOM%%RANDOM%"
set "AGENT_ID=!SESSION_ID:RMAI-=AIWR-!"
if /i "!AGENT_ID!"=="!SESSION_ID!" set "AGENT_ID=AIWR-%RANDOM%%RANDOM%%RANDOM%"
set "CONTROL_PATH=devices/!SESSION_ID!/control/current-command.json"
set "REPORT_PREFIX=devices/!SESSION_ID!/reports/inbox"

cls
echo ================================================================
echo RescueMeAI - Secure GitHub Support Connection v3
echo ================================================================
echo Session : !SESSION_ID!
echo Agent   : !AGENT_ID!
echo.
echo Pure-CMD compatibility mode. No PowerShell or JScript required.
echo Outbound-only validated command listener; no inbound shell is opened.
echo Destructive recovery remains behind the LOCAL safety gate.
echo ================================================================
echo.

set "LAST_STAGE=RUNTIME_DOWNLOAD"
call :FETCH "lib/safety.cmd" "%RUNTIME%\safety.cmd" || goto :FETCHFAIL
call :FETCH "lib/device-agent-v2.cmd" "%RUNTIME%\device-agent-v2.cmd" || goto :FETCHFAIL

rem Reuse an already-valid credential if one exists.
if exist "%TOKEN%" (
  set "ACCESS="
  set /p "ACCESS="<"%TOKEN%"
  if defined ACCESS (
    call :VALIDATE_REPO
    if not errorlevel 1 goto :AUTHORIZED_EXISTING
  )
)

:REQUEST_DEVICE
set "LAST_STAGE=DEVICE_CODE_REQUEST"
set "DEV=%WORK%\device-code.txt"
set "TOK=%WORK%\device-token.txt"
set "HTTP=%WORK%\github-http.txt"
for %%F in ("%DEV%" "%TOK%" "%HTTP%") do if exist %%F del /f /q %%F >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\device-code-curl.txt"
set "LAST_CURL=!errorlevel!"
if not "!LAST_CURL!"=="0" (
  set "LAST_ERROR=HTTPS request to GitHub device-code endpoint failed"
  goto :AUTHFAIL
)
set "HTTP_CODE="
if exist "%HTTP%" set /p "HTTP_CODE="<"%HTTP%"
set "LAST_HTTP=!HTTP_CODE!"
if not "!HTTP_CODE!"=="200" (
  set "LAST_ERROR=GitHub device-code endpoint did not return HTTP 200"
  goto :AUTHFAIL
)

set "DEVICE_CODE="
set "USER_CODE="
set "INTERVAL=5"
set "EXPIRES=900"
set "FORM="
set /p "FORM="<"%DEV%"
call :PARSE_FORM "!FORM!"
if not defined DEVICE_CODE (
  set "LAST_ERROR=GitHub response did not contain device_code"
  goto :AUTHFAIL
)
if not defined USER_CODE (
  set "LAST_ERROR=GitHub response did not contain user_code"
  goto :AUTHFAIL
)

cls
color 0B >nul 2>&1
echo ================================================================
echo RescueMeAI - GitHub authorization required once
echo ================================================================
echo.
echo On your phone, open:
echo   https://github.com/login/device
echo.
echo Enter this code:
echo.
echo   !USER_CODE!
echo.
echo Approve the RescueMeAI GitHub connection.
echo This PC continues automatically after approval.
echo ================================================================

set /a MAXPOLLS=(EXPIRES/INTERVAL)+8 >nul 2>&1
if !MAXPOLLS! LSS 20 set "MAXPOLLS=188"
set /a POLLS=0
:POLL
set "LAST_STAGE=DEVICE_AUTH_POLL"
set /a POLLS+=1
if !POLLS! GTR !MAXPOLLS! goto :REQUEST_DEVICE
set /a WAITN=INTERVAL+1
"%PING%" -n !WAITN! 127.0.0.1 >nul 2>&1
if exist "%TOK%" del /f /q "%TOK%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
if not "!LAST_CURL!"=="0" goto :POLL

set "ACCESS="
set "REFRESH_VALUE="
set "OAUTH_ERROR="
set "FORM="
set /p "FORM="<"%TOK%"
call :PARSE_FORM "!FORM!"
if defined ACCESS goto :VALIDATE
if /i "!OAUTH_ERROR!"=="authorization_pending" goto :POLL
if /i "!OAUTH_ERROR!"=="slow_down" (
  set /a INTERVAL+=5
  goto :POLL
)
if /i "!OAUTH_ERROR!"=="expired_token" goto :REQUEST_DEVICE
if /i "!OAUTH_ERROR!"=="access_denied" (
  set "LAST_ERROR=GitHub authorization was denied on the approval device"
  goto :AUTHFAIL
)
if defined OAUTH_ERROR (
  set "LAST_ERROR=GitHub OAuth error: !OAUTH_ERROR!"
  goto :AUTHFAIL
)
goto :POLL

:VALIDATE
set "LAST_STAGE=PRIVATE_REPO_VALIDATION"
call :VALIDATE_REPO
if errorlevel 1 goto :REPOFAIL
>"%TOKEN%.new" echo(!ACCESS!
if errorlevel 1 (
  set "LAST_ERROR=Could not persist GitHub access credential"
  goto :AUTHFAIL
)
move /y "%TOKEN%.new" "%TOKEN%" >nul 2>&1
if errorlevel 1 (
  set "LAST_ERROR=Could not activate saved GitHub access credential"
  goto :AUTHFAIL
)
attrib +h +s "%TOKEN%" >nul 2>&1
if defined REFRESH_VALUE (
  >"%REFRESH%" echo(!REFRESH_VALUE!
  attrib +h +s "%REFRESH%" >nul 2>&1
)
goto :AUTHORIZED

:AUTHORIZED_EXISTING
set "REFRESH_VALUE="
:AUTHORIZED
set "ACCESS="
set "REFRESH_VALUE="
>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo CONNECT_VERSION=%CONNECT_VERSION%
>>"%CONFIG%" echo SESSION_ID=!SESSION_ID!
>>"%CONFIG%" echo AGENT_ID=!AGENT_ID!
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=!CONTROL_PATH!
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo REPORT_PREFIX=!REPORT_PREFIX!
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%RUNTIME_REF%
>"%AGENTDIR%\agent-id.txt" echo !AGENT_ID!
if exist "%AGENTDIR%\last-command-id.txt" del /f /q "%AGENTDIR%\last-command-id.txt" >nul 2>&1
if exist "%AGENTDIR%\inflight-command-id.txt" del /f /q "%AGENTDIR%\inflight-command-id.txt" >nul 2>&1

cls
color 0A >nul 2>&1
echo ================================================================
echo [PASS] RescueMeAI private channel authorized
echo ================================================================
echo Session : !SESSION_ID!
echo Agent   : !AGENT_ID!
echo Starting persistent pure-CMD listener now.
echo Leave this window open.
echo ================================================================
call "%RUNTIME%\device-agent-v2.cmd"
exit /b !errorlevel!

:PARSE_FORM
set "PF=%~1"
for /f "tokens=1-8 delims=&" %%A in ("!PF!") do (
  call :PAIR "%%A"
  call :PAIR "%%B"
  call :PAIR "%%C"
  call :PAIR "%%D"
  call :PAIR "%%E"
  call :PAIR "%%F"
  call :PAIR "%%G"
  call :PAIR "%%H"
)
exit /b 0

:PAIR
set "PP=%~1"
if not defined PP exit /b 0
for /f "tokens=1,* delims==" %%K in ("%PP%") do (
  if /i "%%K"=="device_code" set "DEVICE_CODE=%%L"
  if /i "%%K"=="user_code" set "USER_CODE=%%L"
  if /i "%%K"=="interval" set "INTERVAL=%%L"
  if /i "%%K"=="expires_in" set "EXPIRES=%%L"
  if /i "%%K"=="access_token" set "ACCESS=%%L"
  if /i "%%K"=="refresh_token" set "REFRESH_VALUE=%%L"
  if /i "%%K"=="error" set "OAUTH_ERROR=%%L"
)
exit /b 0

:VALIDATE_REPO
set "REPOHTTP=%WORK%\repo-http.txt"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%WORK%\repo-check.json" -w "%%{http_code}" >"%REPOHTTP%" 2>"%WORK%\repo-check-curl.txt"
set "LAST_CURL=!errorlevel!"
if not "!LAST_CURL!"=="0" exit /b 1
set "REPO_CODE="
if exist "%REPOHTTP%" set /p "REPO_CODE="<"%REPOHTTP%"
set "LAST_HTTP=!REPO_CODE!"
if not "!REPO_CODE!"=="200" exit /b 1
exit /b 0

:FETCH
set "FPATH=%~1"
set "FOUT=%~2"
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "https://raw.githubusercontent.com/%SOURCE_REPO%/%RUNTIME_REF%/!FPATH!" -o "!FOUT!"
if errorlevel 1 exit /b 1
if not exist "!FOUT!" exit /b 1
for %%Z in ("!FOUT!") do if %%~zZ LSS 20 exit /b 1
exit /b 0

:DEPFAIL
set "LAST_STAGE=DEPENDENCY_CHECK"
set "LAST_ERROR=Required WinRE component is missing"
goto :AUTHFAIL

:FETCHFAIL
set "LAST_ERROR=RescueMeAI could not download the pure-CMD support runtime"
goto :AUTHFAIL

:REPOFAIL
color 0E >nul 2>&1
echo.
echo [WARNING] GitHub authorization succeeded but private repository access failed.
echo GitHub HTTP: !LAST_HTTP!
echo No recovery command was executed.
exit /b 40

:AUTHFAIL
color 0C >nul 2>&1
echo.
echo [FAIL] RescueMeAI secure GitHub connection was not established.
echo Stage       : !LAST_STAGE!
echo Reason      : !LAST_ERROR!
echo curl code   : !LAST_CURL!
echo GitHub HTTP : !LAST_HTTP!
echo No recovery command was executed.
exit /b 90
