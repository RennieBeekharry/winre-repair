@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Restart the already-paired RescueMeAI persistent agent with corrected UI and safety modules.
rem WR_ACTION=START_RESCUEMEAI_AGENT_V2
rem WR_TARGET=RescueMeAI recovery tooling and private command channel only.
rem WR_CONSEQUENCE=Refreshes RescueMeAI runtime modules before the listener starts.
rem WR_ROLLBACK=Stop RescueMeAI safely while waiting. No Windows recovery action runs here.

set "COMMAND_VERSION=RMAI-2026.08.14-AGENT-START-4"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "CONFIG=%WORK%\agent.cfg"
set "AGENT=C:\wr-agent-v2.cmd"
set "BOOTSTRAP=%RUNTIME%\runtime-sync.cmd"
set "RESOLVER=%RUNTIME%\resolve.cmd"
set "SOURCE_REPO=RennieBeekharry/winre-repair"
set "SOURCE_REF=0c183b8da61f49427deb5a0ddd6f51e0341f468c"
set "LOG_REPO=RennieBeekharry/winre-repair-logs"
set "LOG_REPO_ID=1333818657"
set "GITHUB_APP_ID=4595411"
set "GITHUB_APP_CLIENT_ID=Iv23lif9UoXW4QvUh8tJ"
set "UI_BORDER================================================================================================="
set "UI_RULE=------------------------------------------------------------------------------------------------"
set "FAIL_RC=91"
set "FAIL_REASON=Required RescueMeAI runtime files are missing."

title RescueMeAI - Windows Recovery
mode con: cols=100 lines=50 >nul 2>&1

if not exist "%TOKEN%" (
  set "FAIL_RC=90"
  set "FAIL_REASON=Saved GitHub authorization is missing."
  goto :APP_FATAL
)
if not exist "%AGENT%" goto :APP_FATAL
if not exist "%BOOTSTRAP%" goto :APP_FATAL
if not exist "%RESOLVER%" goto :APP_FATAL

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

:MENU
cls
color 0B >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       AI-ASSISTED WINDOWS RECOVERY
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Internet       : [CONNECTED]
echo Status         : READY TO START
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo                        READY TO CONTINUE RECOVERY
echo %UI_RULE%
echo.
echo RescueMeAI is paired and the private support channel is working.
echo.
echo Press ENTER to start RescueMeAI.
echo It will refresh its own UI/safety modules, stay online, and let ChatGPT
echo continue diagnosis automatically.
echo.
echo While the screen says WAITING, press S at any time to stop safely.
echo Destructive Windows actions still require separate LOCAL approval.
echo.
echo   [ENTER]  START RESCUEMEAI
echo   [STOP]   RETURN TO COMMAND PROMPT
echo.
set "START_INPUT="
set /p "START_INPUT=Your choice: "
if /i "!START_INPUT!"=="STOP" goto :USER_EXIT
if defined START_INPUT goto :MENU

call "%AGENT%"
set "AGENT_RC=!errorlevel!"
if "!AGENT_RC!"=="0" goto :STOPPED
set "FAIL_RC=!AGENT_RC!"
set "FAIL_REASON=RescueMeAI could not safely keep the persistent agent online."
goto :APP_FATAL

:STOPPED
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status         : STOPPED SAFELY
echo Windows changes: NO ACTIVE COMMAND WAS INTERRUPTED
echo %UI_BORDER%
echo.
echo RescueMeAI stopped at a safe waiting boundary.
echo Press any key to return to the Windows Recovery command prompt.
pause >nul
goto :RETURN_CMD

:USER_EXIT
cls
color 0E >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo %UI_BORDER%
echo Status         : START CANCELLED
echo Windows changes: NONE
echo %UI_BORDER%
echo.
echo RescueMeAI was not started.
echo Press any key to return to the Windows Recovery command prompt.
pause >nul
goto :RETURN_CMD

:APP_FATAL
cls
color 0C >nul 2>&1
echo %UI_BORDER%
echo                               RESCUEMEAI
echo                       APPLICATION FAILURE
echo %UI_BORDER%
echo Version        : %COMMAND_VERSION%
echo Status         : APP_FATAL
echo Windows changes: STOPPED
echo Return code    : !FAIL_RC!
echo %UI_BORDER%
echo.
echo WHAT HAPPENED
echo %UI_RULE%
echo !FAIL_REASON!
echo.
echo WHAT YOU SHOULD DO
echo %UI_RULE%
echo Reply to ChatGPT with exactly: fail
echo.
echo Press any key when you are ready to return to Command Prompt.
pause >nul
goto :RETURN_CMD_FAIL

:RETURN_CMD
color 07 >nul 2>&1
title Command Prompt
exit /b 0

:RETURN_CMD_FAIL
color 07 >nul 2>&1
title Command Prompt
exit /b !FAIL_RC!
