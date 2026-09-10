@echo off
setlocal EnableExtensions EnableDelayedExpansion
title RescueMeAI - Secure Device Connection v2

set "CONNECT_VERSION=2026.09.09-v2"
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
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "APP_ID=4595411"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "RUNTIME_REF=90a315b7b5990bde57e331d81d6f3d0d53367f95"
set "TLS=--ssl-no-revoke"
set "WEBIP="
set "APIIP="
set "LAST_STAGE=STARTUP"
set "LAST_HTTP=NOT_RUN"
set "LAST_CURL=NOT_RUN"
set "LAST_ERROR=NONE"

for %%D in ("%WORK%" "%RUNTIME%" "%AUTHDIR%" "%AGENTDIR%") do if not exist %%D md %%D >nul 2>&1
if not exist "%CURL%" goto :DEPFAIL
if not exist "%CSCRIPT%" goto :DEPFAIL
if not exist "%FINDSTR%" goto :DEPFAIL

"%CURL%" --help all 2>nul | "%FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "TLS=--ssl-revoke-best-effort"
call :RESOLVE github.com WEBIP
call :RESOLVE api.github.com APIIP
if defined APIIP >"%WORK%\github-api-ip.txt" echo !APIIP!
if defined WEBIP >"%WORK%\github-web-ip.txt" echo !WEBIP!

set "SESSION_ID="
if exist "C:\RescueMeAI\state\session-id.txt" set /p "SESSION_ID="<"C:\RescueMeAI\state\session-id.txt"
if not defined SESSION_ID set "SESSION_ID=RMAI-%RANDOM%%RANDOM%%RANDOM%%RANDOM%"
set "AGENT_ID=!SESSION_ID:RMAI-=AIWR-!"
if /i "!AGENT_ID!"=="!SESSION_ID!" set "AGENT_ID=AIWR-%RANDOM%%RANDOM%%RANDOM%"
set "CONTROL_PATH=devices/!SESSION_ID!/control/current-command.json"
set "REPORT_PREFIX=devices/!SESSION_ID!/reports/inbox"

cls
echo ================================================================
echo RescueMeAI - Secure GitHub Support Connection v2
echo ================================================================
echo Session : !SESSION_ID!
echo Agent   : !AGENT_ID!
echo.
echo Outbound-only validated command listener.
echo No RDP, SSH, WinRM, port-forwarding, or inbound shell is opened.
echo Destructive recovery remains blocked behind the LOCAL safety gate.
echo ================================================================
echo.

set "LAST_STAGE=RUNTIME_DOWNLOAD"
call :FETCH "lib/json-get.js" "%RUNTIME%\json-get.js" || goto :FETCHFAIL
call :FETCH "lib/agent-core.js" "%RUNTIME%\agent-core.js" || goto :FETCHFAIL
call :FETCH "lib/safety.cmd" "%RUNTIME%\safety.cmd" || goto :FETCHFAIL
call :FETCH "lib/device-agent.cmd" "%RUNTIME%\device-agent.cmd" || goto :FETCHFAIL
set "JSON=%RUNTIME%\json-get.js"

rem Prove the parser locally before GitHub authorization.
>"%WORK%\json-selftest.json" echo {"value":"OK"}
set "SELFTEST="
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%WORK%\json-selftest.json" value 2^>nul') do set "SELFTEST=%%A"
if /i not "!SELFTEST!"=="OK" (
  set "LAST_STAGE=JSON_SELFTEST"
  set "LAST_ERROR=JSON parser self-test failed"
  goto :AUTHFAIL
)

rem Reuse an already-valid saved credential if one exists.
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
set "DEV=%WORK%\device-code.json"
set "TOK=%WORK%\device-token.json"
set "HTTP=%WORK%\github-http.txt"
for %%F in ("%DEV%" "%TOK%" "%HTTP%") do if exist %%F del /f /q %%F >nul 2>&1
call :DEVICE_POST "%DEV%" "%HTTP%"
if errorlevel 1 goto :AUTHFAIL
set "HTTP_CODE="
if exist "%HTTP%" set /p "HTTP_CODE="<"%HTTP%"
set "LAST_HTTP=!HTTP_CODE!"
if not "!HTTP_CODE!"=="200" (
  set "LAST_ERROR=GitHub device-code endpoint did not return HTTP 200"
  goto :AUTHFAIL
)

set "DEVICE_CODE="
set "USER_CODE="
set "VERIFY_URI=https://github.com/login/device"
set "INTERVAL=5"
set "EXPIRES=900"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" device_code 2^>nul') do set "DEVICE_CODE=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" user_code 2^>nul') do set "USER_CODE=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" verification_uri 2^>nul') do set "VERIFY_URI=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" interval 2^>nul') do set "INTERVAL=%%A"
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%DEV%" expires_in 2^>nul') do set "EXPIRES=%%A"
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
echo   !VERIFY_URI!
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
if !POLLS! GTR !MAXPOLLS! (
  set "LAST_ERROR=GitHub device code expired before approval"
  goto :REQUEST_DEVICE
)
call :WAIT !INTERVAL!
if exist "%TOK%" del /f /q "%TOK%" >nul 2>&1
call :TOKEN_POST "%TOK%" "%HTTP%"
if errorlevel 1 goto :POLL
set "ACCESS="
set "REFRESH_VALUE="
set "OAUTH_ERROR="
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" access_token 2^>nul') do set "ACCESS=%%A"
if defined ACCESS goto :VALIDATE
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" error 2^>nul') do set "OAUTH_ERROR=%%A"
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
for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%TOK%" refresh_token 2^>nul') do set "REFRESH_VALUE=%%A"

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
echo Starting the persistent outbound listener now.
echo Leave this window open.
echo ================================================================
call "%RUNTIME%\device-agent.cmd"
exit /b !errorlevel!

:DEVICE_POST
set "DOUT=%~1"
set "DHTTP=%~2"
set "RESOLVEOPT="
if defined WEBIP set "RESOLVEOPT=--resolve github.com:443:!WEBIP!"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 !RESOLVEOPT! -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DOUT%" -w "%%{http_code}" >"%DHTTP%" 2>"%WORK%\device-code-curl.txt"
set "LAST_CURL=!errorlevel!"
if "!LAST_CURL!"=="0" exit /b 0
rem Retry once without the resolver pin in case the cached address changed.
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" --data-urlencode "client_id=%CLIENT_ID%" "https://github.com/login/device/code" -o "%DOUT%" -w "%%{http_code}" >"%DHTTP%" 2>"%WORK%\device-code-curl.txt"
set "LAST_CURL=!errorlevel!"
if not "!LAST_CURL!"=="0" set "LAST_ERROR=HTTPS request to GitHub device-code endpoint failed"
exit /b !LAST_CURL!

:TOKEN_POST
set "TOUT=%~1"
set "THTTP=%~2"
set "RESOLVEOPT="
if defined WEBIP set "RESOLVEOPT=--resolve github.com:443:!WEBIP!"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 !RESOLVEOPT! -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" --data-urlencode "client_id=%CLIENT_ID%" --data-urlencode "device_code=!DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOUT%" -w "%%{http_code}" >"%THTTP%" 2>"%WORK%\device-token-curl.txt"
set "LAST_CURL=!errorlevel!"
exit /b !LAST_CURL!

:VALIDATE_REPO
set "REPOHTTP=%WORK%\repo-http.txt"
set "RESOLVEOPT="
if defined APIIP set "RESOLVEOPT=--resolve api.github.com:443:!APIIP!"
"%CURL%" %TLS% --silent --show-error --connect-timeout 15 --max-time 60 !RESOLVEOPT! -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "User-Agent: RescueMeAI/%CONNECT_VERSION%" "https://api.github.com/repositories/%LOG_REPO_ID%" -o "%WORK%\repo-check.json" -w "%%{http_code}" >"%REPOHTTP%" 2>"%WORK%\repo-check-curl.txt"
set "LAST_CURL=!errorlevel!"
set "REPO_CODE="
if exist "%REPOHTTP%" set /p "REPO_CODE="<"%REPOHTTP%"
set "LAST_HTTP=!REPO_CODE!"
if not "!LAST_CURL!"=="0" exit /b 1
if not "!REPO_CODE!"=="200" exit /b 1
exit /b 0

:FETCH
set "FPATH=%~1"
set "FOUT=%~2"
"%CURL%" %TLS% --fail --location --silent --show-error --connect-timeout 15 --max-time 120 "https://raw.githubusercontent.com/%SOURCE_REPO%/%RUNTIME_REF%/!FPATH!" -o "!FOUT!"
if errorlevel 1 exit /b 1
if not exist "!FOUT!" exit /b 1
for %%Z in ("!FOUT!") do if %%~zZ LSS 20 exit /b 1
exit /b 0

:RESOLVE
set "%~2="
if not exist "%NSLOOKUP%" exit /b 0
set "CAND="
for /f "tokens=*" %%L in ('"%NSLOOKUP%" %~1 1.1.1.1 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="1.1.1.1" set "%~2=!CAND!"
)
exit /b 0

:WAIT
set /a WN=%~1+1
"%PING%" -n !WN! 127.0.0.1 >nul 2>&1
exit /b 0

:DEPFAIL
set "LAST_STAGE=DEPENDENCY_CHECK"
set "LAST_ERROR=Required WinRE component is missing"
goto :AUTHFAIL

:FETCHFAIL
set "LAST_ERROR=Validated RescueMeAI runtime could not be downloaded"
goto :AUTHFAIL

:REPOFAIL
color 0E >nul 2>&1
echo.
echo [WARNING] GitHub sign-in succeeded, but the credential cannot access
echo the private recovery repository.
echo Stage: !LAST_STAGE!
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
if exist "%WORK%\device-code.json" (
  set "ERRTEXT="
  for /f "delims=" %%A in ('"%CSCRIPT%" //nologo "%JSON%" "%WORK%\device-code.json" error 2^>nul') do set "ERRTEXT=%%A"
  if defined ERRTEXT echo GitHub error: !ERRTEXT!
)
echo No recovery command was executed.
exit /b 90
