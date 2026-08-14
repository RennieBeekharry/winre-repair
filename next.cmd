@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Self-contained RescueMeAI Terms acceptance and repository-scoped GitHub App pairing.
rem WR_ACTION=BOOTSTRAP_RESCUEMEAI_SECURE_PRIVATE_REPORTING
rem WR_TARGET=Recovery tooling under C:\WinRERepair only; no Windows boot files or disk layout.
rem WR_CONSEQUENCE=Records Terms acceptance and establishes a repository-scoped outbound GitHub App credential.
rem WR_ROLLBACK=Local RescueMeAI authorization files can be removed later; no Windows recovery changes are performed.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-8"
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
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "GITHUB_REPOSITORY_ID=1333818657"

rem WinRE UI geometry. Screen theme is selected centrally by :UI_THEME.
set "UI_WIDTH=96"
set "UI_TEXT_WIDTH=92"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "UI_SPACES=                                                                                                    "

rem Take ownership of the console title so repeated launcher invocations do
rem not accumulate C:\wr.cmd text in the Windows title bar.
title RescueMeAI - Windows Recovery

rem The persistent C:\wr.cmd launcher downloaded this exact build over HTTPS.
rem Current-run Internet access is therefore already proven.
set "LAUNCHER_APIIP=%APIIP%"
set "APIIP=%LAUNCHER_APIIP%"
set "WEBIP="
set "INTERNET_STATUS=CONNECTED"

set "STAGE=START"
set "COMPONENT=next.cmd"
set "FAIL_RC=90"
set "COMPONENT_RC=NOT_RUN"
set "FAIL_REASON=RescueMeAI secure pairing did not complete."
set "TERMS_STATUS=NOT_REACHED"
set "AUTH_STATUS=NOT_REACHED"
set "AUTH_HTTP=NOT_RUN"
set "AUTH_CURL_RC=NOT_RUN"
set "UPLOAD_STATUS=NOT_REACHED"
set "UPLOAD_HTTP=NOT_RUN"
set "UPLOAD_CURL_RC=NOT_RUN"
set "REPORTVOL="

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%LEGAL%" md "%LEGAL%" >nul 2>&1
if not exist "%AUTHDIR%" md "%AUTHDIR%" >nul 2>&1
call :UI_SETUP
call :WRITE_REPORT RUNNING 0 "RescueMeAI secure pairing started."
call :WRITE_DETAILS

set "STAGE=PRECHECK"
set "COMPONENT=required WinRE tools"
call :REQUIRE "%CURL%" "curl.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%FINDSTR%" "findstr.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%NSLOOKUP%" "nslookup.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%CERTUTIL%" "certutil.exe"
if errorlevel 1 goto :FAIL
call :REQUIRE "%PING%" "ping.exe"
if errorlevel 1 goto :FAIL

rem Direct-IP ping is secondary evidence only. The successful launcher HTTPS
rem fetch remains authoritative for the CONNECTED header state.
if exist "%PING%" (
  "%PING%" -n 1 -w 1500 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

rem =========================================================================
rem TERMS ACCEPTANCE
rem =========================================================================
set "STAGE=TERMS_ACCEPTANCE"
set "COMPONENT=embedded Terms gate"
set "TERMS_STATUS=CHECKING"
set "ALREADY_ACCEPTED=NO"
set "ACCEPTED_VERSION="
if exist "%ACCEPTANCE_RECORD%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%ACCEPTANCE_RECORD%") do (
    if /i "%%A"=="accepted" if /i "%%B"=="YES" set "ALREADY_ACCEPTED=YES"
    if /i "%%A"=="terms_version" set "ACCEPTED_VERSION=%%B"
  )
)
if /i "!ALREADY_ACCEPTED!"=="YES" if /i "!ACCEPTED_VERSION!"=="%TERMS_VERSION%" (
  set "TERMS_STATUS=ACCEPTED_PREVIOUSLY"
  goto :TERMS_DONE
)

call :UI_HEADER WARNING "TERMS AND RECOVERY RISK ACCEPTANCE" "REPAIR WRITE - NON-DESTRUCTIVE"
call :UI_SECTION "TERMS AND RECOVERY RISK ACCEPTANCE"
call :UI_LINE "Terms version: %TERMS_VERSION%"
echo.
call :UI_WRAP "RescueMeAI is system-recovery software. Recovery actions can cause data loss, corruption, downtime, loss of bootability, or the need for reset, reinstall, professional service, or hardware repair."
echo.
call :UI_LINE "By continuing, you acknowledge and agree that:"
call :UI_WRAP "- Recovery results are NOT guaranteed."
call :UI_WRAP "- AI-generated recommendations can be incorrect."
call :UI_WRAP "- Important data and recovery keys should be backed up where possible."
call :UI_WRAP "- Recovery-relevant technical evidence may be stored locally and, after authenticated reporting is enabled, in the configured private recovery evidence backend."
call :UI_WRAP "- RescueMeAI is provided AS IS to the maximum extent permitted by law."
call :UI_WRAP "- You assume the risks of using recovery software and liability is limited to the maximum extent permitted by applicable law."
call :UI_WRAP "- Mandatory statutory or consumer rights remain where law does not permit waiver or exclusion."
call :UI_SECTION "LEGAL DOCUMENTS"
call :UI_LINE "Legal repository: %LEGAL_BASE%"
call :UI_LINE "Legal landing file: %LEGAL_FILE%"
call :UI_SECTION "IMPORTANT"
call :UI_WRAP "Typing ACCEPT agrees to the general RescueMeAI legal terms. It does NOT authorize a destructive repair. Destructive actions require a separate, action-specific local authorization when RescueMeAI permits them."
call :UI_SECTION "ACTION REQUIRED"
call :UI_WRAP "Type exactly ACCEPT to agree and continue. Anything else stops RescueMeAI safely and returns you to the command prompt."
echo.
set "TERMS_TYPED="
set /p "TERMS_TYPED=ACCEPT TERMS OF USE: "
if not "!TERMS_TYPED!"=="ACCEPT" (
  set "TERMS_STATUS=NOT_ACCEPTED"
  call :WRITE_REPORT WARNING 40 "The required ACCEPT phrase was not entered. RescueMeAI stopped safely before authorization or recovery."
  call :WRITE_DETAILS
  call :USB_COPY
  goto :TERMS_NOT_ACCEPTED
)
>"%ACCEPTANCE_RECORD%" echo accepted=YES
>>"%ACCEPTANCE_RECORD%" echo terms_version=%TERMS_VERSION%
>>"%ACCEPTANCE_RECORD%" echo accepted_phrase=ACCEPT
>>"%ACCEPTANCE_RECORD%" echo date=%date%
>>"%ACCEPTANCE_RECORD%" echo time=%time%
>>"%ACCEPTANCE_RECORD%" echo destructive_authorization=NOT_GRANTED
set "TERMS_STATUS=ACCEPTED"

:TERMS_DONE
call :WRITE_DETAILS

rem =========================================================================
rem SECURE GITHUB APP DEVICE FLOW
rem =========================================================================
set "STAGE=GITHUB_APP_DEVICE_CODE"
set "COMPONENT=github.com/login/device/code"
set "AUTH_STATUS=REQUESTING_DEVICE_CODE"
call :REQUEST_DEVICE_CODE
if errorlevel 1 goto :FAIL

call :JSON_VALUE "%WORK%\github-device.json" "device_code" DEVICE_CODE
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=GitHub device response did not contain a device code."
  goto :FAIL
)
call :JSON_VALUE "%WORK%\github-device.json" "user_code" USER_CODE
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=GitHub device response did not contain a user code."
  goto :FAIL
)
call :JSON_VALUE "%WORK%\github-device.json" "verification_uri" VERIFY_URI
if errorlevel 1 set "VERIFY_URI=https://github.com/login/device"
call :JSON_VALUE "%WORK%\github-device.json" "expires_in" EXPIRES_IN
if errorlevel 1 set "EXPIRES_IN=900"
call :JSON_VALUE "%WORK%\github-device.json" "interval" POLL_INTERVAL
if errorlevel 1 set "POLL_INTERVAL=5"

call :UI_HEADER INFO "SECURE GITHUB APP PAIRING" "REPAIR WRITE - AUTHORIZATION ONLY"
call :UI_SECTION "SECURE GITHUB APP PAIRING"
call :UI_WRAP "Private recovery evidence is restricted to %LOGREPO%."
call :UI_SECTION "ON YOUR PHONE"
call :UI_LINE "Open: !VERIFY_URI!"
call :UI_LINE "Enter this one-time code:"
echo.
call :UI_CENTER "!USER_CODE!"
echo.
call :UI_WRAP "[WAITING] Approve the RescueMeAI authorization request on your phone. This PC will continue automatically after approval. Do not close this window."
set "AUTH_STATUS=WAITING_FOR_USER"
call :WRITE_DETAILS

set /a "MAX_POLLS=(EXPIRES_IN/POLL_INTERVAL)+4" >nul 2>&1
if !MAX_POLLS! LSS 10 set "MAX_POLLS=180"
set /a POLL_COUNT=0

:TOKEN_POLL
set /a POLL_COUNT+=1
if !POLL_COUNT! GTR !MAX_POLLS! (
  set "AUTH_STATUS=EXPIRED"
  set "COMPONENT_RC=90"
  set "FAIL_RC=90"
  set "FAIL_REASON=GitHub one-time device code expired before authorization completed."
  goto :FAIL
)
call :SLEEP !POLL_INTERVAL!
call :POLL_TOKEN
set "POLL_RC=!errorlevel!"
if "!POLL_RC!"=="10" goto :TOKEN_POLL
if "!POLL_RC!"=="11" (
  set /a POLL_INTERVAL+=5
  goto :TOKEN_POLL
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

set "STAGE=PRIVATE_REPORT_UPLOAD"
set "COMPONENT=private evidence upload"
set "UPLOAD_STATUS=UPLOADING"
call :WRITE_REPORT PASS 0 "RescueMeAI Terms accepted and repository-scoped GitHub App authorization completed."
call :WRITE_DETAILS
call :UPLOAD_PRIVATE
if errorlevel 1 goto :FAIL
set "UPLOAD_STATUS=PASS"
call :WRITE_REPORT PASS 0 "RescueMeAI private authenticated reporting is online."
call :WRITE_DETAILS
call :USB_COPY

call :UI_HEADER PASS "PRIVATE REPORTING ONLINE" "NO NEW ACTION"
call :UI_SECTION "[PASS] PRIVATE REPORTING ONLINE"
call :UI_WRAP "RescueMeAI is paired successfully and can send authenticated private recovery reports to the configured evidence repository."
call :UI_WRAP "No Windows repair, boot, disk, partition, filesystem, or registry repair was performed by this pairing build."
call :UI_SECTION "WHAT YOU SHOULD DO"
call :UI_WRAP "Reply to ChatGPT with exactly: pass"
call :UI_SECTION "ADDITIONAL INFORMATION REQUIRED"
call :UI_LINE "None"
call :UI_SECTION "ADDITIONAL INSTRUCTIONS"
call :UI_WRAP "Do not rerun C:\wr.cmd unless RescueMeAI asks you to."
call :UI_LINE "%UI_BORDER%"
exit /b 0

:TERMS_NOT_ACCEPTED
call :UI_HEADER WARNING "TERMS NOT ACCEPTED" "NO RECOVERY ACTION"
call :UI_SECTION "[WARNING] RESCUEMEAI STOPPED SAFELY"
call :UI_WRAP "The required phrase ACCEPT was not entered exactly, so RescueMeAI did not record acceptance of the Terms of Use."
call :UI_SECTION "WHAT HAPPENED"
call :UI_LINE "Terms acceptance       : NOT RECORDED"
call :UI_LINE "GitHub App authorization: NOT STARTED"
call :UI_LINE "Private reporting       : NOT STARTED"
call :UI_LINE "Windows recovery actions: NOT STARTED"
call :UI_LINE "Destructive actions     : NONE"
call :UI_LINE "Windows recovery state  : NOT CHANGED"
call :UI_LINE "RescueMeAI local logs    : UPDATED"
call :UI_SECTION "WHY RESCUEMEAI STOPPED"
call :UI_WRAP "RescueMeAI requires the exact word ACCEPT before it can continue beyond the legal acceptance gate. Any other entry is treated as a safe decline or cancellation."
call :UI_SECTION "WHAT HAPPENS NEXT"
call :UI_WRAP "RescueMeAI is exiting now and returning control to the Windows Recovery command prompt."
call :UI_WRAP "If you want to start again later, run: C:\wr.cmd"
call :UI_SECTION "ADDITIONAL INFORMATION REQUIRED"
call :UI_LINE "None"
call :UI_LINE "%UI_BORDER%"
echo.
call :UI_LINE "Returning to command prompt..."
color 07 >nul 2>&1
title Command Prompt
exit /b 40

:FAIL
call :WRITE_REPORT FAIL "!FAIL_RC!" "!FAIL_REASON!"
call :WRITE_DETAILS
call :USB_COPY
call :UI_HEADER ERROR "SECURE PAIRING FAILED" "NO RECOVERY ACTION"
call :UI_SECTION "[FAIL] RESCUEMEAI SECURE PAIRING FAILED"
call :UI_LINE "Stage        : !STAGE!"
call :UI_LINE "Component    : !COMPONENT!"
call :UI_LINE "Return code  : !FAIL_RC!"
call :UI_LINE "Component RC : !COMPONENT_RC!"
call :UI_LINE "Terms        : !TERMS_STATUS!"
call :UI_LINE "GitHub auth  : !AUTH_STATUS!"
call :UI_LINE "Auth HTTP    : !AUTH_HTTP!"
call :UI_LINE "Auth curl RC : !AUTH_CURL_RC!"
call :UI_LINE "Report upload: !UPLOAD_STATUS!"
call :UI_LINE "Upload HTTP  : !UPLOAD_HTTP!"
call :UI_LINE "Upload curl  : !UPLOAD_CURL_RC!"
call :UI_SECTION "REASON"
call :UI_WRAP "!FAIL_REASON!"
call :UI_SECTION "WHAT YOU SHOULD DO"
call :UI_WRAP "Reply to ChatGPT with exactly: fail"
call :UI_SECTION "ADDITIONAL INFORMATION REQUIRED"
call :UI_WRAP "Screenshot this exact screen only if private reporting is not online."
call :UI_WRAP "Nothing destructive was attempted."
call :UI_LINE "%UI_BORDER%"
pause >nul
exit /b !FAIL_RC!

rem =========================================================================
rem CENTRAL WINRE UI RENDERER
rem =========================================================================
:UI_SETUP
"%MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:UI_THEME
rem One authoritative semantic screen-theme mapping for WinRE.
set "UI_THEME=%~1"
set "UI_COLOR=07"
if /i "!UI_THEME!"=="INFO" set "UI_COLOR=0B"
if /i "!UI_THEME!"=="PASS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="SUCCESS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="WARNING" set "UI_COLOR=0E"
if /i "!UI_THEME!"=="ERROR" set "UI_COLOR=0C"
if /i "!UI_THEME!"=="FAIL" set "UI_COLOR=0C"
if /i "!UI_THEME!"=="NEUTRAL" set "UI_COLOR=07"
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
rem RECOVERY / AUTH HELPERS
rem =========================================================================
:REQUIRE
if exist "%~1" exit /b 0
set "COMPONENT=%~2"
set "COMPONENT_RC=91"
set "FAIL_RC=91"
set "FAIL_REASON=Required %~2 was not found in the recovery environment."
exit /b 1

:REQUEST_DEVICE_CODE
set "DEVICE_JSON=%WORK%\github-device.json"
set "DEVICE_HTTP_FILE=%WORK%\github-device-http.txt"
set "CURLERR=%WORK%\GITHUB_CURL_ERROR.txt"
if exist "%DEVICE_JSON%" del /f /q "%DEVICE_JSON%" >nul 2>&1
if exist "%DEVICE_HTTP_FILE%" del /f /q "%DEVICE_HTTP_FILE%" >nul 2>&1
if exist "%CURLERR%" del /f /q "%CURLERR%" >nul 2>&1
set "DEVICE_OK=NO"
if exist "%WORK%\github-web-ip.txt" (
  set "WEB_CAND="
  set /p "WEB_CAND="<"%WORK%\github-web-ip.txt"
  if defined WEB_CAND call :TRY_DEVICE_IP "!WEB_CAND!"
)
if /i "!DEVICE_OK!"=="YES" exit /b 0
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if /i not "!DEVICE_OK!"=="YES" call :LOOKUP_AND_TRY_DEVICE "%%D"
)
if /i "!DEVICE_OK!"=="YES" exit /b 0
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%" "https://github.com/login/device/code" -o "%DEVICE_JSON%" -w "%%{http_code}" >"%DEVICE_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%DEVICE_HTTP_FILE%" set /p "AUTH_HTTP="<"%DEVICE_HTTP_FILE%"
if "!AUTH_CURL_RC!"=="0" if "!AUTH_HTTP!"=="200" (
  set "DEVICE_OK=YES"
  set "AUTH_STATUS=DEVICE_CODE_READY"
  exit /b 0
)
set "COMPONENT_RC=!AUTH_CURL_RC!"
set "FAIL_RC=90"
set "AUTH_STATUS=DEVICE_CODE_FAILED"
set "FAIL_REASON=Could not reach GitHub's device-authorization endpoint from WinRE."
exit /b 1

:LOOKUP_AND_TRY_DEVICE
set "LOOKUP_DNS=%~1"
set "LOOKUP_IP="
for /f "delims=" %%L in ('"%NSLOOKUP%" %WEBHOST% %LOOKUP_DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "LOOKUP_TOKEN="
  for %%T in (%%L) do set "LOOKUP_TOKEN=%%T"
  if defined LOOKUP_TOKEN if /i not "!LOOKUP_TOKEN!"=="%LOOKUP_DNS%" set "LOOKUP_IP=!LOOKUP_TOKEN!"
)
if defined LOOKUP_IP call :TRY_DEVICE_IP "!LOOKUP_IP!"
exit /b 0

:TRY_DEVICE_IP
set "WEB_CAND=%~1"
if not defined WEB_CAND exit /b 1
if exist "%DEVICE_JSON%" del /f /q "%DEVICE_JSON%" >nul 2>&1
if exist "%DEVICE_HTTP_FILE%" del /f /q "%DEVICE_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 12 --max-time 90 --resolve "%WEBHOST%:443:%WEB_CAND%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%" "https://github.com/login/device/code" -o "%DEVICE_JSON%" -w "%%{http_code}" >"%DEVICE_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%DEVICE_HTTP_FILE%" set /p "AUTH_HTTP="<"%DEVICE_HTTP_FILE%"
if "!AUTH_CURL_RC!"=="0" if "!AUTH_HTTP!"=="200" (
  set "WEBIP=%WEB_CAND%"
  >"%WORK%\github-web-ip.txt" echo(!WEBIP!
  set "DEVICE_OK=YES"
  set "AUTH_STATUS=DEVICE_CODE_READY"
  exit /b 0
)
exit /b 1

:POLL_TOKEN
set "TOKEN_JSON=%WORK%\github-token.json"
set "TOKEN_HTTP_FILE=%WORK%\github-token-http.txt"
if exist "%TOKEN_JSON%" del /f /q "%TOKEN_JSON%" >nul 2>&1
if exist "%TOKEN_HTTP_FILE%" del /f /q "%TOKEN_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 90 --resolve "%WEBHOST%:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%&device_code=!DEVICE_CODE!&grant_type=urn:ietf:params:oauth:grant-type:device_code&repository_id=%GITHUB_REPOSITORY_ID%" "https://github.com/login/oauth/access_token" -o "%TOKEN_JSON%" -w "%%{http_code}" >"%TOKEN_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%TOKEN_HTTP_FILE%" set /p "AUTH_HTTP="<"%TOKEN_HTTP_FILE%"
if not "!AUTH_CURL_RC!"=="0" (
  set "COMPONENT_RC=!AUTH_CURL_RC!"
  set "FAIL_RC=90"
  set "AUTH_STATUS=TOKEN_POLL_NETWORK_FAILED"
  set "FAIL_REASON=The GitHub authorization status request failed at curl/network/TLS."
  exit /b 90
)
if not "!AUTH_HTTP!"=="200" (
  set "COMPONENT_RC=!AUTH_HTTP!"
  set "FAIL_RC=90"
  set "AUTH_STATUS=TOKEN_POLL_HTTP_FAILED"
  set "FAIL_REASON=The GitHub authorization status request returned an unexpected HTTP response."
  exit /b 90
)
set "ACCESS_TOKEN="
set "TOKEN_ERROR="
call :JSON_VALUE "%TOKEN_JSON%" "access_token" ACCESS_TOKEN >nul 2>&1
if defined ACCESS_TOKEN (
  set "REFRESH_TOKEN="
  set "TOKEN_EXPIRES_IN="
  set "REFRESH_EXPIRES_IN="
  call :JSON_VALUE "%TOKEN_JSON%" "refresh_token" REFRESH_TOKEN >nul 2>&1
  call :JSON_VALUE "%TOKEN_JSON%" "expires_in" TOKEN_EXPIRES_IN >nul 2>&1
  call :JSON_VALUE "%TOKEN_JSON%" "refresh_token_expires_in" REFRESH_EXPIRES_IN >nul 2>&1
  set "AUTH_STATUS=AUTHORIZED"
  exit /b 0
)
call :JSON_VALUE "%TOKEN_JSON%" "error" TOKEN_ERROR >nul 2>&1
if /i "!TOKEN_ERROR!"=="authorization_pending" exit /b 10
if /i "!TOKEN_ERROR!"=="slow_down" exit /b 11
if /i "!TOKEN_ERROR!"=="access_denied" (
  set "AUTH_STATUS=DENIED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The RescueMeAI GitHub App authorization was denied."
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="expired_token" (
  set "AUTH_STATUS=EXPIRED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=The GitHub one-time device code expired."
  exit /b 90
)
if /i "!TOKEN_ERROR!"=="device_flow_disabled" (
  set "AUTH_STATUS=DEVICE_FLOW_DISABLED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=Device Flow is disabled for the RescueMeAI GitHub App."
  exit /b 90
)
set "AUTH_STATUS=TOKEN_RESPONSE_INVALID"
set "FAIL_RC=96"
set "COMPONENT_RC=96"
set "FAIL_REASON=GitHub returned an unexpected device-flow response."
exit /b 96

:UPLOAD_PRIVATE
set "UPLOADSRC=%WORK%\PRIVATE_UPLOAD_REPORT.txt"
set "B64FILE=%WORK%\PRIVATE_UPLOAD_REPORT.b64"
set "B64CLEAN=%WORK%\PRIVATE_UPLOAD_REPORT.base64.txt"
set "JSONFILE=%WORK%\PRIVATE_UPLOAD_REQUEST.json"
set "RESPFILE=%WORK%\PRIVATE_UPLOAD_RESPONSE.json"
set "HTTPFILE=%WORK%\PRIVATE_UPLOAD_HTTP.txt"
set "LOGTOKEN="
set /p "LOGTOKEN="<"%TOKENFILE%"
if not defined LOGTOKEN (
  set "UPLOAD_STATUS=FAIL_EMPTY_TOKEN"
  set "COMPONENT_RC=90"
  set "FAIL_RC=90"
  set "FAIL_REASON=The local GitHub App authorization token file was empty."
  exit /b 90
)
>"%UPLOADSRC%" echo PRIVATE RESCUEMEAI RECOVERY REPORT
>>"%UPLOADSRC%" echo =================================
type "%REPORT%" >>"%UPLOADSRC%"
if exist "%DETAILS%" (
  >>"%UPLOADSRC%" echo.
  >>"%UPLOADSRC%" echo --- RUN_DETAILS ---
  type "%DETAILS%" >>"%UPLOADSRC%"
)
"%CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "LOGTOKEN="
  set "UPLOAD_STATUS=FAIL_ENCODE"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Could not encode the private recovery report."
  exit /b 91
)
"%FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "LOGTOKEN="
  set "UPLOAD_STATUS=FAIL_ENCODE"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Encoded private recovery report was empty."
  exit /b 91
)
set "UPLOADPATH=reports/inbox/pairing-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"RescueMeAI secure pairing report","content":"!B64!"}
set "PUTURL=https://%APIHOST%/repos/%LOGREPO%/contents/!UPLOADPATH!"
set "UPLOAD_OK=NO"
if defined APIIP call :TRY_API_UPLOAD "!APIIP!"
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
if exist "%WORK%\github-api-ip.txt" (
  set "API_CAND="
  set /p "API_CAND="<"%WORK%\github-api-ip.txt"
  if defined API_CAND call :TRY_API_UPLOAD "!API_CAND!"
)
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if /i not "!UPLOAD_OK!"=="YES" call :LOOKUP_AND_TRY_API "%%D"
)
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%CURLERR%"
set "UPLOAD_CURL_RC=!errorlevel!"
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
set "LOGTOKEN="
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" (
  set "UPLOAD_STATUS=PASS"
  exit /b 0
)
set "UPLOAD_STATUS=FAIL"
set "COMPONENT_RC=!UPLOAD_CURL_RC!"
set "FAIL_RC=90"
set "FAIL_REASON=GitHub App authorization succeeded, but the private recovery report could not be uploaded."
if "!UPLOAD_HTTP!"=="403" set "FAIL_REASON=GitHub App authorization succeeded, but Contents write permission is not available for the private evidence repository."
if "!UPLOAD_HTTP!"=="404" set "FAIL_REASON=GitHub App authorization succeeded, but the app cannot access the configured private evidence repository."
exit /b 90

:LOOKUP_AND_TRY_API
set "LOOKUP_DNS=%~1"
set "LOOKUP_IP="
for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %LOOKUP_DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "LOOKUP_TOKEN="
  for %%T in (%%L) do set "LOOKUP_TOKEN=%%T"
  if defined LOOKUP_TOKEN if /i not "!LOOKUP_TOKEN!"=="%LOOKUP_DNS%" set "LOOKUP_IP=!LOOKUP_TOKEN!"
)
if defined LOOKUP_IP call :TRY_API_UPLOAD "!LOOKUP_IP!"
exit /b 0

:TRY_API_UPLOAD
set "API_CAND=%~1"
if not defined API_CAND exit /b 1
if exist "%HTTPFILE%" del /f /q "%HTTPFILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 12 --max-time 120 --resolve "%APIHOST%:443:%API_CAND%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !LOGTOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%CURLERR%"
set "UPLOAD_CURL_RC=!errorlevel!"
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" (
  set "APIIP=%API_CAND%"
  >"%WORK%\github-api-ip.txt" echo(!APIIP!
  set "UPLOAD_OK=YES"
  set "UPLOAD_STATUS=PASS"
  exit /b 0
)
exit /b 1

:JSON_VALUE
set "JV_FILE=%~1"
set "JV_KEY=%~2"
set "JV_RET=%~3"
set "JV_LINE="
set "JV_TAIL="
set "JV_VALUE="
for /f "usebackq delims=" %%L in (`"%FINDSTR%" /i /c:"%JV_KEY%" "%JV_FILE%" 2^>nul`) do set "JV_LINE=%%L"
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
>>"%DETAILS%" echo private_report_upload=!UPLOAD_STATUS!
>>"%DETAILS%" echo upload_http=!UPLOAD_HTTP!
>>"%DETAILS%" echo upload_curl_rc=!UPLOAD_CURL_RC!
>>"%DETAILS%" echo legal_repository=%LEGAL_BASE%
>>"%DETAILS%" echo legal_file=%LEGAL_FILE%
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
