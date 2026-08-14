@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Self-contained RescueMeAI Terms acceptance and repository-scoped GitHub App pairing.
rem WR_ACTION=BOOTSTRAP_RESCUEMEAI_SECURE_PRIVATE_REPORTING
rem WR_TARGET=Recovery tooling under C:\WinRERepair only; no Windows boot files or disk layout.
rem WR_CONSEQUENCE=Records Terms acceptance and establishes a repository-scoped outbound GitHub App credential.
rem WR_ROLLBACK=Local RescueMeAI authorization files can be removed later; no Windows recovery changes are performed.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-5"
set "PRODUCT=RescueMeAI"
set "DESCRIPTION=AI-ASSISTED WINDOWS RECOVERY"
set "TERMS_VERSION=2026-08-14"
set "LEGAL_URL=https://github.com/RennieBeekharry/winre-repair/blob/main/LEGAL.md"
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
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "LOGREPO=RennieBeekharry/winre-repair-logs"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "GITHUB_REPOSITORY_ID=1333818657"

rem The persistent C:\wr.cmd launcher downloaded this exact build over HTTPS.
rem Therefore current-run Internet access is already proven without relying
rem on ICMP ping. Preserve any API address the launcher resolved.
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

rem A direct-IP ping is only a secondary network signal. The successful
rem launcher HTTPS fetch remains authoritative for CONNECTED status.
if exist "%PING%" (
  "%PING%" -n 1 -w 1500 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

rem -------------------------------------------------------------------------
rem TERMS ACCEPTANCE - embedded so no secondary RescueMeAI download is needed.
rem -------------------------------------------------------------------------
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

call :HEADER 0E "TERMS AND RECOVERY RISK ACCEPTANCE" "REPAIR WRITE - NON-DESTRUCTIVE"
call :CENTER "TERMS AND RECOVERY RISK ACCEPTANCE"
echo.
echo Terms version: %TERMS_VERSION%
echo.
echo RescueMeAI is system-recovery software. Recovery actions can cause
echo data loss, corruption, downtime, loss of bootability, or the need for
echo reset, reinstall, professional service, or hardware repair.
echo.
echo By continuing, you acknowledge and agree that:
echo   - Recovery results are NOT guaranteed.
echo   - AI-generated recommendations can be incorrect.
echo   - Important data and recovery keys should be backed up where possible.
echo   - Recovery-relevant technical evidence may be stored locally and,
echo     after authenticated reporting is enabled, in the configured private
echo     recovery evidence backend.
echo   - RescueMeAI is provided AS IS to the maximum extent permitted by law.
echo   - You assume the risks of using recovery software and liability is
echo     limited to the maximum extent permitted by applicable law.
echo   - Mandatory statutory or consumer rights remain where law does not
echo     permit waiver or exclusion.
echo.
echo Full Terms, Privacy Policy, Licence, Risk Notice and Trademark policy:
echo   %LEGAL_URL%
echo.
echo IMPORTANT
echo ------------------------------------------------------------------------
echo Typing ACCEPT agrees to the general RescueMeAI legal terms.
echo It does NOT authorize a destructive repair. Destructive actions require
echo a separate, action-specific local authorization when RescueMeAI permits
echo them.
echo ------------------------------------------------------------------------
echo Type exactly ACCEPT to agree and continue.
echo Anything else stops RescueMeAI safely without starting recovery.
echo.
set "TERMS_TYPED="
set /p "TERMS_TYPED=ACCEPT TERMS OF USE: "
if not "!TERMS_TYPED!"=="ACCEPT" (
  set "TERMS_STATUS=DECLINED"
  call :WRITE_REPORT WARNING 40 "RescueMeAI Terms were not accepted. No recovery or authorization action was performed."
  call :WRITE_DETAILS
  call :USB_COPY
  goto :WARNING
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

rem -------------------------------------------------------------------------
rem SECURE GITHUB APP DEVICE FLOW
rem No classic OAuth scopes. repository_id narrows the user token to the
rem configured private evidence/control repository.
rem -------------------------------------------------------------------------
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

call :HEADER 0B "SECURE GITHUB APP PAIRING" "REPAIR WRITE - AUTHORIZATION ONLY"
call :CENTER "SECURE GITHUB APP PAIRING"
echo.
echo Private recovery evidence will be limited to:
echo   %LOGREPO%
echo.
echo On your phone, open:
echo   !VERIFY_URI!
echo.
echo Enter this one-time code:
echo.
call :CENTER "!USER_CODE!"
echo.
echo [WAITING] Approve the RescueMeAI authorization request on your phone.
echo           This PC will continue automatically after approval.
echo           Do not close this window.
echo.
echo Legal: %LEGAL_URL%
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

rem Store the short-lived GitHub App user token and refresh token locally.
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
rem PRIVATE REPORT PROOF
rem -------------------------------------------------------------------------
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

call :HEADER 0A "PRIVATE REPORTING ONLINE" "NO NEW ACTION"
call :CENTER "[PASS] PRIVATE REPORTING ONLINE"
echo.
echo RESULT
echo ------------------------------------------------------------------------
echo RescueMeAI is paired successfully and can send authenticated private
echo recovery reports to the configured evidence repository.
echo.
echo No Windows repair, boot, disk, partition, filesystem, or registry repair
echo was performed by this pairing build.
echo.
echo WHAT YOU SHOULD DO
echo   Reply to ChatGPT with exactly: pass
echo.
echo ADDITIONAL INFORMATION REQUIRED
echo   None
echo.
echo ADDITIONAL INSTRUCTIONS
echo   Do not rerun C:\wr.cmd unless RescueMeAI asks you to.
echo ========================================================================
exit /b 0

:WARNING
call :HEADER 0E "TERMS NOT ACCEPTED" "NO RECOVERY ACTION"
call :CENTER "[WARNING] RESCUEMEAI DID NOT START"
echo.
echo RESULT
echo   The RescueMeAI Terms of Use were not accepted.
echo   No authorization or recovery action was performed.
echo.
echo WHAT YOU SHOULD DO
echo   Reply to ChatGPT with exactly: warning
echo.
echo ADDITIONAL INFORMATION REQUIRED
echo   None
echo ========================================================================
pause >nul
exit /b 40

:FAIL
call :WRITE_REPORT FAIL "!FAIL_RC!" "!FAIL_REASON!"
call :WRITE_DETAILS
call :USB_COPY
call :HEADER 0C "SECURE PAIRING FAILED" "NO RECOVERY ACTION"
call :CENTER "[FAIL] RESCUEMEAI SECURE PAIRING FAILED"
echo.
echo RESULT
echo ------------------------------------------------------------------------
echo Stage        : !STAGE!
echo Component    : !COMPONENT!
echo Return code  : !FAIL_RC!
echo Component RC : !COMPONENT_RC!
echo Terms        : !TERMS_STATUS!
echo GitHub auth  : !AUTH_STATUS!
echo Auth HTTP    : !AUTH_HTTP!
echo Auth curl RC : !AUTH_CURL_RC!
echo Report upload: !UPLOAD_STATUS!
echo Upload HTTP  : !UPLOAD_HTTP!
echo Upload curl  : !UPLOAD_CURL_RC!
echo.
echo Reason
echo   !FAIL_REASON!
echo.
echo WHAT YOU SHOULD DO
echo   Reply to ChatGPT with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED
echo   Screenshot this exact screen only if private reporting is not online.
echo.
echo Nothing destructive was attempted.
echo ========================================================================
pause >nul
exit /b !FAIL_RC!

:HEADER
set "UI_COLOR=%~1"
set "UI_STEP=%~2"
set "UI_SAFETY=%~3"
color %UI_COLOR% >nul 2>&1
cls
echo ========================================================================
call :CENTER "RESCUEMEAI"
call :CENTER "%DESCRIPTION%"
echo ========================================================================
echo  Version      : %COMMAND_VERSION%
echo  Internet     : [%INTERNET_STATUS%]
echo  Current Step : %UI_STEP%
echo  Safety       : %UI_SAFETY%
echo  Legal        : %LEGAL_URL%
echo ========================================================================
exit /b 0

:CENTER
set "CENTER_TEXT=%~1"
set /a CENTER_LEN=0
:CENTER_LEN_LOOP
if not "!CENTER_TEXT:~%CENTER_LEN%,1!"=="" (
  set /a CENTER_LEN+=1
  if !CENTER_LEN! LSS 72 goto :CENTER_LEN_LOOP
)
set /a CENTER_PAD=(72-CENTER_LEN)/2
if !CENTER_PAD! LSS 0 set "CENTER_PAD=0"
set "CENTER_SPACES=                                                                        "
echo !CENTER_SPACES:~0,%CENTER_PAD%!!CENTER_TEXT!
exit /b 0

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

rem Prefer a cached github.com address, then try several DNS resolvers.
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

rem Final attempt lets the WinRE resolver handle github.com directly.
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

rem Try the launcher's proven API IP first if available.
if defined APIIP call :TRY_API_UPLOAD "!APIIP!"
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
rem Then use a cached API IP if present.
if exist "%WORK%\github-api-ip.txt" (
  set "API_CAND="
  set /p "API_CAND="<"%WORK%\github-api-ip.txt"
  if defined API_CAND call :TRY_API_UPLOAD "!API_CAND!"
)
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
rem Then try fresh addresses from several DNS resolvers.
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if /i not "!UPLOAD_OK!"=="YES" call :LOOKUP_AND_TRY_API "%%D"
)
if /i "!UPLOAD_OK!"=="YES" (
  set "LOGTOKEN="
  exit /b 0
)
rem Final fallback: normal WinRE DNS, matching the successful launcher path.
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
>>"%DETAILS%" echo legal_url=%LEGAL_URL%
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
