@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.14-1180-ET
rem RescueMeAI GitHub App device flow for WinRE using only CMD + curl.
rem No classic OAuth scopes. No client secret. No JScript dependency.

if /i "%~1"=="authorize" goto :AUTHORIZE
if /i "%~1"=="upload" goto :UPLOAD
if /i "%~1"=="refresh" goto :REFRESH
exit /b 64

:INIT
set "WR_GA_WORK=C:\WinRERepair"
set "WR_GA_CONFIG=%WR_GA_WORK%\agent.cfg"
set "WR_GA_AUTHDIR=%WR_GA_WORK%\.auth"
set "WR_GA_TOKEN=%WR_GA_AUTHDIR%\github-logs.token"
set "WR_GA_REFRESH=%WR_GA_AUTHDIR%\github-refresh.token"
set "WR_GA_TOKENMETA=%WR_GA_AUTHDIR%\github-token.meta"
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
set "WR_GA_APPID="
set "WR_GA_REPOSITORY_ID="
set "UPLOAD_HTTP="
set "UPLOAD_CURL_RC="

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
  if /i "%%A"=="GITHUB_APP_CLIENT_ID" set "WR_GA_CLIENTID=%%B"
  if /i "%%A"=="GITHUB_APP_ID" set "WR_GA_APPID=%%B"
  if /i "%%A"=="GITHUB_REPOSITORY_ID" set "WR_GA_REPOSITORY_ID=%%B"
)
if not defined WR_GA_LOGREPO (
  call :RESULT FAIL "LOG_REPO configuration is missing." LOCAL "" 91
  exit /b 91
)
if not defined WR_GA_CLIENTID (
  call :RESULT FAIL "GitHub App Client ID configuration is missing." LOCAL "" 91
  exit /b 91
)
if not defined WR_GA_APPID (
  call :RESULT FAIL "GitHub App ID configuration is missing." LOCAL "" 91
  exit /b 91
)
if not defined WR_GA_REPOSITORY_ID (
  call :RESULT FAIL "GitHub repository ID restriction is missing." LOCAL "" 91
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

rem Prefer a currently valid short-lived GitHub App user token.
if exist "%WR_GA_TOKEN%" (
  call :UPLOAD_INTERNAL "bootstrap-existing"
  if not errorlevel 1 exit /b 0
  if "!UPLOAD_HTTP!"=="401" if exist "%WR_GA_REFRESH%" (
    call :REFRESH_INTERNAL
    if not errorlevel 1 (
      call :UPLOAD_INTERNAL "bootstrap-refreshed"
      if not errorlevel 1 exit /b 0
    )
  )
  if "!UPLOAD_HTTP!"=="403" exit /b 90
  if "!UPLOAD_HTTP!"=="404" exit /b 90
  del /f /q /a "%WR_GA_TOKEN%" >nul 2>&1
)

rem If only a refresh token remains, attempt rotation before re-pairing.
if exist "%WR_GA_REFRESH%" (
  call :REFRESH_INTERNAL
  if not errorlevel 1 (
    call :UPLOAD_INTERNAL "bootstrap-refreshed"
    if not errorlevel 1 exit /b 0
    if "!UPLOAD_HTTP!"=="403" exit /b 90
    if "!UPLOAD_HTTP!"=="404" exit /b 90
  )
  del /f /q /a "%WR_GA_REFRESH%" >nul 2>&1
)

set "DEVICE_JSON=%WR_GA_WORK%\github-device.json"
set "DEVICE_HTTP=%WR_GA_WORK%\github-device-http.txt"
if exist "%DEVICE_JSON%" del /f /q "%DEVICE_JSON%" >nul 2>&1
if exist "%DEVICE_HTTP%" del /f /q "%DEVICE_HTTP%" >nul 2>&1
if exist "%WR_GA_CURLERR%" del /f /q "%WR_GA_CURLERR%" >nul 2>&1

rem GitHub App device flow requests only the Client ID here. There is no
rem classic OAuth scope request; app permissions come from the GitHub App.
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_WEBHOST%:443:%WR_GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%WR_GA_CLIENTID%" "https://github.com/login/device/code" -o "%DEVICE_JSON%" -w "%%{http_code}" >"%DEVICE_HTTP%" 2>"%WR_GA_CURLERR%"
set "DEVICE_CURL_RC=!errorlevel!"
set "DEVICE_HTTP_CODE="
if exist "%DEVICE_HTTP%" set /p "DEVICE_HTTP_CODE="<"%DEVICE_HTTP%"
if not "!DEVICE_CURL_RC!"=="0" (
  call :RESULT FAIL "Could not start GitHub App device authorization; curl failed." "!DEVICE_HTTP_CODE!" "" "!DEVICE_CURL_RC!"
  exit /b 90
)
if not "!DEVICE_HTTP_CODE!"=="200" (
  call :RESULT FAIL "GitHub App device authorization endpoint did not return HTTP 200." "!DEVICE_HTTP_CODE!" "" "!DEVICE_CURL_RC!"
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
echo RESCUEMEAI - SECURE GITHUB APP PAIRING
echo ================================================================
echo GitHub App ID : %WR_GA_APPID%
echo Repository    : %WR_GA_LOGREPO%
echo Repository ID : %WR_GA_REPOSITORY_ID%
echo.
echo On your phone, open:
echo.
echo   !VERIFY_URI!
echo.
echo Enter this short one-time code:
echo.
echo                 !USER_CODE!
echo.
echo Approve the RescueMeAI GitHub App authorization request.
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
rem repository_id further restricts this user token to the single private
rem RescueMeAI evidence/control repository even within the app installation.
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_WEBHOST%:443:%WR_GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%WR_GA_CLIENTID%&device_code=!DEVICE_CODE!&grant_type=urn:ietf:params:oauth:grant-type:device_code&repository_id=%WR_GA_REPOSITORY_ID%" "https://github.com/login/oauth/access_token" -o "%TOKEN_JSON%" -w "%%{http_code}" >"%TOKEN_HTTP%" 2>"%WR_GA_CURLERR%"
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
  call :JSON_VALUE "%TOKEN_JSON%" "interval" NEW_INTERVAL >nul 2>&1
  if defined NEW_INTERVAL set "POLL_INTERVAL=!NEW_INTERVAL!"
  if not defined NEW_INTERVAL set /a POLL_INTERVAL+=5
  goto :TOKEN_POLL
)
if /i "!TOKEN_ERROR!"=="access_denied" (
  call :RESULT FAIL "GitHub App device authorization was denied." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="expired_token" (
  call :RESULT FAIL "GitHub one-time device code expired." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="device_flow_disabled" (
  call :RESULT FAIL "Device Flow is disabled for the RescueMeAI GitHub App. Enable Device Flow in the app settings." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="incorrect_client_credentials" (
  call :RESULT FAIL "The configured RescueMeAI GitHub App Client ID was rejected by GitHub." "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
if defined TOKEN_ERROR (
  call :RESULT FAIL "GitHub App device authorization returned error: !TOKEN_ERROR!" "!TOKEN_HTTP_CODE!" "" "!TOKEN_CURL_RC!"
  exit /b 90
)
goto :TOKEN_POLL

:TOKEN_RECEIVED
set "REFRESH_TOKEN="
set "TOKEN_EXPIRES_IN="
set "REFRESH_EXPIRES_IN="
call :JSON_VALUE "%TOKEN_JSON%" "refresh_token" REFRESH_TOKEN >nul 2>&1
call :JSON_VALUE "%TOKEN_JSON%" "expires_in" TOKEN_EXPIRES_IN >nul 2>&1
call :JSON_VALUE "%TOKEN_JSON%" "refresh_token_expires_in" REFRESH_EXPIRES_IN >nul 2>&1
call :STORE_TOKENS
set "ACCESS_TOKEN="
set "REFRESH_TOKEN="
call :UPLOAD_INTERNAL "bootstrap-device"
if errorlevel 1 (
  if "!UPLOAD_HTTP!"=="403" (
    call :RESULT FAIL "GitHub App authorization succeeded, but Contents write permission is not available for the private recovery repository." "!UPLOAD_HTTP!" "" "!UPLOAD_CURL_RC!"
  )
  if "!UPLOAD_HTTP!"=="404" (
    call :RESULT FAIL "GitHub App authorization succeeded, but the app cannot access the configured private recovery repository. Verify the app is installed on winre-repair-logs." "!UPLOAD_HTTP!" "" "!UPLOAD_CURL_RC!"
  )
  exit /b 90
)
exit /b 0

:REFRESH
call :INIT
if errorlevel 1 exit /b %errorlevel%
call :REFRESH_INTERNAL
exit /b %errorlevel%

:REFRESH_INTERNAL
if not exist "%WR_GA_REFRESH%" (
  call :RESULT FAIL "No GitHub App refresh token is available; device pairing is required." LOCAL "" 90
  exit /b 90
)
set "SAVED_REFRESH="
set /p "SAVED_REFRESH="<"%WR_GA_REFRESH%"
if not defined SAVED_REFRESH (
  call :RESULT FAIL "Saved GitHub App refresh token is empty; device pairing is required." LOCAL "" 90
  exit /b 90
)
set "REFRESH_JSON=%WR_GA_WORK%\github-refresh.json"
set "REFRESH_HTTP_FILE=%WR_GA_WORK%\github-refresh-http.txt"
if exist "%REFRESH_JSON%" del /f /q "%REFRESH_JSON%" >nul 2>&1
if exist "%REFRESH_HTTP_FILE%" del /f /q "%REFRESH_HTTP_FILE%" >nul 2>&1
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_WEBHOST%:443:%WR_GA_WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%WR_GA_CLIENTID%&grant_type=refresh_token&refresh_token=!SAVED_REFRESH!" "https://github.com/login/oauth/access_token" -o "%REFRESH_JSON%" -w "%%{http_code}" >"%REFRESH_HTTP_FILE%" 2>"%WR_GA_CURLERR%"
set "REFRESH_CURL_RC=!errorlevel!"
set "SAVED_REFRESH="
set "REFRESH_HTTP="
if exist "%REFRESH_HTTP_FILE%" set /p "REFRESH_HTTP="<"%REFRESH_HTTP_FILE%"
if not "!REFRESH_CURL_RC!"=="0" (
  call :RESULT FAIL "GitHub App token refresh failed at curl/network/TLS." "!REFRESH_HTTP!" "" "!REFRESH_CURL_RC!"
  exit /b 90
)
if not "!REFRESH_HTTP!"=="200" (
  call :RESULT FAIL "GitHub App token refresh endpoint did not return HTTP 200." "!REFRESH_HTTP!" "" "!REFRESH_CURL_RC!"
  exit /b 90
)
set "ACCESS_TOKEN="
set "REFRESH_TOKEN="
set "TOKEN_EXPIRES_IN="
set "REFRESH_EXPIRES_IN="
call :JSON_VALUE "%REFRESH_JSON%" "access_token" ACCESS_TOKEN >nul 2>&1
call :JSON_VALUE "%REFRESH_JSON%" "refresh_token" REFRESH_TOKEN >nul 2>&1
call :JSON_VALUE "%REFRESH_JSON%" "expires_in" TOKEN_EXPIRES_IN >nul 2>&1
call :JSON_VALUE "%REFRESH_JSON%" "refresh_token_expires_in" REFRESH_EXPIRES_IN >nul 2>&1
if not defined ACCESS_TOKEN (
  set "REFRESH_ERROR="
  call :JSON_VALUE "%REFRESH_JSON%" "error" REFRESH_ERROR >nul 2>&1
  if defined REFRESH_ERROR (
    call :RESULT FAIL "GitHub App token refresh returned error: !REFRESH_ERROR!" "!REFRESH_HTTP!" "" "!REFRESH_CURL_RC!"
  ) else (
    call :RESULT FAIL "GitHub App token refresh did not return an access token." "!REFRESH_HTTP!" "" "!REFRESH_CURL_RC!"
  )
  exit /b 90
)
call :STORE_TOKENS
set "ACCESS_TOKEN="
set "REFRESH_TOKEN="
call :RESULT PASS "GitHub App user token refreshed." "!REFRESH_HTTP!" "" "!REFRESH_CURL_RC!"
exit /b 0

:STORE_TOKENS
if not defined ACCESS_TOKEN exit /b 91
>"%WR_GA_TOKEN%" echo(!ACCESS_TOKEN!
attrib +h +s "%WR_GA_TOKEN%" >nul 2>&1
if defined REFRESH_TOKEN (
  >"%WR_GA_REFRESH%" echo(!REFRESH_TOKEN!
  attrib +h +s "%WR_GA_REFRESH%" >nul 2>&1
) else (
  if exist "%WR_GA_REFRESH%" del /f /q /a "%WR_GA_REFRESH%" >nul 2>&1
)
>"%WR_GA_TOKENMETA%" echo auth_type=github_app_user_access_token
>>"%WR_GA_TOKENMETA%" echo app_id=%WR_GA_APPID%
>>"%WR_GA_TOKENMETA%" echo client_id=%WR_GA_CLIENTID%
>>"%WR_GA_TOKENMETA%" echo repository=%WR_GA_LOGREPO%
>>"%WR_GA_TOKENMETA%" echo repository_id=%WR_GA_REPOSITORY_ID%
>>"%WR_GA_TOKENMETA%" echo access_expires_in=!TOKEN_EXPIRES_IN!
>>"%WR_GA_TOKENMETA%" echo refresh_expires_in=!REFRESH_EXPIRES_IN!
>>"%WR_GA_TOKENMETA%" echo stored_date=%date%
>>"%WR_GA_TOKENMETA%" echo stored_time=%time%
attrib +h +s "%WR_GA_TOKENMETA%" >nul 2>&1
exit /b 0

:UPLOAD
call :INIT
if errorlevel 1 exit /b %errorlevel%
if not exist "%WR_GA_TOKEN%" (
  if exist "%WR_GA_REFRESH%" (
    call :REFRESH_INTERNAL
    if errorlevel 1 exit /b 90
  ) else (
    call :RESULT FAIL "Private reporting is not authorized yet; GitHub App device pairing is required." LOCAL "" 90
    exit /b 90
  )
)
call :UPLOAD_INTERNAL "run"
if not errorlevel 1 exit /b 0
if "!UPLOAD_HTTP!"=="401" if exist "%WR_GA_REFRESH%" (
  call :REFRESH_INTERNAL
  if errorlevel 1 exit /b 90
  call :UPLOAD_INTERNAL "run-refreshed"
  exit /b !errorlevel!
)
exit /b 90

:UPLOAD_INTERNAL
set "UPLOAD_LABEL=%~1"
set "LOGTOKEN="
set /p "LOGTOKEN="<"%WR_GA_TOKEN%"
if not defined LOGTOKEN (
  call :RESULT FAIL "Saved GitHub App user authorization file is empty." LOCAL "" 90
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
"%WR_GA_CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WR_GA_APIHOST%:443:%WR_GA_APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%WR_GA_CURLERR%"
set "UPLOAD_CURL_RC=!errorlevel!"
set "LOGTOKEN="
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" (
  call :RESULT PASS "Private report uploaded with RescueMeAI GitHub App authorization." "!UPLOAD_HTTP!" "!UPLOADPATH!" "!UPLOAD_CURL_RC!"
  exit /b 0
)
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="200" (
  call :RESULT PASS "Private report uploaded with RescueMeAI GitHub App authorization." "!UPLOAD_HTTP!" "!UPLOADPATH!" "!UPLOAD_CURL_RC!"
  exit /b 0
)
set "UPLOAD_REASON=GitHub App private report upload failed."
if "!UPLOAD_HTTP!"=="401" set "UPLOAD_REASON=Saved GitHub App user token is expired, invalid, or revoked."
if "!UPLOAD_HTTP!"=="403" set "UPLOAD_REASON=RescueMeAI GitHub App authorization lacks required Contents write permission."
if "!UPLOAD_HTTP!"=="404" set "UPLOAD_REASON=RescueMeAI GitHub App cannot access the configured private repository; verify the app installation is restricted to and includes winre-repair-logs."
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
