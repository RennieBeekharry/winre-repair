@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem WR-MODULE: safety 2026.08.14-1527-ET
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
set "WR_SAFE_FAIL_REASON="

if not exist "%WR_SAFE_SCRIPT%" (
  set "WR_SAFE_FAIL_REASON=Command file does not exist."
  goto :FAIL90
)

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

if not defined WR_SAFE_META_RISK (
  set "WR_SAFE_FAIL_REASON=Missing WR_RISK metadata."
  goto :FAIL93
)
if not defined WR_SAFE_SUMMARY (
  set "WR_SAFE_FAIL_REASON=Missing WR_SUMMARY metadata."
  goto :FAIL93
)
if not defined WR_SAFE_ACTION (
  set "WR_SAFE_FAIL_REASON=Missing WR_ACTION metadata."
  goto :FAIL93
)
if not defined WR_SAFE_TARGET_DESC (
  set "WR_SAFE_FAIL_REASON=Missing WR_TARGET metadata."
  goto :FAIL93
)
if not defined WR_SAFE_CONSEQUENCE (
  set "WR_SAFE_FAIL_REASON=Missing WR_CONSEQUENCE metadata."
  goto :FAIL93
)
if not defined WR_SAFE_ROLLBACK (
  set "WR_SAFE_FAIL_REASON=Missing WR_ROLLBACK metadata."
  goto :FAIL93
)

if /i "%WR_SAFE_META_RISK%"=="READ_ONLY" goto :META_RISK_OK
if /i "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" goto :META_RISK_OK
if /i "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" goto :META_RISK_OK
set "WR_SAFE_FAIL_REASON=Invalid script risk metadata: %WR_SAFE_META_RISK%"
goto :FAIL93

:META_RISK_OK
if /i "%WR_SAFE_QUEUE_RISK%"=="READ_ONLY" goto :QUEUE_RISK_OK
if /i "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" goto :QUEUE_RISK_OK
if /i "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" goto :QUEUE_RISK_OK
set "WR_SAFE_FAIL_REASON=Invalid queue risk metadata: %WR_SAFE_QUEUE_RISK%"
goto :FAIL93

:QUEUE_RISK_OK
findstr /i /c:"diskpart" /c:"format " /c:"delete partition" /c:"create partition" /c:"convert gpt" /c:"convert mbr" /c:"dism /apply-image" /c:"dism.exe /apply-image" /c:"systemreset" /c:"reset this pc" /c:"bcdedit /delete" /c:"reg delete" /c:"cipher /w" /c:"wbadmin delete" /c:"manage-bde -off" "%WR_SAFE_SCRIPT%" >nul 2>&1
if not errorlevel 1 set "WR_SAFE_SCAN_DESTRUCTIVE=YES"

set "WR_SAFE_EFFECTIVE=READ_ONLY"
if /i "%WR_SAFE_QUEUE_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_META_RISK%"=="REPAIR_WRITE" set "WR_SAFE_EFFECTIVE=REPAIR_WRITE"
if /i "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" set "WR_SAFE_EFFECTIVE=DESTRUCTIVE"

if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_QUEUE_RISK%"=="DESTRUCTIVE" (
  set "WR_SAFE_FAIL_REASON=Local scan detected destructive content but queue risk was lower."
  goto :FAIL94
)
if /i "%WR_SAFE_SCAN_DESTRUCTIVE%"=="YES" if /i not "%WR_SAFE_META_RISK%"=="DESTRUCTIVE" (
  set "WR_SAFE_FAIL_REASON=Local scan detected destructive content but script risk was lower."
  goto :FAIL94
)

if /i not "%WR_SAFE_EFFECTIVE%"=="DESTRUCTIVE" (
  >"%WR_SAFE_STATE%" echo status=PASS
  >>"%WR_SAFE_STATE%" echo effective_risk=%WR_SAFE_EFFECTIVE%
  >>"%WR_SAFE_STATE%" echo command_id=%WR_SAFE_COMMAND_ID%
  exit /b 0
)

if "%WR_SAFE_TARGET%"=="*" (
  set "WR_SAFE_FAIL_REASON=Destructive request used wildcard target."
  goto :FAIL95
)
if /i not "%WR_SAFE_TARGET%"=="%WR_SAFE_AGENT%" (
  set "WR_SAFE_FAIL_REASON=Destructive request targets a different agent."
  goto :FAIL95
)
if /i not "%WR_SAFE_LOCAL_AUTH%"=="REQUIRED" (
  set "WR_SAFE_FAIL_REASON=Destructive request did not require local authorization."
  goto :FAIL95
)

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

:FAIL90
call :WRITE_FAIL 90
exit /b 90
:FAIL93
call :WRITE_FAIL 93
exit /b 93
:FAIL94
call :WRITE_FAIL 94
exit /b 94
:FAIL95
call :WRITE_FAIL 95
exit /b 95

:WRITE_FAIL
>"%WR_SAFE_STATE%" echo status=FAIL
>>"%WR_SAFE_STATE%" echo return_code=%~1
>>"%WR_SAFE_STATE%" echo reason=%WR_SAFE_FAIL_REASON%
exit /b 0
