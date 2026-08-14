@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: runtime-sync 2026.08.14-1030-ET

set "MODE=%~1"
set "REPO=%~2"
set "REF=%~3"
if not defined REPO set "REPO=RennieBeekharry/winre-repair"
if not defined REF set "REF=main"
set "WORK=C:\WinRERepair"
set "RUNTIME=%WORK%\runtime"
set "CURL=C:\Windows\System32\curl.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "BASE=https://api.github.com/repos/%REPO%/contents"

if not exist "%CURL%" exit /b 91
if not exist "%FINDSTR%" exit /b 91
if not exist "%RUNTIME%" md "%RUNTIME%" >nul 2>&1

call :GET "lib/ui.cmd" "ui.cmd" "WR-MODULE: ui" || exit /b 90
call :GET "lib/network.cmd" "network.cmd" "WR-MODULE: network" || exit /b 90
call :GET "lib/reporting.cmd" "reporting.cmd" "WR-MODULE: reporting" || exit /b 90
call :GET "lib/github-auth.cmd" "github-auth.cmd" "WR-MODULE: github-auth" || exit /b 90
call :GET "lib/github-auth.js" "github-auth.js" "WR-MODULE: github-auth-js" || exit /b 90
call :GET "lib/safety.cmd" "safety.cmd" "WR-MODULE: safety" || exit /b 90
if /i "%MODE%"=="agent" (
  call :GET "lib/agent-core.js" "agent-core.js" "WR-MODULE: agent-core-js" || exit /b 90
)
exit /b 0

:GET
set "SRC=%~1"
set "DEST=%RUNTIME%\%~2"
set "MARK=%~3"
set "TMP=%DEST%.tmp"
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%BASE%/%SRC%?ref=%REF%" -o "%TMP%"
if errorlevel 1 exit /b 1
if not exist "%TMP%" exit /b 1
"%FINDSTR%" /i /c:"%MARK%" "%TMP%" >nul 2>&1
if errorlevel 1 (
  del /f /q "%TMP%" >nul 2>&1
  exit /b 1
)
move /y "%TMP%" "%DEST%" >nul
exit /b 0
