@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.14-1518-ET
rem RescueMeAI WinRE console renderer v2.
rem Keep live recovery screens simple, stable, and operator-readable.

set "RMAI_UI_DESC=AI-ASSISTED WINDOWS RECOVERY"
set "RMAI_UI_LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "RMAI_UI_LEGAL_FILE=LEGAL.md"
set "RMAI_UI_BORDER================================================================================================="
set "RMAI_UI_RULE=------------------------------------------------------------------------------------------------"
set "RMAI_UI_MODE=C:\Windows\System32\mode.com"
if not exist "%RMAI_UI_MODE%" set "RMAI_UI_MODE=mode"

if /i "%~1"=="setup" goto :SETUP
if /i "%~1"=="screen" goto :SCREEN
if /i "%~1"=="line" goto :LINE
if /i "%~1"=="wrap" goto :WRAP
if /i "%~1"=="section" goto :SECTION
if /i "%~1"=="center" goto :CENTER
if /i "%~1"=="result" goto :RESULT
if /i "%~1"=="header" goto :HEADER_COMPAT
if /i "%~1"=="note" goto :NOTE_COMPAT
exit /b 64

:SETUP
"%RMAI_UI_MODE%" con: cols=100 lines=50 >nul 2>&1
exit /b 0

:SET_THEME
set "RMAI_THEME=%~1"
set "RMAI_COLOR=07"
if /i "%RMAI_THEME%"=="INFO" set "RMAI_COLOR=0B"
if /i "%RMAI_THEME%"=="PASS" set "RMAI_COLOR=0A"
if /i "%RMAI_THEME%"=="SUCCESS" set "RMAI_COLOR=0A"
if /i "%RMAI_THEME%"=="WARNING" set "RMAI_COLOR=0E"
if /i "%RMAI_THEME%"=="ERROR" set "RMAI_COLOR=0C"
if /i "%RMAI_THEME%"=="FAIL" set "RMAI_COLOR=0C"
color %RMAI_COLOR% >nul 2>&1
exit /b 0

:DRAW_HEADER
rem VERSION INTERNET STATUS SAFETY DESCRIPTION THEME
set "D_VERSION=%~1"
set "D_INTERNET=%~2"
set "D_STATUS=%~3"
set "D_SAFETY=%~4"
set "D_DESC=%~5"
set "D_THEME=%~6"
if not defined D_DESC set "D_DESC=%RMAI_UI_DESC%"
if not defined D_THEME set "D_THEME=INFO"
call :SET_THEME "%D_THEME%"
cls
echo %RMAI_UI_BORDER%
echo                               RESCUEMEAI
echo                       %D_DESC%
echo %RMAI_UI_BORDER%
echo Version      : %D_VERSION%
echo Internet     : [%D_INTERNET%]
echo Status       : %D_STATUS%
echo Safety       : %D_SAFETY%
echo Legal        : %RMAI_UI_LEGAL_BASE%
echo Legal file   : %RMAI_UI_LEGAL_FILE%
echo %RMAI_UI_BORDER%
exit /b 0

:SCREEN
rem screen VERSION INTERNET STATUS SAFETY DESCRIPTION THEME
call :SETUP
call :DRAW_HEADER "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"
exit /b 0

:RESULT
rem result STATE MESSAGE EVIDENCE INSTRUCTION VERSION INTERNET
set "R_STATE=%~2"
set "R_MESSAGE=%~3"
set "R_EVIDENCE=%~4"
set "R_INSTRUCTION=%~5"
set "R_VERSION=%~6"
set "R_INTERNET=%~7"
if not defined R_VERSION set "R_VERSION=UNKNOWN"
if not defined R_INTERNET set "R_INTERNET=UNKNOWN"
if not defined R_EVIDENCE set "R_EVIDENCE=None."
if not defined R_INSTRUCTION set "R_INSTRUCTION=No action is required."
set "R_THEME=WARNING"
if /i "%R_STATE%"=="PASS" set "R_THEME=PASS"
if /i "%R_STATE%"=="FAIL" set "R_THEME=ERROR"
call :SETUP
call :DRAW_HEADER "%R_VERSION%" "%R_INTERNET%" "%R_STATE%" "NO NEW ACTION" "%RMAI_UI_DESC%" "%R_THEME%"
echo.
echo                              RESULT: %R_STATE%
echo %RMAI_UI_RULE%
echo.
echo WHAT HAPPENED
echo   %R_MESSAGE%
echo.
echo WHAT YOU NEED TO DO
echo   %R_INSTRUCTION%
echo.
if /i not "%R_EVIDENCE%"=="None." (
  echo DETAILS
  echo   %R_EVIDENCE%
  echo.
)
echo AGENT STATE
echo   RescueMeAI is still running unless this screen explicitly says APP_FATAL or STOPPED.
echo   While WAITING, press S to stop safely.
echo.
echo %RMAI_UI_BORDER%
exit /b 0

:LINE
echo(%~3
exit /b 0

:WRAP
rem Let the console wrap naturally; avoids fragile substring rendering in WinRE.
echo(%~3
exit /b 0

:SECTION
echo.
echo(%~3
echo %RMAI_UI_RULE%
exit /b 0

:CENTER
echo                              %~3
exit /b 0

:HEADER_COMPAT
set "H_INET=%RMAI_INTERNET_STATUS%"
if not defined H_INET set "H_INET=CHECKING"
set "H_SAFE=%RMAI_SAFETY%"
if not defined H_SAFE set "H_SAFE=CONTROLLED RECOVERY"
set "H_THEME=%RMAI_UI_THEME%"
if not defined H_THEME set "H_THEME=INFO"
call :DRAW_HEADER "%~3" "%H_INET%" "%~2" "%H_SAFE%" "%~4" "%H_THEME%"
exit /b 0

:NOTE_COMPAT
echo(%~2
exit /b 0
