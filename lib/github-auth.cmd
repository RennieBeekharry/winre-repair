@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.15-V2-SELF-HEALING-TLS
rem RescueMeAI GitHub App user-token auth for WinRE.
rem - HTTPS/TLS only.
rem - Refreshes expiring user tokens.
rem - Falls back to GitHub device flow when refresh is invalid/expired.
rem - Never writes access/refresh tokens to GitHub reports.

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
set "GA_RESOLVE=%GA_WORK%\runtime\resolve.cmd"
set "GA_APIHOST=api.github.com"
set "GA_WEBHOST=github.com"
set "GA_LOGREPO="
set "GA_REPOID="
set "GA_CLIENTID="
set "GA_APPID="
set "GA_APIIP="
set "GA_WEBIP="
set "GA_TLS=--ssl-revoke-best-effort"
set "GA_LAST_HTTP="
set "GA_LAST_CURL="
if not exist "%GA_WORK%" md "%GA_WORK%" >nul 2>&1
if not exist "%GA_AUTHDIR%" md "%GA_AUTHDIR%" >nul 2>&1
if not exist "%GA_CURL%" call :FAIL 91 "Required curl.exe is missing." & exit /b 91
if not exist "%GA_CERTUTIL%" call :FAIL 91 "Required certutil.exe is missing." & exit /b 91
if not exist "%GA_CONFIG%" call :FAIL 91 "RescueMeAI configuration is missing." & exit /b 91
if not exist "%GA_RESOLVE%" call :FAIL 91 "RescueMeAI secure resolver is missing." & exit /b 91
for /f "usebackq tokens=1,* delims==" %%A in ("%GA_CONFIG%") do (
  if /i "%%A"=="LOG_REPO" set "GA_LOGREPO=%%B"
  if /i "%%A"=="GITHUB_REPOSITORY_ID" set "GA_REPOID=%%B"
  if /i "%%A"=="GITHUB_APP_CLIENT_ID" set "GA_CLIENTID=%%B"
  if /i "%%A"=="GITHUB_APP_ID" set "GA_APPID=%%B"
)
if not defined GA_LOGREPO call :FAIL 91 "LOG_REPO configuration is missing." & exit /b 91
if not defined GA_REPOID call :FAIL 91 "GitHub repository restriction is missing." & exit /b 91
if not defined GA_CLIENTID call :FAIL 91 "GitHub App Client ID is missing." & exit /b 91
call "%GA_RESOLVE%" resolve "%GA_APIHOST%" GA_APIIP
if errorlevel 1 call :FAIL 92 "Could not establish a validated HTTPS route to api.github.com." & exit /b 92
call "%GA_RESOLVE%" resolve "%GA_WEBHOST%" GA_WEBIP
if errorlevel 1 call :FAIL 92 "Could not establish a validated HTTPS route to github.com." & exit /b 92
exit /b 0

:AUTHORIZE
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :AUTHORIZE_CORE
exit /b %errorlevel%

:AUTHORIZE_CORE
if exist "%GA_TOKEN%" (
  call :TEST_TOKEN
  if not errorlevel 1 exit /b 0
)
if exist "%GA_REFRESH%" (
  call :REFRESH_CORE
  if not errorlevel 1 (
    call :TEST_TOKEN
    if not errorlevel 1 exit /b 0
  )
)
rem A bad/expired refresh token is not fatal. GitHub explicitly requires restarting
rem the device flow in that case.
call :DEVICE_FLOW
if errorlevel 1 exit /b %errorlevel%
call :TEST_TOKEN
if errorlevel 1 (
  call :FAIL 90 "GitHub device authorization completed, but the resulting token could not access the configured private repository."
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
set "GA_SAVED_REFRESH="
set /p "GA_SAVED_REFRESH="<"%GA_REFRESH%"
if not defined GA_SAVED_REFRESH exit /b 90
set "GA_JSON=%GA_WORK%\github-refresh-v2.json"
set "GA_HTTP=%GA_WORK%\github-refresh-v2-http.txt"
if exist "%GA_JSON%" del /f /q "%GA_JSON%" >nul 2>&1
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!GA_SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%GA_JSON%" -w "%%{http_code}" >"%GA_HTTP%" 2>"%GA_WORK%\github-refresh-v2-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_HTTP%" set /p "GA_LAST_HTTP="<"%GA_HTTP%"
set "GA_SAVED_REFRESH="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="200" exit /b 90
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
set "GA_ERROR="
call :JSON_GET "%GA_JSON%" access_token GA_NEW_ACCESS >nul 2>&1
if not defined GA_NEW_ACCESS (
  call :JSON_GET "%GA_JSON%" error GA_ERROR >nul 2>&1
  if /i "!GA_ERROR!"=="bad_refresh_token" (
    if exist "%GA_REFRESH%" move /y "%GA_REFRESH%" "%GA_REFRESH%.stale" >nul 2>&1
    if exist "%GA_TOKEN%" del /f /q /a "%GA_TOKEN%" >nul 2>&1
  )
  exit /b 90
)
call :JSON_GET "%GA_JSON%" refresh_token GA_NEW_REFRESH >nul 2>&1
call :STORE_TOKEN "!GA_NEW_ACCESS!" "!GA_NEW_REFRESH!" REFRESH
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
exit /b 0

:DEVICE_FLOW
set "GA_DEVJSON=%GA_WORK%\github-device-v14.json"
set "GA_DEVHTTP=%GA_WORK%\github-device-v14-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" "https://github.com/login/device/code" -o "%GA_DEVJSON%" -w "%%{http_code}" >"%GA_DEVHTTP%" 2>"%GA_WORK%\github-device-v14-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_DEVHTTP%" set /p "GA_LAST_HTTP="<"%GA_DEVHTTP%"
if not "!GA_LAST_CURL!"=="0" (
  call :FAIL 90 "GitHub device authorization request failed at the HTTPS transport layer."
  exit /b 90
)
if not "!GA_LAST_HTTP!"=="200" (
  call :FAIL 90 "GitHub device authorization endpoint did not return HTTP 200."
  exit /b 90
)
set "GA_DEVICE_CODE="
set "GA_USER_CODE="
set "GA_VERIFY_URI=https://github.com/login/device"
set "GA_EXPIRES=900"
set "GA_INTERVAL=5"
set "GA_ERROR="
call :JSON_GET "%GA_DEVJSON%" error GA_ERROR >nul 2>&1
if defined GA_ERROR (
  call :FAIL 90 "GitHub device authorization returned an error before pairing could start."
  exit /b 90
)
call :JSON_GET "%GA_DEVJSON%" device_code GA_DEVICE_CODE
if errorlevel 1 (
  call :FAIL 96 "GitHub returned HTTP 200 but no device_code could be parsed."
  exit /b 96
)
call :JSON_GET "%GA_DEVJSON%" user_code GA_USER_CODE
if errorlevel 1 (
  call :FAIL 96 "GitHub returned a device_code but no user_code could be parsed."
  exit /b 96
)
call :JSON_GET "%GA_DEVJSON%" verification_uri GA_VERIFY_URI >nul 2>&1
call :JSON_GET "%GA_DEVJSON%" expires_in GA_EXPIRES >nul 2>&1
call :JSON_GET "%GA_DEVJSON%" interval GA_INTERVAL >nul 2>&1
if not defined GA_EXPIRES set "GA_EXPIRES=900"
if not defined GA_INTERVAL set "GA_INTERVAL=5"

cls
color 0E >nul 2>&1
echo ====================================================================================================
echo                                           RESCUEMEAI
echo                                  LOCAL ACTION REQUIRED
echo ====================================================================================================
echo.
echo Secure GitHub authorization needs renewal.
echo.
echo ON YOUR PHONE
echo ----------------------------------------------------------------------------------------------------
echo   Open: !GA_VERIFY_URI!
echo   Enter this one-time code:
echo.
echo                                    !GA_USER_CODE!
echo.
echo   Approve the RescueMeAI GitHub App.
echo.
echo WHAT HAPPENS NEXT
echo ----------------------------------------------------------------------------------------------------
echo   RescueMeAI will detect approval automatically and continue.
echo   No Windows repair runs during authorization.
echo.

set /a GA_MAXPOLLS=(GA_EXPIRES/GA_INTERVAL)+4 >nul 2>&1
if !GA_MAXPOLLS! LSS 10 set "GA_MAXPOLLS=180"
set /a GA_POLL=0
:DEVICE_POLL
set /a GA_POLL+=1
if !GA_POLL! GTR !GA_MAXPOLLS! (
  call :FAIL 90 "GitHub device authorization code expired before approval completed."
  exit /b 90
)
timeout /t !GA_INTERVAL! /nobreak >nul
set "GA_TJSON=%GA_WORK%\github-token-v14.json"
set "GA_THTTP=%GA_WORK%\github-token-v14-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "device_code=!GA_DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" --data-urlencode "repository_id=%GA_REPOID%" "https://github.com/login/oauth/access_token" -o "%GA_TJSON%" -w "%%{http_code}" >"%GA_THTTP%" 2>"%GA_WORK%\github-token-v14-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_THTTP%" set /p "GA_LAST_HTTP="<"%GA_THTTP%"
if not "!GA_LAST_CURL!"=="0" goto :DEVICE_POLL
if not "!GA_LAST_HTTP!"=="200" goto :DEVICE_POLL
set "GA_ACCESS="
set "GA_NEW_REFRESH="
set "GA_TOKEN_ERROR="
call :JSON_GET "%GA_TJSON%" access_token GA_ACCESS >nul 2>&1
if defined GA_ACCESS (
  call :JSON_GET "%GA_TJSON%" refresh_token GA_NEW_REFRESH >nul 2>&1
  call :STORE_TOKEN "!GA_ACCESS!" "!GA_NEW_REFRESH!" DEVICE
  set "GA_ACCESS="
  set "GA_NEW_REFRESH="
  exit /b 0
)
call :JSON_GET "%GA_TJSON%" error GA_TOKEN_ERROR >nul 2>&1
if /i "!GA_TOKEN_ERROR!"=="authorization_pending" goto :DEVICE_POLL
if /i "!GA_TOKEN_ERROR!"=="slow_down" (
  set /a GA_INTERVAL+=5
  goto :DEVICE_POLL
)
if /i "!GA_TOKEN_ERROR!"=="access_denied" (
  call :FAIL 90 "GitHub device authorization was denied."
  exit /b 90
)
if /i "!GA_TOKEN_ERROR!"=="expired_token" (
  call :FAIL 90 "GitHub device authorization code expired."
  exit /b 90
)
if defined GA_TOKEN_ERROR (
  call :FAIL 90 "GitHub device authorization returned an unrecoverable OAuth error."
  exit /b 90
)
goto :DEVICE_POLL

:TEST_TOKEN
if not exist "%GA_TOKEN%" exit /b 1
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 1
set "GA_TEST=%GA_WORK%\github-token-test-v2.json"
set "GA_TESTHTTP=%GA_WORK%\github-token-test-v2-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%GA_REPOID%" -o "%GA_TEST%" -w "%%{http_code}" >"%GA_TESTHTTP%" 2>"%GA_WORK%\github-token-test-v2-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_TESTHTTP%" set /p "GA_LAST_HTTP="<"%GA_TESTHTTP%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 1
if not "!GA_LAST_HTTP!"=="200" exit /b 1
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

:UPLOAD
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :AUTHORIZE_CORE
if errorlevel 1 exit /b %errorlevel%
call :UPLOAD_CORE
if errorlevel 1 (
  if "!GA_LAST_HTTP!"=="401" (
    call :REFRESH_CORE
    if not errorlevel 1 call :UPLOAD_CORE
  )
)
exit /b %errorlevel%

:UPLOAD_CORE
if not exist "%GA_TOKEN%" exit /b 90
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 90
set "GA_PAYLOAD=%GA_WORK%\private-report-v2.txt"
set "GA_B64TMP=%GA_WORK%\private-report-v2.b64"
set "GA_BODY=%GA_WORK%\private-report-v2.json"
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
  echo(%%L| findstr /b /c:"-----" >nul 2>&1
  if errorlevel 1 set "GA_B64=!GA_B64!%%L"
)
set "GA_PATH=reports/inbox/run-%RANDOM%%RANDOM%%RANDOM%.txt"
>"%GA_BODY%" echo {"message":"RescueMeAI recovery report","content":"!GA_B64!"}
set "GA_B64="
set "GA_UPHTTP=%GA_WORK%\github-upload-v2-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%GA_BODY%" "https://api.github.com/repos/%GA_LOGREPO%/contents/!GA_PATH!" -o "%GA_WORK%\github-upload-v2-response.json" -w "%%{http_code}" >"%GA_UPHTTP%" 2>"%GA_WORK%\github-upload-v2-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%GA_UPHTTP%" set /p "GA_LAST_HTTP="<"%GA_UPHTTP%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="201" exit /b 90
exit /b 0

:JSON_GET
setlocal EnableDelayedExpansion
set "JG_FILE=%~1"
set "JG_KEY=%~2"
set "JG_JSON="
if not exist "!JG_FILE!" endlocal & exit /b 1
for /f "usebackq delims=" %%L in ("!JG_FILE!") do set "JG_JSON=!JG_JSON!%%L"
if not defined JG_JSON endlocal & exit /b 1
set "JG_JSON=!JG_JSON:"=!"
set "JG_JSON=!JG_JSON:{=!"
set "JG_JSON=!JG_JSON:}=!"
set "JG_JSON=!JG_JSON:,= !"
set "JG_VALUE="
for %%P in (!JG_JSON!) do (
  for /f "tokens=1,* delims=:" %%A in ("%%P") do (
    if /i "%%A"=="!JG_KEY!" set "JG_VALUE=%%B"
  )
)
if not defined JG_VALUE endlocal & exit /b 1
endlocal & set "%~3=%JG_VALUE%" & exit /b 0

:FAIL
set "GF_RC=%~1"
set "GF_REASON=%~2"
>"%GA_RESULT%" echo status=FAIL
>>"%GA_RESULT%" echo reason=%GF_REASON%
>>"%GA_RESULT%" echo http=%GA_LAST_HTTP%
>>"%GA_RESULT%" echo curl_return_code=%GA_LAST_CURL%
>>"%GA_RESULT%" echo transport=HTTPS_TLS
exit /b 0
