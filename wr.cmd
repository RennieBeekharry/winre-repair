@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0348-ET"
set "BUILD_TIME=2026-08-14 03:48 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "URL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" exit /b 91
"%PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if errorlevel 1 "%WPEUTIL%" InitializeNetwork >nul 2>&1

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

set "APIIP="
for /f "delims=" %%L in ('"%NSLOOKUP%" %APIHOST% %DNS% 2^>nul ^| "%FINDSTR%" /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "APIIP=!CAND!"
)

if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%URL%" -o "%TMP%"
)
if not exist "%TMP%" (
  echo WR FAILED: could not download the current command.
  exit /b 90
)
"%FINDSTR%" /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 (
  echo WR FAILED: downloaded command did not validate.
  del /f /q "%TMP%" >nul 2>&1
  exit /b 90
)
move /y "%TMP%" "%OUT%" >nul
call "%OUT%"
exit /b %errorlevel%
