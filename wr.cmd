@echo off
setlocal EnableExtensions
set "CURL=C:\Windows\System32\curl.exe"
set "WPEUTIL=X:\Windows\System32\wpeutil.exe"
set "URL=https://raw.githubusercontent.com/RennieBeekharry/winre-repair/main/next.cmd?cb=%RANDOM%%RANDOM%"
set "OUT=X:\next.cmd"
set "TMP=X:\next.cmd.tmp"

if exist "%TMP%" del /f /q "%TMP%" >nul 2>&1
if exist "%OUT%" del /f /q "%OUT%" >nul 2>&1

%WPEUTIL% InitializeNetwork >nul 2>&1

for %%I in (185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133) do (
  "%CURL%" --ssl-no-revoke --fail --silent --show-error --connect-timeout 10 --max-time 120 --resolve "raw.githubusercontent.com:443:%%I" "%URL%" -o "%TMP%"
  if not errorlevel 1 goto :GOT
)

echo.
echo WR FAILED: Could not download the latest command file from GitHub.
exit /b 90

:GOT
move /y "%TMP%" "%OUT%" >nul
call "%OUT%"
exit /b %errorlevel%
