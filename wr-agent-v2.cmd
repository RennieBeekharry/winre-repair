@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: agent-v2 2026.08.14-1508-ET
rem RescueMeAI persistent agent with operator-visible continuity controls.

set "AGENT_VERSION=RMAI-AGENT-V2-2026.08.14-1508-ET"
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
set "STATEFILE=%WORK%\AGENT_STATE.txt"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CHOICE=X:\Windows\System32\choice.exe"
if not exist "%CHOICE%" set "CHOICE=C:\Windows\System32\choice.exe"
if not exist "%CHOICE%" set "CHOICE="
set "DNS=64.71.255.204"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF="
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%AGENTDIR%" md "%AGENTDIR%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1

if not exist "%CURL%" exit /b 91
if not exist "%CERTUTIL%" exit /b 91
if not exist "%CSCRIPT%" exit /b 91
if not exist "%FINDSTR%" exit /b 91
if not exist "%BOOTSTRAP%" exit /b 91
if not exist "%CONFIG%" exit /b 91

for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG%") do (
  if /i "%%A"=="SOURCE_REPO" set "SOURCE_REPO=%%B"
  if /i "%%A"=="SOURCE_REF" set "SOURCE_REF=%%B"
)
if not defined SOURCE_REPO exit /b 93
if not defined SOURCE_REF exit /b 93

call "%BOOTSTRAP%" agent "%SOURCE_REPO%" "%SOURCE_REF%"
if errorlevel 1 exit /b 91

set "UI=%RUNTIME%\ui.cmd"
set "REPORTING=%RUNTIME%\reporting.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"
set "SAFETY=%RUNTIME%\safety.cmd"
set "CORE=%RUNTIME%\agent-core.js"
set "NETWORK=%RUNTIME%\network.cmd"
for %%F in ("%UI%" "%REPORTING%" "%AUTH%" "%SAFETY%" "%CORE%" "%NETWORK%") do if not exist %%F exit /b 91

if not exist "%AGENTIDFILE%" >"%AGENTIDFILE%" echo AIWR-%RANDOM%%RANDOM%%RANDOM%
set "AGENT_ID="
set /p "AGENT_ID="<"%AGENTIDFILE%"
if not defined AGENT_ID exit /b 93

set "QUEUE_INCIDENT_ACTIVE=0"
set "CHANNEL_INCIDENT_ACTIVE=0"
set "WAIT_BANNER_SHOWN=0"
set /a QUEUE_WARNINGS=0

rem Preserve crash evidence without replaying the interrupted command.
if exist "%INFLIGHT%" (
  set "OLD_INFLIGHT="
  set /p "OLD_INFLIGHT="<"%INFLIGHT%"
  if defined OLD_INFLIGHT (
    >"%INTERRUPTED%" echo !OLD_INFLIGHT!
    >"%LAST%" echo !OLD_INFLIGHT!
    del /f /q "%INFLIGHT%" >nul 2>&1
    call :REPORT WARNING 40 "A previous queued command was interrupted and was NOT replayed." "Interrupted command ID !OLD_INFLIGHT! requires AI review before any dependent action." "Reply warning. RescueMeAI remains online and waiting for a reviewed next command."
  )
)

:ESTABLISH_CHANNEL
call "%NETWORK%" ensure
if errorlevel 1 (
  call :SHOW_SESSION_WARNING "Internet connectivity is unavailable. RescueMeAI is healthy and will keep retrying."
  call :WAIT_LOCAL_STOP
  if errorlevel 2 goto :USER_STOP
  goto :ESTABLISH_CHANNEL
)
call "%AUTH%" authorize "%CONFIG%"
if errorlevel 1 (
  call :SHOW_SESSION_WARNING "Private recovery-channel authorization is unavailable. RescueMeAI is healthy and will keep retrying."
  call :WAIT_LOCAL_STOP
  if errorlevel 2 goto :USER_STOP
  goto :ESTABLISH_CHANNEL
)

call :REPORT PASS 0 "RescueMeAI persistent agent is online and listening for validated commands." "None." "No action is required. Leave this window open; press S while WAITING to stop safely."
call :SHOW_WAITING

:LOOP
if exist "%PENDING%" del /f /q "%PENDING%" >nul 2>&1
"%CSCRIPT%" //nologo "%CORE%" poll "%CURL%" "%WORK%" "%CONFIG%" "%TOKEN%" "%AGENT_ID%" "%PENDING%" "%NSLOOKUP%" "%DNS%" >nul 2>&1
set "POLLRC=!errorlevel!"

if "!POLLRC!"=="10" (
  set /a QUEUE_WARNINGS=0
  set "QUEUE_INCIDENT_ACTIVE=0"
  set "CHANNEL_INCIDENT_ACTIVE=0"
  goto :WAIT
)

if "!POLLRC!"=="40" (
  set /a QUEUE_WARNINGS+=1
  if !QUEUE_WARNINGS! GEQ 3 if "!CHANNEL_INCIDENT_ACTIVE!"=="0" (
    set "CHANNEL_INCIDENT_ACTIVE=1"
    call :REPORT WARNING 40 "The private command channel is temporarily unavailable." "No command is being executed. RescueMeAI will retry with backoff." "Reply warning only if you want ChatGPT to review the connection immediately."
    call :SHOW_SESSION_WARNING "The private command channel is temporarily unavailable. No command is running; RescueMeAI is retrying."
  )
  goto :WAIT
)

if !POLLRC! GEQ 80 goto :QUEUE_QUARANTINE
if not exist "%PENDING%" goto :QUEUE_QUARANTINE

set /a QUEUE_WARNINGS=0
set "QUEUE_INCIDENT_ACTIVE=0"
set "CHANNEL_INCIDENT_ACTIVE=0"
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
if not defined WR_CMD_ID goto :QUEUE_QUARANTINE
if not defined WR_CMD_ACTION goto :QUEUE_QUARANTINE

>"%INFLIGHT%" echo %WR_CMD_ID%
call :SHOW_RUNNING

if /i "%WR_CMD_ACTION%"=="PING" (
  call :COMPLETE PASS 0 "RescueMeAI command channel responded successfully." "None." "No action is required. RescueMeAI remains online."
  goto :WAIT
)
if /i "%WR_CMD_ACTION%"=="STOP_AGENT" (
  call :COMPLETE PASS 0 "RescueMeAI agent stopped by an authenticated control command." "None." "The listener is stopping cleanly."
  exit /b 0
)
if /i not "%WR_CMD_ACTION%"=="RUN_NEXT" goto :QUEUE_QUARANTINE

set "CMDFILE=%AGENTDIR%\command-%WR_CMD_ID%.cmd"
set "CMDURL=https://api.github.com/repos/%WR_CMD_REPO%/contents/%WR_CMD_PATH%?ref=%WR_CMD_REF%"
call "%NETWORK%" fetch "%CMDURL%" "%CMDFILE%"
if errorlevel 1 (
  call :COMPLETE FAIL 90 "The immutable recovery command could not be downloaded." "No command was executed." "Reply fail. RescueMeAI remains online for the corrected next command."
  goto :WAIT
)

"%CERTUTIL%" -hashfile "%CMDFILE%" SHA256 >"%AGENTDIR%\command-hash.txt" 2>&1
"%FINDSTR%" /i /c:"%WR_CMD_SHA256%" "%AGENTDIR%\command-hash.txt" >nul 2>&1
if errorlevel 1 (
  call :COMPLETE FAIL 96 "Recovery command integrity verification failed." "The command was NOT executed." "Reply fail. RescueMeAI remains online for a corrected immutable command."
  goto :WAIT
)

call "%SAFETY%" evaluate "%CMDFILE%" "%WR_CMD_RISK%" "%WR_CMD_ID%" "%WR_CMD_TARGET%" "%AGENT_ID%"
set "SAFERC=!errorlevel!"
if "!SAFERC!"=="40" (
  call :COMPLETE WARNING 40 "A destructive command was blocked because local authorization was not provided." "Nothing destructive was executed." "Reply warning. RescueMeAI remains online."
  goto :WAIT
)
if !SAFERC! GEQ 80 (
  call :COMPLETE FAIL !SAFERC! "The local safety gate rejected the queued command." "Nothing was executed." "Reply fail. RescueMeAI remains online."
  goto :WAIT
)

if exist "%RESULTENV%" del /f /q "%RESULTENV%" >nul 2>&1
call "%CMDFILE%"
set "CMDRC=!errorlevel!"
set "FINAL_STATUS=WARNING"
set "FINAL_MESSAGE=Recovery command completed with a condition that needs review."
set "FINAL_EVIDENCE=None unless RescueMeAI requests additional evidence."
set "FINAL_INSTRUCTION=Reply warning. RescueMeAI remains online."
if "!CMDRC!"=="0" (
  set "FINAL_STATUS=PASS"
  set "FINAL_MESSAGE=Recovery command completed successfully."
  set "FINAL_INSTRUCTION=Reply pass. RescueMeAI remains online."
) else if !CMDRC! GEQ 80 (
  set "FINAL_STATUS=FAIL"
  set "FINAL_MESSAGE=Recovery command stopped because a required step failed."
  set "FINAL_INSTRUCTION=Reply fail. RescueMeAI remains online."
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
  set "FINAL_EVIDENCE=The invalid result was quarantined; no automatic retry occurred."
  set "FINAL_INSTRUCTION=Reply fail. RescueMeAI remains online."
  set "CMDRC=97"
)
call :COMPLETE "!FINAL_STATUS!" !CMDRC! "!FINAL_MESSAGE!" "!FINAL_EVIDENCE!" "!FINAL_INSTRUCTION!"
goto :WAIT

:QUEUE_QUARANTINE
set "QUEUE_REASON=Authenticated queue validation failed."
if exist "%STATEFILE%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%STATEFILE%") do if /i "%%A"=="reason" set "QUEUE_REASON=%%B"
)
if "!QUEUE_INCIDENT_ACTIVE!"=="0" (
  set "QUEUE_INCIDENT_ACTIVE=1"
  call :REPORT WARNING 40 "The current private command was quarantined and NOT executed." "Queue reason: !QUEUE_REASON!" "Reply warning only if requested. RescueMeAI remains online waiting for a corrected command."
  call :SHOW_SESSION_WARNING "The current private command failed validation and was quarantined. Nothing was executed. RescueMeAI is waiting for a corrected command."
)
goto :WAIT

:COMPLETE
set "DONE_STATUS=%~1"
set "DONE_RC=%~2"
set "DONE_MESSAGE=%~3"
set "DONE_EVIDENCE=%~4"
set "DONE_INSTRUCTION=%~5"
>"%LAST%" echo %WR_CMD_ID%
del /f /q "%INFLIGHT%" >nul 2>&1
call :REPORT "%DONE_STATUS%" "%DONE_RC%" "%DONE_MESSAGE%" "%DONE_EVIDENCE%" "%DONE_INSTRUCTION%"
call "%UI%" result "%DONE_STATUS%" "%DONE_MESSAGE%" "%DONE_EVIDENCE%" "%DONE_INSTRUCTION%" "%AGENT_VERSION%" "CONNECTED"
echo.
echo [ONLINE] RescueMeAI is still running and will wait for the next validated command.
echo          Press S while WAITING to stop safely.
set "WAIT_BANNER_SHOWN=1"
exit /b 0

:REPORT
set "REP_STATUS=%~1"
set "REP_RC=%~2"
set "REP_MESSAGE=%~3"
set "REP_EVIDENCE=%~4"
set "REP_INSTRUCTION=%~5"
call "%REPORTING%" write "%REP_STATUS%" "%REP_RC%" "%AGENT_VERSION%" "%REP_MESSAGE%" "%REP_EVIDENCE%" "%REP_INSTRUCTION%"
>"%DETAILS%" echo product=RescueMeAI
>>"%DETAILS%" echo runtime_class=PERSISTENT_AGENT
>>"%DETAILS%" echo agent_version=%AGENT_VERSION%
>>"%DETAILS%" echo agent_id=%AGENT_ID%
>>"%DETAILS%" echo status=%REP_STATUS%
>>"%DETAILS%" echo return_code=%REP_RC%
>>"%DETAILS%" echo message=%REP_MESSAGE%
if defined WR_CMD_ID >>"%DETAILS%" echo command_id=%WR_CMD_ID%
if defined WR_CMD_ACTION >>"%DETAILS%" echo command_action=%WR_CMD_ACTION%
if defined QUEUE_REASON >>"%DETAILS%" echo queue_reason=%QUEUE_REASON%
call "%REPORTING%" usbcopy >nul 2>&1
call "%AUTH%" upload "%CONFIG%" >nul 2>&1
exit /b 0

:SHOW_WAITING
call "%UI%" screen "%AGENT_VERSION%" "CONNECTED" "ONLINE / WAITING FOR NEXT COMMAND" "VALIDATED COMMANDS ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo Agent ID : %AGENT_ID%
echo Status   : ONLINE
echo.
echo RescueMeAI will continue automatically when a validated command arrives.
echo Press S while this screen is WAITING to stop RescueMeAI safely.
echo Active repair commands are not interrupted mid-write; stop control resumes at the next safe boundary.
set "WAIT_BANNER_SHOWN=1"
exit /b 0

:SHOW_RUNNING
call "%UI%" screen "%AGENT_VERSION%" "CONNECTED" "RUNNING COMMAND %WR_CMD_ID%" "%WR_CMD_RISK%" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
echo.
echo Command ID : %WR_CMD_ID%
echo Action     : %WR_CMD_ACTION%
echo Risk       : %WR_CMD_RISK%
echo.
echo RescueMeAI is executing this validated command.
echo Local stop is deferred until the next safe waiting boundary so an active write is not interrupted halfway.
set "WAIT_BANNER_SHOWN=0"
exit /b 0

:SHOW_SESSION_WARNING
set "WARN_TEXT=%~1"
call "%UI%" screen "%AGENT_VERSION%" "CONNECTED" "WARNING / RETRYING" "NO UNVALIDATED ACTION" "AI-ASSISTED WINDOWS RECOVERY" "WARNING"
echo.
echo %WARN_TEXT%
echo.
echo RescueMeAI remains running. Press S while WAITING to stop safely.
set "WAIT_BANNER_SHOWN=1"
exit /b 0

:WAIT
if "!WAIT_BANNER_SHOWN!"=="0" call :SHOW_WAITING
call :WAIT_LOCAL_STOP
if errorlevel 2 goto :USER_STOP
goto :LOOP

:WAIT_LOCAL_STOP
if defined CHOICE (
  "%CHOICE%" /C XS /N /T 15 /D X >nul 2>&1
  set "KEYRC=!errorlevel!"
  if "!KEYRC!"=="2" exit /b 2
  exit /b 0
)
if exist "%PING%" "%PING%" -n 16 127.0.0.1 >nul 2>&1
exit /b 0

:USER_STOP
call :REPORT PASS 0 "RescueMeAI was stopped safely by the local user while waiting." "No recovery command was interrupted." "The listener is stopping and control will return to the startup wrapper."
exit /b 0
