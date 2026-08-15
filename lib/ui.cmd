@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.15-0048-ET
rem RescueMeAI WinRE console renderer v4.
rem Normal results are reported automatically. Human prompts are reserved for genuine local actions.

set "RMAI_UI_DESC=AI-ASSISTED WINDOWS RECOVERY"
set "RMAI_UI_LEGAL_BASE=https://github.com/RennieBeekharry/winre-repair"
set "RMAI_UI_LEGAL_FILE=LEGAL.md"
set "RMAI_UI_BORDER================================================================================================="
set "RMAI_UI_RULE=------------------------------------------------------------------------------------------------"
set "RMAI_UI_MODE=C:\Windows\System32\mode.com"
if not exist "%RMAI_UI_MODE%" set "RMAI_UI_MODE=mode"
set "RMAI_UI_FINDSTR=C:\Windows\System32\findstr.exe"
if not exist "%RMAI_UI_FINDSTR%" set "RMAI_UI_FINDSTR=findstr"

if /i "%~1"=="setup" goto :SETUP
if /i "%~1"=="screen" goto :SCREEN
if /i "%~1"=="line" goto :LINE
if /i "%~1"=="wrap" goto :WRAP
if /i "%~1"=="section" goto :SECTION
if /i "%~1"=="center" goto :CENTER
if /i "%~1"=="result" goto :RESULT
if /i "%~1"=="localaction" goto :LOCAL_ACTION
if /i "%~1"=="roadmap" goto :ROADMAP
if /i "%~1"=="readiness" goto :READINESS
if /i "%~1"=="progress" goto :PROGRESS
if /i "%~1"=="working" goto :WORKING
if /i "%~1"=="waiting" goto :WAITING
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
set "D_VERSION=%~1"
set "D_INTERNET=%~2"
set "D_STATUS=%~3"
set "D_CHANGE=%~4"
set "D_DESC=%~5"
set "D_THEME=%~6"
if not defined D_DESC set "D_DESC=%RMAI_UI_DESC%"
if not defined D_THEME set "D_THEME=INFO"
if not defined D_CHANGE set "D_CHANGE=NONE"
call :SET_THEME "%D_THEME%"
cls
echo %RMAI_UI_BORDER%
echo                               RESCUEMEAI
echo                       %D_DESC%
echo %RMAI_UI_BORDER%
echo Version         : %D_VERSION%
echo Internet        : [%D_INTERNET%]
echo Status          : %D_STATUS%
echo Windows changes : %D_CHANGE%
echo Legal           : %RMAI_UI_LEGAL_BASE%
echo Legal file      : %RMAI_UI_LEGAL_FILE%
echo %RMAI_UI_BORDER%
exit /b 0

:SCREEN
call :SETUP
call :DRAW_HEADER "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"
exit /b 0

:MAKE_BAR
set "RMAI_BAR_PERCENT=%~1"
>nul 2>&1 echo(%RMAI_BAR_PERCENT%|"%RMAI_UI_FINDSTR%" /r /x "[0-9][0-9]*"
if errorlevel 1 set "RMAI_BAR_PERCENT=0"
set /a RMAI_BAR_PERCENT+=0
if %RMAI_BAR_PERCENT% LSS 0 set "RMAI_BAR_PERCENT=0"
if %RMAI_BAR_PERCENT% GTR 100 set "RMAI_BAR_PERCENT=100"
set /a RMAI_BAR_FILLED=RMAI_BAR_PERCENT/5
set /a RMAI_BAR_REMAIN=20-RMAI_BAR_FILLED
set "RMAI_BAR_FULL=####################"
set "RMAI_BAR_EMPTY=--------------------"
set "RMAI_BAR=!RMAI_BAR_FULL:~0,%RMAI_BAR_FILLED%!!RMAI_BAR_EMPTY:~0,%RMAI_BAR_REMAIN%!"
exit /b 0

:ROADMAP
set "RM_STAGE=%~2"
set "RM_PERCENT=%~3"
if not defined RM_STAGE set "RM_STAGE=1"
>nul 2>&1 echo(%RM_STAGE%|"%RMAI_UI_FINDSTR%" /r /x "[0-9][0-9]*"
if errorlevel 1 set "RM_STAGE=1"
set /a RM_STAGE+=0
if %RM_STAGE% LSS 1 set "RM_STAGE=1"
if %RM_STAGE% GTR 10 set "RM_STAGE=10"
if not defined RM_PERCENT set /a RM_PERCENT=RM_STAGE*10
set /a RM_PERCENT+=0
if %RM_PERCENT% LSS 0 set "RM_PERCENT=0"
if %RM_PERCENT% GTR 100 set "RM_PERCENT=100"
call :MAKE_BAR "%RM_PERCENT%"
set /a RM_NEXT=RM_STAGE+1
echo.
echo RECOVERY ROADMAP                         Stage %RM_STAGE% of 10
echo Plan progress: [%RMAI_BAR%] %RM_PERCENT% percent ^(estimated^)
echo %RMAI_UI_RULE%
for /L %%I in (1,1,10) do (
  set "RM_LABEL=    "
  if %%I LSS %RM_STAGE% set "RM_LABEL=PASS"
  if %%I EQU %RM_STAGE% set "RM_LABEL=NOW "
  if %%I EQU %RM_NEXT% set "RM_LABEL=NEXT"
  if %%I GEQ 8 if %%I GTR %RM_STAGE% set "RM_LABEL=LOCK"
  if %%I EQU 1 set "RM_NAME=Hardware Safety"
  if %%I EQU 2 set "RM_NAME=Evidence + Windows Diagnostics"
  if %%I EQU 3 set "RM_NAME=Built-in Windows Repair"
  if %%I EQU 4 set "RM_NAME=Boot Test / Reassess"
  if %%I EQU 5 set "RM_NAME=Targeted Repair"
  if %%I EQU 6 set "RM_NAME=Advanced Offline Repair"
  if %%I EQU 7 set "RM_NAME=Restore / Rollback"
  if %%I EQU 8 set "RM_NAME=Repair Reinstall"
  if %%I EQU 9 set "RM_NAME=Reset Windows"
  if %%I EQU 10 set "RM_NAME=Clean Reinstall - LAST RESORT"
  echo [!RM_LABEL!] %%I. !RM_NAME!
)
exit /b 0

:READINESS
set "RD_BACKUP=%~2"
set "RD_MEDIA=%~3"
set "RD_CHANGE=%~4"
set "RD_REASON=%~5"
if not defined RD_BACKUP set "RD_BACKUP=NOT REQUIRED YET"
if not defined RD_MEDIA set "RD_MEDIA=NOT NEEDED YET"
if not defined RD_CHANGE set "RD_CHANGE=NONE"
echo.
echo SAFETY READINESS
echo %RMAI_UI_RULE%
echo Backup        : %RD_BACKUP%
echo Recovery USB  : %RD_MEDIA%
echo Windows change: %RD_CHANGE%
if defined RD_REASON echo Reason        : %RD_REASON%
exit /b 0

:PROGRESS
set "PG_TASK=%~2"
set "PG_PERCENT=%~3"
set "PG_UNITS=%~4"
set "PG_DATA=%~5"
set "PG_SPEED=%~6"
set "PG_ELAPSED=%~7"
set "PG_ETA=%~8"
if not defined PG_TASK set "PG_TASK=Recovery operation"
if not defined PG_PERCENT set "PG_PERCENT=UNKNOWN"
if not defined PG_ELAPSED set "PG_ELAPSED=Not available"
if not defined PG_ETA set "PG_ETA=Not available yet - result dependent"
echo.
echo CURRENT TASK
echo %RMAI_UI_RULE%
echo %PG_TASK%
set "PG_NUM=-1"
>nul 2>&1 echo(%PG_PERCENT%|"%RMAI_UI_FINDSTR%" /r /x "[0-9][0-9]*"
if not errorlevel 1 set /a PG_NUM=PG_PERCENT+0
if %PG_NUM% GEQ 0 if %PG_NUM% LEQ 100 (
  call :MAKE_BAR "%PG_NUM%"
  echo Progress : [%RMAI_BAR%] %PG_NUM% percent
) else (
  echo Progress : %PG_PERCENT%
)
if defined PG_UNITS echo Units    : %PG_UNITS%
if defined PG_DATA echo Data     : %PG_DATA%
if defined PG_SPEED echo Speed    : %PG_SPEED%
echo Elapsed  : %PG_ELAPSED%
echo ETA      : %PG_ETA%
exit /b 0

:WORKING
set "WK_MESSAGE=%~2"
if not defined WK_MESSAGE set "WK_MESSAGE=RescueMeAI is working on the current recovery step."
echo.
echo WHAT IS HAPPENING NOW
echo %RMAI_UI_RULE%
echo %WK_MESSAGE%
echo.
echo WHAT YOU NEED TO DO
echo %RMAI_UI_RULE%
echo PLEASE WAIT - RescueMeAI is working.
echo No action is required from you right now.
exit /b 0

:WAITING
set "WT_MESSAGE=%~2"
if not defined WT_MESSAGE set "WT_MESSAGE=RescueMeAI is online and waiting for the next validated recovery instruction."
echo.
echo AGENT STATE: ONLINE / WAITING
echo %RMAI_UI_RULE%
echo %WT_MESSAGE%
echo.
echo PLEASE WAIT - no action is required from you right now.
echo RescueMeAI receives and reports normal results automatically.
echo To stop safely while Status says WAITING, press S once.
exit /b 0

:RESULT
rem result STATE MESSAGE EVIDENCE INSTRUCTION VERSION INTERNET
rem INSTRUCTION is retained for compatibility/reporting but normal result screens never require relay input.
set "R_STATE=%~2"
set "R_MESSAGE=%~3"
set "R_EVIDENCE=%~4"
set "R_VERSION=%~6"
set "R_INTERNET=%~7"
if not defined R_VERSION set "R_VERSION=UNKNOWN"
if not defined R_INTERNET set "R_INTERNET=UNKNOWN"
if not defined R_EVIDENCE set "R_EVIDENCE=None."
set "R_THEME=WARNING"
if /i "%R_STATE%"=="PASS" set "R_THEME=PASS"
if /i "%R_STATE%"=="FAIL" set "R_THEME=ERROR"
call :SETUP
call :DRAW_HEADER "%R_VERSION%" "%R_INTERNET%" "%R_STATE% - REPORTED AUTOMATICALLY" "NO NEW ACTION" "%RMAI_UI_DESC%" "%R_THEME%"
echo.
echo                              RESULT: %R_STATE%
echo %RMAI_UI_RULE%
echo.
echo WHAT HAPPENED
echo   %R_MESSAGE%
echo.
if /i not "%R_EVIDENCE%"=="None." (
  echo DETAILS
  echo   %R_EVIDENCE%
  echo.
)
echo WHAT YOU NEED TO DO
echo %RMAI_UI_RULE%
echo   NOTHING RIGHT NOW.
echo   This result was sent automatically to the recovery control channel.
echo   RescueMeAI will remain online and continue when the next validated command arrives.
echo.
echo WHAT HAPPENS NEXT
echo   PLEASE WAIT. The recovery workflow continues automatically.
echo   You only need to act if this screen explicitly says LOCAL ACTION REQUIRED
echo   or APPLICATION FAILURE / APP_FATAL.
echo.
echo SAFE STOP
echo   To intentionally stop RescueMeAI, wait until Status says WAITING and press S once.
echo   Do not close the window or press Ctrl+C while a command is running.
echo.
echo %RMAI_UI_BORDER%
exit /b 0

:LOCAL_ACTION
rem localaction VERSION INTERNET WINDOWS_CHANGE TITLE ACTION_TEXT REASON THEME
set "LA_VERSION=%~2"
set "LA_INTERNET=%~3"
set "LA_CHANGE=%~4"
set "LA_TITLE=%~5"
set "LA_ACTION=%~6"
set "LA_REASON=%~7"
set "LA_THEME=%~8"
if not defined LA_THEME set "LA_THEME=WARNING"
if not defined LA_TITLE set "LA_TITLE=LOCAL ACTION REQUIRED"
call :SETUP
call :DRAW_HEADER "%LA_VERSION%" "%LA_INTERNET%" "LOCAL ACTION REQUIRED" "%LA_CHANGE%" "%RMAI_UI_DESC%" "%LA_THEME%"
echo.
echo                         %LA_TITLE%
echo %RMAI_UI_RULE%
echo.
echo WHAT YOU NEED TO DO
echo   %LA_ACTION%
echo.
if defined LA_REASON (
  echo WHY THIS IS NEEDED
  echo   %LA_REASON%
  echo.
)
echo WHAT HAPPENS NEXT
echo   RescueMeAI will continue automatically when it can verify that the local action is complete.
echo   Do not type pass, fail, or warning unless this screen explicitly asks for text.
echo %RMAI_UI_BORDER%
exit /b 0

:LINE
echo(%~3
exit /b 0

:WRAP
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
