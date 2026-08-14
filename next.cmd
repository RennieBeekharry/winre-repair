@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install and start the AI Recovery command agent and private reporting channel.
rem WR_ACTION=INSTALL_AI_RECOVERY_AGENT
rem WR_TARGET=Recovery tooling under C:\WinRERepair and C:\wr-agent.cmd only.
rem WR_CONSEQUENCE=Creates or updates recovery-agent files and temporary WinRE network mappings. It does not alter Windows boot files, partitions, or personal data.
rem WR_ROLLBACK=Agent files can be removed later; temporary X: network mappings disappear when WinRE restarts.

set "COMMAND_VERSION=WR-2026.08.14-1132-ET"
set "BUILD_TIME=2026-08-14 11:32 ET"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
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
set "SOURCE_REF=a093558afc9bc7eec065d91548475d317e7c7717"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "RESOLVER_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/resolve.cmd?ref=%SOURCE_REF%"
set "BOOTSTRAP_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/runtime-sync.cmd?ref=%SOURCE_REF%"
set "AGENT_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/wr-agent.cmd?ref=%SOURCE_REF%"
set "FAIL_REASON=Agent transition failed before a specific reason was recorded."
set "STAGE=START"

cls
color 07 >nul 2>&1
echo ================================================================
echo AI RECOVERY - AGENT TRANSITION
echo Version: %COMMAND_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================
echo This pass installs/starts the persistent AI Recovery agent.
echo.
echo Disk formatting / cleaning     : NONE
echo Partition operations           : NONE
echo Windows boot/system repair      : NONE
echo Destructive operations          : NONE
echo.
echo Network bootstrap:
echo   - validate any working launcher GitHub address
echo   - try multiple DNS resolvers if needed
echo   - cache validated GitHub addresses for this recovery session
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%WORK%" (
  set "FAIL_REASON=Could not access or create C:\WinRERepair."
  goto :FAIL
)
if not exist "%RUNTIME%" (
  set "FAIL_REASON=Could not access or create the recovery runtime directory."
  goto :FAIL
)
if not exist "%CURL%" (
  set "FAIL_REASON=Required Windows curl.exe was not found."
  goto :FAIL
)
if not exist "%FINDSTR%" (
  set "FAIL_REASON=Required Windows findstr.exe was not found."
  goto :FAIL
)
if not exist "%NSLOOKUP%" (
  set "FAIL_REASON=Required Windows nslookup.exe was not found."
  goto :FAIL
)

if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

set "STAGE=RESOLVE_API_GITHUB"
call :RESOLVE_HOST "%APIHOST%" APIIP
if errorlevel 1 (
  set "FAIL_REASON=Could not obtain a validated HTTPS address for api.github.com after trying cached/inherited data and multiple DNS resolvers."
  goto :FAIL
)
>"%WORK%\github-api-ip.txt" echo(%APIIP%

set "STAGE=RESOLVE_GITHUB_WEB"
call :RESOLVE_HOST "%WEBHOST%" WEBIP
if errorlevel 1 (
  set "FAIL_REASON=Could not obtain a validated HTTPS address for github.com, which is required for one-time device authorization."
  goto :FAIL
)
>"%WORK%\github-web-ip.txt" echo(%WEBIP%
call :STAGE_HOSTS

set "STAGE=FETCH_RESOLVER"
call :FETCH "%RESOLVER_URL%" "%RESOLVER%.tmp"
if errorlevel 1 (
  set "FAIL_REASON=Could not download the pinned resilient resolver through the validated GitHub API connection."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: resolve" "%RESOLVER%.tmp" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=Downloaded resolver failed module validation."
  goto :FAIL
)
move /y "%RESOLVER%.tmp" "%RESOLVER%" >nul
if errorlevel 1 (
  set "FAIL_REASON=Could not stage the resilient resolver locally."
  goto :FAIL
)

set "STAGE=FETCH_RUNTIME"
call :FETCH "%BOOTSTRAP_URL%" "%BOOTSTRAP%.tmp"
if errorlevel 1 (
  set "FAIL_REASON=Could not download the pinned modular runtime through the validated GitHub connection."
  goto :FAIL
)
"%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%.tmp" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=Downloaded runtime bootstrap failed validation."
  goto :FAIL
)
move /y "%BOOTSTRAP%.tmp" "%BOOTSTRAP%" >nul
if errorlevel 1 (
  set "FAIL_REASON=Could not stage the validated runtime bootstrap locally."
  goto :FAIL
)

set "STAGE=SYNC_MODULES"
call "%BOOTSTRAP%" agent "%SOURCE_REPO%" "%SOURCE_REF%"
if errorlevel 1 (
  set "FAIL_REASON=One or more pinned AI Recovery runtime modules could not be synchronized or validated."
  goto :FAIL
)

set "STAGE=FETCH_AGENT"
call :FETCH "%AGENT_URL%" "%AGENT%.tmp"
if errorlevel 1 (
  set "FAIL_REASON=Could not download the pinned AI Recovery agent."
  goto :FAIL
)
"%FINDSTR%" /i /c:"AI-RECOVERY-AGENT-2026.08.14-1105-ET" "%AGENT%.tmp" >nul 2>&1
if errorlevel 1 (
  set "FAIL_REASON=Downloaded AI Recovery agent failed version validation."
  goto :FAIL
)
move /y "%AGENT%.tmp" "%AGENT%" >nul
if errorlevel 1 (
  set "FAIL_REASON=Could not stage C:\wr-agent.cmd locally."
  goto :FAIL
)

set "STAGE=WRITE_CONFIG"
>"%CONFIG%" echo CONTROL_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo LOG_REPO=RennieBeekharry/winre-repair-logs
>>"%CONFIG%" echo OAUTH_CLIENT_ID=178c6fc778ccc68e1d6a
>>"%CONFIG%" echo POLL_SECONDS=15

cls
color 0A >nul 2>&1
echo ================================================================
echo [PASS] AI RECOVERY AGENT INSTALLED
echo ================================================================
echo Agent     : %AGENT%
echo Runtime   : %RUNTIME%
echo GitHub API: %APIIP% [validated/cached]
echo GitHub Web: %WEBIP% [validated/cached]
echo.
echo WHAT YOU SHOULD DO:
echo   Follow the short one-time GitHub pairing instructions that appear next.
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None unless the pairing screen explicitly requests it.
echo ================================================================
echo.

set "STAGE=START_AGENT"
call "%AGENT%"
exit /b %errorlevel%

:FETCH
set "FETCH_URL=%~1"
set "FETCH_OUT=%~2"
if exist "%FETCH_OUT%" del /f /q "%FETCH_OUT%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCH_URL%" -o "%FETCH_OUT%"
if errorlevel 1 exit /b 1
if not exist "%FETCH_OUT%" exit /b 1
for %%Z in ("%FETCH_OUT%") do if %%~zZ LSS 32 exit /b 1
exit /b 0

:RESOLVE_HOST
set "RH_HOST=%~1"
set "RH_RET=%~2"
set "RH_FOUND="
set "RH_CAND="
set "RH_CACHE="
if /i "%RH_HOST%"=="api.github.com" set "RH_CACHE=%WORK%\github-api-ip.txt"
if /i "%RH_HOST%"=="github.com" set "RH_CACHE=%WORK%\github-web-ip.txt"

if /i "%RH_HOST%"=="api.github.com" if defined APIIP (
  set "RH_CAND=%APIIP%"
  call :TEST_HOST
  if not errorlevel 1 set "RH_FOUND=%RH_CAND%"
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
if not defined RH_FOUND exit /b 1
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
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 8 --max-time 20 --resolve "%RH_HOST%:443:%RH_CAND%" "https://%RH_HOST%/" -o NUL >nul 2>&1
exit /b %errorlevel%

:STAGE_HOSTS
if not exist "X:\Windows\System32\drivers\etc" exit /b 0
if exist "%HOSTS%" (
  "%FINDSTR%" /v /i /c:"# AI-RECOVERY" "%HOSTS%" >"%WORK%\hosts-clean.tmp" 2>nul
  if exist "%WORK%\hosts-clean.tmp" copy /y "%WORK%\hosts-clean.tmp" "%HOSTS%" >nul 2>&1
)
>>"%HOSTS%" echo %APIIP% api.github.com # AI-RECOVERY
>>"%HOSTS%" echo %WEBIP% github.com # AI-RECOVERY
exit /b 0

:FAIL
>"%DETAILS%" echo stage=!STAGE!
>>"%DETAILS%" echo reason=!FAIL_REASON!
>>"%DETAILS%" echo build=%COMMAND_VERSION%
>>"%DETAILS%" echo api_ip=!APIIP!
>>"%DETAILS%" echo github_web_ip=!WEBIP!
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] AI RECOVERY AGENT TRANSITION FAILED
echo ================================================================
echo Stage : !STAGE!
echo Reason:
echo   !FAIL_REASON!
echo.
echo Nothing destructive was attempted.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to AI Recovery with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None unless AI Recovery explicitly asks for a screenshot/paste.
echo ================================================================
exit /b 90
