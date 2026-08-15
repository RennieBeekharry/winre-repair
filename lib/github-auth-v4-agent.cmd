@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.15-V4-DETAILED-HANDOFF
rem RescueMeAI persistent-agent GitHub authorization/reporting module.
rem Interactive device authorization belongs to the launcher. This module only validates,
rem refreshes, and uploads with safe structured diagnostics. It never prints credential values.

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
set "GA_IDENTITY_HTTP=NOT_RUN"
set "GA_REPOSITORY_HTTP=NOT_RUN"
set "GA_REFRESH_HTTP=NOT_RUN"
set "GA_PHASE=INIT"
set "GA_LAST_SUCCESS=module entered"

if not exist "%GA_WORK%" md "%GA_WORK%" >nul 2>&1
if not exist "%GA_AUTHDIR%" md "%GA_AUTHDIR%" >nul 2>&1
if not exist "%GA_CURL%" goto :INIT_FAIL_CURL
if not exist "%GA_CONFIG%" goto :INIT_FAIL_CONFIG

for /f "usebackq tokens=1,* delims==" %%A in ("%GA_CONFIG%") do (
  if /i "%%A"=="LOG_REPO" set "GA_LOGREPO=%%B"
  if /i "%%A"=="GITHUB_REPOSITORY_ID" set "GA_REPOID=%%B"
  if /i "%%A"=="GITHUB_APP_CLIENT_ID" set "GA_CLIENTID=%%B"
  if /i "%%A"=="GITHUB_APP_ID" set "GA_APPID=%%B"
)
if not defined GA_LOGREPO goto :INIT_FAIL_CONFIG
if not defined GA_REPOID goto :INIT_FAIL_CONFIG
if not defined GA_CLIENTID goto :INIT_FAIL_CONFIG

if exist "%GA_WORK%\github-api-ip.txt" set /p "GA_APIIP="<"%GA_WORK%\github-api-ip.txt"
if exist "%GA_WORK%\github-web-ip.txt" set /p "GA_WEBIP="<"%GA_WORK%\github-web-ip.txt"
if not defined GA_APIIP goto :INIT_FAIL_ROUTE
if not defined GA_WEBIP goto :INIT_FAIL_ROUTE

"%GA_CURL%" --help all 2>nul | "%GA_FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "GA_TLS=--ssl-revoke-best-effort"
set "GA_LAST_SUCCESS=configuration and cached HTTPS routes loaded"
exit /b 0

:INIT_FAIL_CURL
call :WRITE_RESULT FAIL INIT "Required curl.exe is missing." 91
exit /b 91
:INIT_FAIL_CONFIG
call :WRITE_RESULT FAIL INIT "RescueMeAI GitHub configuration is missing or incomplete." 91
exit /b 91
:INIT_FAIL_ROUTE
call :WRITE_RESULT FAIL INIT "Validated cached GitHub HTTPS route is missing." 92
exit /b 92

:AUTHORIZE
call :INIT
if errorlevel 1 exit /b !errorlevel!
call :TEST_TOKEN
if not errorlevel 1 (
  call :WRITE_RESULT PASS SAVED_TOKEN "Saved GitHub authorization validated for identity and private recovery repository." 0
  exit /b 0
)
set "GA_PHASE=REFRESH"
call :REFRESH_CORE
if errorlevel 1 (
  call :WRITE_RESULT FAIL REFRESH "Saved authorization failed and refresh could not produce a validated replacement. Restart the RescueMeAI launcher for a new device authorization." 90
  exit /b 90
)
call :TEST_TOKEN
if errorlevel 1 (
  call :WRITE_RESULT FAIL POST_REFRESH "Refresh returned a credential, but GitHub validation still failed. Restart the RescueMeAI launcher." 90
  exit /b 90
)
call :WRITE_RESULT PASS POST_REFRESH "GitHub authorization refreshed and validated successfully." 0
exit /b 0

:REFRESH
call :INIT
if errorlevel 1 exit /b !errorlevel!
call :REFRESH_CORE
if errorlevel 1 exit /b 90
call :TEST_TOKEN
if errorlevel 1 exit /b 90
call :WRITE_RESULT PASS REFRESH "GitHub authorization refreshed and validated successfully." 0
exit /b 0

:TEST_TOKEN
set "GA_PHASE=SAVED_TOKEN_IDENTITY"
set "GA_IDENTITY_HTTP=NOT_RUN"
set "GA_REPOSITORY_HTTP=NOT_RUN"
if not exist "%GA_TOKEN%" exit /b 1
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 1

set "GA_OUT=%GA_WORK%\github-agent-user-test.json"
set "GA_HTTPFILE=%GA_WORK%\github-agent-user-test-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/user" -o "%GA_OUT%" -w "%%{http_code}" >"%GA_HTTPFILE%" 2>"%GA_WORK%\github-agent-user-test-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_IDENTITY_HTTP="
if exist "%GA_HTTPFILE%" set /p "GA_IDENTITY_HTTP="<"%GA_HTTPFILE%"
set "GA_LAST_HTTP=!GA_IDENTITY_HTTP!"
if not "!GA_LAST_CURL!"=="0" (
  set "GA_ACCESS="
  exit /b 1
)
if not "!GA_IDENTITY_HTTP!"=="200" (
  set "GA_ACCESS="
  exit /b 1
)
set "GA_LAST_SUCCESS=GitHub accepted saved credential for user identity"

set "GA_PHASE=SAVED_TOKEN_REPOSITORY"
set "GA_OUT=%GA_WORK%\github-agent-repo-test.json"
set "GA_HTTPFILE=%GA_WORK%\github-agent-repo-test-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%GA_REPOID%" -o "%GA_OUT%" -w "%%{http_code}" >"%GA_HTTPFILE%" 2>"%GA_WORK%\github-agent-repo-test-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_REPOSITORY_HTTP="
if exist "%GA_HTTPFILE%" set /p "GA_REPOSITORY_HTTP="<"%GA_HTTPFILE%"
set "GA_LAST_HTTP=!GA_REPOSITORY_HTTP!"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 1
if not "!GA_REPOSITORY_HTTP!"=="200" exit /b 1
set "GA_LAST_SUCCESS=GitHub accepted saved credential for private recovery repository"
exit /b 0

:REFRESH_CORE
set "GA_PHASE=REFRESH"
set "GA_REFRESH_HTTP=NOT_RUN"
if not exist "%GA_REFRESH%" exit /b 90
if not exist "%GA_HELPER%" exit /b 90
if not exist "%GA_CSCRIPT%" exit /b 90
set "GA_SAVED_REFRESH="
set /p "GA_SAVED_REFRESH="<"%GA_REFRESH%"
if not defined GA_SAVED_REFRESH exit /b 90
set "GA_JSON=%GA_WORK%\github-agent-refresh.json"
set "GA_HTTPFILE=%GA_WORK%\github-agent-refresh-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!GA_SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%GA_JSON%" -w "%%{http_code}" >"%GA_HTTPFILE%" 2>"%GA_WORK%\github-agent-refresh-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_REFRESH_HTTP="
if exist "%GA_HTTPFILE%" set /p "GA_REFRESH_HTTP="<"%GA_HTTPFILE%"
set "GA_LAST_HTTP=!GA_REFRESH_HTTP!"
set "GA_SAVED_REFRESH="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_REFRESH_HTTP!"=="200" exit /b 90
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
call :JGET "%GA_JSON%" access_token GA_NEW_ACCESS
if errorlevel 1 exit /b 90
call :JGET "%GA_JSON%" refresh_token GA_NEW_REFRESH
call :STORE_TOKEN "!GA_NEW_ACCESS!" "!GA_NEW_REFRESH!"
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
set "GA_LAST_SUCCESS=refresh endpoint returned and stored a replacement credential"
exit /b 0

:UPLOAD
call :INIT
if errorlevel 1 exit /b !errorlevel!
call :AUTHORIZE
if errorlevel 1 exit /b !errorlevel!
call :UPLOAD_CORE
if not errorlevel 1 (
  call :WRITE_RESULT PASS REPORT_UPLOAD "Private recovery report uploaded successfully." 0
  exit /b 0
)
call :WRITE_RESULT FAIL REPORT_UPLOAD "Private recovery report upload failed." 90
exit /b 90

:UPLOAD_CORE
set "GA_PHASE=REPORT_UPLOAD"
if not exist "%GA_TOKEN%" exit /b 90
if not exist "%GA_CERTUTIL%" exit /b 90
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
if errorlevel 1 (
  set "GA_ACCESS="
  exit /b 90
)
set "GA_B64="
for /f "usebackq delims=" %%L in ("%GA_B64TMP%") do (
  echo(%%L| "%GA_FINDSTR%" /b /c:"-----" >nul 2>&1
  if errorlevel 1 set "GA_B64=!GA_B64!%%L"
)
set "GA_PATH=reports/inbox/run-%RANDOM%%RANDOM%%RANDOM%.txt"
>"%GA_BODY%" echo {"message":"RescueMeAI recovery report","content":"!GA_B64!"}
set "GA_B64="
set "GA_HTTPFILE=%GA_WORK%\github-agent-upload-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%GA_BODY%" "https://api.github.com/repos/%GA_LOGREPO%/contents/!GA_PATH!" -o "%GA_WORK%\github-agent-upload-response.json" -w "%%{http_code}" >"%GA_HTTPFILE%" 2>"%GA_WORK%\github-agent-upload-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_HTTPFILE%" set /p "GA_LAST_HTTP="<"%GA_HTTPFILE%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="201" exit /b 90
set "GA_LAST_SUCCESS=private recovery report accepted by GitHub"
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
if not defined GA_STORE_ACCESS exit /b 1
>"%GA_TOKEN%" echo(!GA_STORE_ACCESS!
attrib +h +s "%GA_TOKEN%" >nul 2>&1
if defined GA_STORE_REFRESH (
  >"%GA_REFRESH%" echo(!GA_STORE_REFRESH!
  attrib +h +s "%GA_REFRESH%" >nul 2>&1
)
exit /b 0

:WRITE_RESULT
set "GR_STATUS=%~1"
set "GR_PHASE=%~2"
set "GR_REASON=%~3"
set "GR_RC=%~4"
>"%GA_RESULT%" echo status=%GR_STATUS%
>>"%GA_RESULT%" echo phase=%GR_PHASE%
>>"%GA_RESULT%" echo reason=%GR_REASON%
>>"%GA_RESULT%" echo return_code=%GR_RC%
>>"%GA_RESULT%" echo http=%GA_LAST_HTTP%
>>"%GA_RESULT%" echo curl_return_code=%GA_LAST_CURL%
>>"%GA_RESULT%" echo identity_http=%GA_IDENTITY_HTTP%
>>"%GA_RESULT%" echo repository_http=%GA_REPOSITORY_HTTP%
>>"%GA_RESULT%" echo refresh_http=%GA_REFRESH_HTTP%
>>"%GA_RESULT%" echo transport=HTTPS_TLS
>>"%GA_RESULT%" echo component=github-auth-v4-agent
>>"%GA_RESULT%" echo last_success=%GA_LAST_SUCCESS%
exit /b 0
