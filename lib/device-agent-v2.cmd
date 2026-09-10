@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: device-agent-v2 2026.09.10-v1
rem Pure-CMD outbound-only RescueMeAI agent for WinRE environments where
rem cscript/PowerShell cannot be relied upon. No inbound remote shell is opened.

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "AGENTDIR=%WORK%\agent"
set "PENDING=%AGENTDIR%\pending.env"
set "INFLIGHT=%AGENTDIR%\inflight-command-id.txt"
set "LAST=%AGENTDIR%\last-command-id.txt"
set "RESULTENV=%WORK%\COMMAND_RESULT.env"
set "SAFETY=%RUNTIME%\safety.cmd"
set "CURL=C:\Windows\System32\curl.exe"
set "CERTUTIL=C:\Windows\System32\certutil.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "PING=X:\Windows\System32\ping.exe"
if not exist "%PING%" set "PING=C:\Windows\System32\ping.exe"
set "SOURCE_REPO=RennieBeekharry/winre-repair"

for %%D in ("%WORK%" "%RUNTIME%" "%AGENTDIR%" "%WORK%\.auth") do if not exist %%D md %%D >nul 2>&1
for %%F in ("%CONFIG%" "%TOKEN%" "%SAFETY%" "%CURL%" "%CERTUTIL%" "%FINDSTR%") do if not exist %%F exit /b 91

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

set "WR_CMD_ID="
call :REPORT PASS 0 "RescueMeAI pure-CMD device agent is online and listening for validated commands." "None."
cls
color 0A >nul 2>&1
echo ================================================================
echo RescueMeAI secure support channel is ONLINE
echo ================================================================
echo Session : %SESSION_ID%
echo Agent   : %AGENT_ID%
echo Mode    : OUTBOUND GITHUB POLLING / PURE CMD
echo Safety  : LOCAL GATE ACTIVE
echo.
echo Leave this window open. No inbound remote shell is open.
echo ================================================================

:LOOP
call :POLL
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
if /i not "%WR_CMD_REPO%"=="%SOURCE_REPO%" (
  call :REPORT FAIL 94 "RUN_NEXT referenced a repository outside the RescueMeAI source allow-list." "Nothing executed."
  goto :COMPLETE_WAIT
)
if /i not "%WR_CMD_PATH:~0,9%"=="commands/" (
  call :REPORT FAIL 94 "RUN_NEXT referenced a path outside commands/." "Nothing executed."
  goto :COMPLETE_WAIT
)
call :HEX_LENGTH "%WR_CMD_REF%" 40
if errorlevel 1 (
  call :REPORT FAIL 93 "RUN_NEXT commit ref failed validation." "Nothing executed."
  goto :COMPLETE_WAIT
)
call :HEX_LENGTH "%WR_CMD_SHA256%" 64
if errorlevel 1 (
  call :REPORT FAIL 93 "RUN_NEXT SHA-256 failed validation." "Nothing executed."
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
"%FINDSTR%" /i /c:"%WR_CMD_SHA256%" "%AGENTDIR%\command-hash.txt" >nul 2>&1
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
if exist "%WORK%\RUN_DETAILS.txt" del /f /q "%WORK%\RUN_DETAILS.txt" >nul 2>&1
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

:POLL
if exist "%PENDING%" del /f /q "%PENDING%" >nul 2>&1
set "QUEUE=%AGENTDIR%\queue.json"
set "QHTTP=%AGENTDIR%\queue-http.txt"
set "ACCESS="
set /p "ACCESS="<"%TOKEN%"
"%CURL%" --ssl-no-revoke --silent --show-error --connect-timeout 15 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !ACCESS!" -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/repos/%LOG_REPO%/contents/%CONTROL_PATH%?ref=main" -o "%QUEUE%" -w "%%{http_code}" >"%QHTTP%" 2>"%AGENTDIR%\queue-curl.txt"
set "QRC=!errorlevel!"
set "ACCESS="
if not "!QRC!"=="0" exit /b 40
set "QCODE="
if exist "%QHTTP%" set /p "QCODE="<"%QHTTP%"
if not "!QCODE!"=="200" exit /b 40

set "CMD_PROTOCOL="
set "CMD_ID="
set "CMD_ACTION="
set "CMD_TARGET="
set "CMD_RISK="
set "CMD_REPO="
set "CMD_PATH="
set "CMD_REF="
set "CMD_SHA="
for /f "usebackq tokens=1,* delims=:" %%A in ("%QUEUE%") do (
  set "K=%%A"
  set "V=%%B"
  set "K=!K:"=!"
  set "K=!K: =!"
  set "V=!V:"=!"
  set "V=!V:,=!"
  set "V=!V: =!"
  if /i "!K!"=="protocol" set "CMD_PROTOCOL=!V!"
  if /i "!K!"=="command_id" set "CMD_ID=!V!"
  if /i "!K!"=="action" set "CMD_ACTION=!V!"
  if /i "!K!"=="target_agent" set "CMD_TARGET=!V!"
  if /i "!K!"=="risk" set "CMD_RISK=!V!"
  if /i "!K!"=="repo" set "CMD_REPO=!V!"
  if /i "!K!"=="path" set "CMD_PATH=!V!"
  if /i "!K!"=="ref" set "CMD_REF=!V!"
  if /i "!K!"=="sha256" set "CMD_SHA=!V!"
)
if not "!CMD_PROTOCOL!"=="1" exit /b 93
if not defined CMD_ID exit /b 93
echo(!CMD_ID!| "%FINDSTR%" /r /x "[0-9][0-9]*" >nul 2>&1
if errorlevel 1 exit /b 93
call :STRLEN "!CMD_ID!" IDLEN
if !IDLEN! GTR 9 exit /b 93
if /i not "!CMD_ACTION!"=="PING" if /i not "!CMD_ACTION!"=="STOP_AGENT" if /i not "!CMD_ACTION!"=="RUN_NEXT" exit /b 94
if /i not "!CMD_TARGET!"=="*" if /i not "!CMD_TARGET!"=="%AGENT_ID%" exit /b 10
if /i not "!CMD_RISK!"=="READ_ONLY" if /i not "!CMD_RISK!"=="REPAIR_WRITE" if /i not "!CMD_RISK!"=="DESTRUCTIVE" exit /b 93
set "LAST_ID=0"
if exist "%LAST%" set /p "LAST_ID="<"%LAST%"
if not defined LAST_ID set "LAST_ID=0"
set /a CIDN=CMD_ID+0 >nul 2>&1
set /a LIDN=LAST_ID+0 >nul 2>&1
if !CIDN! LEQ !LIDN! exit /b 10

>"%PENDING%" echo WR_CMD_ID=!CMD_ID!
>>"%PENDING%" echo WR_CMD_ACTION=!CMD_ACTION!
>>"%PENDING%" echo WR_CMD_TARGET=!CMD_TARGET!
>>"%PENDING%" echo WR_CMD_RISK=!CMD_RISK!
if /i "!CMD_ACTION!"=="RUN_NEXT" (
  if not defined CMD_REPO exit /b 93
  if not defined CMD_PATH exit /b 93
  if not defined CMD_REF exit /b 93
  if not defined CMD_SHA exit /b 93
  >>"%PENDING%" echo WR_CMD_REPO=!CMD_REPO!
  >>"%PENDING%" echo WR_CMD_PATH=!CMD_PATH!
  >>"%PENDING%" echo WR_CMD_REF=!CMD_REF!
  >>"%PENDING%" echo WR_CMD_SHA256=!CMD_SHA!
)
exit /b 0

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
if exist "%WORK%\RUN_DETAILS.txt" (
  for %%Z in ("%WORK%\RUN_DETAILS.txt") do set "DSIZE=%%~zZ"
  if !DSIZE! LEQ 6000 (
    >>"%RFILE%" echo.
    >>"%RFILE%" echo --- BOUNDED RUN DETAILS ---
    type "%WORK%\RUN_DETAILS.txt" >>"%RFILE%"
  ) else (
    >>"%RFILE%" echo details_status=LOCAL_DETAILS_TOO_LARGE_TO_UPLOAD
  )
)
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
  echo(%%L| "%FINDSTR%" /b /c:"-----" >nul 2>&1
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

:HEX_LENGTH
set "HX=%~1"
set "NEED=%~2"
call :STRLEN "%HX%" HLEN
if not "%HLEN%"=="%NEED%" exit /b 1
echo(%HX%| "%FINDSTR%" /r /x "[0-9A-Fa-f][0-9A-Fa-f]*" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:STRLEN
set "S=%~1"
set /a N=0
:SL
if not "!S:~%N%,1!"=="" (
  set /a N+=1
  if !N! LSS 256 goto :SL
)
set "%~2=%N%"
exit /b 0
