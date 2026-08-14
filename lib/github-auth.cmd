@echo off
rem WR-MODULE: github-auth 2026.08.14-0948-ET
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
"%WR_GA_CSCRIPT%" //nologo "%WR_GA_HELPER%" "%WR_GA_MODE%" "%WR_GA_CURL%" "%WR_GA_NSLOOKUP%" "64.71.255.204" "C:\WinRERepair" "RennieBeekharry/winre-repair-logs" "%WR_GA_TOKEN%" "%WR_GA_REPORT%" "%WR_GA_DETAILS%"
exit /b %errorlevel%
