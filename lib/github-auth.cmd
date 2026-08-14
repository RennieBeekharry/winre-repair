@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.14-1164-ET
rem Pure CMD + curl implementation for WinRE. No cscript/JScript dependency.

if /i "%~1"=="authorize" goto :AUTHORIZE
if /i "%~1"=="upload" goto :UPLOAD
exit /b 64

:INIT
set "WR_GA_WORK=C:\WinRERepair"
set "WR_GA_CONFIG=%WR_GA_WORK%\agent.cfg"
set "WR_GA_AUTHDIR=%WR_GA_WORK%\.auth"
set "WR_GA_TOKEN=%WR_GA_AUTHDIR%\github-logs.token"
set "WR_GA_REPORT=%WR_GA_WORK%\LAST_RUN_REPORT.txt"
set "WR_GA_DETAILS=%WR_GA_WORK%\RUN_DETAILS.txt"
set "WR_GA_RESULT=%WR_GA_WORK%\GITHUB_RESULT.txt"
set "WR_GA_CURLERR=%WR_GA_WORK%\GITHUB_CURL_ERROR.txt"
set "WR_GA_CURL=C:\Windows\System32\curl.exe"
set "WR_GA_CERTUTIL=C:\Windows\System32\certutil.exe"
set "WR_GA_FINDSTR=C:\Windows\System32\findstr.exe"
set "WR_GA_PING=X:\Windows\System32\ping.exe"
set "WR_GA_APIHOST=api.github.com"
set "WR_GA_WEBHOST=github.com"
set "WR_GA_APIIP="
set "WR_GA_WEBIP="
set "WR_GA_LOGREPO="
set "WR_GA_CLIENTID="

if not exist "%WR_GA_WORK%" md "%WR_GA_WORK%" >nul 2>&1
if not exist "%WR_GA_AUTHDIR%" md "%WR_GA_AUTHDIR%" >nul 2>&1
if not exist "%WR_GA_CURL%" (
  call :RESULT FAIL "Required curl.exe is missing." LOCAL "" 91
  exit /b 91
)
if not exist "%WR_GA_CERTUTIL%" (
  call :RESULT FAIL "Required certutil.exe is missing." LOCAL "" 91
  exit /b 91
)
if not exist "%WR_GA_FINDSTR%" (
  call :RESULT FAIL "Required findstr.exe is missing." LOCAL "" 91
  exit /b 91
)
if not exist "%WR_GA_CONFIG%" (
  call :RESULT FAIL "RescueMeAI configuration is missing." LOCAL "" 91
  exit /b 91
)
if exist "%WR_GA_WORK%\github-api-ip.txt" set /p "WR_GA_APIIP="<"%WR_GA_WORK%\github-api-ip.txt"
if exist "%WR_GA_WORK%\github-web-ip.txt" set /p "WR_GA_WEBIP="<"%WR_GA_WORK%\github-web-ip.txt"
for /f "usebackq tokens=1,* delims==" %%A in ("%WR_GA_CONFIG%") do (
  if /i "%%A"=="LOG_REPO" set "WR_GA_LOGREPO=%%B"
  if /i "%%A"=="OAUTH_CLIENT_ID" set "WR_GA_CLIENTID=%%B"
)
if not defined WR_GA_LOGREPO (
  call :RESULT FAIL "LOG_REPO configuration is missing." LOCAL "" 91
  exit /b 91
)
if not defined WR_GA_CLIENTID (
  call :RESULT FAIL "OAuth client ID configuration is missing." LOCAL "" 91
  exit /b 91
)
if not defined WR_GA_APIIP (
  call :RESULT FAIL "Validated api.github.com address is unavailable." LOCAL "" 92
  exit /b 92
)
if not defined WR_GA_WEBIP (
  call :RESULT FAIL "Validated github.com address is unavailable." LOCAL "" 92
  exit /b 92
)
exit /b 0

:AUTHORIZE
call :INIT
if errorlevel 1 exit /b %errorlevel%

rem Reuse an existing token only if it can still upload a private report.
if exist "%WR_GA_TOKEN%" (
  call :UPLOAD_INTERNAL "bootstrap-existing"
  if not errorlevel 1 exit /b 0
  del /f /q /a "%WR_GA_TOKEN%" >nul 2>&1
)

set "DEVICE_JSON=%WR_GA_WORK%\github-device.json"
set "DEVICE_HTTP=%WR_GA_WORK%\github-device-http.txt"
if exist "%DEVICE_JSON%" del /f /q "%DEVICE_JSON%" >nul 2>&1
if exist "%DEVICE_HTTP%" del /f /q "%DEVICE_HTTP%" >nul 2>&1
if exist "%WR_GA_CURLERR%" del /f /q "%WR_GA_CURLERR%" >nul 2>&1

"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_WEBHOST%:443:%WR_GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%WR_GA_CLIENTID%&scope=repo" "https://github.com/login/device/code" -o "%DEVICE_JSON%" -w "%%{http_code}" >"%DEVICE_HTTP%" 2>"%WR_GA_CURLERR%"
set "DEVICE_CURL_RC=!errorlevel!"
set "DEVICE_HTTP_CODE="
if exist "%DEVICE_HTTP%" set /p "DEVICE_HTTP_CODE="<"%DEVICE_HTTP%"
if not "!DEVICE_CURL_RC!"=="0" (
  call :RESULT FAIL "Could not start GitHub device authorization; curl failed." "!DEVICE_HTTP_CODE!" "" "!DEVICE_CURL_RC!"
  exit /b 90
)
if not "!DEVICE_HTTP_CODE!"=="200" (
  call :RESULT FAIL "GitHub device authorization endpoint did not return HTTP 200." "!DEVICE_HTTP_CODE!" "" "!DEVICE_CURL_RC!"
  exit /b 90
)

call :JSON_VALUE "%DEVICE_JSON%" "device_code" DEVICE_CODE
if errorlevel 1 (
  call :RESULT FAIL "GitHub device response did not contain device_code." "!DEVICE_HTTP_CODE!" "" 90
  exit /b 90
)
call :JSON_VALUE "%DEVICE_JSON%" "user_code" USER_CODE
if errorlevel 1 (
  call :RESULT FAIL "GitHub device response did not contain user_code." "!DEVICE_HTTP_CODE!" "" 90
  exit /b 90
)
call :JSON_VALUE "%DEVICE_JSON%" "verification_uri" VERIFY_URI
if errorlevel 1 set "VERIFY_URI=https://github.com/login/device"
call :JSON_VALUE "%DEVICE_JSON%" "expires_in" EXPIRES_IN
if errorlevel 1 set "EXPIRES_IN=900"
call :JSON_VALUE "%DEVICE_JSON%" "interval" POLL_INTERVAL
if errorlevel 1 set "POLL_INTERVAL=5"

cls
color 0E >nul 2>&1
echo ================================================================
echo RESCUEMEAI - GITHUB DEVICE AUTHORIZATION
echo ================================================================
echo On your phone, open:
echo.
echo   !VERIFY_URI!
echo.
echo Enter this short one-time code:
echo.
echo                 !USER_CODE!
echo.
echo Approve the GitHub authorization request.
echo This PC will continue automatically after approval.
echo Do not close this window.
echo ================================================================

set /a "MAX_POLLS=(EXPIRES_IN/POLL_INTERVAL)+4" >nul 2>&1
if !MAX_POLLS! LSS 10 set "MAX_POLLS=180"
set /a POLL_COUNT=0

:TOKEN_POLL
set /a POLL_COUNT+=1
if !POLL_COUNT! GTR !MAX_POLLS! (
  call :RESULT FAIL "GitHub one-time device code expired before authorization completed." TIMEOUT "" 90
  exit /b 90
)
call :SLEEP !POLL_INTERVAL!
set "TOKEN_JSON=%WR_GA_WORK%\github-token.json"
set "TOKEN_HTTP=%WR_GA_WORK%\github-token-http.txt"
if exist "%TOKEN_JSON%" del /f /q "%TOKEN_JSON%" >nul 2>&1
if exist "%TOKEN_HTTP%" del /f /q "%TOKEN_HTTP%" >nul 2>&1
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_WEBHOST%:443:%WR_GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%WR_GA_CLIENTID%&device_code=!DEVICE_CODE!&grant_type=urn:ietf:params:oauth:grant-type:device_code" "https://github.com/login/oauth/access_token" -o "%TOKEN_JSON%" -w "%%{http_code}" >"%TOKEN_HTTP%" 2>"%WR_GA_CURLERR%"
set "TOKEN_CURL_RC=!errorlevel!"
set "TOKEN_HTTP_CODE="
if exist "%TOKEN_HTTP%" set /p "TOKEN_HTTP_CODE="<"%TOKEN_HTTP%"
if not "!TOKEN_CURL_RC!"=="0" goto :TOKEN_POLL
if not "!TOKEN_HTTP_CODE!"=="200" goto :TOKEN_POLL

set "ACCESS_TOKEN="
call :JSON_VALUE "%TOKEN_JSON%" "access_token" ACCESS_TOKEN >nul 2>&1
if defined ACCESS_TOKEN goto :TOKEN_RECEIVED
set "TOKEN_ERROR="
call :JSON_VALUE "%TOKEN_JSON%" "error" TOKEN_ERROR >nul 2>&1
if /i "!TOKEN_ERROR!"=="authorization_pending" goto :TOKEN_POLL
if /i "!TOKEN_ERROR!"=="slow_down" (
  set /a POLL_INTERVAL+=5
  goto :TOKEN_POLL
)
if /i "!TOKEN_ERROR!"=="access_denied" (
  call :RESULT FAIL "GitHub device authorization was denied." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="expired_token" (
  call :RESULT FAIL "GitHub one-time device code expired." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if defined TOKEN_ERROR (
  call :RESULT FAIL "GitHub device authorization returned error: !TOKEN_ERROR!" "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
goto :TOKEN_POLL

:TOKEN_RECEIVED
>"%WR_GA_TOKEN%" echo(!ACCESS_TOKEN!
attrib +h +s "%WR_GA_TOKEN%" >nul 2>&1
set "ACCESS_TOKEN="
call :UPLOAD_INTERNAL "bootstrap-device"
if errorlevel 1 (
  del /f /q /a "%WR_GA_TOKEN%" >nul 2>&1
  exit /b 90
)
exit /b 0

:UPLOAD
call :INIT
if errorlevel 1 exit /b %errorlevel%
if not exist "%WR_GA_TOKEN%" (
  call :RESULT FAIL "Private reporting is not authorized yet." LOCAL "" 90
  exit /b 90
)
call :UPLOAD_INTERNAL "run"
exit /b %errorlevel%

:UPLOAD_INTERNAL
set "UPLOAD_LABEL=%~1"
set "LOGTOKEN="
set /p "LOGTOKEN="<"%WR_GA_TOKEN%"
if not defined LOGTOKEN (
  call :RESULT FAIL "Saved authorization file is empty." LOCAL "" 90
  exit /b 90
)
set "UPLOADSRC=%WR_GA_WORK%\PRIVATE_UPLOAD_REPORT.txt"
set "B64FILE=%WR_GA_WORK%\PRIVATE_UPLOAD_REPORT.b64"
set "B64CLEAN=%WR_GA_WORK%\PRIVATE_UPLOAD_REPORT.base64.txt"
set "JSONFILE=%WR_GA_WORK%\PRIVATE_UPLOAD_REQUEST.json"
set "RESPFILE=%WR_GA_WORK%\PRIVATE_UPLOAD_RESPONSE.json"
set "HTTPFILE=%WR_GA_WORK%\PRIVATE_UPLOAD_HTTP.txt"
>"%UPLOADSRC%" echo PRIVATE RESCUEMEAI RECOVERY RUN REPORT
>>"%UPLOADSRC%" echo ======================================
if exist "%WR_GA_REPORT%" type "%WR_GA_REPORT%" >>"%UPLOADSRC%"
if exist "%WR_GA_DETAILS%" (
  >>"%UPLOADSRC%" echo.
  >>"%UPLOADSRC%" echo --- RUN_DETAILS ---
  type "%WR_GA_DETAILS%" >>"%UPLOADSRC%"
)
"%WR_GA_CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "LOGTOKEN="
  call :RESULT FAIL "Could not encode private recovery report." LOCAL "" 91
  exit /b 91
)
"%WR_GA_FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "LOGTOKEN="
  call :RESULT FAIL "Encoded private recovery report was empty." LOCAL "" 91
  exit /b 91
)
set "SAFE_LABEL=%UPLOAD_LABEL::=_%"
set "UPLOADPATH=reports/inbox/%SAFE_LABEL%-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"RescueMeAI recovery report","content":"!B64!"}
set "PUTURL=https://api.github.com/repos/%WR_GA_LOGREPO%/contents/!UPLOADPATH!"
if exist "%HTTPFILE%" del /f /q "%HTTPFILE%" >nul 2>&1
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_APIHOST%:443:%WR_GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%WR_GA_CURLERR%"
set "UPLOAD_CURL_RC=!errorlevel!"
set "LOGTOKEN="
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" (
  call :RESULT PASS "Private report uploaded." "!UPLOAD_HTTP!" "!UPLOADPATH!" "!UPLOAD_CURL_RC!"
  exit /b 0
)
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="200" (
  call :RESULT PASS "Private report uploaded." "!UPLOAD_HTTP!" "!UPLOADPATH!" "!UPLOAD_CURL_RC!"
  exit /b 0
)
set "UPLOAD_REASON=GitHub private report upload failed."
if "!UPLOAD_HTTP!"=="401" set "UPLOAD_REASON=Saved authorization is invalid, expired, or revoked."
if "!UPLOAD_HTTP!"=="403" set "UPLOAD_REASON=GitHub authorization does not permit the private repository write."
if "!UPLOAD_HTTP!"=="404" set "UPLOAD_REASON=Authorized account cannot access the configured private log repository."
if "!UPLOAD_HTTP!"=="429" set "UPLOAD_REASON=GitHub rate limit was reached."
if not "!UPLOAD_CURL_RC!"=="0" set "UPLOAD_REASON=Private report upload failed at curl/network/TLS."
call :RESULT FAIL "!UPLOAD_REASON!" "!UPLOAD_HTTP!" "" "!UPLOAD_CURL_RC!"
exit /b 90

:JSON_VALUE
set "JV_FILE=%~1"
set "JV_KEY=%~2"
set "JV_RET=%~3"
set "JV_LINE="
set "JV_TAIL="
set "JV_VALUE="
for /f "usebackq delims=" %%L in (`"%WR_GA_FINDSTR%" /i /c:"%JV_KEY%" "%JV_FILE%" 2^>nul`) do set "JV_LINE=%%L"
if not defined JV_LINE exit /b 1
set "JV_TAIL=!JV_LINE:*%JV_KEY%=!"
set "JV_TAIL=!JV_TAIL:*:=!"
for /f "tokens=1 delims=," %%V in ("!JV_TAIL!") do set "JV_VALUE=%%V"
for /f "tokens=*" %%V in ("!JV_VALUE!") do set "JV_VALUE=%%V"
set "JV_VALUE=!JV_VALUE:"=!"
set "JV_VALUE=!JV_VALUE:}=!"
if not defined JV_VALUE exit /b 1
set "%JV_RET%=%JV_VALUE%"
exit /b 0

:SLEEP
set "SLEEP_SECONDS=%~1"
if not defined SLEEP_SECONDS set "SLEEP_SECONDS=5"
if exist "%WR_GA_PING%" (
  set /a "SLEEP_PINGS=SLEEP_SECONDS+1" >nul 2>&1
  "%WR_GA_PING%" -n !SLEEP_PINGS! 127.0.0.1 >nul 2>&1
)
exit /b 0

:RESULT
set "RES_STATUS=%~1"
set "RES_REASON=%~2"
set "RES_HTTP=%~3"
set "RES_PATH=%~4"
set "RES_CURL=%~5"
>"%WR_GA_RESULT%" echo status=%RES_STATUS%
>>"%WR_GA_RESULT%" echo reason=%RES_REASON%
>>"%WR_GA_RESULT%" echo http=%RES_HTTP%
>>"%WR_GA_RESULT%" echo curl_return_code=%RES_CURL%
if defined RES_PATH >>"%WR_GA_RESULT%" echo path=%RES_PATH%
exit /b 0
