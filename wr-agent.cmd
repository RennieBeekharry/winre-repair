@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "AGENT_VERSION=AI-RECOVERY-AGENT-2026.08.14-1105-ET"
set "WORK=C:\WinRERepair"
set "AGENTDIR=%WORK%\agent"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "AGENTIDFILE=%AGENTDIR%\agent-id.txt"
set "PENDING=%AGENTDIR%\pending.env"
set "INFLIGHT=%AGENTDIR%\inflight-command-id.txt"
set "INTERRUPTED=%AGENTDIR%\interrupted-command-id.txt"
set "LAST=%AGENTDIR%\last-command-id.txt"
set "RESULTENV=%WORK%\COMMAND_RESULT.env"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "PING=X:\Windows\System32\ping.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=main"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "BOOTSTRAP_URL=https://%APIHOST%/repos/%SOURCE_REPO%/contents/lib/runtime-sync.cmd?ref=%SOURCE_REF%"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AGENTDIR%" md "%AGENTDIR%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1
if not exist "%CURL%" goto :BOOTFAIL
if not exist "%CERTUTIL%" goto :BOOTFAIL
if not exist "%CSCRIPT%" goto :BOOTFAIL
if not exist "%FINDSTR%" goto :BOOTFAIL

if exist "%PING%" (
  "%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
  if errorlevel 1 if exist "%WPEUTIL%" "%WPEUTIL%" InitializeNetwork >nul 2>&1
)

rem Prefer the locally staged modular bootstrap. This avoids unnecessary
rem dependency on a fresh GitHub fetch after every WinRE restart.
if exist "%BOOTSTRAP%" (
  "%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%" >nul 2>&1
  if not errorlevel 1 goto :HAVE_BOOTSTRAP
)
call :FETCH_BOOTSTRAP
if errorlevel 1 goto :BOOTFAIL

:HAVE_BOOTSTRAP
call "%BOOTSTRAP%" agent "%SOURCE_REPO%" "%SOURCE_REF%"
if errorlevel 1 goto :BOOTFAIL

set "UI=%RUNTIME%\ui.cmd"
set "REPORTING=%RUNTIME%\reporting.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"
set "SAFETY=%RUNTIME%\safety.cmd"
set "CORE=%RUNTIME%\agent-core.js"
set "NETWORK=%RUNTIME%\network.cmd"

if not exist "%CONFIG%" (
  call "%UI%" result FAIL "AI Recovery agent configuration is missing." "None. AI Recovery can rebuild the configuration." "Reply fail."
  exit /b 90
)

rem Persistent random agent ID identifies this recovery session, not the user.
if not exist "%AGENTIDFILE%" >"%AGENTIDFILE%" echo AIWR-%RANDOM%%RANDOM%%RANDOM%
set "AGENT_ID="
set /p "AGENT_ID="<"%AGENTIDFILE%"
if not defined AGENT_ID goto :BOOTFAIL

rem Crash/restart protection: a command journaled as in-flight is never rerun.
rem Preserve the interruption, advance the handled ID, then clear the lock.
if exist "%INFLIGHT%" (
  set "OLD_INFLIGHT="
  set /p "OLD_INFLIGHT="<"%INFLIGHT%"
  if defined OLD_INFLIGHT (
    >"%INTERRUPTED%" echo !OLD_INFLIGHT!
    >"%LAST%" echo !OLD_INFLIGHT!
    del /f /q "%INFLIGHT%" >nul 2>&1
    call "%REPORTING%" write WARNING 40 "%AGENT_VERSION%" "A previous queued command was interrupted and was NOT rerun automatically." "None unless AI Recovery requests the interrupted-command evidence." "Reply warning. AI Recovery must review the interrupted state before issuing a higher command ID."
    call "%REPORTING%" usbcopy >nul 2>&1
    call "%AUTH%" upload "%CONFIG%" >nul 2>&1
    call "%UI%" result WARNING "A previous queued command was interrupted and was NOT rerun automatically." "None unless AI Recovery requests the interrupted-command evidence." "Reply warning. AI Recovery must review the interrupted state before issuing a higher command ID."
    exit /b 40
  )
  del /f /q "%INFLIGHT%" >nul 2>&1
)

call "%UI%" header "AI RECOVERY AGENT" "%AGENT_VERSION%" "Secure validated command channel"
echo Agent ID : %AGENT_ID%
echo Mode     : STARTING
echo.
echo Routine approved recovery actions can run automatically.
echo Destructive actions require explicit LOCAL authorization on this PC.
echo Remote AI/backend instructions cannot bypass that local approval.
echo ================================================================

call "%NETWORK%" ensure
if errorlevel 1 (
  call "%UI%" result FAIL "Internet connectivity could not be established." "Check the Ethernet/network connection. A screenshot is useful only if requested." "Reply fail."
  exit /b 92
)

rem Establish private reporting/control authorization if not already valid.
call "%AUTH%" authorize "%CONFIG%"
if errorlevel 1 (
  call "%UI%" result FAIL "Private recovery-channel authorization was not completed." "Follow the authorization reason shown above. Screenshot it only if the reason is unclear." "Reply fail."
  exit /b 90
)

call "%REPORTING%" write PASS 0 "%AGENT_VERSION%" "AI Recovery agent is online and listening for validated commands." "None." "Reply pass. You may then give AI Recovery your next instruction."
call "%REPORTING%" usbcopy >nul 2>&1
call "%AUTH%" upload "%CONFIG%" >nul 2>&1
call "%UI%" result PASS "AI Recovery agent is online and listening for validated commands." "None." "Reply pass. You may then give AI Recovery your next instruction."
echo.
echo Agent remains running. Do not close this window while you want automatic recovery control.

set /a QUEUE_WARNINGS=0

:LOOP
if exist "%PENDING%" del /f /q "%PENDING%" >nul 2>&1
"%CSCRIPT%" //nologo "%CORE%" poll "%CURL%" "%WORK%" "%CONFIG%" "%TOKEN%" "%AGENT_ID%" "%PENDING%" "%NSLOOKUP%" "%DNS%" >nul 2>&1
set "POLLRC=!errorlevel!"
if "!POLLRC!"=="10" (
  set /a QUEUE_WARNINGS=0
  goto :WAIT
)
if "!POLLRC!"=="40" (
  set /a QUEUE_WARNINGS+=1
  if !QUEUE_WARNINGS! GEQ 5 (
    call "%REPORTING%" write WARNING 40 "%AGENT_VERSION%" "The command channel is temporarily unavailable; the agent is still retrying." "No screenshot is required unless this warning persists." "Reply warning if you want AI Recovery to investigate the connection now."
    call "%REPORTING%" usbcopy >nul 2>&1
    call "%UI%" result WARNING "The command channel is temporarily unavailable; the agent is still retrying." "No screenshot is required unless this warning persists." "Reply warning if you want AI Recovery to investigate the connection now."
    set /a QUEUE_WARNINGS=0
  )
  goto :WAIT
)
if !POLLRC! GEQ 80 goto :QUEUEFAIL
if not exist "%PENDING%" goto :QUEUEFAIL
set /a QUEUE_WARNINGS=0

set "WR_CMD_ID="
set "WR_CMD_ACTION="
set "WR_CMD_TARGET="
set "WR_CMD_RISK="
set "WR_CMD_REPO="
set "WR_CMD_PATH="
set "WR_CMD_REF="
set "WR_CMD_SHA256="
for /f "usebackq tokens=1,* delims==" %%A in ("%PENDING%") do (
  if /i "%%A"=="WR_CMD_ID" set "WR_CMD_ID=%%B"
  if /i "%%A"=="WR_CMD_ACTION" set "WR_CMD_ACTION=%%B"
  if /i "%%A"=="WR_CMD_TARGET" set "WR_CMD_TARGET=%%B"
  if /i "%%A"=="WR_CMD_RISK" set "WR_CMD_RISK=%%B"
  if /i "%%A"=="WR_CMD_REPO" set "WR_CMD_REPO=%%B"
  if /i "%%A"=="WR_CMD_PATH" set "WR_CMD_PATH=%%B"
  if /i "%%A"=="WR_CMD_REF" set "WR_CMD_REF=%%B"
  if /i "%%A"=="WR_CMD_SHA256" set "WR_CMD_SHA256=%%B"
)
if not defined WR_CMD_ID goto :QUEUEFAIL
if not defined WR_CMD_ACTION goto :QUEUEFAIL

rem Journal BEFORE any action. A crash cannot cause silent replay.
>"%INFLIGHT%" echo %WR_CMD_ID%

if /i "%WR_CMD_ACTION%"=="PING" (
  call :COMPLETE PASS 0 "AI Recovery command channel responded successfully." "None." "Reply pass."
  goto :WAIT
)
if /i "%WR_CMD_ACTION%"=="STOP_AGENT" (
  call :COMPLETE PASS 0 "AI Recovery agent stopped by an authenticated control command." "None." "Reply pass. Start C:\wr-agent.cmd again when you want automatic recovery control."
  exit /b 0
)
if /i not "%WR_CMD_ACTION%"=="RUN_NEXT" goto :QUEUEFAIL

set "CMDFILE=%AGENTDIR%\command-%WR_CMD_ID%.cmd"
set "CMDURL=https://api.github.com/repos/%WR_CMD_REPO%/contents/%WR_CMD_PATH%?ref=%WR_CMD_REF%"
call "%NETWORK%" fetch "%CMDURL%" "%CMDFILE%"
if errorlevel 1 (
  call :COMPLETE FAIL 90 "The immutable recovery command could not be downloaded." "No screenshot is needed unless AI Recovery asks for one." "Reply fail."
  goto :WAIT
)

"%CERTUTIL%" -hashfile "%CMDFILE%" SHA256 >"%AGENTDIR%\command-hash.txt" 2>&1
"%FINDSTR%" /i /c:"%WR_CMD_SHA256%" "%AGENTDIR%\command-hash.txt" >nul 2>&1
if errorlevel 1 (
  call :COMPLETE FAIL 96 "Recovery command integrity verification failed. The command was NOT executed." "No additional information is required; the private report contains the expected command metadata." "Reply fail."
  goto :WAIT
)

call "%SAFETY%" evaluate "%CMDFILE%" "%WR_CMD_RISK%" "%WR_CMD_ID%" "%WR_CMD_TARGET%" "%AGENT_ID%"
set "SAFERC=!errorlevel!"
if "!SAFERC!"=="40" (
  call :COMPLETE WARNING 40 "A destructive command was blocked because local authorization was not provided." "None unless you want AI Recovery to reconsider the proposed destructive step." "Reply warning. Nothing destructive was executed."
  goto :WAIT
)
if !SAFERC! GEQ 80 (
  call :COMPLETE FAIL !SAFERC! "The local safety gate rejected the queued command. Nothing was executed." "No screenshot is required unless AI Recovery requests it." "Reply fail."
  goto :WAIT
)

if exist "%RESULTENV%" del /f /q "%RESULTENV%" >nul 2>&1
call "%CMDFILE%"
set "CMDRC=!errorlevel!"
set "FINAL_STATUS=WARNING"
set "FINAL_MESSAGE=Recovery command completed with a condition that needs review."
set "FINAL_EVIDENCE=None unless AI Recovery requests additional evidence."
set "FINAL_INSTRUCTION=Reply warning."
if "!CMDRC!"=="0" (
  set "FINAL_STATUS=PASS"
  set "FINAL_MESSAGE=Recovery command completed successfully."
  set "FINAL_INSTRUCTION=Reply pass."
) else if !CMDRC! GEQ 80 (
  set "FINAL_STATUS=FAIL"
  set "FINAL_MESSAGE=Recovery command stopped because a required step failed."
  set "FINAL_INSTRUCTION=Reply fail."
)

if exist "%RESULTENV%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%RESULTENV%") do (
    if /i "%%A"=="STATUS" set "FINAL_STATUS=%%B"
    if /i "%%A"=="MESSAGE" set "FINAL_MESSAGE=%%B"
    if /i "%%A"=="EVIDENCE" set "FINAL_EVIDENCE=%%B"
    if /i "%%A"=="INSTRUCTION" set "FINAL_INSTRUCTION=%%B"
  )
)
if /i not "!FINAL_STATUS!"=="PASS" if /i not "!FINAL_STATUS!"=="FAIL" if /i not "!FINAL_STATUS!"=="WARNING" (
  set "FINAL_STATUS=FAIL"
  set "FINAL_MESSAGE=Recovery command returned an invalid result status."
  set "FINAL_EVIDENCE=No additional information is required; the private report should be reviewed."
  set "FINAL_INSTRUCTION=Reply fail."
  set "CMDRC=97"
)
call :COMPLETE "!FINAL_STATUS!" !CMDRC! "!FINAL_MESSAGE!" "!FINAL_EVIDENCE!" "!FINAL_INSTRUCTION!"
goto :WAIT

:COMPLETE
set "DONE_STATUS=%~1"
set "DONE_RC=%~2"
set "DONE_MESSAGE=%~3"
set "DONE_EVIDENCE=%~4"
set "DONE_INSTRUCTION=%~5"
>"%LAST%" echo %WR_CMD_ID%
del /f /q "%INFLIGHT%" >nul 2>&1
call "%REPORTING%" write "%DONE_STATUS%" "%DONE_RC%" "%AGENT_VERSION%" "%DONE_MESSAGE%" "%DONE_EVIDENCE%" "%DONE_INSTRUCTION%"
call "%REPORTING%" usbcopy >nul 2>&1
call "%AUTH%" upload "%CONFIG%" >nul 2>&1
set "UPLOAD_RC=!errorlevel!"
if not "!UPLOAD_RC!"=="0" (
  if /i "%DONE_STATUS%"=="PASS" set "DONE_STATUS=WARNING"
  set "DONE_EVIDENCE=Please paste or screenshot this result because the private report upload failed."
  set "DONE_INSTRUCTION=Reply warning so AI Recovery can restore the reporting channel."
)
call "%UI%" result "%DONE_STATUS%" "%DONE_MESSAGE%" "%DONE_EVIDENCE%" "%DONE_INSTRUCTION%"
exit /b 0

:QUEUEFAIL
call "%REPORTING%" write FAIL 94 "%AGENT_VERSION%" "The authenticated command queue failed validation. No queued command was executed." "No screenshot is required unless AI Recovery asks for the queue validation details." "Reply fail. The agent stopped fail-closed."
call "%REPORTING%" usbcopy >nul 2>&1
call "%AUTH%" upload "%CONFIG%" >nul 2>&1
call "%UI%" result FAIL "The authenticated command queue failed validation. No queued command was executed." "No screenshot is required unless AI Recovery asks for the queue validation details." "Reply fail. The agent stopped fail-closed."
exit /b 94

:WAIT
if exist "%PING%" "%PING%" -n 16 127.0.0.1 >nul 2>&1
goto :LOOP

:FETCH_BOOTSTRAP
set "APIIP="
set "CAND="
if exist "%NSLOOKUP%" (
  for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
    for %%T in (%%L) do set "CAND=%%T"
    if not "!CAND!"=="%DNS%" set "APIIP=!CAND!"
  )
)
if exist "%BOOTSTRAP%.tmp" del /f /q "%BOOTSTRAP%.tmp" >nul 2>&1
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%BOOTSTRAP_URL%" -o "%BOOTSTRAP%.tmp"
) else (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%BOOTSTRAP_URL%" -o "%BOOTSTRAP%.tmp"
)
if errorlevel 1 exit /b 1
"%FINDSTR%" /i /c:"WR-MODULE: runtime-sync" "%BOOTSTRAP%.tmp" >nul 2>&1
if errorlevel 1 exit /b 1
move /y "%BOOTSTRAP%.tmp" "%BOOTSTRAP%" >nul
exit /b 0

:BOOTFAIL
color 0C >nul 2>&1
echo ================================================================
echo [FAIL] AI RECOVERY AGENT COULD NOT START
echo ================================================================
echo A required runtime/network component could not be loaded.
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to AI Recovery with exactly: fail
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   Paste or screenshot this message only if AI Recovery asks for it.
echo ================================================================
exit /b 91
