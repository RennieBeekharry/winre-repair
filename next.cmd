@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Install and start the AI Recovery command agent and private reporting channel.
rem WR_ACTION=INSTALL_AI_RECOVERY_AGENT
rem WR_TARGET=Recovery tooling under C:\WinRERepair and C:\wr-agent.cmd only.
rem WR_CONSEQUENCE=Creates or updates recovery-agent files and session configuration. It does not alter Windows boot files, partitions, or personal data.
rem WR_ROLLBACK=The agent files can be removed later; this transition does not reverse earlier recovery actions.

set "COMMAND_VERSION=WR-2026.08.14-1112-ET"
set "BUILD_TIME=2026-08-14 11:12 ET"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=5defac98ebb0485c5c59d99b8f92db1587c787a4"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "BOOTSTRAP_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/runtime-sync.cmd?ref=%SOURCE_REF%"
set "AGENT_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/wr-agent.cmd?ref=%SOURCE_REF%"

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
echo During first-time setup the terminal will display a short GitHub
echo one-time code. Open the displayed site on your phone and enter it.
echo No long token needs to be typed into WinRE.
echo ================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%CURL%" goto :FAIL
if not exist "%FINDSTR%" goto :FAIL
if not exist "%NSLOOKUP%" goto :FAIL

if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)
call :RESOLVE

call :FETCH "%BOOTSTRAP_URL%" "%BOOTSTRAP%.tmp"
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%.tmp" >nul 2>&1
if errorlevel 1 goto :FAIL
move /y "%BOOTSTRAP%.tmp" "%BOOTSTRAP%" >nul

call "%BOOTSTRAP%" agent "%SOURCE_REPO%" main
if errorlevel 1 goto :FAIL

call :FETCH "%AGENT_URL%" "%AGENT%.tmp"
if errorlevel 1 goto :FAIL
"%FINDSTR%" /i /c:"AI-RECOVERY-AGENT-2026.08.14-1105-ET" "%AGENT%.tmp" >nul 2>&1
if errorlevel 1 goto :FAIL
move /y "%AGENT%.tmp" "%AGENT%" >nul

rem Current development-session backend. No credential is stored here.
rem Public AI Recovery will obtain these settings through first-time pairing.
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
echo Control   : private authenticated GitHub queue
echo Reporting : private authenticated GitHub reports
echo.
echo WHAT YOU SHOULD DO:
echo   Follow the one-time pairing instructions that appear next.
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None unless the pairing screen reports a failure.
echo ================================================================
echo.

call "%AGENT%"
exit /b %errorlevel%

:FETCH
set "FETCH_URL=%~1"
set "FETCH_OUT=%~2"
if exist "%FETCH_OUT%" del /f /q "%FETCH_OUT%" >nul 2>&1
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:%APIIP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCH_URL%" -o "%FETCH_OUT%"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%FETCH_URL%" -o "%FETCH_OUT%"
)
if errorlevel 1 exit /b 1
if not exist "%FETCH_OUT%" exit /b 1
for %%Z in ("%FETCH_OUT%") do if %%~zZ LSS 32 exit /b 1
exit /b 0

:RESOLVE
set "APIIP="
set "CAND="
for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "APIIP=!CAND!"
)
exit /b 0

:FAIL
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] AI RECOVERY AGENT TRANSITION FAILED
echo ================================================================
echo Nothing destructive was attempted.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to AI Recovery with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   None unless AI Recovery asks for a screenshot/paste of this screen.
echo ================================================================
exit /b 90
