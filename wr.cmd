@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Persistent WinRE launcher.
rem - Checks connectivity before doing anything else.
rem - Restores WinRE networking only when connectivity is missing.
rem - Prefers GitHub Contents API raw mode to avoid stale raw CDN responses.
set "LAUNCHER_VERSION=WR-LAUNCHER-2026.08.14-0108-ET"
set "BUILD_TIME=2026-08-14 01:08 ET"
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "IPCONFIG=X:\Windows\System32\ipconfig.exe"
set "PING=X:\Windows\System32\ping.exe"
set "NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DNS=64.71.255.204"
set "APIHOST=api.github.com"
set "APIURL=https://api.github.com/repos/RennieBeekharry/winre-repair/contents/next.cmd?ref=main&cb=%RANDOM%%RANDOM%%RANDOM%"
set "RAWURL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/next.cmd?cb=%RANDOM%%RANDOM%%RANDOM%"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"

echo ================================================================
echo WINRE-REPAIR LAUNCHER
echo Version: %LAUNCHER_VERSION%
echo Built:   %BUILD_TIME%
echo ================================================================

if not exist "%CURL%" (
  echo WR FAILED: curl.exe was not found at %CURL%.
  exit /b 91
)

rem ---------------------------------------------------------------
rem NETWORK GUARD
rem A reboot normally tears down WinRE networking. If Internet already
rem works, leave it alone. Otherwise initialize WinRE networking, renew
rem DHCP, wait briefly, and retry before contacting GitHub.
rem ---------------------------------------------------------------
call :CHECKNET
if not errorlevel 1 (
  echo Internet: connected
  goto :NETREADY
)

echo Internet: not detected - restoring WinRE networking...
%WPEUTIL% InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
%PING% -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 (
  echo Internet: restored
  goto :NETREADY
)

rem One bounded retry. Do not loop forever if DHCP/network hardware is down.
echo Internet: first recovery attempt did not verify - retrying once...
%WPEUTIL% InitializeNetwork >nul 2>&1
if exist "%IPCONFIG%" "%IPCONFIG%" /renew >nul 2>&1
%PING% -n 4 127.0.0.1 >nul 2>&1
call :CHECKNET
if not errorlevel 1 (
  echo Internet: restored on retry
  goto :NETREADY
)

echo Internet: probe still unavailable; trying GitHub transport directly.

:NETREADY
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

rem First choice: GitHub REST Contents API using raw media type. Public repo,
rem so no token or embedded secret is required.
set "APIIP="
call :RESOLVE %APIHOST% APIIP
if defined APIIP (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "%APIHOST%:443:!APIIP!" -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%APIURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE API
  if exist "%OUT%" goto :GOT
)

rem Second API attempt using normal DNS if WinRE DNS is currently healthy.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
"%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 -H "Accept: application/vnd.github.raw+json" -H "X-GitHub-Api-Version: 2026-03-10" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%APIURL%" -o "%TMP%"
if not errorlevel 1 call :VALIDATE API-DNS
if exist "%OUT%" goto :GOT

rem Last resort: raw.githubusercontent.com with known GitHub IPs.
if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
for %%I in (185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133) do (
  "%CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 10 --max-time 120 --resolve "raw.githubusercontent.com:443:%%I" -H "Cache-Control: no-cache, no-store, max-age=0" -H "Pragma: no-cache" "%RAWURL%" -o "%TMP%"
  if not errorlevel 1 call :VALIDATE RAW
  if exist "%OUT%" goto :GOT
)

echo.
echo WR FAILED: Internet/GitHub transport could not be restored.
echo No repair command was executed.
exit /b 90

:GOT
echo Transport: !TRANSPORT!
for /f "tokens=2 delims==" %%V in ('%FINDSTR% /b /c:"set \"COMMAND_VERSION=" "%OUT%" 2^>nul') do set "FETCHEDVER=%%~V"
if defined FETCHEDVER echo Command:   !FETCHEDVER!
call "%OUT%"
exit /b %errorlevel%

:CHECKNET
rem Use two public IP probes so broken DNS does not look like lost Internet.
%PING% -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
%PING% -n 1 -w 2000 8.8.8.8 >nul 2>&1
if not errorlevel 1 exit /b 0
exit /b 1

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
