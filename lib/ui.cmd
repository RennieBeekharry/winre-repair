@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.14-1240-ET
rem RescueMeAI console UI standard. Pure batch for WinRE compatibility.

set "RMAI_UI_LEGAL=https://github.com/RennieBeekharry/winre-repair/blob/main/LEGAL.md"
set "RMAI_UI_DESC=AI-ASSISTED WINDOWS RECOVERY"

if /i "%~1"=="screen" goto :SCREEN_ENTRY
if /i "%~1"=="header" goto :HEADER_COMPAT
if /i "%~1"=="result" goto :RESULT
if /i "%~1"=="note" goto :NOTE
if /i "%~1"=="prompt" goto :PROMPT
exit /b 64

:SCREEN_ENTRY
rem screen VERSION INTERNET STEP SAFETY DESCRIPTION COLOR
set "UI_VERSION=%~2"
set "UI_INTERNET=%~3"
set "UI_STEP=%~4"
set "UI_SAFETY=%~5"
set "UI_DESC=%~6"
set "UI_COLOR=%~7"
if not defined UI_DESC set "UI_DESC=%RMAI_UI_DESC%"
if not defined UI_COLOR set "UI_COLOR=07"
call :SCREEN
exit /b 0

:HEADER_COMPAT
rem Backward-compatible mapping for older callers:
rem header TITLE VERSION DESCRIPTION
set "UI_VERSION=%~3"
set "UI_INTERNET=%RMAI_INTERNET_STATUS%"
set "UI_STEP=%~2"
set "UI_SAFETY=%RMAI_SAFETY%"
set "UI_DESC=%~4"
set "UI_COLOR=%RMAI_UI_COLOR%"
if not defined UI_INTERNET set "UI_INTERNET=CHECKING"
if not defined UI_SAFETY set "UI_SAFETY=CONTROLLED RECOVERY"
if not defined UI_DESC set "UI_DESC=%RMAI_UI_DESC%"
if not defined UI_COLOR set "UI_COLOR=0B"
call :SCREEN
exit /b 0

:SCREEN
color !UI_COLOR! >nul 2>&1
cls
echo ========================================================================
call :CENTER "RESCUEMEAI"
call :CENTER "!UI_DESC!"
echo ========================================================================
echo  Version      : !UI_VERSION!
echo  Internet     : !UI_INTERNET!
echo  Current Step : !UI_STEP!
echo  Safety       : !UI_SAFETY!
echo  Legal        :
echo    %RMAI_UI_LEGAL%
echo ========================================================================
exit /b 0

:NOTE
echo %~2
exit /b 0

:PROMPT
rem prompt LABEL [VARIABLE]
set "UI_PROMPT_LABEL=%~2"
set "UI_PROMPT_VAR=%~3"
if not defined UI_PROMPT_LABEL set "UI_PROMPT_LABEL=ENTER VALUE"
if not defined UI_PROMPT_VAR set "UI_PROMPT_VAR=RMAI_UI_INPUT"
set "%UI_PROMPT_VAR%="
set /p "%UI_PROMPT_VAR%=%UI_PROMPT_LABEL%: "
exit /b 0

:RESULT
rem result STATE MESSAGE EVIDENCE INSTRUCTION [VERSION] [INTERNET]
set "WR_UI_STATE=%~2"
set "WR_UI_MESSAGE=%~3"
set "WR_UI_EVIDENCE=%~4"
set "WR_UI_INSTRUCTION=%~5"
set "WR_UI_VERSION=%~6"
set "WR_UI_INTERNET=%~7"
set "WR_UI_REPLY=warning"
set "WR_UI_COLOR=0E"
if /i "%WR_UI_STATE%"=="PASS" (
  set "WR_UI_COLOR=0A"
  set "WR_UI_REPLY=pass"
)
if /i "%WR_UI_STATE%"=="FAIL" (
  set "WR_UI_COLOR=0C"
  set "WR_UI_REPLY=fail"
)
if not defined WR_UI_VERSION set "WR_UI_VERSION=%RMAI_VERSION%"
if not defined WR_UI_VERSION set "WR_UI_VERSION=UNKNOWN"
if not defined WR_UI_INTERNET set "WR_UI_INTERNET=%RMAI_INTERNET_STATUS%"
if not defined WR_UI_INTERNET set "WR_UI_INTERNET=UNKNOWN"
if not defined WR_UI_EVIDENCE set "WR_UI_EVIDENCE=None."
if not defined WR_UI_INSTRUCTION set "WR_UI_INSTRUCTION=Follow the instruction shown by RescueMeAI."

set "UI_VERSION=%WR_UI_VERSION%"
set "UI_INTERNET=%WR_UI_INTERNET%"
set "UI_STEP=%WR_UI_STATE% RESULT"
set "UI_SAFETY=NO NEW ACTION"
set "UI_DESC=%RMAI_UI_DESC%"
set "UI_COLOR=%WR_UI_COLOR%"
call :SCREEN
echo.
echo [!WR_UI_STATE!] RESCUEMEAI RESULT
echo ------------------------------------------------------------------------
echo RESULT:
echo   !WR_UI_MESSAGE!
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to ChatGPT with exactly: !WR_UI_REPLY!
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   !WR_UI_EVIDENCE!
echo.
echo ADDITIONAL INSTRUCTIONS:
echo   !WR_UI_INSTRUCTION!
echo ------------------------------------------------------------------------
echo Do not rerun commands unless RescueMeAI explicitly asks you to.
echo ========================================================================
exit /b 0

:CENTER
set "CENTER_TEXT=%~1"
set /a CENTER_LEN=0
:CENTER_LEN_LOOP
if not "!CENTER_TEXT:~%CENTER_LEN%,1!"=="" (
  set /a CENTER_LEN+=1
  if !CENTER_LEN! LSS 72 goto :CENTER_LEN_LOOP
)
set /a CENTER_PAD=(72-CENTER_LEN)/2
if !CENTER_PAD! LSS 0 set "CENTER_PAD=0"
set "CENTER_SPACES=                                                                        "
echo !CENTER_SPACES:~0,%CENTER_PAD%!!CENTER_TEXT!
exit /b 0
