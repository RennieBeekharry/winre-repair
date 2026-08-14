@echo off
rem WR-MODULE: ui 2026.08.14-0948-ET
if /i "%~1"=="header" goto :HEADER
if /i "%~1"=="result" goto :RESULT
if /i "%~1"=="note" goto :NOTE
exit /b 64

:HEADER
color 07 >nul 2>&1
cls
echo ================================================================
echo %~2
if not "%~3"=="" echo Version: %~3
if not "%~4"=="" echo %~4
echo ================================================================
exit /b 0

:NOTE
echo %~2
exit /b 0

:RESULT
set "WR_UI_STATE=%~2"
set "WR_UI_MESSAGE=%~3"
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
color %WR_UI_COLOR% >nul 2>&1
echo.
echo ================================================================
echo [%WR_UI_STATE%] WINRE-REPAIR RESULT
echo ================================================================
echo %WR_UI_MESSAGE%
echo ---------------------------------------------------------------
echo Reply to ChatGPT with one word only: %WR_UI_REPLY%
echo ================================================================
exit /b 0
