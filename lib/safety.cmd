@echo off
rem WR-MODULE: safety 2026.08.14-1010-ET
rem Local policy is authoritative. Remote metadata may increase risk, never reduce it.
if /i "%~1"=="evaluate" goto :EVALUATE
exit /b 64

:EVALUATE
set "WR_SAFE_SCRIPT=%~2"
set "WR_SAFE_QUEUE_RISK=%~3"
set "WR_SAFE_COMMAND_ID=%~4"
set "WR_SAFE_TARGET=%~5"
set "WR_SAFE_AGENT=%~6"
set "WR_SAFE_META_RISK="
set "WR_SAFE_LOCAL_AUTH="
set "WR_SAFE_SUMMARY="
set "WR_SAFE_ACTION="
set "WR_SAFE_TARGET_DESC="
set "WR_SAFE_CONSEQUENCE="
set "WR_SAFE_ROLLBACK="
set "WR_SAFE_EFFECTIVE="
set "WR_SAFE_SCAN_DESTRUCTIVE=NO"

if not exist "%WR_SAFE_SCRIPT%" exit /b 90

for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_RISK=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_META_RISK=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_LOCAL_AUTH=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_LOCAL_AUTH=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_SUMMARY=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_SUMMARY=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_ACTION=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_ACTION=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_TARGET=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_TARGET_DESC=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_CONSEQUENCE=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_CONSEQUENCE=%%B"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /c:"rem WR_ROLLBACK=" "%WR_SAFE_SCRIPT%" 2^>nul') do set "WR_SAFE_ROLLBACK=%%B"

if not defined WR_SAFE_META_RISK exit /b 93
if not defined WR_SAFE_SUMMARY exit /b 93
if not defined WR_SAFE_ACTION exit /b 93
if not defined WR_SAFE_TARGET_DESC exit /b 93
if not defined WR_SAFE_CONSEQUENCE exit /b 93
if not defined WR_SAFE_ROLLBACK exit /b 93

if /i not "%WR_SAFE_META_RISK%"=="READ_ONLY" if /i not "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" if /i not "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" exit /b 93
if /i not "%WR_SAFE_QUEUE_RISK%"=="READ_ONLY" if /i not "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" if /i not "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" exit /b 93

rem Conservative static scan. A match can only upgrade risk to DESTRUCTIVE.
findstr /i /c:"diskpart" /c:"format " /c:"delete partition" /c:"create partition" /c:"convert gpt" /c:"convert mbr" /c:"dism /apply-image" /c:"dism.exe /apply-image" /c:"systemreset" /c:"reset this pc" /c:"bcdedit /delete" /c:"reg delete" /c:"cipher /w" /c:"wbadmin delete" /c:"manage-bde -off" "%WR_SAFE_SCRIPT%" >nul 2>&1
if not errorlevel 1 set "WR_SAFE_SCAN_DESTRUCTIVE=YES"

set "WR_SAFE_EFFECTIVE=READ_ONLY"
if /i "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"

rem If local scanning discovers destructive behavior that either remote queue or
rem script metadata tried to classify lower, fail closed rather than prompting.
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" exit /b 94
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" exit /b 94

if /i not "%WR_SAFE_EFFECTIVE%"=="DESTRUCTIVE" exit /b 0

rem Destructive requests may never use a wildcard target and must explicitly
rem opt in to the local authorization boundary.
if "%WR_SAFE_TARGET%"=="*" exit /b 95
if /i not "%WR_SAFE_TARGET%"=="%WR_SAFE_AGENT%" exit /b 95
if /i not "%WR_SAFE_LOCAL_AUTH%"=="REQUIRED" exit /b 95

set "WR_SAFE_SUFFIX=%WR_SAFE_AGENT:~-6%"
set "WR_SAFE_PHRASE=AUTHORIZE DESTRUCTIVE %WR_SAFE_COMMAND_ID% %WR_SAFE_SUFFIX%"
cls
color 0E >nul 2>&1
echo ================================================================
echo [WARNING] LOCAL DESTRUCTIVE AUTHORIZATION REQUIRED
echo ================================================================
echo Command ID : %WR_SAFE_COMMAND_ID%
echo Agent      : %WR_SAFE_AGENT%
echo Action     : %WR_SAFE_ACTION%
echo Target     : %WR_SAFE_TARGET_DESC%
echo ---------------------------------------------------------------
echo Proposed action:
echo   %WR_SAFE_SUMMARY%
echo.
echo Consequence / risk:
echo   %WR_SAFE_CONSEQUENCE%
echo.
echo Rollback limits:
echo   %WR_SAFE_ROLLBACK%
echo ---------------------------------------------------------------
echo GitHub and ChatGPT CANNOT approve this step for you.
echo Nothing destructive runs unless you type EXACTLY:
echo.
echo   %WR_SAFE_PHRASE%
echo.
set "WR_SAFE_TYPED="
set /p "WR_SAFE_TYPED=Authorization: "
if not "%WR_SAFE_TYPED%"=="%WR_SAFE_PHRASE%" (
  color 0E >nul 2>&1
  echo.
  echo [WARNING] Authorization not provided. Command blocked.
  exit /b 40
)

if not exist "C:\WinRERepair\approvals" md "C:\WinRERepair\approvals" >nul 2>&1
>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo authorization=LOCAL_TYPED
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo command_id=%WR_SAFE_COMMAND_ID%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo agent_id=%WR_SAFE_AGENT%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo action=%WR_SAFE_ACTION%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo target=%WR_SAFE_TARGET_DESC%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo date=%date%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo time=%time%
exit /b 0
