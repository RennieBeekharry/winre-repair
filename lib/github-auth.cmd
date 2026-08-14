@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR-MODULE: github-auth 2026.08.14-1043-ET
if /i "%~1"=="authorize" goto :AUTHORIZE
if /i "%~1"=="upload" goto :UPLOAD
exit /b 64

:AUTHORIZE
call :RUN authorize
exit /b %errorlevel%

:UPLOAD
call :RUN upload
exit /b %errorlevel%

:RUN
set "WR_GA_MODE=%~1"
set "WR_GA_CONFIG=C:\WinRERepair\agent.cfg"
set "WR_GA_LOGREPO="
set "WR_GA_OAUTH_CLIENT_ID="
if exist "%WR_GA_CONFIG%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%WR_GA_CONFIG%") do (
    if /i "%%A"=="LOG_REPO" set "WR_GA_LOGREPO=%%B"
    if /i "%%A"=="OAUTH_CLIENT_ID" set "WR_GA_OAUTH_CLIENT_ID=%%B"
  )
)
if not defined WR_GA_LOGREPO exit /b 91
if not defined WR_GA_OAUTH_CLIENT_ID exit /b 91

echo(%WR_GA_LOGREPO%| findstr /r /x "[A-Za-z0-9_.-][A-Za-z0-9_.-]*/[A-Za-z0-9_.-][A-Za-z0-9_.-]*" >nul 2>&1
if errorlevel 1 exit /b 91
echo(%WR_GA_OAUTH_CLIENT_ID%| findstr /r /x "[A-Za-z0-9][A-Za-z0-9]*" >nul 2>&1
if errorlevel 1 exit /b 91

set "WR_GA_CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%WR_GA_CSCRIPT%" set "WR_GA_CSCRIPT=C:\Windows\System32\cscript.exe"
set "WR_GA_CURL=C:\Windows\System32\curl.exe"
set "WR_GA_NSLOOKUP=C:\Windows\System32\nslookup.exe"
set "WR_GA_HELPER=C:\WinRERepair\runtime\github-auth.js"
set "WR_GA_TOKEN=C:\WinRERepair\.auth\github-logs.token"
set "WR_GA_REPORT=C:\WinRERepair\LAST_RUN_REPORT.txt"
set "WR_GA_DETAILS=C:\WinRERepair\RUN_DETAILS.txt"
if not exist "%WR_GA_CSCRIPT%" exit /b 91
if not exist "%WR_GA_HELPER%" exit /b 91
if not exist "C:\WinRERepair\.auth" md "C:\WinRERepair\.auth" >nul 2>&1
"%WR_GA_CSCRIPT%" //nologo "%WR_GA_HELPER%" "%WR_GA_MODE%" "%WR_GA_CURL%" "%WR_GA_NSLOOKUP%" "64.71.255.204" "C:\WinRERepair" "%WR_GA_LOGREPO%" "%WR_GA_TOKEN%" "%WR_GA_REPORT%" "%WR_GA_DETAILS%" "%WR_GA_OAUTH_CLIENT_ID%"
exit /b %errorlevel%
