@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.15-V3-LAUNCHER-HANDOFF
rem RescueMeAI agent-side GitHub authentication for WinRE.
rem The launcher owns interactive device authorization. The persistent agent only:
rem - validates the already-issued token;
rem - refreshes it when possible;
rem - uploads bounded private recovery reports.
rem No device-flow prompt is started from inside the persistent agent.

if /i "%~1"=="authorize" goto :AUTHORIZE
if /i "%~1"=="refresh" goto :REFRESH
if /i "%~1"=="upload" goto :UPLOAD
exit /b 64

:INIT
set "GA_WORK=C:\WinRERepair"
set "GA_CONFIG=%GA_WORK%\agent.cfg"
set "GA_AUTHDIR=%GA_WORK%\.auth"
set "GA_TOKEN=%GA_AUTHDIR%\github-logs.token"
set "GA_REFRESH=%GA_AUTHDIR%\github-refresh.token"
set "GA_META=%GA_AUTHDIR%\github-token.meta"
set "GA_RESULT=%GA_WORK%\GITHUB_RESULT.txt"
set "GA_CURL=C:\Windows\System32\curl.exe"
set "GA_CERTUTIL=C:\Windows\System32\certutil.exe"
set "GA_FINDSTR=C:\Windows\System32\findstr.exe"
set "GA_CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%GA_CSCRIPT%" set "GA_CSCRIPT=C:\Windows\System32\cscript.exe"
set "GA_HELPER=%GA_WORK%\start23-json.js"
set "GA_APIHOST=api.github.com"
set "GA_WEBHOST=github.com"
set "GA_LOGREPO="
set "GA_REPOID="
set "GA_CLIENTID="
set "GA_APPID="
set "GA_APIIP="
set "GA_WEBIP="
set "GA_TLS="
set "GA_LAST_HTTP=NOT_RUN"
set "GA_LAST_CURL=NOT_RUN"

if not exist "%GA_WORK%" md "%GA_WORK%" >nul 2>&1
if not exist "%GA_AUTHDIR%" md "%GA_AUTHDIR%" >nul 2>&1

if not exist "%GA_CURL%" (
  call :FAIL 91 "Required curl.exe is missing."
  exit /b 91
)
if not exist "%GA_CERTUTIL%" (
  call :FAIL 91 "Required certutil.exe is missing."
  exit /b 91
)
if not exist "%GA_CONFIG%" (
  call :FAIL 91 "RescueMeAI configuration is missing."
  exit /b 91
)

for /f "usebackq tokens=1,* delims==" %%A in ("%GA_CONFIG%") do (
  if /i "%%A"=="LOG_REPO" set "GA_LOGREPO=%%B"
  if /i "%%A"=="GITHUB_REPOSITORY_ID" set "GA_REPOID=%%B"
  if /i "%%A"=="GITHUB_APP_CLIENT_ID" set "GA_CLIENTID=%%B"
  if /i "%%A"=="GITHUB_APP_ID" set "GA_APPID=%%B"
)
if not defined GA_LOGREPO (
  call :FAIL 91 "LOG_REPO configuration is missing."
  exit /b 91
)
if not defined GA_REPOID (
  call :FAIL 91 "GitHub repository restriction is missing."
  exit /b 91
)
if not defined GA_CLIENTID (
  call :FAIL 91 "GitHub App Client ID is missing."
  exit /b 91
)

if exist "%GA_WORK%\github-api-ip.txt" set /p "GA_APIIP="<"%GA_WORK%\github-api-ip.txt"
if exist "%GA_WORK%\github-web-ip.txt" set /p "GA_WEBIP="<"%GA_WORK%\github-web-ip.txt"
if not defined GA_APIIP (
  call :FAIL 92 "Validated api.github.com route cache is missing."
  exit /b 92
)
if not defined GA_WEBIP (
  call :FAIL 92 "Validated github.com route cache is missing."
  exit /b 92
)

"%GA_CURL%" --help all 2>nul | "%GA_FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "GA_TLS=--ssl-revoke-best-effort"
exit /b 0

:AUTHORIZE
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :AUTHORIZE_CORE
exit /b %errorlevel%

:AUTHORIZE_CORE
call :TEST_TOKEN
if not errorlevel 1 exit /b 0
call :REFRESH_CORE
if errorlevel 1 (
  call :FAIL 90 "Saved GitHub authorization is no longer valid. Restart the RescueMeAI launcher to renew authorization."
  exit /b 90
)
call :TEST_TOKEN
if errorlevel 1 (
  call :FAIL 90 "GitHub token refresh completed but repository validation still failed. Restart the RescueMeAI launcher."
  exit /b 90
)
exit /b 0

:REFRESH
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :REFRESH_CORE
exit /b %errorlevel%

:REFRESH_CORE
if not exist "%GA_REFRESH%" exit /b 90
if not exist "%GA_HELPER%" exit /b 90
if not exist "%GA_CSCRIPT%" exit /b 90
set "GA_SAVED_REFRESH="
set /p "GA_SAVED_REFRESH="<"%GA_REFRESH%"
if not defined GA_SAVED_REFRESH exit /b 90
set "GA_JSON=%GA_WORK%\github-agent-refresh.json"
set "GA_HTTP=%GA_WORK%\github-agent-refresh-http.txt"
if exist "%GA_JSON%" del /f /q "%GA_JSON%" >nul 2>&1
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!GA_SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%GA_JSON%" -w "%%{http_code}" >"%GA_HTTP%" 2>"%GA_WORK%\github-agent-refresh-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_HTTP%" set /p "GA_LAST_HTTP="<"%GA_HTTP%"
set "GA_SAVED_REFRESH="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="200" exit /b 90
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
call :JGET "%GA_JSON%" access_token GA_NEW_ACCESS
if errorlevel 1 exit /b 90
call :JGET "%GA_JSON%" refresh_token GA_NEW_REFRESH
call :STORE_TOKEN "!GA_NEW_ACCESS!" "!GA_NEW_REFRESH!" REFRESH
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
exit /b 0

:TEST_TOKEN
if not exist "%GA_TOKEN%" exit /b 1
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 1
set "GA_TEST=%GA_WORK%\github-agent-token-test.json"
set "GA_TESTHTTP=%GA_WORK%\github-agent-token-test-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%GA_REPOID%" -o "%GA_TEST%" -w "%%{http_code}" >"%GA_TESTHTTP%" 2>"%GA_WORK%\github-agent-token-test-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_TESTHTTP%" set /p "GA_LAST_HTTP="<"%GA_TESTHTTP%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 1
if not "!GA_LAST_HTTP!"=="200" exit /b 1
exit /b 0

:UPLOAD
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :AUTHORIZE_CORE
if errorlevel 1 exit /b %errorlevel%
call :UPLOAD_CORE
if not errorlevel 1 exit /b 0
if "!GA_LAST_HTTP!"=="401" (
  call :REFRESH_CORE
  if not errorlevel 1 call :UPLOAD_CORE
)
exit /b %errorlevel%

:UPLOAD_CORE
if not exist "%GA_TOKEN%" exit /b 90
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 90
set "GA_PAYLOAD=%GA_WORK%\private-report-agent.txt"
set "GA_B64TMP=%GA_WORK%\private-report-agent.b64"
set "GA_BODY=%GA_WORK%\private-report-agent.json"
>"%GA_PAYLOAD%" echo PRIVATE RESCUEMEAI RECOVERY RUN REPORT
>>"%GA_PAYLOAD%" echo ======================================
if exist "%GA_WORK%\LAST_RUN_REPORT.txt" type "%GA_WORK%\LAST_RUN_REPORT.txt" >>"%GA_PAYLOAD%"
if exist "%GA_WORK%\RUN_DETAILS.txt" (
  >>"%GA_PAYLOAD%" echo.
  >>"%GA_PAYLOAD%" echo --- RUN_DETAILS ---
  type "%GA_WORK%\RUN_DETAILS.txt" >>"%GA_PAYLOAD%"
)
for %%Z in ("%GA_PAYLOAD%") do set "GA_SIZE=%%~zZ"
if !GA_SIZE! GTR 6000 (
  >"%GA_PAYLOAD%" echo PRIVATE RESCUEMEAI RECOVERY RUN REPORT
  >>"%GA_PAYLOAD%" echo ======================================
  if exist "%GA_WORK%\LAST_RUN_REPORT.txt" type "%GA_WORK%\LAST_RUN_REPORT.txt" >>"%GA_PAYLOAD%"
  >>"%GA_PAYLOAD%" echo details_status=LOCAL_DETAILS_TOO_LARGE_FOR_CMD_UPLOAD
  >>"%GA_PAYLOAD%" echo details_path=C:\WinRERepair\RUN_DETAILS.txt
)
if exist "%GA_B64TMP%" del /f /q "%GA_B64TMP%" >nul 2>&1
"%GA_CERTUTIL%" -encode "%GA_PAYLOAD%" "%GA_B64TMP%" >nul 2>&1
if errorlevel 1 exit /b 90
set "GA_B64="
for /f "usebackq delims=" %%L in ("%GA_B64TMP%") do (
  echo(%%L| "%GA_FINDSTR%" /b /c:"-----" >nul 2>&1
  if errorlevel 1 set "GA_B64=!GA_B64!%%L"
)
set "GA_PATH=reports/inbox/run-%RANDOM%%RANDOM%%RANDOM%.txt"
>"%GA_BODY%" echo {"message":"RescueMeAI recovery report","content":"!GA_B64!"}
set "GA_B64="
set "GA_UPHTTP=%GA_WORK%\github-agent-upload-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%GA_BODY%" "https://api.github.com/repos/%GA_LOGREPO%/contents/!GA_PATH!" -o "%GA_WORK%\github-agent-upload-response.json" -w "%%{http_code}" >"%GA_UPHTTP%" 2>"%GA_WORK%\github-agent-upload-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_UPHTTP%" set /p "GA_LAST_HTTP="<"%GA_UPHTTP%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="201" exit /b 90
exit /b 0

:JGET
set "%~3="
if not exist "%GA_HELPER%" exit /b 1
set "GA_JOUT=%GA_WORK%\github-agent-jget.txt"
if exist "%GA_JOUT%" del /f /q "%GA_JOUT%" >nul 2>&1
"%GA_CSCRIPT%" //nologo "%GA_HELPER%" "%~1" "%~2" >"%GA_JOUT%" 2>"%GA_WORK%\github-agent-jget-error.txt"
if errorlevel 1 exit /b 1
set "GA_JV="
set /p "GA_JV="<"%GA_JOUT%"
if not defined GA_JV exit /b 1
set "%~3=!GA_JV!"
set "GA_JV="
exit /b 0

:STORE_TOKEN
set "GA_STORE_ACCESS=%~1"
set "GA_STORE_REFRESH=%~2"
set "GA_STORE_SOURCE=%~3"
if not defined GA_STORE_ACCESS exit /b 1
>"%GA_TOKEN%" echo(!GA_STORE_ACCESS!
attrib +h +s "%GA_TOKEN%" >nul 2>&1
if defined GA_STORE_REFRESH (
  >"%GA_REFRESH%" echo(!GA_STORE_REFRESH!
  attrib +h +s "%GA_REFRESH%" >nul 2>&1
)
>"%GA_META%" echo provider=GITHUB_APP
>>"%GA_META%" echo app_id=%GA_APPID%
>>"%GA_META%" echo repository_id=%GA_REPOID%
>>"%GA_META%" echo source=%GA_STORE_SOURCE%
>>"%GA_META%" echo issued_date=%date%
>>"%GA_META%" echo issued_time=%time%
attrib +h +s "%GA_META%" >nul 2>&1
set "GA_STORE_ACCESS="
set "GA_STORE_REFRESH="
exit /b 0

:FAIL
set "GF_RC=%~1"
set "GF_REASON=%~2"
>"%GA_RESULT%" echo status=FAIL
>>"%GA_RESULT%" echo reason=%GF_REASON%
>>"%GA_RESULT%" echo http=%GA_LAST_HTTP%
>>"%GA_RESULT%" echo curl_return_code=%GA_LAST_CURL%
>>"%GA_RESULT%" echo transport=HTTPS_TLS
>>"%GA_RESULT%" echo component=github-auth-v3-agent-handoff
exit /b 0
