@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Secure Device Connection

set "CONNECT_VERSION=2026.09.09-v1"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "AUTHDIR=%WORK%\.auth"
set "AGENTDIR=%WORK%\agent"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%AUTHDIR%\github-logs.token"
set "REFRESH=%AUTHDIR%\github-refresh.token"
set "CURL=C:\Windows\System32\curl.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "RUNTIME_REF=cd0cab9c92ce880f695dbc220e046ba110df481f"

for %%D in ("%WORK%" "%RUNTIME%" "%AUTHDIR%" "%AGENTDIR%") do if not exist %%D md %%D >nul 2>&1
if not exist "%CURL%" goto :DEPFAIL
if not exist "%CSCRIPT%" goto :DEPFAIL

set "SESSION_ID="
if exist "C:\RescueMeAI\state\session-id.txt" set /p "SESSION_ID="<"C:\RescueMeAI\state\session-id.txt"
if not defined SESSION_ID set "SESSION_ID=RMAI-%RANDOM%%RANDOM%%RANDOM%%RANDOM%"
set "AGENT_ID=!SESSION_ID:RMAI-=AIWR-!"
if /i "!AGENT_ID!"=="!SESSION_ID!" set "AGENT_ID=AIWR-%RANDOM%%RANDOM%%RANDOM%"
set "CONTROL_PATH=devices/!SESSION_ID!/control/current-command.json"
set "REPORT_PREFIX=devices/!SESSION_ID!/reports/inbox"

cls
echo ================================================================
echo RescueMeAI - Secure GitHub Support Connection
echo ================================================================
echo Session : !SESSION_ID!
echo Agent   : !AGENT_ID!
echo.
echo This installs an OUTBOUND-ONLY validated command listener.
echo It does not open Remote Desktop, SSH, WinRM, or an inbound shell.
echo Destructive recovery still requires the local safety gate.
echo ================================================================
echo.

call :FETCH "lib/json-get.js" "%RUNTIME%\json-get.js"
if errorlevel 1 goto :FETCHFAIL
call :FETCH "lib/agent-core.js" "%RUNTIME%\agent-core.js"
if errorlevel 1 goto :FETCHFAIL
call :FETCH "lib/safety.cmd" "%RUNTIME%\safety.cmd"
if errorlevel 1 goto :FETCHFAIL
call :FETCH "lib/device-agent.cmd" "%RUNTIME%\device-agent.cmd"
if errorlevel 1 goto :FETCHFAIL

set "JSON=%RUNTIME%\json-get.js"
set "DEV=%WORK%\device-code.json"
set "TOK=%WORK%\device-token.json"
set "HTTP=%WORK%\github-http.txt"

:REQUEST_DEVICE
if exist "%DEV%" del /f /q "%DEV%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DEV%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\device-code-curl.txt"
if errorlevel 1 goto :AUTHFAIL
set "HTTP_CODE="
set /p "HTTP_CODE="<"%HTTP%"
if not "!HTTP_CODE!"=="200" goto :AUTHFAIL

set "DEVICE_CODE="
set "USER_CODE="
set "VERIFY_URI=https://github.com/login/device"
set "INTERVAL=5"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" device_code 2^>nul') do set "DEVICE_CODE=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" user_code 2^>nul') do set "USER_CODE=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" verification_uri 2^>nul') do set "VERIFY_URI=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" interval 2^>nul') do set "INTERVAL=%%A"
if not defined DEVICE_CODE goto :AUTHFAIL
if not defined USER_CODE goto :AUTHFAIL

cls
color 0B >nul 2>&1
echo ================================================================
echo RescueMeAI - GitHub authorization required once
echo ================================================================
echo.
echo On your phone, open:
echo   !VERIFY_URI!
echo.
echo Enter this code:
echo.
echo   !USER_CODE!
echo.
echo Approve the RescueMeAI GitHub connection.
echo This PC will continue automatically after approval.
echo ================================================================

set /a POLLS=0
:POLL
set /a POLLS+=1
if !POLLS! GTR 180 goto :AUTHFAIL
"%PING%" -n !INTERVAL! 127.0.0.1 >nul 2>&1
if exist "%TOK%" del /f /q "%TOK%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOK%" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\device-token-curl.txt"
if errorlevel 1 goto :POLL
set "ACCESS="
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" access_token 2^>nul') do set "ACCESS=%%A"
if defined ACCESS goto :VALIDATE
set "OAUTH_ERROR="
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" error 2^>nul') do set "OAUTH_ERROR=%%A"
if /i "!OAUTH_ERROR!"=="access_denied" goto :AUTHFAIL
if /i "!OAUTH_ERROR!"=="expired_token" goto :REQUEST_DEVICE
if /i "!OAUTH_ERROR!"=="slow_down" set /a INTERVAL+=5
goto :POLL

:VALIDATE
set "REPOHTTP=%WORK%\repo-http.txt"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 60 -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%WORK%\repo-check.json" -w "%%{http_code}" >"%REPOHTTP%" 2>"%WORK%\repo-check-curl.txt"
if errorlevel 1 goto :AUTHFAIL
set "REPO_CODE="
set /p "REPO_CODE="<"%REPOHTTP%"
if not "!REPO_CODE!"=="200" goto :REPOFAIL

>"%TOKEN%.new" echo(!ACCESS!
if errorlevel 1 goto :AUTHFAIL
move /y "%TOKEN%.new" "%TOKEN%" >nul 2>&1
attrib +h +s "%TOKEN%" >nul 2>&1
set "REFRESH_VALUE="
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" refresh_token 2^>nul') do set "REFRESH_VALUE=%%A"
if defined REFRESH_VALUE (
  >"%REFRESH%" echo(!REFRESH_VALUE!
  attrib +h +s "%REFRESH%" >nul 2>&1
)
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
echo.
echo Starting the persistent outbound listener now.
echo Leave this window open.
echo ================================================================
call "%RUNTIME%\device-agent.cmd"
exit /b !errorlevel!

:FETCH
set "FPATH=%~1"
set "FOUT=%~2"
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "https://raw.githubusercontent.com/%SOURCE_REPO%/%RUNTIME_REF%/!FPATH!" -o "!FOUT!"
if errorlevel 1 exit /b 1
if not exist "!FOUT!" exit /b 1
for %%Z in ("!FOUT!") do if %%~zZ LSS 20 exit /b 1
exit /b 0

:DEPFAIL
color 0C >nul 2>&1
echo [FAIL] Required WinRE components are missing.
exit /b 91

:FETCHFAIL
color 0C >nul 2>&1
echo [FAIL] RescueMeAI could not download the validated support runtime.
exit /b 90

:REPOFAIL
color 0E >nul 2>&1
echo [WARNING] GitHub authorization succeeded, but the RescueMeAI GitHub App
echo cannot access the private recovery repository yet.
echo Approve/install the app for RennieBeekharry/winre-repair-logs, then rerun
echo the same one-line command.
exit /b 40

:AUTHFAIL
color 0C >nul 2>&1
echo [FAIL] GitHub device authorization did not complete successfully.
echo No recovery command was executed.
exit /b 90
