@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Resume the paired RescueMeAI agent after validating both GitHub endpoints and refreshing authorization.
rem WR_ACTION=START_RESCUEMEAI_AGENT_LOCAL_RUNTIME
rem WR_TARGET=RescueMeAI runtime bootstrap and private command channel only.
rem WR_CONSEQUENCE=Refreshes RescueMeAI authorization and resumes the recovery agent. It does not modify Windows recovery state.
rem WR_ROLLBACK=Stop RescueMeAI safely while waiting and return to Command Prompt.

set "COMMAND_VERSION=RMAI-2026.08.14-AGENT-START-10"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "AUTH=%RUNTIME%\github-auth.cmd"
set "RESOLVE=%RUNTIME%\resolve.cmd"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=b31b1a0f5231063b2dbf5ae34156eadcc64a65e6"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "MODE=C:\Windows\System32\mode.com"
if not exist "%MODE%" set "MODE=mode"
set "FAIL_RC=91"
set "FAIL_REASON=RescueMeAI could not resume the saved recovery session."
set "APIIP="
set "WEBIP="
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"

title RescueMeAI - Windows Recovery
"%MODE%" con: cols=100 lines=50 >nul 2>&1
if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1

call :SHOW_ACTIVITY "Checking local recovery runtime" "Reusing the validated modules already staged on this PC."
if not exist "%AGENT%" (
  set "FAIL_REASON=Persistent RescueMeAI agent is missing."
  goto :APP_FATAL
)
for %%F in (ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js) do (
  if not exist "%RUNTIME%\%%F" (
    set "FAIL_REASON=Required staged runtime module %%F is missing."
    goto :APP_FATAL
  )
)

call :SHOW_ACTIVITY "Preparing local bootstrap" "Using the already-staged runtime without another bootstrap download."
>"%BOOTSTRAP%" echo @echo off
>>"%BOOTSTRAP%" echo setlocal EnableExtensions
>>"%BOOTSTRAP%" echo rem WR-MODULE: runtime-local-ready 2026.08.14-1555-ET
>>"%BOOTSTRAP%" echo set "RUNTIME=C:\WinRERepair\runtime"
>>"%BOOTSTRAP%" echo for %%%%F in ^(ui.cmd network.cmd resolve.cmd reporting.cmd github-auth.cmd safety.cmd agent-core.js^) do if not exist "%%RUNTIME%%\%%%%F" exit /b 91
>>"%BOOTSTRAP%" echo exit /b 0
if not exist "%BOOTSTRAP%" (
  set "FAIL_RC=97"
  set "FAIL_REASON=RescueMeAI could not create its local runtime bootstrap."
  goto :APP_FATAL
)

>"%CONFIG%" echo PRODUCT=RescueMeAI
>>"%CONFIG%" echo LOG_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_REPO=%LOG_REPO%
>>"%CONFIG%" echo CONTROL_PATH=control/current-command.json
>>"%CONFIG%" echo CONTROL_REF=main
>>"%CONFIG%" echo GITHUB_APP_ID=%GITHUB_APP_ID%
>>"%CONFIG%" echo GITHUB_APP_CLIENT_ID=%GITHUB_APP_CLIENT_ID%
>>"%CONFIG%" echo GITHUB_REPOSITORY_ID=%LOG_REPO_ID%
>>"%CONFIG%" echo SOURCE_REPO=%SOURCE_REPO%
>>"%CONFIG%" echo SOURCE_REF=%SOURCE_REF%

call :SHOW_ACTIVITY "Checking GitHub API route" "Resolving and validating api.github.com before authorization."
call "%RESOLVE%" resolve api.github.com APIIP
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=RescueMeAI could not establish a validated route to api.github.com."
  goto :APP_FATAL
)

call :SHOW_ACTIVITY "Checking GitHub authorization route" "Resolving and validating github.com before token refresh."
call "%RESOLVE%" resolve github.com WEBIP
if errorlevel 1 (
  set "FAIL_RC=92"
  set "FAIL_REASON=RescueMeAI could not establish a validated route to github.com."
  goto :APP_FATAL
)

call :SHOW_ACTIVITY "Refreshing secure command channel" "Validating or refreshing the saved GitHub App authorization."
call "%AUTH%" authorize
if errorlevel 1 (
  set "FAIL_RC=!errorlevel!"
  set "FAIL_REASON=RescueMeAI could not validate or refresh the private GitHub authorization."
  goto :APP_FATAL
)

:MENU
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version         : %COMMAND_VERSION%
echo Internet        : [CONNECTED]
echo Status          : READY TO RESUME
echo Windows changes : NONE
echo %UI_BORDER%
echo.
echo                              ACTION REQUIRED
echo %UI_RULE%
echo.
echo RescueMeAI has restored the secure recovery command channel.
echo The queued Windows repair has NOT run yet.
echo.
echo TO CONTINUE:
echo.
echo        PRESS THE ENTER KEY ONCE
echo        Do NOT type the word ENTER.
echo.
echo TO CANCEL:
echo.
echo        TYPE: STOP
echo        THEN press the ENTER key.
echo.
set "START_INPUT="
set /p "START_INPUT=Waiting for you: "
if /i "!START_INPUT!"=="STOP" goto :USER_EXIT
if defined START_INPUT goto :MENU

call :SHOW_ACTIVITY "Starting persistent recovery agent" "Connecting to the queued recovery step."
call "%AGENT%"
set "AGENT_RC=!errorlevel!"
if "!AGENT_RC!"=="0" goto :STOPPED
set "FAIL_RC=!AGENT_RC!"
set "FAIL_REASON=RescueMeAI could not safely keep the persistent agent online."
goto :APP_FATAL

:SHOW_ACTIVITY
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version         : %COMMAND_VERSION%
echo Status          : WORKING
echo Windows changes : NONE
echo %UI_BORDER%
echo.
echo CURRENT ACTIVITY
echo %UI_RULE%
echo   %~1
echo.
echo   %~2
echo.
echo PLEASE WAIT. No action is required while this screen says WORKING.
exit /b 0

:STOPPED
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status          : STOPPED SAFELY
echo Windows changes : NO ACTIVE COMMAND WAS INTERRUPTED
echo %UI_BORDER%
echo Press any key to return to Command Prompt.
pause >nul
goto :RETURN_CMD

:USER_EXIT
cls
color 0E >nul 2>&1
echo RescueMeAI start cancelled. No Windows changes were made.
echo Press any key to return to Command Prompt.
pause >nul
goto :RETURN_CMD

:APP_FATAL
cls
color 0C >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                         APPLICATION FAILURE
echo %UI_BORDER%
echo Version         : %COMMAND_VERSION%
echo Return code     : !FAIL_RC!
echo Windows changes : STOPPED
echo %UI_BORDER%
echo !FAIL_REASON!
echo.
if exist "%WORK%\GITHUB_RESULT.txt" (
  echo LOCAL GITHUB DETAIL
  echo %UI_RULE%
  type "%WORK%\GITHUB_RESULT.txt"
  echo.
)
echo ACTION REQUIRED: return to ChatGPT and send exactly: fail
echo If the detail above is visible, include its short message in your reply.
echo This screen will remain until you press a key.
pause >nul
goto :RETURN_CMD

:RETURN_CMD
color 07 >nul 2>&1
title Administrator: Command Prompt
cd /d X:\Windows\System32 >nul 2>&1
cmd /k
