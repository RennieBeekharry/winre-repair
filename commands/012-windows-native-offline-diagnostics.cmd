@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Run Windows-native offline health diagnostics before escalating to repair.
rem WR_ACTION=WINDOWS_NATIVE_OFFLINE_DIAGNOSTICS
rem WR_TARGET=C:\Windows offline installation and RescueMeAI diagnostic logs only.
rem WR_CONSEQUENCE=Runs DISM ScanHealth/CheckHealth and SFC VerifyOnly. No Windows repair is requested.
rem WR_ROLLBACK=None required; target-image operations are diagnostic only.

set "WIN=C:"
set "WINDIR=C:\Windows"
set "WORK=C:\WinRERepair"
set "OUT=%WORK%\COMMAND_RESULT.env"
set "UI=%WORK%\runtime\ui.cmd"
set "SCRATCH=%WORK%\scratch"
set "DISM=X:\Windows\System32\dism.exe"
set "SFC=X:\Windows\System32\sfc.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "CMDVER=RMAI-DIAG12-2026.08.14-1820-ET"
set "DISM_SCAN_LOG=%WORK%\diag12-dism-scan.log"
set "DISM_CHECK_OUT=%WORK%\diag12-dism-check.txt"
set "DISM_CHECK_LOG=%WORK%\diag12-dism-check.log"
set "SFC_LOG=%WORK%\diag12-sfc.log"
set "DISM_SCAN_RC=999"
set "DISM_CHECK_RC=999"
set "SFC_RC=999"
set "DISM_STATE=UNKNOWN"
set "SFC_MARKER=NONE_SEEN"
set "PENDINGXML=NO"
set "FINAL=PASS"

if not exist "%WINDIR%\System32\config\SYSTEM" goto :TARGET_FAIL
if not exist "%DISM%" set "DISM=dism.exe"
if not exist "%SFC%" set "SFC=sfc.exe"
if not exist "%FINDSTR%" set "FINDSTR=findstr.exe"
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1

if exist "%UI%" (
  call "%UI%" screen "%CMDVER%" "CONNECTED" "WORKING" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 2 20
  call "%UI%" readiness "RECOMMENDED" "RECOMMENDED" "READ ONLY" "Current diagnostics do not require backup or bootable media."
  call "%UI%" progress "DISM component-store scan" "Not measurable yet" "" "" "" "Starting now" "DISM will show native progress below."
  call "%UI%" working "Scanning the offline Windows component store for corruption."
)

echo.
echo DISM is scanning the offline Windows image. This does NOT repair Windows.
echo.
"%DISM%" /Image:%WIN%\ /Cleanup-Image /ScanHealth /ScratchDir:"%SCRATCH%" /LogPath:"%DISM_SCAN_LOG%"
set "DISM_SCAN_RC=!errorlevel!"

if exist "%UI%" (
  call "%UI%" screen "%CMDVER%" "CONNECTED" "WORKING" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 2 20
  call "%UI%" readiness "RECOMMENDED" "RECOMMENDED" "READ ONLY" "Current diagnostics do not require backup or bootable media."
  call "%UI%" progress "DISM health classification" "67" "2 of 3 diagnostic stages" "" "" "DISM scan complete" "Less than a minute for this stage."
  call "%UI%" working "Classifying the component-store health recorded by DISM."
)

"%DISM%" /Image:%WIN%\ /Cleanup-Image /CheckHealth /ScratchDir:"%SCRATCH%" /LogPath:"%DISM_CHECK_LOG%" >"%DISM_CHECK_OUT%" 2>&1
set "DISM_CHECK_RC=!errorlevel!"
"%FINDSTR%" /i /c:"No component store corruption detected" "%DISM_CHECK_OUT%" >nul 2>&1
if not errorlevel 1 set "DISM_STATE=HEALTHY"
if /i "!DISM_STATE!"=="UNKNOWN" (
  "%FINDSTR%" /i /c:"repairable" "%DISM_CHECK_OUT%" >nul 2>&1
  if not errorlevel 1 set "DISM_STATE=REPAIRABLE"
)
if /i "!DISM_STATE!"=="UNKNOWN" if not "!DISM_SCAN_RC!"=="0" set "DISM_STATE=SCAN_ERROR_RC_!DISM_SCAN_RC!"

if exist "%UI%" (
  call "%UI%" screen "%CMDVER%" "CONNECTED" "WORKING" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 2 20
  call "%UI%" readiness "RECOMMENDED" "RECOMMENDED" "READ ONLY" "Current diagnostics do not require backup or bootable media."
  call "%UI%" progress "SFC protected-file verification" "Not measurable yet" "Stage 3 of 3" "" "" "Starting now" "SFC will show its native progress below."
  call "%UI%" working "Verifying protected Windows system files without requesting repair."
)

echo.
echo SFC is verifying protected system files. This does NOT repair Windows.
echo.
"%SFC%" /verifyonly /offbootdir=%WIN%\ /offwindir=%WINDIR% /offlogfile="%SFC_LOG%"
set "SFC_RC=!errorlevel!"

if exist "%SFC_LOG%" (
  "%FINDSTR%" /i /c:"Cannot repair member file" "%SFC_LOG%" >nul 2>&1
  if not errorlevel 1 set "SFC_MARKER=UNREPAIRED_INTEGRITY_VIOLATION_SEEN"
)
if exist "%WINDIR%\WinSxS\pending.xml" set "PENDINGXML=YES"

if /i "!DISM_STATE!"=="REPAIRABLE" set "FINAL=WARNING"
if /i "!SFC_MARKER!"=="UNREPAIRED_INTEGRITY_VIOLATION_SEEN" set "FINAL=WARNING"
if not "!DISM_SCAN_RC!"=="0" set "FINAL=WARNING"
if not "!DISM_CHECK_RC!"=="0" set "FINAL=WARNING"
if not "!SFC_RC!"=="0" set "FINAL=WARNING"

>"%OUT%" echo STATUS=!FINAL!
>>"%OUT%" echo MESSAGE=Windows-native offline diagnostic pass completed without requesting repairs.
>>"%OUT%" echo EVIDENCE=DISM_SCAN_RC=!DISM_SCAN_RC!; DISM_CHECK_RC=!DISM_CHECK_RC!; DISM_STATE=!DISM_STATE!; SFC_RC=!SFC_RC!; SFC_MARKER=!SFC_MARKER!; PENDING_XML=!PENDINGXML!.
if /i "!FINAL!"=="PASS" (
  >>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online.
) else (
  >>"%OUT%" echo INSTRUCTION=Reply warning. RescueMeAI remains online; review evidence before any repair.
)
exit /b 0

:TARGET_FAIL
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=The expected offline Windows installation could not be validated at C:\Windows.
>>"%OUT%" echo EVIDENCE=SYSTEM hive not found at C:\Windows\System32\config\SYSTEM. No repair was attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
