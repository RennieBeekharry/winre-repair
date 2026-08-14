@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: ui 2026.08.14-1818-ET
rem RescueMeAI WinRE console renderer v3.
rem Centralize operator-readable status, roadmap, readiness and progress output.

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
rem VERSION INTERNET STATUS WINDOWS_CHANGE DESCRIPTION THEME
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
rem screen VERSION INTERNET STATUS WINDOWS_CHANGE DESCRIPTION THEME
call :SETUP
call :DRAW_HEADER "%~2" "%~3" "%~4" "%~5" "%~6" "%~7"
exit /b 0

:MAKE_BAR
rem MAKE_BAR integer-percent 0..100; returns RMAI_BAR within this process.
set "RMAI_BAR_PERCENT=%~1"
set /a RMAI_BAR_PERCENT+=0 2>nul
if %RMAI_BAR_PERCENT% LSS 0 set "RMAI_BAR_PERCENT=0"
if %RMAI_BAR_PERCENT% GTR 100 set "RMAI_BAR_PERCENT=100"
set /a RMAI_BAR_FILLED=RMAI_BAR_PERCENT/5
set /a RMAI_BAR_REMAIN=20-RMAI_BAR_FILLED
set "RMAI_BAR_FULL=####################"
set "RMAI_BAR_EMPTY=--------------------"
set "RMAI_BAR=!RMAI_BAR_FULL:~0,%RMAI_BAR_FILLED%!!RMAI_BAR_EMPTY:~0,%RMAI_BAR_REMAIN%!"
exit /b 0

:ROADMAP
rem roadmap CURRENT_STAGE [ESTIMATED_PERCENT]
set "RM_STAGE=%~2"
set "RM_PERCENT=%~3"
if not defined RM_STAGE set "RM_STAGE=1"
set /a RM_STAGE+=0 2>nul
if %RM_STAGE% LSS 1 set "RM_STAGE=1"
if %RM_STAGE% GTR 10 set "RM_STAGE=10"
if not defined RM_PERCENT set /a RM_PERCENT=RM_STAGE*10
set /a RM_PERCENT+=0 2>nul
call :MAKE_BAR "%RM_PERCENT%"
set "RM_NEXT=%RM_STAGE%"
set /a RM_NEXT+=1
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
rem readiness BACKUP_STATUS MEDIA_STATUS WINDOWS_CHANGE [REASON]
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
rem progress TASK PERCENT UNITS DATA SPEED ELAPSED ETA
set "PG_TASK=%~2"
set "PG_PERCENT=%~3"
set "PG_UNITS=%~4"
set "PG_DATA=%~5"
set "PG_SPEED=%~6"
set "PG_ELAPSED=%~7"
set "PG_ETA=%~8"
if not defined PG_TASK set "PG_TASK=Recovery operation"
if not defined PG_PERCENT set "PG_PERCENT=-1"
if not defined PG_ELAPSED set "PG_ELAPSED=Not available"
if not defined PG_ETA set "PG_ETA=Not available yet - result dependent"
echo.
echo CURRENT TASK
echo %RMAI_UI_RULE%
echo %PG_TASK%
set /a PG_NUM=%PG_PERCENT%+0 2>nul
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
rem working [MESSAGE]
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
rem waiting [MESSAGE]
set "WT_MESSAGE=%~2"
if not defined WT_MESSAGE set "WT_MESSAGE=RescueMeAI is online and waiting for the next recovery instruction."
echo.
echo AGENT STATE: ONLINE / WAITING
echo %RMAI_UI_RULE%
echo %WT_MESSAGE%
echo.
echo PLEASE WAIT - no action is required from you right now.
echo To stop safely while Status says WAITING, press S once.
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
if not defined R_INSTRUCTION set "R_INSTRUCTION=See the action required below."
set "R_THEME=WARNING"
if /i "%R_STATE%"=="PASS" set "R_THEME=PASS"
if /i "%R_STATE%"=="FAIL" set "R_THEME=ERROR"
set "R_REPLY=warning"
if /i "%R_STATE%"=="PASS" set "R_REPLY=pass"
if /i "%R_STATE%"=="FAIL" set "R_REPLY=fail"
call :SETUP
call :DRAW_HEADER "%R_VERSION%" "%R_INTERNET%" "ACTION REQUIRED - %R_STATE%" "NO NEW ACTION" "%RMAI_UI_DESC%" "%R_THEME%"
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
echo                              ACTION REQUIRED
echo %RMAI_UI_RULE%
echo.
echo   On your phone, return to this ChatGPT conversation and send exactly:
echo.
echo                                %R_REPLY%
echo.
echo   Then leave this PC window open. RescueMeAI will stay online and wait
echo   for the next recovery instruction from ChatGPT.
echo.
echo WHAT HAPPENS NEXT
echo   After you send %R_REPLY%, ChatGPT will review the private report and prepare
echo   the next recovery step. You do not need to run C:\wr.cmd again.
echo.
echo AGENT STATE
echo   RescueMeAI remains online. After reporting this result it waits safely
echo   for the next validated recovery instruction.
echo.
echo SAFE STOP
echo   If you intentionally want to stop RescueMeAI, wait until Status says WAITING,
echo   then press S once. Do not close the window or press Ctrl+C during a command.
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
