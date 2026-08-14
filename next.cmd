@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Diagnose, pair, and start the AI Recovery command agent without touching Windows boot files or disk layout.
rem WR_ACTION=DIAGNOSE_AND_START_AI_RECOVERY_AGENT
rem WR_TARGET=Recovery tooling under C:\WinRERepair and C:\wr-agent.cmd only.
rem WR_CONSEQUENCE=Creates or updates recovery-agent files and temporary WinRE network mappings. It does not alter Windows boot files, partitions, filesystems, or personal data.
rem WR_ROLLBACK=Agent files can be removed later; temporary X: network mappings disappear when WinRE restarts.

set "COMMAND_VERSION=WR-2026.08.14-1150-ET"
set "BUILD_TIME=2026-08-14 11:50 ET"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "REPORT=%WORK%\LAST_RUN_REPORT.txt"
set "SYNCDETAILS=%WORK%\RUNTIME_SYNC_DETAILS.txt"
set "GITHUBRESULT=%WORK%\GITHUB_RESULT.txt"
set "AGENT=C:\wr-agent.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "HOSTS=X:\Windows\System32\drivers\etc\hosts"
set "APIHOST=api.github.com"
set "WEBHOST=github.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=2ad5b80f38c85fbe483992ed335d066ebaa4b15b"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"
set "RESOLVER_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/resolve.cmd?ref=%SOURCE_REF%"
set "BOOTSTRAP_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/runtime-sync.cmd?ref=%SOURCE_REF%"
set "AGENT_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/wr-agent.cmd?ref=%SOURCE_REF%"

set "STAGE=START"
set "COMPONENT=next.cmd"
set "FAIL_REASON=Bootstrap did not complete."
set "FAIL_RC=90"
set "COMPONENT_RC="
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
set "RUNTIME_MODULE=None"
set "RUNTIME_COMPONENT_STAGE=None"
set "RUNTIME_COMPONENT_RC=NOT_RUN"
set "AGENT_DOWNLOAD=NOT_STARTED"
set "AGENT_DOWNLOAD_RC=NOT_RUN"
set "AGENT_STAGE=NOT_STARTED"
set "CSCRIPT_AVAILABLE=NO"
set "CSCRIPT_PATH=None"
set "GITHUB_AUTHORIZATION=NOT_REACHED"
set "GITHUB_AUTH_RC=NOT_RUN"
set "GITHUB_AUTH_HTTP=NOT_RUN"
set "GITHUB_AUTH_CURL_RC=NOT_RUN"
set "GITHUB_AUTH_REASON=Not reached."
set "REPORTVOL="

if exist "X:\Windows\System32\cscript.exe" (
  set "CSCRIPT_AVAILABLE=YES"
  set "CSCRIPT_PATH=X:\Windows\System32\cscript.exe"
) else if exist "C:\Windows\System32\cscript.exe" (
  set "CSCRIPT_AVAILABLE=YES"
  set "CSCRIPT_PATH=C:\Windows\System32\cscript.exe"
)

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
call :WRITE_DETAILS
call :WRITE_REPORT RUNNING 0 "AI Recovery diagnostic bootstrap started."

cls
color 07 >nul 2>&1
echo ================================================================
echo AI RECOVERY - DIAGNOSTIC AGENT TRANSITION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo This pass diagnoses the failed 1132 bootstrap and starts pairing.
echo.
echo Disk formatting / cleaning     : NONE
echo Partition / filesystem changes : NONE
echo Windows boot/system repair      : NONE
echo Destructive operations          : NONE
echo ================================================================

if not exist "%WORK%" (
  set "STAGE=PRECHECK"
  set "COMPONENT=C:\WinRERepair"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Could not access or create C:\WinRERepair."
  goto :FAIL
)
if not exist "%RUNTIME%" (
  set "STAGE=PRECHECK"
  set "COMPONENT=C:\WinRERepair\runtime"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Could not access or create the runtime directory."
  goto :FAIL
)
if not exist "%CURL%" (
  set "STAGE=PRECHECK"
  set "COMPONENT=curl.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required Windows curl.exe was not found."
  goto :FAIL
)
if not exist "%FINDSTR%" (
  set "STAGE=PRECHECK"
  set "COMPONENT=findstr.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required Windows findstr.exe was not found."
  goto :FAIL
)
if not exist "%NSLOOKUP%" (
  set "STAGE=PRECHECK"
  set "COMPONENT=nslookup.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Required Windows nslookup.exe was not found."
  goto :FAIL
)
if /i "%CSCRIPT_AVAILABLE%"=="NO" (
  set "STAGE=PRECHECK"
  set "COMPONENT=cscript.exe"
  set "COMPONENT_RC=91"
  set "FAIL_RC=91"
  set "FAIL_REASON=Windows Script Host cscript.exe is unavailable in both WinRE and offline Windows."
  goto :FAIL
)

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
    if "!PING_AFTER_RC!"=="0" (set "NETWORK_STATE=ONLINE") else set "NETWORK_STATE=PARTIAL_OR_ICMP_BLOCKED"
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
  set "FAIL_REASON=Could not download the pinned resolver through the validated GitHub API connection."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: resolve" "%RESOLVER%.tmp" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded lib/resolve.cmd failed module validation."
  goto :FAIL
)
move /y "%RESOLVER%.tmp" "%RESOLVER%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated lib/resolve.cmd could not be staged locally."
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
  set "FAIL_REASON=Could not download the pinned runtime synchronization module."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%.tmp" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded lib/runtime-sync.cmd failed module validation."
  goto :FAIL
)
move /y "%BOOTSTRAP%.tmp" "%BOOTSTRAP%" >nul 2>&1
if errorlevel 1 (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated lib/runtime-sync.cmd could not be staged locally."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=RUNTIME_SYNC"
set "COMPONENT=lib/runtime-sync.cmd"
set "RUNTIME_SYNC=RUNNING"
call :WRITE_DETAILS
call "%BOOTSTRAP%" agent "%SOURCE_REPO%" "%SOURCE_REF%"
set "RUNTIME_SYNC_RC=!errorlevel!"
if not "!RUNTIME_SYNC_RC!"=="0" (
  set "RUNTIME_SYNC=FAIL"
  call :READ_SYNC_DETAILS
  set "COMPONENT=!RUNTIME_MODULE!"
  set "COMPONENT_RC=!RUNTIME_COMPONENT_RC!"
  set "FAIL_RC=!RUNTIME_SYNC_RC!"
  if "!FAIL_RC!"=="" set "FAIL_RC=90"
  set "FAIL_REASON=Runtime synchronization failed at !RUNTIME_MODULE! / !RUNTIME_COMPONENT_STAGE!."
  goto :FAIL
)
set "RUNTIME_SYNC=PASS"
set "RUNTIME_MODULE=ALL"
set "RUNTIME_COMPONENT_STAGE=COMPLETE"
set "RUNTIME_COMPONENT_RC=0"
call :WRITE_DETAILS

set "STAGE=FETCH_AGENT"
set "COMPONENT=wr-agent.cmd"
set "AGENT_DOWNLOAD=RUNNING"
call :WRITE_DETAILS
call :FETCH "%AGENT_URL%" "%AGENT%.tmp"
set "AGENT_DOWNLOAD_RC=!errorlevel!"
if not "!AGENT_DOWNLOAD_RC!"=="0" (
  set "AGENT_DOWNLOAD=FAIL"
  set "COMPONENT_RC=!AGENT_DOWNLOAD_RC!"
  set "FAIL_RC=90"
  set "FAIL_REASON=Could not download the pinned AI Recovery agent."
  goto :FAIL
)
set "AGENT_DOWNLOAD=PASS"
"%FINDSTR%" /i /c:"AI-RECOVERY-AGENT-2026.08.14-1105-ET" "%AGENT%.tmp" >nul 2>&1
if errorlevel 1 (
  set "AGENT_STAGE=FAIL"
  set "COMPONENT_RC=96"
  set "FAIL_RC=96"
  set "FAIL_REASON=Downloaded wr-agent.cmd failed version validation."
  goto :FAIL
)
move /y "%AGENT%.tmp" "%AGENT%" >nul 2>&1
if errorlevel 1 (
  set "AGENT_STAGE=FAIL"
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Validated wr-agent.cmd could not be staged to C:\wr-agent.cmd."
  goto :FAIL
)
set "AGENT_STAGE=PASS"
call :WRITE_DETAILS

set "STAGE=WRITE_CONFIG"
set "COMPONENT=agent.cfg"
>"%CONFIG%" echo CONTROL_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo LOG_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo OAUTH_CLIENT_ID=178c6fc778ccc68e1d6a
>>"%CONFIG%" echo POLL_SECONDS=15
if not exist "%CONFIG%" (
  set "COMPONENT_RC=97"
  set "FAIL_RC=97"
  set "FAIL_REASON=Could not write the local AI Recovery agent configuration."
  goto :FAIL
)
call :WRITE_DETAILS

set "STAGE=GITHUB_AUTHORIZATION"
set "COMPONENT=lib/github-auth.js"
set "GITHUB_AUTHORIZATION=STARTED"
set "GITHUB_AUTH_REASON=Authorization helper started."
call :WRITE_DETAILS
call :WRITE_REPORT RUNNING 0 "Runtime passed. Waiting for one-time GitHub device authorization."
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
if /i "!GITHUB_AUTH_REASON!"=="Not reached." set "GITHUB_AUTH_REASON=Private GitHub authorization completed."
call :WRITE_DETAILS
call :WRITE_REPORT PASS 0 "Private recovery reporting authorization completed; starting persistent agent."
call :USB_COPY

set "STAGE=START_AGENT"
set "COMPONENT=wr-agent.cmd"
call :WRITE_DETAILS
call "%AGENT%"
set "AGENTRC=!errorlevel!"
if "!AGENTRC!"=="0" exit /b 0
set "COMPONENT_RC=!AGENTRC!"
set "FAIL_RC=!AGENTRC!"
set "FAIL_REASON=The persistent agent returned instead of remaining online. Review RUN_DETAILS and the agent result."
goto :FAIL

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
if /i "%RH_HOST%"=="api.github.com" if defined APIIP (
  set "RH_CAND=%APIIP%"
  call :TEST_HOST
  if not errorlevel 1 set "RH_FOUND=!RH_CAND!"
)
if not defined RH_FOUND if defined RH_CACHE if exist "%RH_CACHE%" (
  set "RH_CAND="
  set /p "RH_CAND="<"%RH_CACHE%"
  if defined RH_CAND (
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
  call :TEST_HOST
  if not errorlevel 1 set "RH_FOUND=!RH_CAND!"
)
exit /b 0

:TEST_HOST
if not defined RH_CAND exit /b 1
set "RH_ANY_RESOLVED=YES"
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 8 --max-time 20 --resolve "%RH_HOST%:443:%RH_CAND%" "https://%RH_HOST%/" -o NUL >nul 2>&1
set "RH_LAST_HTTPS_RC=!errorlevel!"
exit /b !RH_LAST_HTTPS_RC!

:STAGE_HOSTS
if not exist "X:\Windows\System32\drivers\etc" exit /b 0
if exist "%HOSTS%" (
  "%FINDSTR%" /v /i /c:"# AI-RECOVERY" "%HOSTS%" >"%WORK%\hosts-clean.tmp" 2>nul
  if exist "%WORK%\hosts-clean.tmp" copy /y "%WORK%\hosts-clean.tmp" "%HOSTS%" >nul 2>&1
)
>>"%HOSTS%" echo %APIIP% api.github.com # AI-RECOVERY
>>"%HOSTS%" echo %WEBIP% github.com # AI-RECOVERY
exit /b 0

:READ_SYNC_DETAILS
if not exist "%SYNCDETAILS%" exit /b 0
for /f "usebackq tokens=1,* delims==" %%A in ("%SYNCDETAILS%") do (
  if /i "%%A"=="component" set "RUNTIME_MODULE=%%B"
  if /i "%%A"=="component_stage" set "RUNTIME_COMPONENT_STAGE=%%B"
  if /i "%%A"=="component_return_code" set "RUNTIME_COMPONENT_RC=%%B"
)
exit /b 0

:READ_GITHUB_RESULT
if not exist "%GITHUBRESULT%" (
  set "GITHUB_AUTH_REASON=Authorization helper returned without GITHUB_RESULT.txt."
  exit /b 0
)
for /f "usebackq tokens=1,* delims==" %%A in ("%GITHUBRESULT%") do (
  if /i "%%A"=="status" set "GITHUB_AUTHORIZATION=%%B"
  if /i "%%A"=="reason" set "GITHUB_AUTH_REASON=%%B"
  if /i "%%A"=="http" set "GITHUB_AUTH_HTTP=%%B"
  if /i "%%A"=="curl_return_code" set "GITHUB_AUTH_CURL_RC=%%B"
)
exit /b 0

:WRITE_REPORT
>"%REPORT%" echo status=%~1
>>"%REPORT%" echo return_code=%~2
>>"%REPORT%" echo command_version=%COMMAND_VERSION%
>>"%REPORT%" echo stage=%STAGE%
>>"%REPORT%" echo component=%COMPONENT%
>>"%REPORT%" echo date=%date%
>>"%REPORT%" echo time=%time%
>>"%REPORT%" echo message=%~3
exit /b 0

:WRITE_DETAILS
>"%DETAILS%" echo build=%COMMAND_VERSION%
>>"%DETAILS%" echo stage=%STAGE%
>>"%DETAILS%" echo component=%COMPONENT%
>>"%DETAILS%" echo component_return_code=%COMPONENT_RC%
>>"%DETAILS%" echo network_state=%NETWORK_STATE%
>>"%DETAILS%" echo ping_before_rc=%PING_BEFORE_RC%
>>"%DETAILS%" echo wpeutil_rc=%WPEUTIL_RC%
>>"%DETAILS%" echo ping_after_rc=%PING_AFTER_RC%
>>"%DETAILS%" echo api_github_resolved=%API_RESOLVED%
>>"%DETAILS%" echo api_github_ip=%APIIP%
>>"%DETAILS%" echo api_github_https=%API_HTTPS%
>>"%DETAILS%" echo api_github_https_rc=%API_HTTPS_RC%
>>"%DETAILS%" echo github_com_resolved=%WEB_RESOLVED%
>>"%DETAILS%" echo github_com_ip=%WEBIP%
>>"%DETAILS%" echo github_com_https=%WEB_HTTPS%
>>"%DETAILS%" echo github_com_https_rc=%WEB_HTTPS_RC%
>>"%DETAILS%" echo runtime_sync=%RUNTIME_SYNC%
>>"%DETAILS%" echo runtime_sync_rc=%RUNTIME_SYNC_RC%
>>"%DETAILS%" echo runtime_module=%RUNTIME_MODULE%
>>"%DETAILS%" echo runtime_component_stage=%RUNTIME_COMPONENT_STAGE%
>>"%DETAILS%" echo runtime_component_rc=%RUNTIME_COMPONENT_RC%
>>"%DETAILS%" echo agent_download=%AGENT_DOWNLOAD%
>>"%DETAILS%" echo agent_download_rc=%AGENT_DOWNLOAD_RC%
>>"%DETAILS%" echo agent_stage=%AGENT_STAGE%
>>"%DETAILS%" echo cscript_available=%CSCRIPT_AVAILABLE%
>>"%DETAILS%" echo cscript_path=%CSCRIPT_PATH%
>>"%DETAILS%" echo github_authorization=%GITHUB_AUTHORIZATION%
>>"%DETAILS%" echo github_authorization_rc=%GITHUB_AUTH_RC%
>>"%DETAILS%" echo github_authorization_http=%GITHUB_AUTH_HTTP%
>>"%DETAILS%" echo github_authorization_curl_rc=%GITHUB_AUTH_CURL_RC%
>>"%DETAILS%" echo github_authorization_reason=%GITHUB_AUTH_REASON%
>>"%DETAILS%" echo reason=%FAIL_REASON%
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
if defined REPORTVOL (
  if not exist "!REPORTVOL!\RecoverySource" md "!REPORTVOL!\RecoverySource" >nul 2>&1
  copy /y "%REPORT%" "!REPORTVOL!\RecoverySource\LAST_RUN_REPORT.txt" >nul 2>&1
  copy /y "%DETAILS%" "!REPORTVOL!\RecoverySource\RUN_DETAILS.txt" >nul 2>&1
)
exit /b 0

:FAIL
call :WRITE_DETAILS
call :WRITE_REPORT FAIL "%FAIL_RC%" "%FAIL_REASON%"
call :USB_COPY
set "EVIDENCE_REQ=Screenshot this exact screen."
if /i "%GITHUB_AUTHORIZATION%"=="PASS" set "EVIDENCE_REQ=None"
cls
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] AI RECOVERY BOOTSTRAP
echo ================================================================
echo Version              : %COMMAND_VERSION%
echo Stage                : !STAGE!
echo Component            : !COMPONENT!
echo Return code          : !COMPONENT_RC!
echo Transition exit code : !FAIL_RC!
echo ---------------------------------------------------------------
echo Network state        : !NETWORK_STATE!
echo api.github.com DNS   : !API_RESOLVED!
echo api.github.com HTTPS : !API_HTTPS! ^(rc !API_HTTPS_RC!^)
echo github.com DNS       : !WEB_RESOLVED!
echo github.com HTTPS     : !WEB_HTTPS! ^(rc !WEB_HTTPS_RC!^)
echo Runtime sync         : !RUNTIME_SYNC! ^(rc !RUNTIME_SYNC_RC!^)
echo Runtime module       : !RUNTIME_MODULE! / !RUNTIME_COMPONENT_STAGE! / rc !RUNTIME_COMPONENT_RC!
echo Agent download/stage : !AGENT_DOWNLOAD! / !AGENT_STAGE! / rc !AGENT_DOWNLOAD_RC!
echo cscript              : !CSCRIPT_AVAILABLE! - !CSCRIPT_PATH!
echo GitHub authorization : !GITHUB_AUTHORIZATION! ^(rc !GITHUB_AUTH_RC!, HTTP !GITHUB_AUTH_HTTP!, curl !GITHUB_AUTH_CURL_RC!^)
echo ---------------------------------------------------------------
echo Reason:
echo   !FAIL_REASON!
echo.
echo Local details:
echo   C:\WinRERepair\RUN_DETAILS.txt
echo   C:\WinRERepair\LAST_RUN_REPORT.txt
if defined REPORTVOL echo USB copy: !REPORTVOL!\RecoverySource\RUN_DETAILS.txt
echo ---------------------------------------------------------------
echo WHAT YOU SHOULD DO:
echo   Reply: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   !EVIDENCE_REQ!
echo ================================================================
exit /b !FAIL_RC!
