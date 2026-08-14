@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: network 2026.08.14-1550-ET
if /i "%~1"=="ensure" goto :ENSURE
if /i "%~1"=="fetch" goto :FETCH
exit /b 64

:ENSURE
set "WR_NET_PING=X:\Windows\System32\ping.exe"
set "WR_NET_WPE=X:\Windows\System32\wpeutil.exe"
if not exist "%WR_NET_PING%" exit /b 91
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
set "WR_NET_FINDSTR=C:\Windows\System32\findstr.exe"
set "WR_NET_RESOLVER=C:\WinRERepair\runtime\resolve.cmd"
set "WR_NET_TOKENFILE=C:\WinRERepair\.auth\github-logs.token"
set "WR_NET_HOST="
set "WR_NET_IP="
set "WR_NET_TOKEN="
if not exist "%WR_NET_CURL%" exit /b 91
if not exist "%WR_NET_RESOLVER%" exit /b 91
if exist "%WR_NET_OUT%" del /f /q "%WR_NET_OUT%" >nul 2>&1

echo(%WR_NET_URL%| "%WR_NET_FINDSTR%" /i /c:"https://api.github.com/" >nul 2>&1
if not errorlevel 1 set "WR_NET_HOST=api.github.com"
echo(%WR_NET_URL%| "%WR_NET_FINDSTR%" /i /c:"https://github.com/" >nul 2>&1
if not errorlevel 1 set "WR_NET_HOST=github.com"

if defined WR_NET_HOST (
  call "%WR_NET_RESOLVER%" resolve "%WR_NET_HOST%" WR_NET_IP
  if errorlevel 1 exit /b 92
)

if /i "%WR_NET_HOST%"=="api.github.com" if exist "%WR_NET_TOKENFILE%" set /p "WR_NET_TOKEN="<"%WR_NET_TOKENFILE%"

if defined WR_NET_IP (
  if defined WR_NET_TOKEN (
    "%WR_NET_CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%WR_NET_HOST%:443:%WR_NET_IP%" -H "Accept: application/vnd.github.raw+json" -H "Authorization: Bearer !WR_NET_TOKEN!" -H "X-GitHub-Api-Version: 2022-11-28" -H "Cache-Control: no-cache, no-store, max-age=0" "%WR_NET_URL%" -o "%WR_NET_OUT%"
  ) else (
    "%WR_NET_CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 --resolve "%WR_NET_HOST%:443:%WR_NET_IP%" -H "Accept: application/vnd.github.raw+json" -H "Cache-Control: no-cache, no-store, max-age=0" "%WR_NET_URL%" -o "%WR_NET_OUT%"
  )
) else (
  "%WR_NET_CURL%" --ssl-no-revoke --fail --location --silent --show-error --connect-timeout 15 --max-time 180 -H "Cache-Control: no-cache, no-store, max-age=0" "%WR_NET_URL%" -o "%WR_NET_OUT%"
)
if errorlevel 1 exit /b 90
if not exist "%WR_NET_OUT%" exit /b 90
for %%Z in ("%WR_NET_OUT%") do if %%~zZ LSS 8 exit /b 90
exit /b 0
