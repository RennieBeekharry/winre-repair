@echo off
setlocal EnableExtensions
title RescueMeAI - Reconnect

set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime\device-agent-v2.cmd"
set "CONFIG=%WORK%\agent.cfg"
set "TOKEN=%WORK%\.auth\github-logs.token"
set "CURL=C:\Windows\System32\curl.exe"
set "WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WPE%" set "WPE=wpeutil.exe"

echo ================================================================
echo RescueMeAI - QUICK RECONNECT
echo ================================================================
echo This file reuses the existing local RescueMeAI session and
echo credential when available. No inbound remote shell is opened.
echo ================================================================

"%WPE%" InitializeNetwork >nul 2>&1

if exist "%RUNTIME%" if exist "%CONFIG%" if exist "%TOKEN%" (
  echo Reusing existing RescueMeAI session...
  call "%RUNTIME%"
  exit /b %errorlevel%
)

echo Existing session runtime is incomplete. Starting secure bootstrap...
if not exist "%CURL%" (
  echo [FAIL] curl.exe is unavailable at %CURL%.
  exit /b 90
)
"%CURL%" --ssl-no-revoke -fL "https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/connect-device-v3.cmd" -o "%WORK%\reconnect-bootstrap.cmd"
if errorlevel 1 (
  echo [FAIL] Could not download the RescueMeAI bootstrap.
  exit /b 90
)
call "%WORK%\reconnect-bootstrap.cmd"
exit /b %errorlevel%
