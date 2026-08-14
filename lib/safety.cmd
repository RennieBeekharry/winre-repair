@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem WR-MODULE: safety 2026.08.14-1524-ET
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
set "WR_SAFE_STATE=C:\WinRERepair\SAFETY_STATE.txt"

if not exist "%WR_SAFE_SCRIPT%" call :FAIL 90 "Command file does not exist."

rem Parse metadata directly from the command file. This avoids WinRE FINDSTR/FOR
rem interaction differences seen with the previous parser.
for /f "usebackq tokens=1,* delims==" %%A in ("%WR_SAFE_SCRIPT%") do (
  if /i "%%A"=="rem WR_RISK" set "WR_SAFE_META_RISK=%%B"
  if /i "%%A"=="rem WR_LOCAL_AUTH" set "WR_SAFE_LOCAL_AUTH=%%B"
  if /i "%%A"=="rem WR_SUMMARY" set "WR_SAFE_SUMMARY=%%B"
  if /i "%%A"=="rem WR_ACTION" set "WR_SAFE_ACTION=%%B"
  if /i "%%A"=="rem WR_TARGET" set "WR_SAFE_TARGET_DESC=%%B"
  if /i "%%A"=="rem WR_CONSEQUENCE" set "WR_SAFE_CONSEQUENCE=%%B"
  if /i "%%A"=="rem WR_ROLLBACK" set "WR_SAFE_ROLLBACK=%%B"
)

if not defined WR_SAFE_META_RISK call :FAIL 93 "Missing WR_RISK metadata."
if not defined WR_SAFE_SUMMARY call :FAIL 93 "Missing WR_SUMMARY metadata."
if not defined WR_SAFE_ACTION call :FAIL 93 "Missing WR_ACTION metadata."
if not defined WR_SAFE_TARGET_DESC call :FAIL 93 "Missing WR_TARGET metadata."
if not defined WR_SAFE_CONSEQUENCE call :FAIL 93 "Missing WR_CONSEQUENCE metadata."
if not defined WR_SAFE_ROLLBACK call :FAIL 93 "Missing WR_ROLLBACK metadata."

if /i not "%WR_SAFE_META_RISK%"=="READ_ONLY" if /i not "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" if /i not "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" call :FAIL 93 "Invalid script risk metadata: %WR_SAFE_META_RISK%"
if /i not "%WR_SAFE_QUEUE_RISK%"=="READ_ONLY" if /i not "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" if /i not "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" call :FAIL 93 "Invalid queue risk metadata: %WR_SAFE_QUEUE_RISK%"

findstr /i /c:"diskpart" /c:"format " /c:"delete partition" /c:"create partition" /c:"convert gpt" /c:"convert mbr" /c:"dism /apply-image" /c:"dism.exe /apply-image" /c:"systemreset" /c:"reset this pc" /c:"bcdedit /delete" /c:"reg delete" /c:"cipher /w" /c:"wbadmin delete" /c:"manage-bde -off" "%WR_SAFE_SCRIPT%" >nul 2>&1
if not errorlevel 1 set "WR_SAFE_SCAN_DESTRUCTIVE=YES"

set "WR_SAFE_EFFECTIVE=READ_ONLY"
if /i "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"

if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" call :FAIL 94 "Local scan detected destructive content but queue risk was lower."
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" call :FAIL 94 "Local scan detected destructive content but script risk was lower."

if /i not "%WR_SAFE_EFFECTIVE%"=="DESTRUCTIVE" (
  >"%WR_SAFE_STATE%" echo status=PASS
  >>"%WR_SAFE_STATE%" echo effective_risk=%WR_SAFE_EFFECTIVE%
  >>"%WR_SAFE_STATE%" echo command_id=%WR_SAFE_COMMAND_ID%
  exit /b 0
)

if "%WR_SAFE_TARGET%"=="*" call :FAIL 95 "Destructive request used wildcard target."
if /i not "%WR_SAFE_TARGET%"=="%WR_SAFE_AGENT%" call :FAIL 95 "Destructive request targets a different agent."
if /i not "%WR_SAFE_LOCAL_AUTH%"=="REQUIRED" call :FAIL 95 "Destructive request did not require local authorization."

set "WR_SAFE_SUFFIX=%WR_SAFE_AGENT:~-6%"
set "WR_SAFE_PHRASE=AUTHORIZE DESTRUCTIVE %WR_SAFE_COMMAND_ID% %WR_SAFE_SUFFIX%"
cls
color 0E >nul 2>&1
echo ================================================================
echo [WARNING] LOCAL DESTRUCTIVE AUTHORIZATION REQUIRED
echo ================================================================
echo Command ID : %WR_SAFE_COMMAND_ID%
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
  >"%WR_SAFE_STATE%" echo status=WARNING
  >>"%WR_SAFE_STATE%" echo reason=Local destructive authorization was not provided.
  exit /b 40
)

if not exist "C:\WinRERepair\approvals" md "C:\WinRERepair\approvals" >nul 2>&1
>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo authorization=LOCAL_TYPED
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo command_id=%WR_SAFE_COMMAND_ID%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo agent_id=%WR_SAFE_AGENT%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo action=%WR_SAFE_ACTION%
>>"C:\WinRERepair\approvals\command-%WR_SAFE_COMMAND_ID%.txt" echo target=%WR_SAFE_TARGET_DESC%
>"%WR_SAFE_STATE%" echo status=PASS
>>"%WR_SAFE_STATE%" echo effective_risk=DESTRUCTIVE
>>"%WR_SAFE_STATE%" echo authorization=LOCAL_TYPED
exit /b 0

:FAIL
>"%WR_SAFE_STATE%" echo status=FAIL
>>"%WR_SAFE_STATE%" echo return_code=%~1
>>"%WR_SAFE_STATE%" echo reason=%~2
exit /b %~1
