@echo off
rem WR-MODULE: ui 2026.08.14-1015-ET
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
set "WR_UI_EVIDENCE=%~4"
set "WR_UI_INSTRUCTION=%~5"
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
if not defined WR_UI_EVIDENCE set "WR_UI_EVIDENCE=None."
if not defined WR_UI_INSTRUCTION set "WR_UI_INSTRUCTION=Follow the instruction shown by AI Recovery."
color %WR_UI_COLOR% >nul 2>&1
echo.
echo ================================================================
echo [%WR_UI_STATE%] AI RECOVERY RESULT
echo ================================================================
echo RESULT:
echo   %WR_UI_MESSAGE%
echo.
echo WHAT YOU SHOULD DO:
echo   Reply to AI Recovery with exactly: %WR_UI_REPLY%
echo.
echo ADDITIONAL INFORMATION REQUIRED:
echo   %WR_UI_EVIDENCE%
echo.
echo ADDITIONAL INSTRUCTIONS:
echo   %WR_UI_INSTRUCTION%
echo ---------------------------------------------------------------
echo Do not rerun commands unless AI Recovery explicitly asks you to.
echo ================================================================
exit /b 0
