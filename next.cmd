@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Stage RescueMeAI legal terms and establish authenticated private recovery reporting.
rem WR_ACTION=BOOTSTRAP_RESCUEMEAI_PRIVATE_REPORTING
rem WR_TARGET=Recovery tooling under C:\WinRERepair only; no Windows boot files or disk layout.
rem WR_CONSEQUENCE=Updates recovery tooling, stages legal documents, records Terms acceptance, and establishes an outbound authenticated reporting credential.
rem WR_ROLLBACK=Tooling and local authorization files can be removed later; no operating-system recovery changes are performed by this build.

set "COMMAND_VERSION=RMAI-2026.08.14-1168-ET"
set "BUILD_TIME=2026-08-14 12:08 ET"
set "PRODUCT=RescueMeAI"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "SYNCDETAILS=%WORK%\RUNTIME_SYNC_DETAILS.txt"
set "GITHUBRESULT=%WORK%\GITHUB_RESULT.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "HOSTS=X:\Windows\System32\drivers\etc\hosts"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=361207af22939f36963036ea18935128fad54b75"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"
set "ACCEPTANCE=%RUNTIME%\acceptance.cmd"
set "RESOLVER_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/resolve.cmd?ref=%SOURCE_REF%"
set "BOOTSTRAP_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/runtime-sync.cmd?ref=%SOURCE_REF%"

set "STAGE=START"
set "COMPONENT=next.cmd"
set "FAIL_REASON=RescueMeAI bootstrap did not complete."
set "FAIL_RC=90"
set "COMPONENT_RC=NOT_RUN"
set "NETWORK_STATE=UNKNOWN"
set "PING_BEFORE_RC=NOT_RUN"
set "WPEUTIL_RC=NOT_RUN"
set "PING_AFTER_RC=NOT_RUN"
set "API_RESOLVED=NO"
set "APIIP="
set "API_HTTPS=NOT_TESTED"
set "API_HTTPS_RC=NOT_RUN"
set "WEB_RESOLVED=NO"
set "WEBIP="
set "WEB_HTTPS=NOT_TESTED"
set "WEB_HTTPS_RC=NOT_RUN"
set "RUNTIME_SYNC=NOT_STARTED"
set "RUNTIME_SYNC_RC=NOT_RUN"
set "RUNTIME_COMPONENT=None"
set "RUNTIME_COMPONENT_STAGE=None"
set "RUNTIME_COMPONENT_RC=NOT_RUN"
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
call :WRITE_DETAILS
call :WRITE_REPORT RUNNING 0 "RescueMeAI private-reporting bootstrap started."

cls
color 07 >nul 2>&1
echo ================================================================
echo RESCUEMEAI - PRIVATE REPORTING BOOTSTRAP
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo This build does NOT repair Windows yet.
echo.
echo Disk formatting / cleaning     : NONE
echo Partition / filesystem changes : NONE
echo Windows boot/system repair      : NONE
echo Destructive operations          : NONE
echo.
echo Goals:
echo   1. Stage RescueMeAI legal documents.
echo   2. Obtain one-time/versioned Terms acceptance.
echo   3. Establish private authenticated reporting without JScript.
echo ================================================================

set "STAGE=PRECHECK"
set "COMPONENT=required WinRE tools"
if not exist "%WORK%" (
  set "COMPONENT=C:\WinRERepair"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Could not access or create the recovery work directory."
  goto :FAIL
)
if not exist "%RUNTIME%" (
  set "COMPONENT=C:\WinRERepair\runtime"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Could not access or create the runtime directory."
  goto :FAIL
)
if not exist "%CURL%" (
  set "COMPONENT=curl.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required curl.exe was not found."
  goto :FAIL
)
if not exist "%FINDSTR%" (
  set "COMPONENT=findstr.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required findstr.exe was not found."
  goto :FAIL
)
if not exist "%NSLOOKUP%" (
  set "COMPONENT=nslookup.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required nslookup.exe was not found."
  goto :FAIL
)
if not exist "%CERTUTIL%" (
  set "COMPONENT=certutil.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required certutil.exe was not found."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=NETWORK_INITIALIZE"
set "COMPONENT=WinRE network"
if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  set "PING_BEFORE_RC=!errorlevel!"
  if "!PING_BEFORE_RC!"=="0" (
    set "NETWORK_STATE=ONLINE"
  ) else (
    if exist "%WPEUTIL%" (
      "%WPEUTIL%" InitializeNetwork >nul 2>&1
      set "WPEUTIL_RC=!errorlevel!"
    )
    "%PING%" -n 1 -w 3000 1.1.1.1 >nul 2>&1
    set "PING_AFTER_RC=!errorlevel!"
    if "!PING_AFTER_RC!"=="0" (
      set "NETWORK_STATE=ONLINE"
    ) else (
      set "NETWORK_STATE=PARTIAL_OR_ICMP_BLOCKED"
    )
  )
) else (
  set "NETWORK_STATE=PING_UNAVAILABLE"
)
call :WRITE_DETAILS

set "STAGE=RESOLVE_API_GITHUB"
set "COMPONENT=api.github.com"
call :RESOLVE_HOST "%APIHOST%" APIIP
set "RESRC=!errorlevel!"
set "API_RESOLVED=!RH_ANY_RESOLVED!"
set "API_HTTPS_RC=!RH_LAST_HTTPS_RC!"
if "!RESRC!"=="0" (
  set "API_HTTPS=PASS"
  >"%WORK%\github-api-ip.txt" echo(!APIIP!
) else (
  set "API_HTTPS=FAIL"
  set "COMPONENT_RC=!API_HTTPS_RC!"
  set "FAIL_RC=92"
  set "FAIL_REASON=Could not obtain an HTTPS-validated address for api.github.com."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=RESOLVE_GITHUB_WEB"
set "COMPONENT=github.com"
call :RESOLVE_HOST "%WEBHOST%" WEBIP
set "RESRC=!errorlevel!"
set "WEB_RESOLVED=!RH_ANY_RESOLVED!"
set "WEB_HTTPS_RC=!RH_LAST_HTTPS_RC!"
if "!RESRC!"=="0" (
  set "WEB_HTTPS=PASS"
  >"%WORK%\github-web-ip.txt" echo(!WEBIP!
) else (
  set "WEB_HTTPS=FAIL"
  set "COMPONENT_RC=!WEB_HTTPS_RC!"
  set "FAIL_RC=92"
  set "FAIL_REASON=Could not obtain an HTTPS-validated address for github.com."
  goto :FAIL
)
call :STAGE_HOSTS
call :WRITE_DETAILS

set "STAGE=FETCH_RESOLVER"
set "COMPONENT=lib/resolve.cmd"
call :FETCH "%RESOLVER_URL%" "%RESOLVER%.tmp"
set "FETCHRC=!errorlevel!"
if not "!FETCHRC!"=="0" (
  set "COMPONENT_RC=!FETCHRC!"
  set "FAIL_RC=90"
  set "FAIL_REASON=Could not download the pinned RescueMeAI resolver."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: resolve" "%RESOLVER%.tmp" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded resolver failed module validation."
  goto :FAIL
)
move /y "%RESOLVER%.tmp" "%RESOLVER%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated resolver could not be staged locally."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=FETCH_RUNTIME_SYNC"
set "COMPONENT=lib/runtime-sync.cmd"
call :FETCH "%BOOTSTRAP_URL%" "%BOOTSTRAP%.tmp"
set "FETCHRC=!errorlevel!"
if not "!FETCHRC!"=="0" (
  set "COMPONENT_RC=!FETCHRC!"
  set "FAIL_RC=90"
  set "FAIL_REASON=Could not download the pinned RescueMeAI runtime synchronizer."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%.tmp" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded runtime synchronizer failed module validation."
  goto :FAIL
)
move /y "%BOOTSTRAP%.tmp" "%BOOTSTRAP%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated runtime synchronizer could not be staged locally."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=RUNTIME_SYNC"
set "COMPONENT=lib/runtime-sync.cmd"
set "RUNTIME_SYNC=RUNNING"
call :WRITE_DETAILS
call "%BOOTSTRAP%" pairing "%SOURCE_REPO%" "%SOURCE_REF%"
set "RUNTIME_SYNC_RC=!errorlevel!"
if not "!RUNTIME_SYNC_RC!"=="0" (
  set "RUNTIME_SYNC=FAIL"
  call :READ_SYNC_DETAILS
  set "COMPONENT=!RUNTIME_COMPONENT!"
  set "COMPONENT_RC=!RUNTIME_COMPONENT_RC!"
  set "FAIL_RC=!RUNTIME_SYNC_RC!"
  set "FAIL_REASON=Runtime synchronization failed at !RUNTIME_COMPONENT! / !RUNTIME_COMPONENT_STAGE!."
  goto :FAIL
)
set "RUNTIME_SYNC=PASS"
set "RUNTIME_COMPONENT=ALL"
set "RUNTIME_COMPONENT_STAGE=COMPLETE"
set "RUNTIME_COMPONENT_RC=0"
call :WRITE_DETAILS

set "STAGE=TERMS_ACCEPTANCE"
set "COMPONENT=lib/acceptance.cmd"
set "TERMS_STATUS=PROMPTING"
call :WRITE_DETAILS
call "%ACCEPTANCE%" check "%WORK%"
set "TERMS_RC=!errorlevel!"
if "!TERMS_RC!"=="40" (
  set "TERMS_STATUS=DECLINED"
  set "COMPONENT_RC=40"
  call :WRITE_DETAILS
  call :WRITE_REPORT WARNING 40 "RescueMeAI Terms were not accepted; no recovery or authorization action was performed."
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

set "STAGE=WRITE_CONFIG"
set "COMPONENT=agent.cfg"
>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo CONTROL_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo LOG_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo OAUTH_CLIENT_ID=178c6fc778ccc68e1d6a
>>"%CONFIG%" echo POLL_SECONDS=15
if not exist "%CONFIG%" (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Could not write the local RescueMeAI configuration."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=GITHUB_AUTHORIZATION"
set "COMPONENT=lib/github-auth.cmd"
set "GITHUB_AUTHORIZATION=STARTED"
set "GITHUB_AUTH_REASON=Pure-CMD GitHub device authorization started."
call :WRITE_DETAILS
call :WRITE_REPORT RUNNING 0 "RescueMeAI runtime and Terms passed; waiting for one-time GitHub device authorization."
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
call :WRITE_DETAILS

set "STAGE=FINAL_REPORT_UPLOAD"
set "COMPONENT=lib/github-auth.cmd"
call :WRITE_REPORT PASS 0 "RescueMeAI private authenticated reporting is online. Persistent command-listener installation is the next controlled step."
call :WRITE_DETAILS
call :USB_COPY
call "%AUTH%" upload
set "FINAL_UPLOAD_RC=!errorlevel!"
if not "!FINAL_UPLOAD_RC!"=="0" (
  set "PRIVATE_REPORT_UPLOAD=FAIL"
  set "COMPONENT_RC=!FINAL_UPLOAD_RC!"
  set "FAIL_RC=!FINAL_UPLOAD_RC!"
  call :READ_GITHUB_RESULT
  set "FAIL_REASON=Authorization succeeded but the final private report upload failed: !GITHUB_AUTH_REASON!"
  goto :FAIL
)
set "PRIVATE_REPORT_UPLOAD=PASS"
set "STAGE=COMPLETE"
set "COMPONENT=private reporting"
set "COMPONENT_RC=0"
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
echo Runtime sync        : !RUNTIME_SYNC!
echo GitHub authorization: !GITHUB_AUTHORIZATION!
echo Private report      : !PRIVATE_REPORT_UPLOAD!
echo.
echo RESULT:
echo   RescueMeAI can now send authenticated private recovery reports.
echo   No Windows repair, disk, boot, partition, or filesystem change ran.
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
echo [FAIL] RESCUEMEAI BOOTSTRAP FAILED
echo ================================================================
echo Version       : %COMMAND_VERSION%
echo Stage         : !STAGE!
echo Component     : !COMPONENT!
echo Return code   : !FAIL_RC!
echo Component RC  : !COMPONENT_RC!
echo ---------------------------------------------------------------
echo Network state : !NETWORK_STATE!
echo api.github.com: resolved=!API_RESOLVED! https=!API_HTTPS! rc=!API_HTTPS_RC!
echo github.com    : resolved=!WEB_RESOLVED! https=!WEB_HTTPS! rc=!WEB_HTTPS_RC!
echo Runtime sync  : !RUNTIME_SYNC! rc=!RUNTIME_SYNC_RC!
echo Runtime item  : !RUNTIME_COMPONENT! / !RUNTIME_COMPONENT_STAGE! / !RUNTIME_COMPONENT_RC!
echo Terms         : !TERMS_STATUS! rc=!TERMS_RC!
echo GitHub auth   : !GITHUB_AUTHORIZATION! rc=!GITHUB_AUTH_RC!
echo Auth HTTP     : !GITHUB_AUTH_HTTP!
echo Auth curl RC  : !GITHUB_AUTH_CURL_RC!
echo Private report: !PRIVATE_REPORT_UPLOAD!
echo ---------------------------------------------------------------
echo Reason:
echo   !FAIL_REASON!
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   Screenshot this exact screen.
echo.
echo Local details:
echo   %DETAILS%
echo   %REPORT%
echo.
echo Nothing destructive was attempted.
echo ================================================================
echo This screen is being held so the legacy launcher cannot hide it.
pause >nul
exit /b !FAIL_RC!

:WARNING
cls
color 0E >nul 2>&1
echo ================================================================
echo [WARNING] RESCUEMEAI DID NOT START
echo ================================================================
echo Version : %COMMAND_VERSION%
echo Stage   : !STAGE!
echo Result  : RescueMeAI Terms were not accepted.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: warning
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None
echo.
echo Nothing destructive was attempted.
echo ================================================================
pause >nul
exit /b 40

:FETCH
set "FETCH_URL=%~1"
set "FETCH_OUT=%~2"
if exist "%FETCH_OUT%" del /f /q "%FETCH_OUT%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCH_URL%" -o "%FETCH_OUT%"
set "FRC=!errorlevel!"
if not "!FRC!"=="0" exit /b !FRC!
if not exist "%FETCH_OUT%" exit /b 90
for %%Z in ("%FETCH_OUT%") do if %%~zZ LSS 32 exit /b 90
exit /b 0

:RESOLVE_HOST
set "RH_HOST=%~1"
set "RH_RET=%~2"
set "RH_FOUND="
set "RH_CAND="
set "RH_CACHE="
set "RH_ANY_RESOLVED=NO"
set "RH_LAST_HTTPS_RC=NOT_RUN"
if /i "%RH_HOST%"=="api.github.com" set "RH_CACHE=%WORK%\github-api-ip.txt"
if /i "%RH_HOST%"=="github.com" set "RH_CACHE=%WORK%\github-web-ip.txt"
if defined RH_CACHE if exist "%RH_CACHE%" (
  set "RH_CAND="
  set /p "RH_CAND="<"%RH_CACHE%"
  if defined RH_CAND (
    set "RH_ANY_RESOLVED=YES"
    call :TEST_HOST
    if not errorlevel 1 set "RH_FOUND=!RH_CAND!"
  )
)
for %%D in (64.71.255.204 1.1.1.1 8.8.8.8 9.9.9.9) do (
  if not defined RH_FOUND call :LOOKUP_HOST "%%D"
)
if not defined RH_FOUND exit /b 92
set "%RH_RET%=%RH_FOUND%"
exit /b 0

:LOOKUP_HOST
set "RH_DNS=%~1"
set "RH_CAND="
set "RH_TOK="
for /f "delims=" %%L in ('"%NSLOOKUP%" %RH_HOST% %RH_DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  set "RH_TOK="
  for %%T in (%%L) do set "RH_TOK=%%T"
  if defined RH_TOK if /i not "!RH_TOK!"=="%RH_DNS%" set "RH_CAND=!RH_TOK!"
)
if defined RH_CAND (
  set "RH_ANY_RESOLVED=YES"
  call :TEST_HOST
  if not errorlevel 1 set "RH_FOUND=!RH_CAND!"
)
exit /b 0

:TEST_HOST
if not defined RH_CAND (
  set "RH_LAST_HTTPS_RC=92"
  exit /b 92
)
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 8 --max-time 20 --resolve "%RH_HOST%:443:%RH_CAND%" "https://%RH_HOST%/" -o NUL >nul 2>&1
set "RH_LAST_HTTPS_RC=!errorlevel!"
exit /b !RH_LAST_HTTPS_RC!

:STAGE_HOSTS
if not exist "X:\Windows\System32\drivers\etc" exit /b 0
if exist "%HOSTS%" (
  "%FINDSTR%" /v /i /c:"# RESCUEMEAI" "%HOSTS%" >"%WORK%\hosts-clean.tmp" 2>nul
  if exist "%WORK%\hosts-clean.tmp" copy /y "%WORK%\hosts-clean.tmp" "%HOSTS%" >nul 2>&1
)
>>"%HOSTS%" echo %APIIP% api.github.com # RESCUEMEAI
>>"%HOSTS%" echo %WEBIP% github.com # RESCUEMEAI
exit /b 0

:READ_SYNC_DETAILS
if not exist "%SYNCDETAILS%" exit /b 0
for /f "usebackq tokens=1,* delims==" %%A in ("%SYNCDETAILS%") do (
  if /i "%%A"=="component" set "RUNTIME_COMPONENT=%%B"
  if /i "%%A"=="component_stage" set "RUNTIME_COMPONENT_STAGE=%%B"
  if /i "%%A"=="component_return_code" set "RUNTIME_COMPONENT_RC=%%B"
)
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
>>"%DETAILS%" echo ping_before_rc=!PING_BEFORE_RC!
>>"%DETAILS%" echo wpeutil_rc=!WPEUTIL_RC!
>>"%DETAILS%" echo ping_after_rc=!PING_AFTER_RC!
>>"%DETAILS%" echo api_github_resolved=!API_RESOLVED!
>>"%DETAILS%" echo api_github_ip=!APIIP!
>>"%DETAILS%" echo api_github_https=!API_HTTPS!
>>"%DETAILS%" echo api_github_https_rc=!API_HTTPS_RC!
>>"%DETAILS%" echo github_web_resolved=!WEB_RESOLVED!
>>"%DETAILS%" echo github_web_ip=!WEBIP!
>>"%DETAILS%" echo github_web_https=!WEB_HTTPS!
>>"%DETAILS%" echo github_web_https_rc=!WEB_HTTPS_RC!
>>"%DETAILS%" echo runtime_sync=!RUNTIME_SYNC!
>>"%DETAILS%" echo runtime_sync_rc=!RUNTIME_SYNC_RC!
>>"%DETAILS%" echo runtime_component=!RUNTIME_COMPONENT!
>>"%DETAILS%" echo runtime_component_stage=!RUNTIME_COMPONENT_STAGE!
>>"%DETAILS%" echo runtime_component_rc=!RUNTIME_COMPONENT_RC!
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
if exist "%WORK%\legal" (
  if not exist "!REPORTVOL!\RescueMeAI\legal" md "!REPORTVOL!\RescueMeAI\legal" >nul 2>&1
  copy /y "%WORK%\legal\*.md" "!REPORTVOL!\RescueMeAI\legal\" >nul 2>&1
)
exit /b 0
