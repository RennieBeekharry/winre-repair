@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Update RescueMeAI UI
rem WR_ACTION=UPDATE_UI
rem WR_TARGET=RescueMeAI UI
rem WR_CONSEQUENCE=Updates RescueMeAI runtime UI
rem WR_ROLLBACK=Restart RescueMeAI to restore pinned UI

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "NETWORK=%RUNTIME%\network.cmd"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "UI=%RUNTIME%\ui.cmd"
set "TMP=%RUNTIME%\ui-v2.tmp"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/lib/ui.cmd?ref=a9ba60419ce9d42b9224c3af28f4a77c2e6fd1a5"

if not exist "%NETWORK%" goto :FAIL
if not exist "%FINDSTR%" goto :FAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
call "%NETWORK%" fetch "%URL%" "%TMP%"
if errorlevel 1 goto :FAIL
if not exist "%TMP%" goto :FAIL
"%FINDSTR%" /i /c:"WR-MODULE: ui 2026.08.14-1518-ET" "%TMP%" >nul 2>&1
if errorlevel 1 goto :FAIL
move /y "%TMP%" "%UI%" >nul 2>&1
if errorlevel 1 goto :FAIL
>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=RescueMeAI display renderer was repaired successfully.
>>"%RESULT%" echo EVIDENCE=UI v2 is active. No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=No action is required. RescueMeAI remains online.
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not apply the display renderer hotfix.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
