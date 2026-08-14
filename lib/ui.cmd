@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.14-1345-ET
rem RescueMeAI WinRE console renderer.
rem WinRE uses centrally selected screen-state themes for robust color output.

set "RMAI_UI_DESC=AI-ASSISTED WINDOWS RECOVERY"
set "RMAI_UI_LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "RMAI_UI_LEGAL_FILE=LEGAL.md"
set "RMAI_UI_WIDTH=96"
set "RMAI_UI_TEXT_WIDTH=92"
set "RMAI_UI_BORDER================================================================================================="
set "RMAI_UI_RULE=------------------------------------------------------------------------------------------------"
set "RMAI_UI_SPACES=                                                                                                    "
set "RMAI_UI_MODE=C:\Windows\System32\mode.com"
if not exist "%RMAI_UI_MODE%" set "RMAI_UI_MODE=mode"

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
"%RMAI_UI_MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:THEME
rem Single authoritative WinRE semantic-theme mapping.
set "UI_THEME=%~2"
if not defined UI_THEME set "UI_THEME=NEUTRAL"
set "UI_COLOR=07"
if /i "!UI_THEME!"=="INFO" set "UI_COLOR=0B"
if /i "!UI_THEME!"=="PASS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="SUCCESS" set "UI_COLOR=0A"
if /i "!UI_THEME!"=="WARNING" set "UI_COLOR=0E"
if /i "!UI_THEME!"=="ERROR" set "UI_COLOR=0C"
if /i "!UI_THEME!"=="FAIL" set "UI_COLOR=0C"
if /i "!UI_THEME!"=="NEUTRAL" set "UI_COLOR=07"
color !UI_COLOR! >nul 2>&1
exit /b 0

:SCREEN
rem screen VERSION INTERNET STEP SAFETY [DESCRIPTION] [THEME]
call :SETUP
set "UI_VERSION=%~2"
set "UI_INTERNET=%~3"
set "UI_STEP=%~4"
set "UI_SAFETY=%~5"
set "UI_DESC=%~6"
set "UI_THEME_REQUEST=%~7"
if not defined UI_DESC set "UI_DESC=%RMAI_UI_DESC%"
if not defined UI_THEME_REQUEST set "UI_THEME_REQUEST=INFO"
call :THEME "" "!UI_THEME_REQUEST!"
cls
call :PRINT "%RMAI_UI_BORDER%"
call :CENTER_TEXT "RESCUEMEAI"
call :CENTER_TEXT "!UI_DESC!"
call :PRINT "%RMAI_UI_BORDER%"
call :PRINT "Version      : !UI_VERSION!"
call :PRINT "Internet     : [!UI_INTERNET!]"
call :PRINT "Current Step : !UI_STEP!"
call :PRINT "Safety       : !UI_SAFETY!"
call :PRINT "Legal        : %RMAI_UI_LEGAL_BASE%"
call :PRINT "Legal file   : %RMAI_UI_LEGAL_FILE%"
call :PRINT "%RMAI_UI_BORDER%"
exit /b 0

:LINE
rem Compatibility: line TYPE TEXT. TYPE is semantic metadata; screen theme owns color.
call :PRINT "%~3"
exit /b 0

:WRAP
rem Compatibility: wrap TYPE TEXT.
set "UI_WRAP_TEXT=%~3"
call :WRAP_TEXT
exit /b 0

:SECTION
rem Compatibility: section TYPE TITLE.
echo.
call :PRINT "%~3"
call :PRINT "%RMAI_UI_RULE%"
exit /b 0

:CENTER_ENTRY
rem Compatibility: center TYPE TEXT.
call :CENTER_TEXT "%~3"
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
set "UI_THEME_RESULT=WARNING"
if /i "!UI_STATE!"=="PASS" (
  set "UI_REPLY=pass"
  set "UI_THEME_RESULT=PASS"
)
if /i "!UI_STATE!"=="FAIL" (
  set "UI_REPLY=fail"
  set "UI_THEME_RESULT=ERROR"
)
call :SCREEN "!UI_VERSION!" "!UI_INTERNET!" "!UI_STATE! RESULT" "NO NEW ACTION" "%RMAI_UI_DESC%" "!UI_THEME_RESULT!"
call :SECTION "!UI_THEME_RESULT!" "[!UI_STATE!] RESCUEMEAI RESULT"
call :WRAP "!UI_THEME_RESULT!" "!UI_MESSAGE!"
call :SECTION INSTRUCTION "WHAT YOU SHOULD DO"
call :WRAP INSTRUCTION "Reply to ChatGPT with exactly: !UI_REPLY!"
call :SECTION INFO "ADDITIONAL INFORMATION REQUIRED"
call :WRAP INFO "!UI_EVIDENCE!"
call :SECTION INSTRUCTION "ADDITIONAL INSTRUCTIONS"
call :WRAP INSTRUCTION "!UI_INSTRUCTION!"
call :PRINT "%RMAI_UI_BORDER%"
exit /b 0

:HEADER_COMPAT
rem Backward-compatible header TITLE VERSION DESCRIPTION.
set "UI_INET=%RMAI_INTERNET_STATUS%"
if not defined UI_INET set "UI_INET=CHECKING"
set "UI_SAFE=%RMAI_SAFETY%"
if not defined UI_SAFE set "UI_SAFE=CONTROLLED RECOVERY"
set "UI_THEME_COMPAT=%RMAI_UI_THEME%"
if not defined UI_THEME_COMPAT set "UI_THEME_COMPAT=INFO"
call :SCREEN "%~3" "!UI_INET!" "%~2" "!UI_SAFE!" "%~4" "!UI_THEME_COMPAT!"
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
      call :PRINT "!UI_LINE!"
      set "UI_LINE=%%W"
    ) else (
      set "UI_LINE=!UI_CANDIDATE!"
    )
  )
)
if defined UI_LINE call :PRINT "!UI_LINE!"
if not defined UI_LINE echo.
exit /b 0

:CENTER_TEXT
set "UI_CENTER_TEXT=%~1"
call :STRLEN "!UI_CENTER_TEXT!" UI_CENTER_LEN
set /a UI_PAD=(%RMAI_UI_WIDTH%-UI_CENTER_LEN)/2
if !UI_PAD! LSS 0 set "UI_PAD=0"
set "UI_CENTER_LINE=!RMAI_UI_SPACES:~0,%UI_PAD%!!UI_CENTER_TEXT!"
call :PRINT "!UI_CENTER_LINE!"
exit /b 0

:PRINT
set "UI_TEXT=%~1"
call :STRLEN "!UI_TEXT!" UI_PRINT_LEN
if !UI_PRINT_LEN! GTR %RMAI_UI_WIDTH% set "UI_TEXT=!UI_TEXT:~0,%RMAI_UI_WIDTH%!"
echo(!UI_TEXT!
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
