@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: device-agent 2026.09.09-v1
rem Outbound-only RescueMeAI GitHub control agent for an isolated recovery device.
rem It accepts only PING, STOP_AGENT, and hashed RUN_NEXT envelopes parsed by agent-core.js.

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "AGENTDIR=%WORK%\agent"
set "PENDING=%AGENTDIR%\pending.env"
set "INFLIGHT=%AGENTDIR%\inflight-command-id.txt"
set "LAST=%AGENTDIR%\last-command-id.txt"
set "RESULTENV=%WORK%\COMMAND_RESULT.env"
set "CORE=%RUNTIME%\agent-core.js"
set "SAFETY=%RUNTIME%\safety.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "DNS=64.71.255.204"

for %%D in ("%WORK%" "%RUNTIME%" "%AGENTDIR%" "%WORK%\.auth") do if not exist %%D md %%D >nul 2>&1
for %%F in ("%CONFIG%" "%TOKEN%" "%CORE%" "%SAFETY%" "%CURL%" "%CERTUTIL%" "%CSCRIPT%") do if not exist %%F exit /b 91

set "AGENT_ID="
set "SESSION_ID="
set "LOG_REPO="
set "CONTROL_PATH="
set "REPORT_PREFIX="
for /f "usebackq tokens=1,* delims==" %%A in ("%CONFIG%") do (
  if /i "%%A"=="AGENT_ID" set "AGENT_ID=%%B"
  if /i "%%A"=="SESSION_ID" set "SESSION_ID=%%B"
  if /i "%%A"=="LOG_REPO" set "LOG_REPO=%%B"
  if /i "%%A"=="CONTROL_PATH" set "CONTROL_PATH=%%B"
  if /i "%%A"=="REPORT_PREFIX" set "REPORT_PREFIX=%%B"
)
if not defined AGENT_ID exit /b 93
if not defined SESSION_ID exit /b 93
if not defined LOG_REPO exit /b 93
if not defined CONTROL_PATH exit /b 93
if not defined REPORT_PREFIX exit /b 93

call :REPORT PASS 0 "RescueMeAI device agent is online and listening for validated commands." "None."
cls
color 0A >nul 2>&1
echo ================================================================
echo RescueMeAI secure support channel is ONLINE
echo ================================================================
echo Session : %SESSION_ID%
echo Agent   : %AGENT_ID%
echo Mode    : OUTBOUND GITHUB POLLING
echo Safety  : LOCAL GATE ACTIVE
echo.
echo Leave this window open. ChatGPT can now exchange validated
echo recovery commands and bounded results through the private channel.
echo No inbound remote shell is open.
echo ================================================================

:LOOP
if exist "%PENDING%" del /f /q "%PENDING%" >nul 2>&1
"%CSCRIPT%" //nologo "%CORE%" poll "%CURL%" "%WORK%" "%CONFIG%" "%TOKEN%" "%AGENT_ID%" "%PENDING%" "%NSLOOKUP%" "%DNS%" >nul 2>&1
set "POLLRC=!errorlevel!"
if "!POLLRC!"=="10" goto :WAIT
if "!POLLRC!"=="40" goto :WAIT
if !POLLRC! GEQ 80 (
  call :REPORT FAIL !POLLRC! "The private command queue failed validation. No command was executed." "Review the control channel."
  goto :WAIT
)
if not exist "%PENDING%" goto :WAIT

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
if not defined WR_CMD_ID goto :WAIT
if not defined WR_CMD_ACTION goto :WAIT
>"%INFLIGHT%" echo %WR_CMD_ID%

if /i "%WR_CMD_ACTION%"=="PING" (
  >"%LAST%" echo %WR_CMD_ID%
  del /f /q "%INFLIGHT%" >nul 2>&1
  call :REPORT PASS 0 "RescueMeAI command channel responded successfully." "None."
  goto :WAIT
)
if /i "%WR_CMD_ACTION%"=="STOP_AGENT" (
  >"%LAST%" echo %WR_CMD_ID%
  del /f /q "%INFLIGHT%" >nul 2>&1
  call :REPORT PASS 0 "RescueMeAI agent stopped by an authenticated control command." "None."
  exit /b 0
)
if /i not "%WR_CMD_ACTION%"=="RUN_NEXT" (
  call :REPORT FAIL 94 "A non-allowlisted command action was rejected." "Nothing executed."
  goto :COMPLETE_WAIT
)

set "CMDFILE=%AGENTDIR%\command-%WR_CMD_ID%.cmd"
set "CMDHTTP=%AGENTDIR%\command-%WR_CMD_ID%-http.txt"
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
"%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 15 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%WR_CMD_REPO%/contents/%WR_CMD_PATH%?ref=%WR_CMD_REF%" -o "%CMDFILE%" -w "%%{http_code}" >"%CMDHTTP%" 2>"%AGENTDIR%\command-curl.txt"
set "FETCHRC=!errorlevel!"
set "ACCESS="
if not "!FETCHRC!"=="0" (
  call :REPORT FAIL 90 "The immutable recovery command could not be downloaded." "No command executed."
  goto :COMPLETE_WAIT
)

"%CERTUTIL%" -hashfile "%CMDFILE%" SHA256 >"%AGENTDIR%\command-hash.txt" 2>&1
findstr /i /c:"%WR_CMD_SHA256%" "%AGENTDIR%\command-hash.txt" >nul 2>&1
if errorlevel 1 (
  call :REPORT FAIL 96 "Recovery command integrity verification failed." "The downloaded command was not executed."
  goto :COMPLETE_WAIT
)

call "%SAFETY%" evaluate "%CMDFILE%" "%WR_CMD_RISK%" "%WR_CMD_ID%" "%WR_CMD_TARGET%" "%AGENT_ID%"
set "SAFERC=!errorlevel!"
if "!SAFERC!"=="40" (
  call :REPORT WARNING 40 "A destructive command was blocked because local authorization was not provided." "Nothing destructive executed."
  goto :COMPLETE_WAIT
)
if !SAFERC! GEQ 80 (
  call :REPORT FAIL !SAFERC! "The local safety gate rejected the queued command." "Nothing executed."
  goto :COMPLETE_WAIT
)

if exist "%RESULTENV%" del /f /q "%RESULTENV%" >nul 2>&1
call "%CMDFILE%"
set "CMDRC=!errorlevel!"
set "FINAL_STATUS=WARNING"
set "FINAL_MESSAGE=Recovery command completed with a condition requiring review."
set "FINAL_EVIDENCE=None unless specifically requested."
if "!CMDRC!"=="0" (
  set "FINAL_STATUS=PASS"
  set "FINAL_MESSAGE=Recovery command completed successfully."
)
if !CMDRC! GEQ 80 (
  set "FINAL_STATUS=FAIL"
  set "FINAL_MESSAGE=Recovery command stopped because a required step failed."
)
if exist "%RESULTENV%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%RESULTENV%") do (
    if /i "%%A"=="STATUS" set "FINAL_STATUS=%%B"
    if /i "%%A"=="MESSAGE" set "FINAL_MESSAGE=%%B"
    if /i "%%A"=="EVIDENCE" set "FINAL_EVIDENCE=%%B"
  )
)
call :REPORT "!FINAL_STATUS!" !CMDRC! "!FINAL_MESSAGE!" "!FINAL_EVIDENCE!"

:COMPLETE_WAIT
>"%LAST%" echo %WR_CMD_ID%
del /f /q "%INFLIGHT%" >nul 2>&1

:WAIT
"%PING%" -n 11 127.0.0.1 >nul 2>&1
goto :LOOP

:REPORT
set "R_STATUS=%~1"
set "R_RC=%~2"
set "R_MESSAGE=%~3"
set "R_EVIDENCE=%~4"
set "RFILE=%WORK%\LAST_RUN_REPORT.txt"
>"%RFILE%" echo status=%R_STATUS%
>>"%RFILE%" echo return_code=%R_RC%
>>"%RFILE%" echo session_id=%SESSION_ID%
>>"%RFILE%" echo agent_id=%AGENT_ID%
>>"%RFILE%" echo command_id=%WR_CMD_ID%
>>"%RFILE%" echo date=%date%
>>"%RFILE%" echo time=%time%
>>"%RFILE%" echo message=%R_MESSAGE%
>>"%RFILE%" echo evidence=%R_EVIDENCE%
call :UPLOAD "%RFILE%"
exit /b 0

:UPLOAD
set "UPFILE=%~1"
set "B64=%WORK%\report.b64"
set "BODY=%WORK%\report.json"
set "HTTP=%WORK%\report-http.txt"
if exist "%B64%" del /f /q "%B64%" >nul 2>&1
"%CERTUTIL%" -encode "%UPFILE%" "%B64%" >nul 2>&1
if errorlevel 1 exit /b 1
set "ENC="
for /f "usebackq delims=" %%L in ("%B64%") do (
  echo(%%L| findstr /b /c:"-----" >nul 2>&1
  if errorlevel 1 set "ENC=!ENC!%%L"
)
set "RPATH=%REPORT_PREFIX%/run-%AGENT_ID%-%RANDOM%%RANDOM%.txt"
>"%BODY%" echo {"message":"RescueMeAI bounded recovery report","content":"!ENC!"}
set "ENC="
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Content-Type: application/json" --data-binary "@%BODY%" "https://api.github.com/repos/%LOG_REPO%/contents/!RPATH!" -o "%WORK%\report-response.json" -w "%%{http_code}" >"%HTTP%" 2>"%WORK%\report-curl.txt"
set "UPRC=!errorlevel!"
set "ACCESS="
exit /b !UPRC!
