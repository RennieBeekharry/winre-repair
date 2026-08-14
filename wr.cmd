@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Persistent WinRE launcher. Prefer GitHub Contents API raw mode to avoid
rem stale raw.githubusercontent.com edge-cache responses.
set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0102-ET"
set "BUILD_TIME=2026-08-14 01:02 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "APIURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main"
set "RAWURL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/next.cmd?cb=%RANDOM%%RANDOM%%RANDOM%"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"

echo WR launcher: %LAUNCHER_VERSION%
echo Built:       %BUILD_TIME%

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

%WPEUTIL% InitializeNetwork >nul 2>&1

rem First choice: GitHub REST Contents API using raw media type. This avoids
rem dependence on the raw-content CDN cache. Public repository: no API key.
set "APIIP="
call :RESOLVE %APIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store" -H "Pragma: no-cache" "%APIURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE API
  if exist "%OUT%" goto :GOT
)

rem Second API attempt using normal DNS in case WinRE DNS is working now.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store" -H "Pragma: no-cache" "%APIURL%" -o "%TMP%"
if not errorlevel 1 call :VALIDATE API-DNS
if exist "%OUT%" goto :GOT

rem Last resort: raw.githubusercontent.com with cache-buster and no-cache
rem headers. Keep this only as a fallback transport.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
for %%I in (185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133) do (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "raw.githubusercontent.com:443:%%I" -H "Cache-Control: no-cache, no-store" -H "Pragma: no-cache" "%RAWURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE RAW
  if exist "%OUT%" goto :GOT
)

echo.
echo WR FAILED: Could not obtain a valid latest command file from GitHub.
exit /b 90

:GOT
echo Transport: !TRANSPORT!
for /f "tokens=2 delims==" %%V in ('%FINDSTR% /b /c:"set \"COMMAND_VERSION=" "%OUT%" 2^>nul') do set "FETCHEDVER=%%~V"
if defined FETCHEDVER echo Command:   !FETCHEDVER!
call "%OUT%"
exit /b %errorlevel%

:VALIDATE
set "TRANSPORT=%~1"
if not exist "%TMP%" exit /b 1
for %%Z in ("%TMP%") do if %%~zZ LSS 1024 exit /b 1
%FINDSTR% /b /l /c:"@echo off" "%TMP%" >nul 2>&1
if errorlevel 1 exit /b 1
%FINDSTR% /l /c:"COMMAND_VERSION=WR-" "%TMP%" >nul 2>&1
if errorlevel 1 exit /b 1
move /y "%TMP%" "%OUT%" >nul
exit /b 0

:RESOLVE
set "%~2="
set "CAND="
for /f "delims=" %%L in ('%NSLOOKUP% %~1 %DNS% 2^>nul ^| %FINDSTR% /R "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"') do (
  for %%T in (%%L) do set "CAND=%%T"
  if not "!CAND!"=="%DNS%" set "%~2=!CAND!"
)
exit /b 0
