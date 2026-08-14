@echo off
setlocal EnableExtensions
rem WR-MODULE: rescuemeai-nslookup 2026.08.14-1609-ET
set "HOST=%~1"
set "CURL=C:\Windows\System32\curl.exe"
set "CSCRIPT=X:\Windows\System32\cscript.exe"
if not exist "%CSCRIPT%" set "CSCRIPT=C:\Windows\System32\cscript.exe"
set "HELPER=C:\WinRERepair\media\doh-resolve.js"
if not exist "%CURL%" exit /b 1
if not exist "%CSCRIPT%" exit /b 1
if not exist "%HELPER%" exit /b 1
"%CSCRIPT%" //nologo "%HELPER%" "%CURL%" "%HOST%"
exit /b %errorlevel%
