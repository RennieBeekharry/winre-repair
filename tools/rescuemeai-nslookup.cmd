@echo off
setlocal EnableExtensions
rem WR-MODULE: rescuemeai-nslookup 2026.08.14-1600-ET
set "HOST=%~1"
set "IP="
call "C:\WinRERepair\runtime\resolve.cmd" resolve "%HOST%" IP >nul 2>&1
if errorlevel 1 exit /b 1
if not defined IP exit /b 1
echo Name: %HOST%
echo Address: %IP%
exit /b 0
