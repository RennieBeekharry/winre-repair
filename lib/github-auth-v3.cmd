@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth-v3 2026.08.15-CSCRIPT-JSON-TLS
rem RescueMeAI GitHub App authorization for WinRE.
rem Uses HTTPS/TLS only and a local cscript JSON parser.

if /i "%~1"=="authorize" goto :AUTHORIZE
if /i "%~1"=="refresh" goto :REFRESH
if /i "%~1"=="upload" goto :UPLOAD
exit /b 64

:INIT
set "GA_WORK=C:\WinRERepair"
set "GA_RUNTIME=%GA_WORK%\runtime"
set "GA_CONFIG=%GA_WORK%\agent.cfg"
set "GA_AUTHDIR=%GA_WORK%\.auth"
set "GA_TOKEN=%GA_AUTHDIR%\github-logs.token"
set "GA_REFRESH=%GA_AUTHDIR%\github-refresh.token"
set "GA_META=%GA_AUTHDIR%\github-token.meta"
set "GA_RESULT=%GA_WORK%\GITHUB_RESULT.txt"
set "GA_REPORT=%GA_WORK%\LAST_RUN_REPORT.txt"
set "GA_DETAILS=%GA_WORK%\RUN_DETAILS.txt"
set "GA_CURL=C:\Windows\System32\curl.exe"
set "GA_CERTUTIL=C:\Windows\System32\certutil.exe"
set "GA_FINDSTR=C:\Windows\System32\findstr.exe"
set "GA_CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%GA_CSCRIPT%" set "GA_CSCRIPT=C:\Windows\System32\cscript.exe"
set "GA_JSON=%GA_RUNTIME%\json-value-v1.js"
set "GA_RESOLVE=%GA_RUNTIME%\resolve.cmd"
set "GA_APIHOST=api.github.com"
set "GA_WEBHOST=github.com"
set "GA_APIIP="
set "GA_WEBIP="
set "GA_LOGREPO="
set "GA_REPOID="
set "GA_CLIENTID="
set "GA_APPID="
set "GA_TLS="
set "GA_LAST_HTTP="
set "GA_LAST_CURL="
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
if not exist "%GA_FINDSTR%" (
  call :FAIL 91 "Required findstr.exe is missing."
  exit /b 91
)
if not exist "%GA_CSCRIPT%" (
  call :FAIL 91 "Required cscript.exe is missing."
  exit /b 91
)
if not exist "%GA_JSON%" (
  call :FAIL 91 "RescueMeAI JSON parser is missing."
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
"%GA_CURL%" --help all 2>nul | "%GA_FINDSTR%" /c:"--ssl-revoke-best-effort" >nul 2>&1
if not errorlevel 1 set "GA_TLS=--ssl-revoke-best-effort"
if exist "%GA_WORK%\github-api-ip.txt" set /p "GA_APIIP="<"%GA_WORK%\github-api-ip.txt"
if exist "%GA_WORK%\github-web-ip.txt" set /p "GA_WEBIP="<"%GA_WORK%\github-web-ip.txt"
if not defined GA_APIIP if exist "%GA_RESOLVE%" call "%GA_RESOLVE%" resolve "%GA_APIHOST%" GA_APIIP
if not defined GA_WEBIP if exist "%GA_RESOLVE%" call "%GA_RESOLVE%" resolve "%GA_WEBHOST%" GA_WEBIP
if not defined GA_APIIP (
  call :FAIL 92 "Could not establish a validated route to api.github.com."
  exit /b 92
)
if not defined GA_WEBIP (
  call :FAIL 92 "Could not establish a validated route to github.com."
  exit /b 92
)
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
call :DEVICE_FLOW
if errorlevel 1 exit /b %errorlevel%
call :TEST_TOKEN
if errorlevel 1 (
  call :FAIL 90 "GitHub authorization completed, but the new token could not access the private recovery repository."
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
set "F=%GA_WORK%\github-refresh-v3.json"
set "H=%GA_WORK%\github-refresh-v3-http.txt"
if exist "%F%" del /f /q "%F%" >nul 2>&1
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "grant_type=refresh_token" --data-urlencode "refresh_token=!GA_SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%F%" -w "%%{http_code}" >"%H%" 2>"%GA_WORK%\github-refresh-v3-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_SAVED_REFRESH="
set "GA_LAST_HTTP="
if exist "%H%" set /p "GA_LAST_HTTP="<"%H%"
if not "!GA_LAST_CURL!"=="0" exit /b 90
if not "!GA_LAST_HTTP!"=="200" exit /b 90
call :JGET "%F%" access_token GA_NEW_ACCESS
if not defined GA_NEW_ACCESS (
  call :JGET "%F%" error GA_ERROR
  if defined GA_ERROR (
    if exist "%GA_REFRESH%" move /y "%GA_REFRESH%" "%GA_REFRESH%.stale" >nul 2>&1
  )
  exit /b 90
)
call :JGET "%F%" refresh_token GA_NEW_REFRESH
call :JGET "%F%" expires_in GA_ACCESS_EXPIRES
call :JGET "%F%" refresh_token_expires_in GA_REFRESH_EXPIRES
call :STORE_TOKEN "!GA_NEW_ACCESS!" "!GA_NEW_REFRESH!" REFRESH
set "GA_NEW_ACCESS="
set "GA_NEW_REFRESH="
exit /b 0

:DEVICE_FLOW
set "D=%GA_WORK%\github-device-v15.json"
set "DH=%GA_WORK%\github-device-v15-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" "https://github.com/login/device/code" -o "%D%" -w "%%{http_code}" >"%DH%" 2>"%GA_WORK%\github-device-v15-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%DH%" set /p "GA_LAST_HTTP="<"%DH%"
if not "!GA_LAST_CURL!"=="0" (
  call :FAIL 90 "GitHub device authorization request failed at the HTTPS transport layer."
  exit /b 90
)
if not "!GA_LAST_HTTP!"=="200" (
  call :FAIL 90 "GitHub device authorization endpoint did not return HTTP 200."
  exit /b 90
)
call :JGET "%D%" device_code GA_DEVICE_CODE
call :JGET "%D%" user_code GA_USER_CODE
call :JGET "%D%" verification_uri GA_VERIFY_URI
call :JGET "%D%" expires_in GA_EXPIRES
call :JGET "%D%" interval GA_INTERVAL
if not defined GA_DEVICE_CODE (
  call :FAIL 96 "GitHub returned HTTP 200 but the device code could not be parsed."
  exit /b 96
)
if not defined GA_USER_CODE (
  call :FAIL 96 "GitHub returned a device code but the user code could not be parsed."
  exit /b 96
)
if not defined GA_VERIFY_URI set "GA_VERIFY_URI=https://github.com/login/device"
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
set /a GA_MAX=(GA_EXPIRES/GA_INTERVAL)+4 >nul 2>&1
if !GA_MAX! LSS 10 set "GA_MAX=180"
set /a GA_COUNT=0
:DEVICE_POLL
set /a GA_COUNT+=1
if !GA_COUNT! GTR !GA_MAX! (
  call :FAIL 90 "GitHub device authorization code expired before approval completed."
  exit /b 90
)
timeout /t !GA_INTERVAL! /nobreak >nul
set "T=%GA_WORK%\github-token-v15.json"
set "TH=%GA_WORK%\github-token-v15-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_WEBHOST%:443:%GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data-urlencode "client_id=%GA_CLIENTID%" --data-urlencode "device_code=!GA_DEVICE_CODE!" --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:device_code" --data-urlencode "repository_id=%GA_REPOID%" "https://github.com/login/oauth/access_token" -o "%T%" -w "%%{http_code}" >"%TH%" 2>"%GA_WORK%\github-token-v15-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%TH%" set /p "GA_LAST_HTTP="<"%TH%"
if not "!GA_LAST_CURL!"=="0" goto :DEVICE_POLL
if not "!GA_LAST_HTTP!"=="200" goto :DEVICE_POLL
call :JGET "%T%" access_token GA_NEW_ACCESS
if defined GA_NEW_ACCESS (
  call :JGET "%T%" refresh_token GA_NEW_REFRESH
  call :JGET "%T%" expires_in GA_ACCESS_EXPIRES
  call :JGET "%T%" refresh_token_expires_in GA_REFRESH_EXPIRES
  call :STORE_TOKEN "!GA_NEW_ACCESS!" "!GA_NEW_REFRESH!" DEVICE
  set "GA_NEW_ACCESS="
  set "GA_NEW_REFRESH="
  exit /b 0
)
call :JGET "%T%" error GA_ERROR
if /i "!GA_ERROR!"=="authorization_pending" goto :DEVICE_POLL
if /i "!GA_ERROR!"=="slow_down" (
  set /a GA_INTERVAL+=5
  goto :DEVICE_POLL
)
if /i "!GA_ERROR!"=="access_denied" (
  call :FAIL 90 "GitHub device authorization was denied."
  exit /b 90
)
if /i "!GA_ERROR!"=="expired_token" (
  call :FAIL 90 "GitHub device authorization code expired."
  exit /b 90
)
if defined GA_ERROR (
  call :FAIL 90 "GitHub device authorization returned an unrecoverable OAuth error."
  exit /b 90
)
goto :DEVICE_POLL

:TEST_TOKEN
if not exist "%GA_TOKEN%" exit /b 1
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 1
set "F=%GA_WORK%\github-token-test-v3.json"
set "H=%GA_WORK%\github-token-test-v3-http.txt"
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 60 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repositories/%GA_REPOID%" -o "%F%" -w "%%{http_code}" >"%H%" 2>"%GA_WORK%\github-token-test-v3-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%H%" set /p "GA_LAST_HTTP="<"%H%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 1
if not "!GA_LAST_HTTP!"=="200" exit /b 1
exit /b 0

:STORE_TOKEN
set "A=%~1"
set "R=%~2"
set "S=%~3"
if not defined A exit /b 1
>"%GA_TOKEN%" echo(!A!
attrib +h +s "%GA_TOKEN%" >nul 2>&1
if defined R (
  >"%GA_REFRESH%" echo(!R!
  attrib +h +s "%GA_REFRESH%" >nul 2>&1
)
>"%GA_META%" echo provider=GITHUB_APP
>>"%GA_META%" echo app_id=%GA_APPID%
>>"%GA_META%" echo repository_id=%GA_REPOID%
>>"%GA_META%" echo source=%S%
>>"%GA_META%" echo access_expires_in=%GA_ACCESS_EXPIRES%
>>"%GA_META%" echo refresh_expires_in=%GA_REFRESH_EXPIRES%
>>"%GA_META%" echo stored_date=%date%
>>"%GA_META%" echo stored_time=%time%
attrib +h +s "%GA_META%" >nul 2>&1
set "A="
set "R="
exit /b 0

:UPLOAD
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :TEST_TOKEN
if errorlevel 1 (
  call :REFRESH_CORE
  if errorlevel 1 (
    call :FAIL 90 "Private report token is unavailable; authorization renewal is required."
    exit /b 90
  )
)
call :UPLOAD_INTERNAL
exit /b %errorlevel%

:UPLOAD_INTERNAL
set "GA_ACCESS="
set /p "GA_ACCESS="<"%GA_TOKEN%"
if not defined GA_ACCESS exit /b 90
set "SRC=%GA_WORK%\PRIVATE_UPLOAD_REPORT.txt"
set "B64=%GA_WORK%\PRIVATE_UPLOAD_REPORT.b64"
set "CLEAN=%GA_WORK%\PRIVATE_UPLOAD_REPORT.clean.txt"
set "REQ=%GA_WORK%\PRIVATE_UPLOAD_REQUEST.json"
set "RESP=%GA_WORK%\PRIVATE_UPLOAD_RESPONSE.json"
set "HTTP=%GA_WORK%\PRIVATE_UPLOAD_HTTP.txt"
>"%SRC%" echo PRIVATE RESCUEMEAI RECOVERY RUN REPORT
>>"%SRC%" echo ======================================
if exist "%GA_REPORT%" type "%GA_REPORT%" >>"%SRC%"
if exist "%GA_DETAILS%" (
  >>"%SRC%" echo.
  >>"%SRC%" echo --- RUN_DETAILS ---
  type "%GA_DETAILS%" >>"%SRC%"
)
"%GA_CERTUTIL%" -f -encode "%SRC%" "%B64%" >nul 2>&1
if errorlevel 1 exit /b 91
"%GA_FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64%" >"%CLEAN%" 2>nul
set "ENC="
for /f "usebackq delims=" %%L in ("%CLEAN%") do set "ENC=!ENC!%%L"
if not defined ENC exit /b 91
set "P=reports/inbox/run-%RANDOM%%RANDOM%.txt"
>"%REQ%" echo {"message":"RescueMeAI recovery report","content":"!ENC!"}
"%GA_CURL%" %GA_TLS% --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%GA_APIHOST%:443:%GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !GA_ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%REQ%" -o "%RESP%" -w "%%{http_code}" "https://api.github.com/repos/%GA_LOGREPO%/contents/!P!" >"%HTTP%" 2>"%GA_WORK%\github-upload-v3-curl.txt"
set "GA_LAST_CURL=!errorlevel!"
set "GA_LAST_HTTP="
if exist "%HTTP%" set /p "GA_LAST_HTTP="<"%HTTP%"
set "GA_ACCESS="
if not "!GA_LAST_CURL!"=="0" exit /b 90
if "!GA_LAST_HTTP!"=="201" exit /b 0
if "!GA_LAST_HTTP!"=="200" exit /b 0
exit /b 90

:JGET
set "%~3="
for /f "usebackq delims=" %%V in (`"%GA_CSCRIPT%" //nologo "%GA_JSON%" "%~1" "%~2" 2^>nul`) do set "%~3=%%V"
exit /b 0

:FAIL
>"%GA_RESULT%" echo status=FAIL
>>"%GA_RESULT%" echo reason=%~2
>>"%GA_RESULT%" echo http=%GA_LAST_HTTP%
>>"%GA_RESULT%" echo curl_return_code=%GA_LAST_CURL%
exit /b 0
