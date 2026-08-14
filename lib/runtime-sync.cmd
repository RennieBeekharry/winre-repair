@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: runtime-sync 2026.08.14-1165-ET

set "MODE=%~1"
set "REPO=%~2"
set "REF=%~3"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "LEGAL=%WORK%\legal"
set "DETAILS=%WORK%\RUNTIME_SYNC_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "APIHOST=api.github.com"
set "BASE=https://%APIHOST%/repos/%REPO%/contents"
set "RESOLVER=%RUNTIME%\resolve.cmd"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%LEGAL%" md "%LEGAL%" >nul 2>&1
>"%DETAILS%" echo status=STARTING
>>"%DETAILS%" echo module=runtime-sync
>>"%DETAILS%" echo component=
>>"%DETAILS%" echo component_stage=PRECHECK
>>"%DETAILS%" echo component_return_code=
>>"%DETAILS%" echo reason=RescueMeAI runtime synchronization starting.

if not defined REPO (
  call :FAIL "runtime-sync" "PRECHECK" "93" "Repository argument is missing."
  exit /b 93
)
if not defined REF set "REF=main"
if not exist "%CURL%" (
  call :FAIL "curl.exe" "PRECHECK" "91" "Required curl.exe is missing."
  exit /b 91
)
if not exist "%FINDSTR%" (
  call :FAIL "findstr.exe" "PRECHECK" "91" "Required findstr.exe is missing."
  exit /b 91
)
if not exist "%RESOLVER%" (
  call :FAIL "lib/resolve.cmd" "PRECHECK" "91" "The staged resolver is missing."
  exit /b 91
)

if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

call "%RESOLVER%" resolve "%APIHOST%" APIIP
set "RSRC=!errorlevel!"
if not "!RSRC!"=="0" (
  call :FAIL "lib/resolve.cmd" "RESOLVE_API_GITHUB" "!RSRC!" "Resolver could not provide a validated HTTPS address for api.github.com."
  exit /b !RSRC!
)
if not defined APIIP (
  call :FAIL "lib/resolve.cmd" "RESOLVE_API_GITHUB" "92" "Resolver returned success without an api.github.com address."
  exit /b 92
)

call :SYNC_RUNTIME "lib/resolve.cmd" "resolve.cmd" "WR-MODULE: resolve"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/ui.cmd" "ui.cmd" "WR-MODULE: ui"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/network.cmd" "network.cmd" "WR-MODULE: network"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/reporting.cmd" "reporting.cmd" "WR-MODULE: reporting"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/github-auth.cmd" "github-auth.cmd" "WR-MODULE: github-auth"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/safety.cmd" "safety.cmd" "WR-MODULE: safety"
if errorlevel 1 exit /b 90
call :SYNC_RUNTIME "lib/acceptance.cmd" "acceptance.cmd" "WR-MODULE: acceptance"
if errorlevel 1 exit /b 90

call :SYNC_LEGAL "TERMS_OF_USE.md"
if errorlevel 1 exit /b 90
call :SYNC_LEGAL "PRIVACY_POLICY.md"
if errorlevel 1 exit /b 90
call :SYNC_LEGAL "DISCLAIMER_AND_RISK_NOTICE.md"
if errorlevel 1 exit /b 90
call :SYNC_LEGAL "LICENSE.md"
if errorlevel 1 exit /b 90
call :SYNC_LEGAL "TRADEMARKS.md"
if errorlevel 1 exit /b 90

rem Legacy JScript agent components remain available only for the old agent
rem mode. Pairing/reporting no longer depends on Windows Script Host.
if /i "%MODE%"=="agent" (
  call :SYNC_RUNTIME "lib/github-auth.js" "github-auth.js" "WR-MODULE: github-auth-js"
  if errorlevel 1 exit /b 90
  call :SYNC_RUNTIME "lib/agent-core.js" "agent-core.js" "WR-MODULE: agent-core-js"
  if errorlevel 1 exit /b 90
)

>"%DETAILS%" echo status=PASS
>>"%DETAILS%" echo module=runtime-sync
>>"%DETAILS%" echo component=ALL
>>"%DETAILS%" echo component_stage=COMPLETE
>>"%DETAILS%" echo component_return_code=0
>>"%DETAILS%" echo api_ip=%APIIP%
>>"%DETAILS%" echo reason=Required RescueMeAI runtime and legal files synchronized and validated.
exit /b 0

:SYNC_RUNTIME
set "SRC=%~1"
set "DEST=%RUNTIME%\%~2"
set "MARK=%~3"
call :SYNC_FILE "%SRC%" "%DEST%" "%MARK%" "runtime module"
exit /b %errorlevel%

:SYNC_LEGAL
set "SRC=%~1"
set "DEST=%LEGAL%\%~1"
call :SYNC_FILE "%SRC%" "%DEST%" "RescueMeAI" "legal document"
exit /b %errorlevel%

:SYNC_FILE
set "SRC=%~1"
set "DEST=%~2"
set "MARK=%~3"
set "KIND=%~4"
set "TMP=%DEST%.tmp"
set "CURLRC="
>"%DETAILS%" echo status=RUNNING
>>"%DETAILS%" echo module=runtime-sync
>>"%DETAILS%" echo component=%SRC%
>>"%DETAILS%" echo component_stage=DOWNLOAD
>>"%DETAILS%" echo component_return_code=
>>"%DETAILS%" echo api_ip=%APIIP%
>>"%DETAILS%" echo reason=Downloading pinned %KIND%.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%BASE%/%SRC%?ref=%REF%" -o "%TMP%"
set "CURLRC=!errorlevel!"
if not "!CURLRC!"=="0" (
  call :FAIL "%SRC%" "DOWNLOAD" "!CURLRC!" "curl failed while downloading the pinned %KIND%."
  exit /b 1
)
if not exist "%TMP%" (
  call :FAIL "%SRC%" "DOWNLOAD" "90" "curl returned success but the %KIND% file was not created."
  exit /b 1
)
for %%Z in ("%TMP%") do if %%~zZ LSS 32 (
  del /f /q "%TMP%" >nul 2>&1
  call :FAIL "%SRC%" "VALIDATE" "96" "Downloaded %KIND% was unexpectedly small."
  exit /b 1
)
"%FINDSTR%" /i /c:"%MARK%" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  call :FAIL "%SRC%" "VALIDATE" "96" "Downloaded %KIND% failed marker validation."
  exit /b 1
)
move /y "%TMP%" "%DEST%" >nul 2>&1
if errorlevel 1 (
  call :FAIL "%SRC%" "STAGE" "97" "Validated %KIND% could not be staged locally."
  exit /b 1
)
exit /b 0

:FAIL
>"%DETAILS%" echo status=FAIL
>>"%DETAILS%" echo module=runtime-sync
>>"%DETAILS%" echo component=%~1
>>"%DETAILS%" echo component_stage=%~2
>>"%DETAILS%" echo component_return_code=%~3
if defined APIIP >>"%DETAILS%" echo api_ip=%APIIP%
>>"%DETAILS%" echo reason=%~4
exit /b 0
