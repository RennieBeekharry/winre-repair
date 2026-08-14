@echo off
rem WR-MODULE: network 2026.08.14-0948-ET
if /i "%~1"=="ensure" goto :ENSURE
if /i "%~1"=="fetch" goto :FETCH
exit /b 64

:ENSURE
set "WR_NET_PING=X:\Windows\System32\ping.exe"
set "WR_NET_WPE=X:\Windows\System32\wpeutil.exe"
"%WR_NET_PING%" -n 1 -w 2000 1.1.1.1 >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "%WR_NET_WPE%" "%WR_NET_WPE%" InitializeNetwork >nul 2>&1
"%WR_NET_PING%" -n 1 -w 3000 1.1.1.1 >nul 2>&1
if errorlevel 1 exit /b 92
exit /b 0

:FETCH
set "WR_NET_URL=%~2"
set "WR_NET_OUT=%~3"
set "WR_NET_CURL=C:\Windows\System32\curl.exe"
if not exist "%WR_NET_CURL%" exit /b 91
if exist "%WR_NET_OUT%" del /f /q "%WR_NET_OUT%" >nul 2>&1
"%WR_NET_CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%WR_NET_URL%" -o "%WR_NET_OUT%"
if errorlevel 1 exit /b 90
if not exist "%WR_NET_OUT%" exit /b 90
for %%Z in ("%WR_NET_OUT%") do if %%~zZ LSS 8 exit /b 90
exit /b 0
