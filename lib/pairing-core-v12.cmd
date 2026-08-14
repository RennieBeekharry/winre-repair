@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: pairing-core 2026.08.14-PAIRING-12
rem Repository-scoped GitHub App device pairing for WinRE.
rem Tolerates GitHub form-encoded or JSON polling responses.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-12"
set "PRODUCT=RescueMeAI"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "TERMS_VERSION=2026-08-14"
set "LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "LEGAL_FILE=LEGAL.md"
set "WORK=C:\WinRERepair"
set "LEGAL=%WORK%\legal"
set "AUTHDIR=%WORK%\.auth"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "ACCEPTANCE_RECORD=%LEGAL%\acceptance.txt"
set "TOKENFILE=%AUTHDIR%\github-logs.token"
set "REFRESHFILE=%AUTHDIR%\github-refresh.token"
set "TOKENMETA=%AUTHDIR%\github-token.meta"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "DOHHOST=cloudflare-dns.com"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "GITHUB_REPOSITORY_ID=1333818657"

set "UI_WIDTH=96"
set "UI_TEXT_WIDTH=92"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "UI_SPACES=                                                                                                    "

title RescueMeAI - Windows Recovery
set "INTERNET_STATUS=CONNECTED"
set "WEBIP="
set "APIIP="
set "DOH_WEB_STATUS=NOT_RUN"
set "DOH_WEB_HTTP=NOT_RUN"
set "DOH_WEB_CURL_RC=NOT_RUN"
set "DOH_WEB_IP="
set "DOH_API_STATUS=NOT_RUN"
set "DOH_API_HTTP=NOT_RUN"
set "DOH_API_CURL_RC=NOT_RUN"
set "DOH_API_IP="
set "STAGE=START"
set "COMPONENT=pairing-core-v12"
set "FAIL_RC=90"
set "COMPONENT_RC=NOT_RUN"
set "FAIL_REASON=RescueMeAI secure pairing did not complete."
set "TERMS_STATUS=CHECKING"
set "AUTH_STATUS=NOT_REACHED"
set "AUTH_HTTP=NOT_RUN"
set "AUTH_CURL_RC=NOT_RUN"
set "UPLOAD_STATUS=NOT_REACHED"
set "UPLOAD_HTTP=NOT_RUN"
set "UPLOAD_CURL_RC=NOT_RUN"
set "REPORTVOL="
set "UNKNOWN_POLL_COUNT=0"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LEGAL%" md "%LEGAL%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
call :UI_SETUP
call :WRITE_REPORT RUNNING 0 "RescueMeAI Pairing-12 started."

call :REQUIRE "%CURL%" "curl.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%FINDSTR%" "findstr.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%CERTUTIL%" "certutil.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%PING%" "ping.exe"
if errorlevel 1 goto :FAIL

rem -------------------------------------------------------------------------
rem TERMS - continuation transition; acceptance must already exist.
rem -------------------------------------------------------------------------
set "ALREADY_ACCEPTED=NO"
set "ACCEPTED_VERSION="
if exist "%ACCEPTANCE_RECORD%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%ACCEPTANCE_RECORD%") do (
    if /i "%%A"=="accepted" if /i "%%B"=="YES" set "ALREADY_ACCEPTED=YES"
    if /i "%%A"=="terms_version" set "ACCEPTED_VERSION=%%B"
  )
)
if /i not "!ALREADY_ACCEPTED!"=="YES" (
  set "TERMS_STATUS=MISSING"
  set "FAIL_RC=40"
  set "COMPONENT_RC=40"
  set "FAIL_REASON=The RescueMeAI Terms acceptance record is missing. Pairing stopped safely."
  goto :FAIL
)
if /i not "!ACCEPTED_VERSION!"=="%TERMS_VERSION%" (
  set "TERMS_STATUS=VERSION_MISMATCH"
  set "FAIL_RC=40"
  set "COMPONENT_RC=40"
  set "FAIL_REASON=The stored Terms acceptance is for a different Terms version. Pairing stopped safely."
  goto :FAIL
)
set "TERMS_STATUS=ACCEPTED_PREVIOUSLY"
call :WRITE_DETAILS

rem -------------------------------------------------------------------------
rem RESOLVE AND VALIDATE GITHUB.COM
rem -------------------------------------------------------------------------
set "STAGE=RESOLVE_GITHUB_WEB"
set "COMPONENT=github.com"
call :DOH_RESOLVE_A "%WEBHOST%" WEBIP
set "DOH_WEB_STATUS=!DOH_LAST_STATUS!"
set "DOH_WEB_HTTP=!DOH_LAST_HTTP!"
set "DOH_WEB_CURL_RC=!DOH_LAST_CURL_RC!"
set "DOH_WEB_IP=!WEBIP!"
if not defined WEBIP (
  set "FAIL_RC=92"
  set "COMPONENT_RC=!DOH_WEB_CURL_RC!"
  set "FAIL_REASON=DNS-over-HTTPS did not return a usable github.com IPv4 address."
  goto :FAIL
)
call :TEST_GITHUB_IP "!WEBIP!"
if errorlevel 1 (
  set "FAIL_RC=92"
  set "COMPONENT_RC=92"
  set "FAIL_REASON=DNS-over-HTTPS returned a github.com address, but HTTPS validation failed."
  goto :FAIL
)
>"%WORK%\github-web-ip.txt" echo(!WEBIP!

rem -------------------------------------------------------------------------
rem REQUEST DEVICE CODE
rem -------------------------------------------------------------------------
set "STAGE=GITHUB_APP_DEVICE_CODE"
set "COMPONENT=github.com/login/device/code"
set "AUTH_STATUS=REQUESTING_DEVICE_CODE"
call :REQUEST_DEVICE_CODE
if errorlevel 1 goto :FAIL

set "DEVICE_CODE="
set "USER_CODE="
set "EXPIRES_IN="
set "POLL_INTERVAL="
set "DEVICE_ERROR="
call :RESPONSE_VALUE "%WORK%\github-device.response" "error" DEVICE_ERROR >nul 2>&1
if defined DEVICE_ERROR (
  set "AUTH_STATUS=DEVICE_CODE_ERROR"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=GitHub device authorization returned error: !DEVICE_ERROR!"
  goto :FAIL
)
call :RESPONSE_VALUE "%WORK%\github-device.response" "device_code" DEVICE_CODE
if errorlevel 1 (
  set "AUTH_STATUS=DEVICE_CODE_PARSE_FAILED"
  set "FAIL_RC=96"
  set "COMPONENT_RC=96"
  set "FAIL_REASON=GitHub returned HTTP 200 but RescueMeAI could not parse device_code."
  goto :FAIL
)
call :RESPONSE_VALUE "%WORK%\github-device.response" "user_code" USER_CODE
if errorlevel 1 (
  set "AUTH_STATUS=USER_CODE_PARSE_FAILED"
  set "FAIL_RC=96"
  set "COMPONENT_RC=96"
  set "FAIL_REASON=GitHub returned a device response but RescueMeAI could not parse user_code."
  goto :FAIL
)
call :RESPONSE_VALUE "%WORK%\github-device.response" "expires_in" EXPIRES_IN >nul 2>&1
if not defined EXPIRES_IN set "EXPIRES_IN=900"
call :RESPONSE_VALUE "%WORK%\github-device.response" "interval" POLL_INTERVAL >nul 2>&1
if not defined POLL_INTERVAL set "POLL_INTERVAL=5"
set /a CODE_MINUTES=(EXPIRES_IN+59)/60 >nul 2>&1
if !CODE_MINUTES! LSS 1 set "CODE_MINUTES=15"
set "AUTH_STATUS=WAITING_FOR_USER"
call :WRITE_DETAILS

call :UI_HEADER INFO "SECURE GITHUB APP PAIRING" "AUTHORIZATION ONLY - NO WINDOWS REPAIR"
call :UI_SECTION "ON YOUR PHONE"
call :UI_LINE "Open: https://github.com/login/device"
call :UI_LINE "Enter this one-time code:"
echo.
call :UI_CENTER "!USER_CODE!"
echo.
call :UI_WRAP "[WAITING] RescueMeAI will remain here while you authorize the device."
call :UI_WRAP "Code valid for up to !CODE_MINUTES! minutes. There is no need to rush."
call :UI_WRAP "After approval, this PC will continue automatically."
call :UI_WRAP "Private evidence access is restricted to repository ID %GITHUB_REPOSITORY_ID%."

set /a "MAX_POLLS=(EXPIRES_IN/POLL_INTERVAL)+4" >nul 2>&1
if !MAX_POLLS! LSS 10 set "MAX_POLLS=180"
set /a POLL_COUNT=0

:TOKEN_POLL
set /a POLL_COUNT+=1
if !POLL_COUNT! GTR !MAX_POLLS! (
  set "AUTH_STATUS=EXPIRED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The GitHub device code expired before authorization completed."
  goto :FAIL
)
call :SLEEP !POLL_INTERVAL!
call :POLL_TOKEN
set "POLL_RC=!errorlevel!"
if "!POLL_RC!"=="10" (
  set "AUTH_STATUS=WAITING_FOR_USER"
  goto :TOKEN_POLL
)
if "!POLL_RC!"=="11" (
  set /a POLL_INTERVAL+=5
  set "AUTH_STATUS=WAITING_SLOW_DOWN"
  goto :TOKEN_POLL
)
if "!POLL_RC!"=="12" (
  set /a UNKNOWN_POLL_COUNT+=1
  set "AUTH_STATUS=WAITING_UNRECOGNIZED_RESPONSE"
  if !UNKNOWN_POLL_COUNT! LEQ 5 goto :TOKEN_POLL
  set "FAIL_RC=96"
  set "COMPONENT_RC=96"
  set "FAIL_REASON=GitHub returned repeated unrecognized polling responses while waiting for authorization."
  goto :FAIL
)
if not "!POLL_RC!"=="0" goto :FAIL

>"%TOKENFILE%" echo(!ACCESS_TOKEN!
attrib +h +s "%TOKENFILE%" >nul 2>&1
if defined REFRESH_TOKEN (
  >"%REFRESHFILE%" echo(!REFRESH_TOKEN!
  attrib +h +s "%REFRESHFILE%" >nul 2>&1
)
>"%TOKENMETA%" echo provider=GITHUB_APP
>>"%TOKENMETA%" echo app_id=%GITHUB_APP_ID%
>>"%TOKENMETA%" echo repository_id=%GITHUB_REPOSITORY_ID%
>>"%TOKENMETA%" echo expires_in=!TOKEN_EXPIRES_IN!
>>"%TOKENMETA%" echo refresh_expires_in=!REFRESH_EXPIRES_IN!
>>"%TOKENMETA%" echo issued_date=%date%
>>"%TOKENMETA%" echo issued_time=%time%
attrib +h +s "%TOKENMETA%" >nul 2>&1
set "ACCESS_TOKEN="
set "REFRESH_TOKEN="
set "AUTH_STATUS=AUTHORIZED"
call :WRITE_DETAILS

rem -------------------------------------------------------------------------
rem UPLOAD FIRST PRIVATE REPORT
rem -------------------------------------------------------------------------
set "STAGE=PRIVATE_REPORT_UPLOAD"
set "COMPONENT=api.github.com private evidence upload"
call :DOH_RESOLVE_A "%APIHOST%" APIIP
set "DOH_API_STATUS=!DOH_LAST_STATUS!"
set "DOH_API_HTTP=!DOH_LAST_HTTP!"
set "DOH_API_CURL_RC=!DOH_LAST_CURL_RC!"
set "DOH_API_IP=!APIIP!"
if not defined APIIP (
  set "UPLOAD_STATUS=FAIL_API_ADDRESS"
  set "FAIL_RC=92"
  set "COMPONENT_RC=!DOH_API_CURL_RC!"
  set "FAIL_REASON=Authorization succeeded, but RescueMeAI could not resolve api.github.com for private reporting."
  goto :FAIL
)
call :UPLOAD_PRIVATE
if errorlevel 1 goto :FAIL
set "UPLOAD_STATUS=PASS"
call :WRITE_REPORT PASS 0 "RescueMeAI private authenticated reporting is online."
call :WRITE_DETAILS
call :USB_COPY

call :UI_HEADER PASS "PRIVATE REPORTING ONLINE" "NO WINDOWS RECOVERY ACTION"
call :UI_SECTION "[PASS] RESCUEMEAI PRIVATE REPORTING ONLINE"
call :UI_WRAP "GitHub App device authorization completed and RescueMeAI uploaded its first authenticated private recovery report."
call :UI_SECTION "WHAT HAPPENED"
call :UI_LINE "Terms              : ACCEPTED PREVIOUSLY"
call :UI_LINE "GitHub authorization: PASS"
call :UI_LINE "Private report      : PASS"
call :UI_LINE "Windows repair      : NOT STARTED"
call :UI_LINE "Destructive actions : NONE"
call :UI_SECTION "WHAT YOU SHOULD DO"
call :UI_WRAP "Reply to ChatGPT with exactly: pass"
call :UI_LINE "%UI_BORDER%"
echo.
echo Returning to command prompt...
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:FAIL
call :WRITE_REPORT FAIL "!FAIL_RC!" "!FAIL_REASON!"
call :WRITE_DETAILS
call :USB_COPY
call :UI_HEADER ERROR "SECURE PAIRING FAILED" "NO RECOVERY ACTION"
call :UI_SECTION "[FAIL] RESCUEMEAI SECURE PAIRING FAILED"
call :UI_LINE "Stage           : !STAGE!"
call :UI_LINE "Component       : !COMPONENT!"
call :UI_LINE "Return code     : !FAIL_RC!"
call :UI_LINE "Component RC    : !COMPONENT_RC!"
call :UI_LINE "Terms           : !TERMS_STATUS!"
call :UI_LINE "GitHub auth     : !AUTH_STATUS!"
call :UI_LINE "Auth HTTP       : !AUTH_HTTP!"
call :UI_LINE "Auth curl RC    : !AUTH_CURL_RC!"
call :UI_LINE "Web DoH         : !DOH_WEB_STATUS!"
call :UI_LINE "Web DoH IP      : !DOH_WEB_IP!"
call :UI_LINE "API DoH         : !DOH_API_STATUS!"
call :UI_LINE "Report upload   : !UPLOAD_STATUS!"
call :UI_LINE "Upload HTTP     : !UPLOAD_HTTP!"
call :UI_LINE "Upload curl RC  : !UPLOAD_CURL_RC!"
call :UI_SECTION "REASON"
call :UI_WRAP "!FAIL_REASON!"
call :UI_SECTION "SAFETY"
call :UI_WRAP "No Windows repair or destructive action was performed by this pairing transition."
call :UI_SECTION "NEXT"
call :UI_WRAP "RescueMeAI is returning automatically to the Windows Recovery command prompt."
call :UI_LINE "%UI_BORDER%"
echo.
echo Returning to command prompt...
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!

rem =========================================================================
rem UI
rem =========================================================================
:UI_SETUP
"%MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:UI_THEME
set "UI_THEME=%~1"
set "UI_COLOR=07"
if /i "!UI_THEME!"=="INFO" set "UI_COLOR=0B"
if /i "!UI_THEME!"=="PASS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="WARNING" set "UI_COLOR=0E"
if /i "!UI_THEME!"=="ERROR" set "UI_COLOR=0C"
color !UI_COLOR! >nul 2>&1
exit /b 0

:UI_HEADER
set "UI_THEME_REQUEST=%~1"
set "UI_STEP=%~2"
set "UI_SAFETY=%~3"
call :UI_THEME "!UI_THEME_REQUEST!"
cls
call :UI_LINE "%UI_BORDER%"
call :UI_CENTER "RESCUEMEAI"
call :UI_CENTER "%DESCRIPTION%"
call :UI_LINE "%UI_BORDER%"
call :UI_LINE "Version      : %COMMAND_VERSION%"
call :UI_LINE "Internet     : [%INTERNET_STATUS%]"
call :UI_LINE "Current Step : !UI_STEP!"
call :UI_LINE "Safety       : !UI_SAFETY!"
call :UI_LINE "Legal        : %LEGAL_BASE%"
call :UI_LINE "Legal file   : %LEGAL_FILE%"
call :UI_LINE "%UI_BORDER%"
exit /b 0

:UI_SECTION
echo.
call :UI_LINE "%~1"
call :UI_LINE "%UI_RULE%"
exit /b 0

:UI_WRAP
set "UI_WRAP_TEXT=%~1"
set "UI_WRAP_LINE="
for %%W in (!UI_WRAP_TEXT!) do (
  if not defined UI_WRAP_LINE (
    set "UI_WRAP_LINE=%%W"
  ) else (
    set "UI_WRAP_CAND=!UI_WRAP_LINE! %%W"
    call :STRLEN "!UI_WRAP_CAND!" UI_WRAP_LEN
    if !UI_WRAP_LEN! GTR %UI_TEXT_WIDTH% (
      call :UI_LINE "!UI_WRAP_LINE!"
      set "UI_WRAP_LINE=%%W"
    ) else (
      set "UI_WRAP_LINE=!UI_WRAP_CAND!"
    )
  )
)
if defined UI_WRAP_LINE call :UI_LINE "!UI_WRAP_LINE!"
if not defined UI_WRAP_LINE echo.
exit /b 0

:UI_CENTER
set "UI_CENTER_TEXT=%~1"
call :STRLEN "!UI_CENTER_TEXT!" UI_CENTER_LEN
set /a UI_CENTER_PAD=(UI_WIDTH-UI_CENTER_LEN)/2
if !UI_CENTER_PAD! LSS 0 set "UI_CENTER_PAD=0"
set "UI_CENTER_LINE=!UI_SPACES:~0,%UI_CENTER_PAD%!!UI_CENTER_TEXT!"
call :UI_LINE "!UI_CENTER_LINE!"
exit /b 0

:UI_LINE
set "UI_TEXT=%~1"
call :STRLEN "!UI_TEXT!" UI_PRINT_LEN
if !UI_PRINT_LEN! GTR %UI_WIDTH% set "UI_TEXT=!UI_TEXT:~0,%UI_WIDTH%!"
echo(!UI_TEXT!
exit /b 0

:STRLEN
set "SL_TEXT=%~1"
set /a SL_LEN=0
:STRLEN_LOOP
if not "!SL_TEXT:~%SL_LEN%,1!"=="" (
  set /a SL_LEN+=1
  if !SL_LEN! LSS 512 goto :STRLEN_LOOP
)
set "%~2=%SL_LEN%"
exit /b 0

rem =========================================================================
rem HELPERS
rem =========================================================================
:REQUIRE
if exist "%~1" exit /b 0
set "COMPONENT=%~2"
set "COMPONENT_RC=91"
set "FAIL_RC=91"
set "FAIL_REASON=Required %~2 was not found in the recovery environment."
exit /b 1

:DOH_RESOLVE_A
set "DOH_QUERY_HOST=%~1"
set "DOH_RETURN_VAR=%~2"
set "%DOH_RETURN_VAR%="
set "DOH_LAST_STATUS=FAIL"
set "DOH_LAST_HTTP=NOT_RUN"
set "DOH_LAST_CURL_RC=NOT_RUN"
for %%I in (1.1.1.1 1.0.0.1) do (
  if /i not "!DOH_LAST_STATUS!"=="PASS" call :TRY_DOH_A "%%I"
)
if /i "!DOH_LAST_STATUS!"=="PASS" exit /b 0
exit /b 1

:TRY_DOH_A
set "DOH_RESOLVER_IP=%~1"
set "DOH_JSON=%WORK%\doh-response.json"
set "DOH_HTTP_FILE=%WORK%\doh-http.txt"
set "DOH_ERR=%WORK%\doh-curl-error.txt"
if exist "%DOH_JSON%" del /f /q "%DOH_JSON%" >nul 2>&1
if exist "%DOH_HTTP_FILE%" del /f /q "%DOH_HTTP_FILE%" >nul 2>&1
if exist "%DOH_ERR%" del /f /q "%DOH_ERR%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 45 --resolve "%DOHHOST%:443:%DOH_RESOLVER_IP%" -H "Accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=%DOH_QUERY_HOST%&type=A" -o "%DOH_JSON%" -w "%%{http_code}" >"%DOH_HTTP_FILE%" 2>"%DOH_ERR%"
set "DOH_LAST_CURL_RC=!errorlevel!"
set "DOH_LAST_HTTP="
if exist "%DOH_HTTP_FILE%" set /p "DOH_LAST_HTTP="<"%DOH_HTTP_FILE%"
if not "!DOH_LAST_CURL_RC!"=="0" exit /b 1
if not "!DOH_LAST_HTTP!"=="200" exit /b 1
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
if not defined DOH_IP exit /b 1
echo(!DOH_IP!|"%FINDSTR%" /r /x "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
if errorlevel 1 exit /b 1
set "%DOH_RETURN_VAR%=!DOH_IP!"
set "DOH_LAST_STATUS=PASS"
exit /b 0

:TEST_GITHUB_IP
set "TEST_IP=%~1"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%WEBHOST%:443:%TEST_IP%" -I "https://github.com/" -o NUL >nul 2>&1
exit /b !errorlevel!

:REQUEST_DEVICE_CODE
set "DEVICE_RESPONSE=%WORK%\github-device.response"
set "DEVICE_HTTP_FILE=%WORK%\github-device-http.txt"
set "CURLERR=%WORK%\GITHUB_CURL_ERROR.txt"
if exist "%DEVICE_RESPONSE%" del /f /q "%DEVICE_RESPONSE%" >nul 2>&1
if exist "%DEVICE_HTTP_FILE%" del /f /q "%DEVICE_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 90 --resolve "%WEBHOST%:443:%WEBIP%" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%" "https://github.com/login/device/code" -o "%DEVICE_RESPONSE%" -w "%%{http_code}" >"%DEVICE_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%DEVICE_HTTP_FILE%" set /p "AUTH_HTTP="<"%DEVICE_HTTP_FILE%"
if "!AUTH_CURL_RC!"=="0" if "!AUTH_HTTP!"=="200" exit /b 0
set "AUTH_STATUS=DEVICE_CODE_FAILED"
set "COMPONENT_RC=!AUTH_CURL_RC!"
set "FAIL_RC=90"
set "FAIL_REASON=GitHub's device-code endpoint did not return HTTP 200."
exit /b 1

:POLL_TOKEN
set "TOKEN_RESPONSE=%WORK%\github-token.response"
set "TOKEN_HTTP_FILE=%WORK%\github-token-http.txt"
if exist "%TOKEN_RESPONSE%" del /f /q "%TOKEN_RESPONSE%" >nul 2>&1
if exist "%TOKEN_HTTP_FILE%" del /f /q "%TOKEN_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 90 --resolve "%WEBHOST%:443:%WEBIP%" -X POST -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%&device_code=!DEVICE_CODE!&grant_type=urn:ietf:params:oauth:grant-type:device_code&repository_id=%GITHUB_REPOSITORY_ID%" "https://github.com/login/oauth/access_token" -o "%TOKEN_RESPONSE%" -w "%%{http_code}" >"%TOKEN_HTTP_FILE%" 2>"%WORK%\GITHUB_CURL_ERROR.txt"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%TOKEN_HTTP_FILE%" set /p "AUTH_HTTP="<"%TOKEN_HTTP_FILE%"
if not "!AUTH_CURL_RC!"=="0" (
  set "AUTH_STATUS=TOKEN_POLL_NETWORK_FAILED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=!AUTH_CURL_RC!"
  set "FAIL_REASON=The GitHub authorization status request failed at the network or TLS layer."
  exit /b 90
)
if not "!AUTH_HTTP!"=="200" (
  set "AUTH_STATUS=TOKEN_POLL_HTTP_FAILED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=!AUTH_HTTP!"
  set "FAIL_REASON=The GitHub authorization status request returned an unexpected HTTP response."
  exit /b 90
)

rem GitHub documents authorization_pending as a normal state. Detect known
rem states by content so this works for form-encoded or JSON responses.
"%FINDSTR%" /i /c:"authorization_pending" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 exit /b 10
"%FINDSTR%" /i /c:"slow_down" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 exit /b 11
"%FINDSTR%" /i /c:"access_denied" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 (
  set "AUTH_STATUS=DENIED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The RescueMeAI GitHub App authorization was denied."
  exit /b 90
)
"%FINDSTR%" /i /c:"expired_token" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 (
  set "AUTH_STATUS=EXPIRED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The GitHub one-time device code expired."
  exit /b 90
)
"%FINDSTR%" /i /c:"device_flow_disabled" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 (
  set "AUTH_STATUS=DEVICE_FLOW_DISABLED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=Device Flow is disabled for the RescueMeAI GitHub App."
  exit /b 90
)
"%FINDSTR%" /i /c:"incorrect_client_credentials" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 (
  set "AUTH_STATUS=CLIENT_ID_REJECTED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=GitHub rejected the configured RescueMeAI GitHub App Client ID."
  exit /b 90
)
"%FINDSTR%" /i /c:"incorrect_device_code" "%TOKEN_RESPONSE%" >nul 2>&1
if not errorlevel 1 (
  set "AUTH_STATUS=DEVICE_CODE_REJECTED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=GitHub rejected the current device code."
  exit /b 90
)

set "ACCESS_TOKEN="
call :RESPONSE_VALUE "%TOKEN_RESPONSE%" "access_token" ACCESS_TOKEN >nul 2>&1
if defined ACCESS_TOKEN (
  set "REFRESH_TOKEN="
  set "TOKEN_EXPIRES_IN="
  set "REFRESH_EXPIRES_IN="
  call :RESPONSE_VALUE "%TOKEN_RESPONSE%" "refresh_token" REFRESH_TOKEN >nul 2>&1
  call :RESPONSE_VALUE "%TOKEN_RESPONSE%" "expires_in" TOKEN_EXPIRES_IN >nul 2>&1
  call :RESPONSE_VALUE "%TOKEN_RESPONSE%" "refresh_token_expires_in" REFRESH_EXPIRES_IN >nul 2>&1
  set "AUTH_STATUS=AUTHORIZED"
  exit /b 0
)

rem Do not kill the user's visible pairing code on one unknown HTTP-200 body.
exit /b 12

:RESPONSE_VALUE
call :FORM_VALUE "%~1" "%~2" "%~3"
if not errorlevel 1 exit /b 0
call :JSON_SIMPLE_VALUE "%~1" "%~2" "%~3"
exit /b %errorlevel%

:FORM_VALUE
set "FV_FILE=%~1"
set "FV_KEY=%~2"
set "FV_RET=%~3"
set "FV_LINE="
set "FV_VALUE="
if not exist "%FV_FILE%" exit /b 1
set /p "FV_LINE="<"%FV_FILE%"
if not defined FV_LINE exit /b 1
set "FV_NEEDLE=%FV_KEY%="
set "FV_TAIL=!FV_LINE:*%FV_NEEDLE%=!"
if "!FV_TAIL!"=="!FV_LINE!" exit /b 1
for /f "tokens=1 delims=&" %%V in ("!FV_TAIL!") do set "FV_VALUE=%%V"
if not defined FV_VALUE exit /b 1
set "%FV_RET%=!FV_VALUE!"
exit /b 0

:JSON_SIMPLE_VALUE
set "JV_FILE=%~1"
set "JV_KEY=%~2"
set "JV_RET=%~3"
set "JV_JOIN="
set "JV_VALUE="
if not exist "%JV_FILE%" exit /b 1
for /f "usebackq delims=" %%L in ("%JV_FILE%") do set "JV_JOIN=!JV_JOIN!%%L"
if not defined JV_JOIN exit /b 1
set "JV_CLEAN=!JV_JOIN:"=!"
set "JV_NEEDLE=%JV_KEY%:"
set "JV_TAIL=!JV_CLEAN:*%JV_NEEDLE%=!"
if "!JV_TAIL!"=="!JV_CLEAN!" exit /b 1
for /f "tokens=1 delims=,}" %%V in ("!JV_TAIL!") do set "JV_VALUE=%%V"
for /f "tokens=*" %%V in ("!JV_VALUE!") do set "JV_VALUE=%%V"
if not defined JV_VALUE exit /b 1
set "%JV_RET%=!JV_VALUE!"
exit /b 0

:UPLOAD_PRIVATE
set "LOGTOKEN="
set /p "LOGTOKEN="<"%TOKENFILE%"
if not defined LOGTOKEN (
  set "UPLOAD_STATUS=FAIL_EMPTY_TOKEN"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The saved GitHub App authorization token was empty."
  exit /b 90
)
set "UPLOADSRC=%WORK%\PRIVATE_UPLOAD_REPORT.txt"
set "B64FILE=%WORK%\PRIVATE_UPLOAD_REPORT.b64"
set "B64CLEAN=%WORK%\PRIVATE_UPLOAD_REPORT.base64.txt"
set "JSONFILE=%WORK%\PRIVATE_UPLOAD_REQUEST.json"
set "RESPFILE=%WORK%\PRIVATE_UPLOAD_RESPONSE.json"
set "HTTPFILE=%WORK%\PRIVATE_UPLOAD_HTTP.txt"
>"%UPLOADSRC%" echo PRIVATE RESCUEMEAI RECOVERY REPORT
>>"%UPLOADSRC%" echo =================================
type "%REPORT%" >>"%UPLOADSRC%"
>>"%UPLOADSRC%" echo.
>>"%UPLOADSRC%" echo --- RUN_DETAILS ---
type "%DETAILS%" >>"%UPLOADSRC%"
"%CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "LOGTOKEN="
  set "UPLOAD_STATUS=FAIL_ENCODE"
  set "FAIL_RC=91"
  set "COMPONENT_RC=91"
  set "FAIL_REASON=Could not encode the private recovery report."
  exit /b 91
)
"%FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "LOGTOKEN="
  set "UPLOAD_STATUS=FAIL_ENCODE"
  set "FAIL_RC=91"
  set "COMPONENT_RC=91"
  set "FAIL_REASON=The encoded private recovery report was empty."
  exit /b 91
)
set "UPLOADPATH=reports/inbox/pairing-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"RescueMeAI Pairing-12 report","content":"!B64!"}
set "PUTURL=https://%APIHOST%/repos/%LOGREPO%/contents/!UPLOADPATH!"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:%APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%WORK%\GITHUB_CURL_ERROR.txt"
set "UPLOAD_CURL_RC=!errorlevel!"
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
set "LOGTOKEN="
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" (
  set "UPLOAD_STATUS=PASS"
  >"%WORK%\github-api-ip.txt" echo(!APIIP!
  exit /b 0
)
set "UPLOAD_STATUS=FAIL"
set "FAIL_RC=90"
set "COMPONENT_RC=!UPLOAD_CURL_RC!"
set "FAIL_REASON=GitHub authorization succeeded, but the private recovery report could not be uploaded."
if "!UPLOAD_HTTP!"=="403" set "FAIL_REASON=Authorization succeeded, but Contents write permission is unavailable for the private evidence repository."
if "!UPLOAD_HTTP!"=="404" set "FAIL_REASON=Authorization succeeded, but the GitHub App cannot access the configured private evidence repository."
exit /b 90

:SLEEP
set "SLEEP_SECONDS=%~1"
if not defined SLEEP_SECONDS set "SLEEP_SECONDS=5"
set /a "SLEEP_PINGS=SLEEP_SECONDS+1" >nul 2>&1
"%PING%" -n !SLEEP_PINGS! 127.0.0.1 >nul 2>&1
exit /b 0

:WRITE_REPORT
set "RP_STATUS=%~1"
set "RP_RC=%~2"
set "RP_MESSAGE=%~3"
>"%REPORT%" echo product=%PRODUCT%
>>"%REPORT%" echo status=%RP_STATUS%
>>"%REPORT%" echo return_code=%RP_RC%
>>"%REPORT%" echo command_version=%COMMAND_VERSION%
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=%RP_MESSAGE%
exit /b 0

:WRITE_DETAILS
>"%DETAILS%" echo product=%PRODUCT%
>>"%DETAILS%" echo build=%COMMAND_VERSION%
>>"%DETAILS%" echo internet=%INTERNET_STATUS%
>>"%DETAILS%" echo stage=!STAGE!
>>"%DETAILS%" echo component=!COMPONENT!
>>"%DETAILS%" echo component_return_code=!COMPONENT_RC!
>>"%DETAILS%" echo terms_status=!TERMS_STATUS!
>>"%DETAILS%" echo github_auth_status=!AUTH_STATUS!
>>"%DETAILS%" echo auth_http=!AUTH_HTTP!
>>"%DETAILS%" echo auth_curl_rc=!AUTH_CURL_RC!
>>"%DETAILS%" echo github_web_ip=!WEBIP!
>>"%DETAILS%" echo doh_web_status=!DOH_WEB_STATUS!
>>"%DETAILS%" echo doh_web_http=!DOH_WEB_HTTP!
>>"%DETAILS%" echo doh_web_curl_rc=!DOH_WEB_CURL_RC!
>>"%DETAILS%" echo doh_web_ip=!DOH_WEB_IP!
>>"%DETAILS%" echo doh_api_status=!DOH_API_STATUS!
>>"%DETAILS%" echo doh_api_http=!DOH_API_HTTP!
>>"%DETAILS%" echo doh_api_curl_rc=!DOH_API_CURL_RC!
>>"%DETAILS%" echo doh_api_ip=!DOH_API_IP!
>>"%DETAILS%" echo private_report_upload=!UPLOAD_STATUS!
>>"%DETAILS%" echo upload_http=!UPLOAD_HTTP!
>>"%DETAILS%" echo upload_curl_rc=!UPLOAD_CURL_RC!
>>"%DETAILS%" echo poll_count=!POLL_COUNT!
>>"%DETAILS%" echo unknown_poll_count=!UNKNOWN_POLL_COUNT!
>>"%DETAILS%" echo reason=!FAIL_REASON!
exit /b 0

:USB_COPY
set "REPORTVOL="
for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  if exist %%D:\ (
    vol %%D: >"%WORK%\vol-report-%%D.txt" 2>&1
    "%FINDSTR%" /i /c:"REPAIRDATA" "%WORK%\vol-report-%%D.txt" >nul 2>&1
    if not errorlevel 1 set "REPORTVOL=%%D:"
  )
)
if not defined REPORTVOL exit /b 40
if not exist "!REPORTVOL!\RescueMeAI" md "!REPORTVOL!\RescueMeAI" >nul 2>&1
copy /y "%REPORT%" "!REPORTVOL!\RescueMeAI\LAST_RUN_REPORT.txt" >nul 2>&1
copy /y "%DETAILS%" "!REPORTVOL!\RescueMeAI\RUN_DETAILS.txt" >nul 2>&1
exit /b 0
