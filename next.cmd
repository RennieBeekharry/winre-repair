@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Stage RescueMeAI legal terms and establish repository-scoped GitHub App private reporting.
rem WR_ACTION=BOOTSTRAP_RESCUEMEAI_SECURE_PRIVATE_REPORTING
rem WR_TARGET=Recovery tooling under C:\WinRERepair only; no Windows boot files or disk layout.
rem WR_CONSEQUENCE=Updates recovery tooling, records Terms acceptance, and establishes a repository-scoped outbound GitHub App credential.
rem WR_ROLLBACK=Tooling and local authorization files can be removed later; no operating-system recovery changes are performed.

set "COMMAND_VERSION=RMAI-2026.08.14-SECURE-PAIRING-3"
set "PRODUCT=RescueMeAI"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "LEGAL=%WORK%\legal"
set "CONFIG=%WORK%\agent.cfg"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "GITHUBRESULT=%WORK%\GITHUB_RESULT.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=d24a5c20574cdce2f6d7ea28a08ebf67a4a5285f"
set "ACCEPTANCE=%RUNTIME%\acceptance.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"

rem C:\wr.cmd has already downloaded this exact file from api.github.com.
rem Preserve the launcher-resolved API address if it used one. We do NOT
rem re-resolve or re-validate api.github.com in this child process.
set "LAUNCHER_APIIP=%APIIP%"
set "APIIP=%LAUNCHER_APIIP%"
set "WEBIP="

set "STAGE=START"
set "COMPONENT=next.cmd"
set "FAIL_RC=90"
set "COMPONENT_RC=NOT_RUN"
set "FAIL_REASON=RescueMeAI secure pairing bootstrap did not complete."
set "NETWORK_STATE=UNKNOWN"
set "API_HTTPS=PROVEN_BY_LAUNCHER"
set "WEB_HTTPS=NOT_TESTED"
set "MODULE_STAGE=NOT_STARTED"
set "TERMS_STATUS=NOT_REACHED"
set "TERMS_RC=NOT_RUN"
set "GITHUB_AUTHORIZATION=NOT_REACHED"
set "GITHUB_AUTH_RC=NOT_RUN"
set "GITHUB_AUTH_HTTP=NOT_RUN"
set "GITHUB_AUTH_CURL_RC=NOT_RUN"
set "GITHUB_AUTH_REASON=Not reached."
set "PRIVATE_REPORT_UPLOAD=NOT_REACHED"
set "REPORTVOL="

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%LEGAL%" md "%LEGAL%" >nul 2>&1
call :WRITE_REPORT RUNNING 0 "RescueMeAI secure GitHub App pairing bootstrap started."
call :WRITE_DETAILS

cls
color 07 >nul 2>&1
echo ================================================================
echo RESCUEMEAI - SECURE PRIVATE REPORTING PAIRING
echo Version: %COMMAND_VERSION%
echo ================================================================
echo This build does NOT repair Windows.
echo.
echo Disk formatting / cleaning     : NONE
echo Partition / filesystem changes : NONE
echo Windows boot/system repair      : NONE
echo Destructive operations          : NONE
echo.
echo Authentication model:
echo   GitHub App ID        : 4595411
echo   Private repository   : RennieBeekharry/winre-repair-logs
echo   Repository ID        : 1333818657
echo   Classic OAuth scopes : NONE
echo.
echo api.github.com status:
echo   PROVEN - the launcher fetched this build from it successfully.
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

rem Fetch only the modules and legal documents needed for pairing. Unlike the
rem old runtime-sync path, this does not perform a second API resolver pass.
set "STAGE=STAGE_PAIRING_FILES"
set "COMPONENT=lib/acceptance.cmd"
set "MODULE_STAGE=DOWNLOAD_ACCEPTANCE"
call :FETCH_API "lib/acceptance.cmd" "%ACCEPTANCE%" "WR-MODULE: acceptance"
if errorlevel 1 goto :FAIL

set "COMPONENT=lib/github-auth.cmd"
set "MODULE_STAGE=DOWNLOAD_AUTH"
call :FETCH_API "lib/github-auth.cmd" "%AUTH%" "WR-MODULE: github-auth"
if errorlevel 1 goto :FAIL

set "COMPONENT=TERMS_OF_USE.md"
set "MODULE_STAGE=DOWNLOAD_TERMS"
call :FETCH_API "TERMS_OF_USE.md" "%LEGAL%\TERMS_OF_USE.md" "RescueMeAI"
if errorlevel 1 goto :FAIL

set "COMPONENT=PRIVACY_POLICY.md"
set "MODULE_STAGE=DOWNLOAD_PRIVACY"
call :FETCH_API "PRIVACY_POLICY.md" "%LEGAL%\PRIVACY_POLICY.md" "RescueMeAI"
if errorlevel 1 goto :FAIL

set "COMPONENT=DISCLAIMER_AND_RISK_NOTICE.md"
set "MODULE_STAGE=DOWNLOAD_DISCLAIMER"
call :FETCH_API "DISCLAIMER_AND_RISK_NOTICE.md" "%LEGAL%\DISCLAIMER_AND_RISK_NOTICE.md" "RescueMeAI"
if errorlevel 1 goto :FAIL

set "COMPONENT=LICENSE.md"
set "MODULE_STAGE=DOWNLOAD_LICENSE"
call :FETCH_API "LICENSE.md" "%LEGAL%\LICENSE.md" "RescueMeAI"
if errorlevel 1 goto :FAIL

set "COMPONENT=TRADEMARKS.md"
set "MODULE_STAGE=DOWNLOAD_TRADEMARKS"
call :FETCH_API "TRADEMARKS.md" "%LEGAL%\TRADEMARKS.md" "RescueMeAI"
if errorlevel 1 goto :FAIL
set "MODULE_STAGE=PAIRING_FILES_READY"
call :WRITE_DETAILS

set "STAGE=TERMS_ACCEPTANCE"
set "COMPONENT=lib/acceptance.cmd"
set "TERMS_STATUS=PROMPTING"
call :WRITE_DETAILS
call "%ACCEPTANCE%" check "%WORK%"
set "TERMS_RC=!errorlevel!"
if "!TERMS_RC!"=="40" (
  set "TERMS_STATUS=DECLINED"
  call :WRITE_DETAILS
  call :WRITE_REPORT WARNING 40 "RescueMeAI Terms were not accepted; no authorization or recovery action was performed."
  call :USB_COPY
  goto :WARNING
)
if not "!TERMS_RC!"=="0" (
  set "TERMS_STATUS=FAIL"
  set "COMPONENT_RC=!TERMS_RC!"
  set "FAIL_RC=!TERMS_RC!"
  set "FAIL_REASON=The RescueMeAI Terms acceptance module failed."
  goto :FAIL
)
set "TERMS_STATUS=ACCEPTED"
call :WRITE_DETAILS

rem github.com is a different endpoint used only for the device-flow pages.
rem Resolve it now, after the proven API path and local Terms are ready.
set "STAGE=RESOLVE_GITHUB_DEVICE_ENDPOINT"
set "COMPONENT=github.com"
call :RESOLVE_WEB
if errorlevel 1 (
  set "WEB_HTTPS=FAIL"
  set "COMPONENT_RC=92"
  set "FAIL_RC=92"
  set "FAIL_REASON=Could not obtain an HTTPS-validated address for the GitHub device-authorization endpoint."
  goto :FAIL
)
set "WEB_HTTPS=PASS"
>"%WORK%\github-web-ip.txt" echo(!WEBIP!

rem github-auth.cmd also uses api.github.com for the private evidence upload.
rem If the launcher provided its proven API address, preserve it. Otherwise,
rem obtain an address without adding a redundant HTTPS gate; API fetches above
rem have already proven the hostname works in this exact run.
if defined APIIP (
  >"%WORK%\github-api-ip.txt" echo(!APIIP!
) else (
  call :LOOKUP_ONLY "%APIHOST%" APIIP
  if defined APIIP >"%WORK%\github-api-ip.txt" echo(!APIIP!
)
if not defined APIIP (
  set "COMPONENT=api.github.com address handoff"
  set "COMPONENT_RC=92"
  set "FAIL_RC=92"
  set "FAIL_REASON=The launcher proved GitHub API access, but no address could be handed to the authentication module."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=WRITE_CONFIG"
set "COMPONENT=agent.cfg"
>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo AUTH_PROVIDER=GITHUB_APP
>>"%CONFIG%" echo CONTROL_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo LOG_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo GITHUB_APP_ID=4595411
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=1333818657
>>"%CONFIG%" echo POLL_SECONDS=15
if not exist "%CONFIG%" (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Could not write the local RescueMeAI configuration."
  goto :FAIL
)

set "STAGE=GITHUB_APP_AUTHORIZATION"
set "COMPONENT=lib/github-auth.cmd"
set "GITHUB_AUTHORIZATION=STARTED"
set "GITHUB_AUTH_REASON=Repository-scoped GitHub App device authorization started."
call :WRITE_DETAILS
call :WRITE_REPORT RUNNING 0 "RescueMeAI Terms passed; waiting for one-time repository-scoped GitHub App authorization."
if exist "%GITHUBRESULT%" del /f /q "%GITHUBRESULT%" >nul 2>&1
call "%AUTH%" authorize
set "GITHUB_AUTH_RC=!errorlevel!"
call :READ_GITHUB_RESULT
if not "!GITHUB_AUTH_RC!"=="0" (
  set "GITHUB_AUTHORIZATION=FAIL"
  set "COMPONENT_RC=!GITHUB_AUTH_CURL_RC!"
  if "!COMPONENT_RC!"=="NOT_RUN" set "COMPONENT_RC=!GITHUB_AUTH_RC!"
  set "FAIL_RC=!GITHUB_AUTH_RC!"
  set "FAIL_REASON=!GITHUB_AUTH_REASON!"
  goto :FAIL
)
set "GITHUB_AUTHORIZATION=PASS"
set "PRIVATE_REPORT_UPLOAD=PASS"

set "STAGE=FINAL_REPORT_UPLOAD"
set "COMPONENT=lib/github-auth.cmd"
call :WRITE_REPORT PASS 0 "RescueMeAI repository-scoped private reporting is online. Persistent listener validation is the next controlled step."
call :WRITE_DETAILS
call :USB_COPY
call "%AUTH%" upload
set "FINAL_UPLOAD_RC=!errorlevel!"
call :READ_GITHUB_RESULT
if not "!FINAL_UPLOAD_RC!"=="0" (
  set "PRIVATE_REPORT_UPLOAD=FAIL"
  set "FAIL_RC=!FINAL_UPLOAD_RC!"
  set "COMPONENT_RC=!GITHUB_AUTH_CURL_RC!"
  set "FAIL_REASON=Pairing succeeded but the final private report upload failed: !GITHUB_AUTH_REASON!"
  goto :FAIL
)
set "PRIVATE_REPORT_UPLOAD=PASS"
call :WRITE_DETAILS
call :USB_COPY

cls
color 0A >nul 2>&1
echo ================================================================
echo [PASS] RESCUEMEAI PRIVATE REPORTING ONLINE
echo ================================================================
echo Version             : %COMMAND_VERSION%
echo Terms               : !TERMS_STATUS!
echo api.github.com HTTPS: !API_HTTPS!
echo github.com HTTPS    : !WEB_HTTPS!
echo Pairing files       : !MODULE_STAGE!
echo GitHub App auth     : !GITHUB_AUTHORIZATION!
echo Private report      : !PRIVATE_REPORT_UPLOAD!
echo.
echo RESULT:
echo   Repository-scoped RescueMeAI private reporting is online.
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
call :WRITE_DETAILS
call :WRITE_REPORT FAIL "!FAIL_RC!" "!FAIL_REASON!"
call :USB_COPY
cls
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] RESCUEMEAI SECURE PAIRING FAILED
echo ================================================================
echo Version        : %COMMAND_VERSION%
echo Stage          : !STAGE!
echo Component      : !COMPONENT!
echo Return code    : !FAIL_RC!
echo Component RC   : !COMPONENT_RC!
echo Network        : !NETWORK_STATE!
echo API HTTPS      : !API_HTTPS!
echo GitHub HTTPS   : !WEB_HTTPS!
echo Pairing files  : !MODULE_STAGE!
echo Terms          : !TERMS_STATUS! rc=!TERMS_RC!
echo GitHub App auth: !GITHUB_AUTHORIZATION! rc=!GITHUB_AUTH_RC!
echo Auth HTTP      : !GITHUB_AUTH_HTTP!
echo Auth curl RC   : !GITHUB_AUTH_CURL_RC!
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

:FETCH_API
set "FA_PATH=%~1"
set "FA_DEST=%~2"
set "FA_MARK=%~3"
set "FA_TMP=%FA_DEST%.tmp"
set "FA_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/%FA_PATH%?ref=%SOURCE_REF%"
if exist "%FA_TMP%" del /f /q "%FA_TMP%" >nul 2>&1

rem First mirror exactly how the parent launcher succeeded: use its API IP if
rem available; otherwise use normal DNS. If the IP-pinned attempt fails, retry
rem once using normal DNS instead of turning DNS into a separate hard gate.
set "FA_RC=1"
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 120 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FA_URL%" -o "%FA_TMP%"
  set "FA_RC=!errorlevel!"
)
if not "!FA_RC!"=="0" (
  if exist "%FA_TMP%" del /f /q "%FA_TMP%" >nul 2>&1
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FA_URL%" -o "%FA_TMP%"
  set "FA_RC=!errorlevel!"
)
if not "!FA_RC!"=="0" (
  set "COMPONENT_RC=!FA_RC!"
  set "FAIL_RC=90"
  set "FAIL_REASON=Could not download !FA_PATH! through the API path already proven by the launcher."
  exit /b 1
)
if not exist "%FA_TMP%" (
  set "COMPONENT_RC=90"
  set "FAIL_RC=90"
  set "FAIL_REASON=Download reported success but !FA_PATH! was not created."
  exit /b 1
)
for %%Z in ("%FA_TMP%") do if %%~zZ LSS 32 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded !FA_PATH! was unexpectedly small."
  exit /b 1
)
"%FINDSTR%" /i /c:"%FA_MARK%" "%FA_TMP%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded !FA_PATH! failed content validation."
  exit /b 1
)
move /y "%FA_TMP%" "%FA_DEST%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated !FA_PATH! could not be staged locally."
  exit /b 1
)
exit /b 0

:RESOLVE_WEB
set "WEBIP="
rem Try a previously validated address first.
if exist "%WORK%\github-web-ip.txt" (
  set "WEB_CAND="
  set /p "WEB_CAND="<"%WORK%\github-web-ip.txt"
  if defined WEB_CAND (
    call :TEST_WEB "!WEB_CAND!"
    if not errorlevel 1 (
      set "WEBIP=!WEB_CAND!"
      exit /b 0
    )
  )
)
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if not defined WEBIP call :LOOKUP_WEB "%%D"
)
if defined WEBIP exit /b 0
exit /b 92

:LOOKUP_WEB
set "WEB_DNS=%~1"
set "WEB_CAND="
set "WEB_TOK="
for /f "delims=" %%L in ('"%NSLOOKUP%" %WEBHOST% %WEB_DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "WEB_TOK="
  for %%T in (%%L) do set "WEB_TOK=%%T"
  if defined WEB_TOK if /i not "!WEB_TOK!"=="%WEB_DNS%" set "WEB_CAND=!WEB_TOK!"
)
if defined WEB_CAND (
  call :TEST_WEB "!WEB_CAND!"
  if not errorlevel 1 set "WEBIP=!WEB_CAND!"
)
exit /b 0

:TEST_WEB
set "TW_IP=%~1"
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 30 --resolve "%WEBHOST%:443:%TW_IP%" "https://%WEBHOST%/login/device" -o NUL >nul 2>&1
exit /b !errorlevel!

:LOOKUP_ONLY
set "LO_HOST=%~1"
set "LO_RET=%~2"
set "LO_RESULT="
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if not defined LO_RESULT (
    set "LO_CAND="
    set "LO_TOK="
    for /f "delims=" %%L in ('"%NSLOOKUP%" %LO_HOST% %%D 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
      set "LO_TOK="
      for %%T in (%%L) do set "LO_TOK=%%T"
      if defined LO_TOK if /i not "!LO_TOK!"=="%%D" set "LO_CAND=!LO_TOK!"
    )
    if defined LO_CAND set "LO_RESULT=!LO_CAND!"
  )
)
set "%LO_RET%=%LO_RESULT%"
exit /b 0

:READ_GITHUB_RESULT
if not exist "%GITHUBRESULT%" (
  set "GITHUB_AUTH_REASON=Authorization helper returned without a result file."
  set "GITHUB_AUTH_HTTP=NOT_RECORDED"
  set "GITHUB_AUTH_CURL_RC=NOT_RECORDED"
  exit /b 0
)
for /f "usebackq tokens=1,* delims==" %%A in ("%GITHUBRESULT%") do (
  if /i "%%A"=="reason" set "GITHUB_AUTH_REASON=%%B"
  if /i "%%A"=="http" set "GITHUB_AUTH_HTTP=%%B"
  if /i "%%A"=="curl_return_code" set "GITHUB_AUTH_CURL_RC=%%B"
)
exit /b 0

:WRITE_DETAILS
>"%DETAILS%" echo product=%PRODUCT%
>>"%DETAILS%" echo build=%COMMAND_VERSION%
>>"%DETAILS%" echo stage=!STAGE!
>>"%DETAILS%" echo component=!COMPONENT!
>>"%DETAILS%" echo component_return_code=!COMPONENT_RC!
>>"%DETAILS%" echo network_state=!NETWORK_STATE!
>>"%DETAILS%" echo api_https=!API_HTTPS!
>>"%DETAILS%" echo launcher_api_ip=!LAUNCHER_APIIP!
>>"%DETAILS%" echo api_ip_handoff=!APIIP!
>>"%DETAILS%" echo github_web_https=!WEB_HTTPS!
>>"%DETAILS%" echo github_web_ip=!WEBIP!
>>"%DETAILS%" echo pairing_file_stage=!MODULE_STAGE!
>>"%DETAILS%" echo terms_status=!TERMS_STATUS!
>>"%DETAILS%" echo terms_rc=!TERMS_RC!
>>"%DETAILS%" echo github_authorization=!GITHUB_AUTHORIZATION!
>>"%DETAILS%" echo github_auth_rc=!GITHUB_AUTH_RC!
>>"%DETAILS%" echo github_auth_http=!GITHUB_AUTH_HTTP!
>>"%DETAILS%" echo github_auth_curl_rc=!GITHUB_AUTH_CURL_RC!
>>"%DETAILS%" echo github_auth_reason=!GITHUB_AUTH_REASON!
>>"%DETAILS%" echo private_report_upload=!PRIVATE_REPORT_UPLOAD!
>>"%DETAILS%" echo fail_return_code=!FAIL_RC!
>>"%DETAILS%" echo reason=!FAIL_REASON!
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
if exist "%LEGAL%" (
  if not exist "!REPORTVOL!\RescueMeAI\legal" md "!REPORTVOL!\RescueMeAI\legal" >nul 2>&1
  copy /y "%LEGAL%\*.md" "!REPORTVOL!\RescueMeAI\legal\" >nul 2>&1
)
exit /b 0
