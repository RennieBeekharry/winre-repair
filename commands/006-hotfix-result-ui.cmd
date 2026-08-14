@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Update only the RescueMeAI result-screen wording so PASS, FAIL, and WARNING clearly require a ChatGPT reply.
rem WR_ACTION=HOTFIX_RESULT_SCREEN
rem WR_TARGET=RescueMeAI runtime UI module only.
rem WR_CONSEQUENCE=Replaces the local RescueMeAI UI module. No Windows recovery state is changed.
rem WR_ROLLBACK=Restarting RescueMeAI from a prior pinned build restores the prior UI module.

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "NETWORK=%RUNTIME%\network.cmd"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "UI=%RUNTIME%\ui.cmd"
set "TMP=%RUNTIME%\ui-result-action.tmp"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/lib/ui.cmd?ref=93ac220f918ee675d1f6e479fc1a6a17a88f90ce"

if not exist "%NETWORK%" goto :FAIL
if not exist "%FINDSTR%" goto :FAIL
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
call "%NETWORK%" fetch "%URL%" "%TMP%"
if errorlevel 1 goto :FAIL
if not exist "%TMP%" goto :FAIL
"%FINDSTR%" /i /c:"WR-MODULE: ui 2026.08.14-1545-ET" "%TMP%" >nul 2>&1
if errorlevel 1 goto :FAIL
move /y "%TMP%" "%UI%" >nul 2>&1
if errorlevel 1 goto :FAIL

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=RescueMeAI result-screen instructions were updated successfully.
>>"%RESULT%" echo EVIDENCE=Only the RescueMeAI UI module changed. Windows recovery state was not modified.
>>"%RESULT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=RescueMeAI could not update its result-screen instructions.
>>"%RESULT%" echo EVIDENCE=No Windows recovery state was changed.
>>"%RESULT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
