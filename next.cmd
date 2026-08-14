@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Self-contained RescueMeAI Terms acceptance and repository-scoped GitHub App pairing.
rem WR_ACTION=BOOTSTRAP_RESCUEMEAI_SECURE_PRIVATE_REPORTING
rem WR_TARGET=Recovery tooling under C:\WinRERepair only; no Windows boot files or disk layout.
rem WR_CONSEQUENCE=Records Terms acceptance and establishes a repository-scoped outbound GitHub App credential.
rem WR_ROLLBACK=Local RescueMeAI authorization files can be removed later; no Windows recovery changes are performed.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-4"
set "PRODUCT=RescueMeAI"
set "TERMS_VERSION=2026-08-14"
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

rem The parent launcher may already have an APIIP variable from its successful
rem download of this exact script. Preserve it before doing anything else.
set "LAUNCHER_APIIP=%APIIP%"
set "APIIP=%LAUNCHER_APIIP%"
set "WEBIP="

set "STAGE=START"
set "COMPONENT=next.cmd"
set "FAIL_RC=90"
set "COMPONENT_RC=NOT_RUN"
set "FAIL_REASON=RescueMeAI secure pairing did not complete."
set "NETWORK_STATE=UNKNOWN"
set "API_STATE=LAUNCHER_FETCH_PROVED_API_ACCESS"
set "WEB_STATE=NOT_REACHED"
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
call :WRITE_REPORT RUNNING 0 "Self-contained RescueMeAI secure pairing started."
call :WRITE_DETAILS

cls
color 07 >nul 2>&1
echo ================================================================
echo RESCUEMEAI - SELF-CONTAINED SECURE PAIRING
echo Version: %COMMAND_VERSION%
echo ================================================================
echo This build performs pairing only. It does NOT repair Windows.
echo.
echo Disk formatting / cleaning     : NONE
echo Partition / filesystem changes : NONE
echo Windows boot/system repair      : NONE
echo Destructive operations          : NONE
echo.
echo GitHub App ID        : %GITHUB_APP_ID%
echo Private repository   : %LOGREPO%
echo Repository ID        : %GITHUB_REPOSITORY_ID%
echo Classic OAuth scopes : NONE
echo.
echo IMPORTANT:
echo   No additional RescueMeAI files are downloaded before pairing.
echo   This removes the repeated WinRE DNS failure seen in Pairing-3.
echo ================================================================

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

set "STAGE=NETWORK_INITIALIZE"
set "COMPONENT=WinRE network"
if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  if not errorlevel 1 (
    set "NETWORK_STATE=ONLINE"
  ) else (
    if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
    "%PING%" -n 1 -w 3000 1.1.1.1 >nul 2>&1
    if not errorlevel 1 (
      set "NETWORK_STATE=ONLINE"
    ) else (
      set "NETWORK_STATE=PARTIAL_OR_ICMP_BLOCKED"
    )
  )
) else (
  set "NETWORK_STATE=PING_UNAVAILABLE"
)
call :WRITE_DETAILS

rem -----------------------------------------------------------------
rem TERMS ACCEPTANCE - embedded so pairing does not depend on another
rem public download. Full legal documents are published in the public
rem RescueMeAI repository and are staged locally after the channel is stable.
rem -----------------------------------------------------------------
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

cls
color 0E >nul 2>&1
echo ================================================================
echo RESCUEMEAI - TERMS AND RECOVERY RISK ACCEPTANCE
echo Terms version: %TERMS_VERSION%
echo ================================================================
echo RescueMeAI is system-recovery software. Recovery actions can cause
echo data loss, corruption, downtime, loss of bootability, or the need
echo for reset, reinstall, professional service, or hardware repair.
echo.
echo By continuing you acknowledge and agree that:
echo   - Recovery results are NOT guaranteed.
echo   - AI-generated recommendations can be incorrect.
echo   - Important data and recovery keys should be backed up where possible.
echo   - Recovery-relevant technical evidence may be stored locally and,
echo     when authenticated reporting is enabled, in the configured private
echo     recovery evidence backend.
echo   - RescueMeAI is provided AS IS to the maximum extent permitted by law.
echo   - You assume the risks of using recovery software and liability is
echo     limited to the maximum extent permitted by applicable law.
echo   - Mandatory statutory or consumer rights are not waived where law
echo     does not permit waiver or exclusion.
echo.
echo Full project documents are published as:
echo   TERMS_OF_USE.md
echo   PRIVACY_POLICY.md
echo   DISCLAIMER_AND_RISK_NOTICE.md
echo   LICENSE.md
echo   TRADEMARKS.md
echo.
echo IMPORTANT:
echo   ACCEPT agrees to the general RescueMeAI terms. It does NOT authorize
echo   a destructive repair. Destructive actions always require a separate,
echo   action-specific local authorization when RescueMeAI permits them.
echo.
echo Type exactly ACCEPT to agree and continue.
echo Anything else stops RescueMeAI without performing a recovery action.
echo ================================================================
set "TERMS_TYPED="
set /p "TERMS_TYPED=Selection: "
if not "%TERMS_TYPED%"=="ACCEPT" (
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

rem -----------------------------------------------------------------
rem Harvest IP addresses without making file downloads. Cache and inherited
rem values are preferred, then ping-name parsing, then explicit DNS servers.
rem -----------------------------------------------------------------
set "STAGE=HARVEST_API_ADDRESS"
set "COMPONENT=api.github.com address"
call :HARVEST_IP "%APIHOST%" APIIP "%WORK%\github-api-ip.txt" "%APIIP%"
if errorlevel 1 (
  set "COMPONENT_RC=92"
  set "FAIL_RC=92"
  set "FAIL_REASON=The launcher reached api.github.com, but RescueMeAI could not retain or rediscover its address for the private report upload."
  goto :FAIL
)
>"%WORK%\github-api-ip.txt" echo(!APIIP!
set "API_STATE=ADDRESS_READY_FROM_LAUNCHER_OR_CACHE"

set "STAGE=HARVEST_GITHUB_DEVICE_ADDRESS"
set "COMPONENT=github.com address"
call :HARVEST_IP "%WEBHOST%" WEBIP "%WORK%\github-web-ip.txt" ""
if errorlevel 1 (
  set "WEB_STATE=ADDRESS_FAILED"
  set "COMPONENT_RC=92"
  set "FAIL_RC=92"
  set "FAIL_REASON=Could not obtain an address for github.com for GitHub App device authorization."
  goto :FAIL
)
>"%WORK%\github-web-ip.txt" echo(!WEBIP!
set "WEB_STATE=ADDRESS_READY"
call :WRITE_DETAILS

rem -----------------------------------------------------------------
rem GITHUB APP DEVICE FLOW - no classic OAuth scope and no JScript.
rem Official GitHub App device flow uses Client ID, device code, grant type,
rem and repository_id to further restrict this token to the evidence repo.
rem -----------------------------------------------------------------
set "STAGE=GITHUB_APP_DEVICE_CODE"
set "COMPONENT=github.com/login/device/code"
set "AUTH_STATUS=REQUESTING_DEVICE_CODE"
set "DEVICE_JSON=%WORK%\github-device.json"
set "DEVICE_HTTP_FILE=%WORK%\github-device-http.txt"
set "CURLERR=%WORK%\GITHUB_CURL_ERROR.txt"
if exist "%DEVICE_JSON%" del /f /q "%DEVICE_JSON%" >nul 2>&1
if exist "%DEVICE_HTTP_FILE%" del /f /q "%DEVICE_HTTP_FILE%" >nul 2>&1
if exist "%CURLERR%" del /f /q "%CURLERR%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WEBHOST%:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%" "https://github.com/login/device/code" -o "%DEVICE_JSON%" -w "%%{http_code}" >"%DEVICE_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%DEVICE_HTTP_FILE%" set /p "AUTH_HTTP="<"%DEVICE_HTTP_FILE%"
if not "!AUTH_CURL_RC!"=="0" (
  set "AUTH_STATUS=DEVICE_CODE_FAILED"
  set "COMPONENT_RC=!AUTH_CURL_RC!"
  set "FAIL_RC=90"
  set "FAIL_REASON=GitHub App device-code request failed at curl/network/TLS."
  goto :FAIL
)
if not "!AUTH_HTTP!"=="200" (
  set "AUTH_STATUS=DEVICE_CODE_FAILED"
  set "COMPONENT_RC=!AUTH_HTTP!"
  set "FAIL_RC=90"
  set "FAIL_REASON=GitHub App device-code request did not return HTTP 200."
  goto :FAIL
)
call :JSON_VALUE "%DEVICE_JSON%" "device_code" DEVICE_CODE
if errorlevel 1 (
  set "FAIL_REASON=GitHub device response did not contain device_code."
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  goto :FAIL
)
call :JSON_VALUE "%DEVICE_JSON%" "user_code" USER_CODE
if errorlevel 1 (
  set "FAIL_REASON=GitHub device response did not contain user_code."
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  goto :FAIL
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
echo GitHub App ID : %GITHUB_APP_ID%
echo Repository    : %LOGREPO%
echo Repository ID : %GITHUB_REPOSITORY_ID%
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
echo This PC continues automatically after approval.
echo Do not close this window.
echo ================================================================
set "AUTH_STATUS=WAITING_FOR_USER"
call :WRITE_DETAILS

set /a "MAX_POLLS=(EXPIRES_IN/POLL_INTERVAL)+4" >nul 2>&1
if !MAX_POLLS! LSS 10 set "MAX_POLLS=180"
set /a POLL_COUNT=0

:TOKEN_POLL
set /a POLL_COUNT+=1
if !POLL_COUNT! GTR !MAX_POLLS! (
  set "AUTH_STATUS=EXPIRED"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  set "FAIL_REASON=GitHub one-time device code expired before authorization completed."
  goto :FAIL
)
call :SLEEP !POLL_INTERVAL!
set "TOKEN_JSON=%WORK%\github-token.json"
set "TOKEN_HTTP_FILE=%WORK%\github-token-http.txt"
if exist "%TOKEN_JSON%" del /f /q "%TOKEN_JSON%" >nul 2>&1
if exist "%TOKEN_HTTP_FILE%" del /f /q "%TOKEN_HTTP_FILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%WEBHOST%:443:%WEBIP%" -X POST -H "Accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" --data "client_id=%GITHUB_APP_CLIENT_ID%&device_code=!DEVICE_CODE!&grant_type=urn:ietf:params:oauth:grant-type:device_code&repository_id=%GITHUB_REPOSITORY_ID%" "https://github.com/login/oauth/access_token" -o "%TOKEN_JSON%" -w "%%{http_code}" >"%TOKEN_HTTP_FILE%" 2>"%CURLERR%"
set "AUTH_CURL_RC=!errorlevel!"
set "AUTH_HTTP="
if exist "%TOKEN_HTTP_FILE%" set /p "AUTH_HTTP="<"%TOKEN_HTTP_FILE%"
if not "!AUTH_CURL_RC!"=="0" goto :TOKEN_POLL
if not "!AUTH_HTTP!"=="200" goto :TOKEN_POLL

set "ACCESS_TOKEN="
set "TOKEN_ERROR="
call :JSON_VALUE "%TOKEN_JSON%" "access_token" ACCESS_TOKEN >nul 2>&1
if defined ACCESS_TOKEN goto :TOKEN_RECEIVED
call :JSON_VALUE "%TOKEN_JSON%" "error" TOKEN_ERROR >nul 2>&1
if /i "!TOKEN_ERROR!"=="authorization_pending" goto :TOKEN_POLL
if /i "!TOKEN_ERROR!"=="slow_down" (
  set /a POLL_INTERVAL+=5
  goto :TOKEN_POLL
)
if /i "!TOKEN_ERROR!"=="access_denied" (
  set "AUTH_STATUS=DENIED"
  set "FAIL_REASON=GitHub App device authorization was denied."
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  goto :FAIL
)
if /i "!TOKEN_ERROR!"=="expired_token" (
  set "AUTH_STATUS=EXPIRED"
  set "FAIL_REASON=GitHub one-time device code expired."
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  goto :FAIL
)
if /i "!TOKEN_ERROR!"=="device_flow_disabled" (
  set "AUTH_STATUS=DEVICE_FLOW_DISABLED"
  set "FAIL_REASON=Device Flow is disabled for the RescueMeAI GitHub App."
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  goto :FAIL
)
if /i "!TOKEN_ERROR!"=="incorrect_client_credentials" (
  set "AUTH_STATUS=CLIENT_ID_REJECTED"
  set "FAIL_REASON=GitHub rejected the configured RescueMeAI GitHub App Client ID."
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  goto :FAIL
)
if defined TOKEN_ERROR (
  set "AUTH_STATUS=GITHUB_ERROR_!TOKEN_ERROR!"
  set "FAIL_REASON=GitHub App device authorization returned error: !TOKEN_ERROR!"
  set "FAIL_RC=90"
  set "COMPONENT_RC=90"
  goto :FAIL
)
goto :TOKEN_POLL

:TOKEN_RECEIVED
set "AUTH_STATUS=AUTHORIZED"
set "REFRESH_TOKEN="
set "TOKEN_EXPIRES_IN="
set "REFRESH_EXPIRES_IN="
call :JSON_VALUE "%TOKEN_JSON%" "refresh_token" REFRESH_TOKEN >nul 2>&1
call :JSON_VALUE "%TOKEN_JSON%" "expires_in" TOKEN_EXPIRES_IN >nul 2>&1
call :JSON_VALUE "%TOKEN_JSON%" "refresh_token_expires_in" REFRESH_EXPIRES_IN >nul 2>&1
>"%TOKENFILE%" echo(!ACCESS_TOKEN!
attrib +h +s "%TOKENFILE%" >nul 2>&1
if defined REFRESH_TOKEN (
  >"%REFRESHFILE%" echo(!REFRESH_TOKEN!
  attrib +h +s "%REFRESHFILE%" >nul 2>&1
)
>"%TOKENMETA%" echo provider=GITHUB_APP
>>"%TOKENMETA%" echo app_id=%GITHUB_APP_ID%
>>"%TOKENMETA%" echo repository_id=%GITHUB_REPOSITORY_ID%
>>"%TOKENMETA%" echo access_expires_in=!TOKEN_EXPIRES_IN!
>>"%TOKENMETA%" echo refresh_expires_in=!REFRESH_EXPIRES_IN!
>>"%TOKENMETA%" echo created_date=%date%
>>"%TOKENMETA%" echo created_time=%time%
attrib +h +s "%TOKENMETA%" >nul 2>&1
set "REFRESH_TOKEN="

rem -----------------------------------------------------------------
rem PRIVATE REPORT UPLOAD. Keep the report deliberately small so base64
rem remains below cmd.exe environment-variable limits.
rem -----------------------------------------------------------------
set "STAGE=PRIVATE_REPORT_UPLOAD"
set "COMPONENT=api.github.com private evidence upload"
set "UPLOAD_STATUS=ENCODING"
call :WRITE_REPORT PASS 0 "RescueMeAI GitHub App device authorization completed; validating private evidence upload."
call :WRITE_DETAILS
call :USB_COPY
set "UPLOADSRC=%WORK%\PAIRING_UPLOAD.txt"
set "B64FILE=%WORK%\PAIRING_UPLOAD.b64"
set "B64CLEAN=%WORK%\PAIRING_UPLOAD.base64.txt"
set "JSONFILE=%WORK%\PAIRING_UPLOAD_REQUEST.json"
set "RESPFILE=%WORK%\PAIRING_UPLOAD_RESPONSE.json"
set "HTTPFILE=%WORK%\PAIRING_UPLOAD_HTTP.txt"
>"%UPLOADSRC%" echo PRIVATE RESCUEMEAI PAIRING REPORT
>>"%UPLOADSRC%" echo ==================================
type "%REPORT%" >>"%UPLOADSRC%"
>>"%UPLOADSRC%" echo terms_status=%TERMS_STATUS%
>>"%UPLOADSRC%" echo auth_status=%AUTH_STATUS%
>>"%UPLOADSRC%" echo github_app_id=%GITHUB_APP_ID%
>>"%UPLOADSRC%" echo repository_id=%GITHUB_REPOSITORY_ID%
>>"%UPLOADSRC%" echo network_state=%NETWORK_STATE%
"%CERTUTIL%" -f -encode "%UPLOADSRC%" "%B64FILE%" >nul 2>&1
if errorlevel 1 (
  set "UPLOAD_STATUS=ENCODE_FAILED"
  set "FAIL_RC=91"
  set "COMPONENT_RC=91"
  set "FAIL_REASON=Could not encode the private pairing report."
  goto :FAIL
)
"%FINDSTR%" /v /c:"-----" /c:"CertUtil" "%B64FILE%" >"%B64CLEAN%" 2>nul
set "B64="
for /f "usebackq delims=" %%L in ("%B64CLEAN%") do set "B64=!B64!%%L"
if not defined B64 (
  set "UPLOAD_STATUS=ENCODE_FAILED"
  set "FAIL_RC=91"
  set "COMPONENT_RC=91"
  set "FAIL_REASON=Encoded private pairing report was empty."
  goto :FAIL
)
set "UPLOADPATH=reports/inbox/rescuemeai-pairing-%RANDOM%%RANDOM%.txt"
>"%JSONFILE%" echo {"message":"RescueMeAI secure pairing report","content":"!B64!"}
set "PUTURL=https://api.github.com/repos/%LOGREPO%/contents/!UPLOADPATH!"
set "UPLOAD_STATUS=UPLOADING"
if exist "%HTTPFILE%" del /f /q "%HTTPFILE%" >nul 2>&1
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:%APIIP%" -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS_TOKEN!" -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" --data-binary "@%JSONFILE%" -o "%RESPFILE%" -w "%%{http_code}" "!PUTURL!" >"%HTTPFILE%" 2>"%CURLERR%"
set "UPLOAD_CURL_RC=!errorlevel!"
set "ACCESS_TOKEN="
set "UPLOAD_HTTP="
if exist "%HTTPFILE%" set /p "UPLOAD_HTTP="<"%HTTPFILE%"
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="201" goto :UPLOAD_PASS
if "!UPLOAD_CURL_RC!"=="0" if "!UPLOAD_HTTP!"=="200" goto :UPLOAD_PASS
set "UPLOAD_STATUS=FAILED"
set "FAIL_RC=90"
set "COMPONENT_RC=!UPLOAD_CURL_RC!"
if "!UPLOAD_CURL_RC!"=="0" set "COMPONENT_RC=!UPLOAD_HTTP!"
set "FAIL_REASON=GitHub App authorization succeeded, but the private report upload failed."
if "!UPLOAD_HTTP!"=="401" set "FAIL_REASON=GitHub App token was rejected during the private report upload."
if "!UPLOAD_HTTP!"=="403" set "FAIL_REASON=GitHub App authorization succeeded, but Contents write permission is not available for the private evidence repository."
if "!UPLOAD_HTTP!"=="404" set "FAIL_REASON=GitHub App authorization succeeded, but the app cannot access winre-repair-logs. Verify the app installation is restricted to and includes that repository."
goto :FAIL

:UPLOAD_PASS
set "UPLOAD_STATUS=PASS"
set "STAGE=COMPLETE"
set "COMPONENT=private reporting"
set "COMPONENT_RC=0"
call :WRITE_REPORT PASS 0 "RescueMeAI repository-scoped private reporting is online."
call :WRITE_DETAILS
call :USB_COPY
cls
color 0A >nul 2>&1
echo ================================================================
echo [PASS] RESCUEMEAI PRIVATE REPORTING ONLINE
echo ================================================================
echo Version         : %COMMAND_VERSION%
echo Terms           : !TERMS_STATUS!
echo GitHub App auth : !AUTH_STATUS!
echo Private report  : !UPLOAD_STATUS!
echo.
echo RESULT:
echo   The private RescueMeAI reporting channel is now operational.
echo   No Windows repair or destructive disk/boot action was performed.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: pass
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None
echo.
echo ADDITIONAL INSTRUCTIONS:
echo   Do not rerun C:\wr.cmd unless ChatGPT asks you to.
echo ================================================================
exit /b 0

:FAIL
call :WRITE_REPORT FAIL "!FAIL_RC!" "!FAIL_REASON!"
call :WRITE_DETAILS
call :USB_COPY
cls
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] RESCUEMEAI SECURE PAIRING FAILED
echo ================================================================
echo Version         : %COMMAND_VERSION%
echo Stage           : !STAGE!
echo Component       : !COMPONENT!
echo Return code     : !FAIL_RC!
echo Component RC    : !COMPONENT_RC!
echo Network         : !NETWORK_STATE!
echo API state       : !API_STATE!
echo GitHub state    : !WEB_STATE!
echo Terms           : !TERMS_STATUS!
echo GitHub App auth : !AUTH_STATUS!
echo Auth HTTP       : !AUTH_HTTP!
echo Auth curl RC    : !AUTH_CURL_RC!
echo Private report  : !UPLOAD_STATUS!
echo Upload HTTP     : !UPLOAD_HTTP!
echo Upload curl RC  : !UPLOAD_CURL_RC!
echo ---------------------------------------------------------------
echo Reason:
echo   !FAIL_REASON!
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   Screenshot this exact screen if private reporting is not online.
echo.
echo Nothing destructive was attempted.
echo ================================================================
pause >nul
exit /b !FAIL_RC!

:WARNING
cls
color 0E >nul 2>&1
echo ================================================================
echo [WARNING] RESCUEMEAI DID NOT START
echo ================================================================
echo Version : %COMMAND_VERSION%
echo Result  : RescueMeAI Terms were not accepted.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: warning
echo.
echo Nothing destructive was attempted.
echo ================================================================
pause >nul
exit /b 40

:REQUIRE
if exist "%~1" exit /b 0
set "COMPONENT=%~2"
set "COMPONENT_RC=91"
set "FAIL_RC=91"
set "FAIL_REASON=Required %~2 was not found."
exit /b 1

:HARVEST_IP
set "HI_HOST=%~1"
set "HI_RET=%~2"
set "HI_CACHE=%~3"
set "HI_HINT=%~4"
set "HI_IP="
if defined HI_HINT call :VALIDATE_IP "%HI_HINT%" && set "HI_IP=%HI_HINT%"
if not defined HI_IP if exist "%HI_CACHE%" (
  set "HI_CACHED="
  set /p "HI_CACHED="<"%HI_CACHE%"
  if defined HI_CACHED call :VALIDATE_IP "!HI_CACHED!" && set "HI_IP=!HI_CACHED!"
)
if not defined HI_IP if exist "%PING%" (
  set "HI_PINGLINE="
  for /f "delims=" %%L in ('"%PING%" -n 1 -w 1000 %HI_HOST% 2^>nul ^| "%FINDSTR%" /i /c:"["') do if not defined HI_PINGLINE set "HI_PINGLINE=%%L"
  if defined HI_PINGLINE (
    for /f "tokens=2 delims=[]" %%I in ("!HI_PINGLINE!") do set "HI_PINGIP=%%I"
    if defined HI_PINGIP call :VALIDATE_IP "!HI_PINGIP!" && set "HI_IP=!HI_PINGIP!"
  )
)
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if not defined HI_IP call :LOOKUP_DNS "%HI_HOST%" "%%D" HI_IP
)
if not defined HI_IP exit /b 1
set "%HI_RET%=%HI_IP%"
exit /b 0

:LOOKUP_DNS
set "LD_HOST=%~1"
set "LD_DNS=%~2"
set "LD_RET=%~3"
set "LD_CAND="
set "LD_TOKEN="
for /f "delims=" %%L in ('"%NSLOOKUP%" %LD_HOST% %LD_DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "LD_TOKEN="
  for %%T in (%%L) do set "LD_TOKEN=%%T"
  if defined LD_TOKEN if /i not "!LD_TOKEN!"=="%LD_DNS%" set "LD_CAND=!LD_TOKEN!"
)
if not defined LD_CAND exit /b 1
call :VALIDATE_IP "%LD_CAND%"
if errorlevel 1 exit /b 1
set "%LD_RET%=%LD_CAND%"
exit /b 0

:VALIDATE_IP
set "VI=%~1"
echo(%VI%| "%FINDSTR%" /R /X "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" >nul 2>&1
exit /b %errorlevel%

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
set "SL_SECONDS=%~1"
if not defined SL_SECONDS set "SL_SECONDS=5"
if exist "%PING%" (
  set /a "SL_COUNT=SL_SECONDS+1" >nul 2>&1
  "%PING%" -n !SL_COUNT! 127.0.0.1 >nul 2>&1
)
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
>>"%DETAILS%" echo stage=!STAGE!
>>"%DETAILS%" echo component=!COMPONENT!
>>"%DETAILS%" echo component_return_code=!COMPONENT_RC!
>>"%DETAILS%" echo network_state=!NETWORK_STATE!
>>"%DETAILS%" echo api_state=!API_STATE!
>>"%DETAILS%" echo api_ip=!APIIP!
>>"%DETAILS%" echo github_state=!WEB_STATE!
>>"%DETAILS%" echo github_ip=!WEBIP!
>>"%DETAILS%" echo terms_status=!TERMS_STATUS!
>>"%DETAILS%" echo auth_status=!AUTH_STATUS!
>>"%DETAILS%" echo auth_http=!AUTH_HTTP!
>>"%DETAILS%" echo auth_curl_rc=!AUTH_CURL_RC!
>>"%DETAILS%" echo upload_status=!UPLOAD_STATUS!
>>"%DETAILS%" echo upload_http=!UPLOAD_HTTP!
>>"%DETAILS%" echo upload_curl_rc=!UPLOAD_CURL_RC!
>>"%DETAILS%" echo fail_return_code=!FAIL_RC!
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
