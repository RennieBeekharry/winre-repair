@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.14-1305-ET
rem Central RescueMeAI console renderer for WinRE.
rem All user-facing colors are selected here by semantic message type.

set "RMAI_UI_DESC=AI-ASSISTED WINDOWS RECOVERY"
set "RMAI_UI_LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "RMAI_UI_LEGAL_FILE=LEGAL.md"
set "RMAI_UI_WIDTH=96"
set "RMAI_UI_TEXT_WIDTH=92"
set "RMAI_UI_BORDER================================================================================================="
set "RMAI_UI_SPACES=                                                                                                    "
set "RMAI_UI_FINDSTR=C:\Windows\System32\findstr.exe"
if not exist "%RMAI_UI_FINDSTR%" set "RMAI_UI_FINDSTR=findstr.exe"
set "RMAI_UI_MODE=C:\Windows\System32\mode.com"
if not exist "%RMAI_UI_MODE%" set "RMAI_UI_MODE=mode"
set "RMAI_UI_TMP=%TEMP%\rmai-ui-%RANDOM%%RANDOM%.txt"

if /i "%~1"=="setup" goto :SETUP
if /i "%~1"=="screen" goto :SCREEN
if /i "%~1"=="line" goto :LINE
if /i "%~1"=="wrap" goto :WRAP
if /i "%~1"=="section" goto :SECTION
if /i "%~1"=="center" goto :CENTER_ENTRY
if /i "%~1"=="result" goto :RESULT
if /i "%~1"=="header" goto :HEADER_COMPAT
if /i "%~1"=="note" goto :NOTE_COMPAT
exit /b 64

:SETUP
rem A slightly wider console improves readability while remaining lightweight.
"%RMAI_UI_MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:SCREEN
rem screen VERSION INTERNET STEP SAFETY [DESCRIPTION]
call :SETUP
set "UI_VERSION=%~2"
set "UI_INTERNET=%~3"
set "UI_STEP=%~4"
set "UI_SAFETY=%~5"
set "UI_DESC=%~6"
if not defined UI_DESC set "UI_DESC=%RMAI_UI_DESC%"
cls
call :PAINT HEADER "%RMAI_UI_BORDER%"
call :CENTER_PAINT HEADER "RESCUEMEAI"
call :CENTER_PAINT HEADER "!UI_DESC!"
call :PAINT HEADER "%RMAI_UI_BORDER%"
call :PAINT LABEL "Version      : !UI_VERSION!"
if /i "!UI_INTERNET!"=="CONNECTED" (
  call :PAINT PASS "Internet     : [CONNECTED]"
) else if /i "!UI_INTERNET!"=="NOT CONNECTED" (
  call :PAINT ERROR "Internet     : [NOT CONNECTED]"
) else (
  call :PAINT WARNING "Internet     : [!UI_INTERNET!]"
)
call :PAINT INFO "Current Step : !UI_STEP!"
call :PAINT LABEL "Safety       : !UI_SAFETY!"
call :PAINT LABEL "Legal        : %RMAI_UI_LEGAL_BASE%"
call :PAINT LABEL "Legal file   : %RMAI_UI_LEGAL_FILE%"
call :PAINT HEADER "%RMAI_UI_BORDER%"
exit /b 0

:LINE
rem line TYPE TEXT
call :PAINT "%~2" "%~3"
exit /b 0

:WRAP
rem wrap TYPE TEXT
set "UI_WRAP_TYPE=%~2"
set "UI_WRAP_TEXT=%~3"
call :WRAP_TEXT
exit /b 0

:SECTION
echo.
call :PAINT "%~2" "%~3"
call :PAINT MUTED "------------------------------------------------------------------------------------------------"
exit /b 0

:CENTER_ENTRY
call :CENTER_PAINT "%~2" "%~3"
exit /b 0

:RESULT
rem result STATE MESSAGE EVIDENCE INSTRUCTION VERSION INTERNET
set "UI_STATE=%~2"
set "UI_MESSAGE=%~3"
set "UI_EVIDENCE=%~4"
set "UI_INSTRUCTION=%~5"
set "UI_VERSION=%~6"
set "UI_INTERNET=%~7"
if not defined UI_VERSION set "UI_VERSION=UNKNOWN"
if not defined UI_INTERNET set "UI_INTERNET=UNKNOWN"
if not defined UI_EVIDENCE set "UI_EVIDENCE=None."
if not defined UI_INSTRUCTION set "UI_INSTRUCTION=Follow the instruction shown by RescueMeAI."
set "UI_REPLY=warning"
set "UI_TYPE=WARNING"
if /i "!UI_STATE!"=="PASS" (
  set "UI_REPLY=pass"
  set "UI_TYPE=PASS"
)
if /i "!UI_STATE!"=="FAIL" (
  set "UI_REPLY=fail"
  set "UI_TYPE=ERROR"
)
call :SCREEN "!UI_VERSION!" "!UI_INTERNET!" "!UI_STATE! RESULT" "NO NEW ACTION" "%RMAI_UI_DESC%"
call :SECTION "!UI_TYPE!" "[!UI_STATE!] RESCUEMEAI RESULT"
call :WRAP "!UI_TYPE!" "!UI_MESSAGE!"
call :SECTION INSTRUCTION "WHAT YOU SHOULD DO"
call :WRAP INSTRUCTION "Reply to ChatGPT with exactly: !UI_REPLY!"
call :SECTION INFO "ADDITIONAL INFORMATION REQUIRED"
call :WRAP INFO "!UI_EVIDENCE!"
call :SECTION INSTRUCTION "ADDITIONAL INSTRUCTIONS"
call :WRAP INSTRUCTION "!UI_INSTRUCTION!"
call :PAINT MUTED "%RMAI_UI_BORDER%"
exit /b 0

:HEADER_COMPAT
rem Backward-compatible header TITLE VERSION DESCRIPTION.
set "UI_INET=%RMAI_INTERNET_STATUS%"
if not defined UI_INET set "UI_INET=CHECKING"
set "UI_SAFE=%RMAI_SAFETY%"
if not defined UI_SAFE set "UI_SAFE=CONTROLLED RECOVERY"
call :SCREEN "%~3" "!UI_INET!" "%~2" "!UI_SAFE!" "%~4"
exit /b 0

:NOTE_COMPAT
call :WRAP INFO "%~2"
exit /b 0

:WRAP_TEXT
set "UI_LINE="
for %%W in (!UI_WRAP_TEXT!) do (
  if not defined UI_LINE (
    set "UI_LINE=%%W"
  ) else (
    set "UI_CANDIDATE=!UI_LINE! %%W"
    call :STRLEN "!UI_CANDIDATE!" UI_LEN
    if !UI_LEN! GTR %RMAI_UI_TEXT_WIDTH% (
      call :PAINT "!UI_WRAP_TYPE!" "!UI_LINE!"
      set "UI_LINE=%%W"
    ) else (
      set "UI_LINE=!UI_CANDIDATE!"
    )
  )
)
if defined UI_LINE call :PAINT "!UI_WRAP_TYPE!" "!UI_LINE!"
if not defined UI_LINE echo.
exit /b 0

:CENTER_PAINT
set "UI_CENTER_TYPE=%~1"
set "UI_CENTER_TEXT=%~2"
call :STRLEN "!UI_CENTER_TEXT!" UI_CENTER_LEN
set /a UI_PAD=(%RMAI_UI_WIDTH%-UI_CENTER_LEN)/2
if !UI_PAD! LSS 0 set "UI_PAD=0"
set "UI_CENTER_LINE=!RMAI_UI_SPACES:~0,%UI_PAD%!!UI_CENTER_TEXT!"
call :PAINT "!UI_CENTER_TYPE!" "!UI_CENTER_LINE!"
exit /b 0

:PAINT
rem PAINT is the only color-selection function.
set "UI_SEM=%~1"
set "UI_TEXT=%~2"
set "UI_ATTR=07"
if /i "!UI_SEM!"=="HEADER" set "UI_ATTR=0B"
if /i "!UI_SEM!"=="INFO" set "UI_ATTR=09"
if /i "!UI_SEM!"=="PASS" set "UI_ATTR=0A"
if /i "!UI_SEM!"=="SUCCESS" set "UI_ATTR=0A"
if /i "!UI_SEM!"=="WARNING" set "UI_ATTR=0E"
if /i "!UI_SEM!"=="ERROR" set "UI_ATTR=0C"
if /i "!UI_SEM!"=="FAIL" set "UI_ATTR=0C"
if /i "!UI_SEM!"=="INSTRUCTION" set "UI_ATTR=0F"
if /i "!UI_SEM!"=="PROMPT" set "UI_ATTR=0D"
if /i "!UI_SEM!"=="MUTED" set "UI_ATTR=08"
if /i "!UI_SEM!"=="LABEL" set "UI_ATTR=07"
call :STRLEN "!UI_TEXT!" UI_PRINT_LEN
if !UI_PRINT_LEN! GTR %RMAI_UI_WIDTH% set "UI_TEXT=!UI_TEXT:~0,%RMAI_UI_WIDTH%!"
>"%RMAI_UI_TMP%" echo(!UI_TEXT!
"%RMAI_UI_FINDSTR%" /a:!UI_ATTR! /r "^" "%RMAI_UI_TMP%" 2>nul
if errorlevel 1 echo(!UI_TEXT!
del /f /q "%RMAI_UI_TMP%" >nul 2>&1
exit /b 0

:STRLEN
set "UI_SL_TEXT=%~1"
set /a UI_SL_LEN=0
:STRLEN_LOOP
if not "!UI_SL_TEXT:~%UI_SL_LEN%,1!"=="" (
  set /a UI_SL_LEN+=1
  if !UI_SL_LEN! LSS 512 goto :STRLEN_LOOP
)
set "%~2=%UI_SL_LEN%"
exit /b 0
