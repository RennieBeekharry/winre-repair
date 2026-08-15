@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Repair the offline Windows component store that DISM identified as repairable, then repair protected system files if DISM succeeds.
rem WR_ACTION=WINDOWS_NATIVE_REPAIR
rem WR_TARGET=C:\Windows offline Windows installation and RescueMeAI repair logs only.
rem WR_CONSEQUENCE=DISM RestoreHealth and SFC Scannow may replace corrupted Windows component-store and protected system files. Personal files are not intentionally modified.
rem WR_ROLLBACK=Windows servicing records the repairs. If the repair fails, RescueMeAI stops before further escalation and preserves logs for review.

set "WIN=C:"
set "WINDIR=C:\Windows"
set "WORK=C:\WinRERepair"
set "OUT=%WORK%\COMMAND_RESULT.env"
set "UI=%WORK%\runtime\ui.cmd"
set "SCRATCH=%WORK%\scratch"
set "DISM=X:\Windows\System32\dism.exe"
set "SFC=X:\Windows\System32\sfc.exe"
set "FINDSTR=C:\Windows\System32\findstr.exe"
set "DISMLOG=%WORK%\repair13-dism-restore.log"
set "SFCLOG=%WORK%\repair13-sfc.log"
set "DISMRC=999"
set "SFCRC=999"
set "SFC_UNREPAIRED=UNKNOWN"

if not exist "%WINDIR%\System32\config\SYSTEM" goto :TARGET_FAIL
if not exist "%DISM%" set "DISM=dism.exe"
if not exist "%SFC%" set "SFC=sfc.exe"
if not exist "%FINDSTR%" set "FINDSTR=findstr.exe"
if not exist "%SCRATCH%" md "%SCRATCH%" >nul 2>&1

if exist "%UI%" (
  call "%UI%" screen "RMAI-REPAIR13-2026.08.14-2145-ET" "CONNECTED" "WORKING" "REPAIR WRITE" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 3 30
  call "%UI%" readiness "RECOMMENDED" "SOURCE VERIFIED - USB NOT ASSEMBLED" "REPAIR WRITE" "DISM reported the component store as repairable and SFC found integrity violations."
  call "%UI%" progress "DISM RestoreHealth" "UNKNOWN" "Repair stage 1 of 2" "" "" "Starting now" "Windows will show native percentage below."
  call "%UI%" working "Repairing the offline Windows component store identified as repairable."
)

echo.
echo DISM is repairing the offline Windows component store.
echo This may replace corrupted Windows system components. Personal files are not targeted.
echo.
"%DISM%" /Image:%WIN%\ /Cleanup-Image /RestoreHealth /ScratchDir:"%SCRATCH%" /LogPath:"%DISMLOG%"
set "DISMRC=!errorlevel!"

if not "!DISMRC!"=="0" goto :DISM_FAILED

if exist "%UI%" (
  call "%UI%" screen "RMAI-REPAIR13-2026.08.14-2145-ET" "CONNECTED" "WORKING" "REPAIR WRITE" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" roadmap 3 35
  call "%UI%" readiness "RECOMMENDED" "SOURCE VERIFIED - USB NOT ASSEMBLED" "REPAIR WRITE" "DISM repair completed; protected Windows files are now being repaired."
  call "%UI%" progress "SFC protected-file repair" "UNKNOWN" "Repair stage 2 of 2" "" "" "Starting now" "Windows will show native progress below when available."
  call "%UI%" working "Repairing protected Windows system files after successful component-store repair."
)

echo.
echo DISM completed successfully. SFC is now repairing protected system files.
echo.
"%SFC%" /scannow /offbootdir=%WIN%\ /offwindir=%WINDIR% /offlogfile="%SFCLOG%"
set "SFCRC=!errorlevel!"
set "SFC_UNREPAIRED=NO"
if exist "%SFCLOG%" (
  "%FINDSTR%" /i /c:"Cannot repair member file" "%SFCLOG%" >nul 2>&1
  if not errorlevel 1 set "SFC_UNREPAIRED=YES"
)

if not "!SFCRC!"=="0" goto :SFC_WARNING
if /i "!SFC_UNREPAIRED!"=="YES" goto :SFC_WARNING

>"%OUT%" echo STATUS=PASS
>>"%OUT%" echo MESSAGE=Windows built-in component-store and protected-file repairs completed successfully.
>>"%OUT%" echo EVIDENCE=DISM_RESTORE_RC=!DISMRC!; SFC_SCANNOW_RC=!SFCRC!; SFC_UNREPAIRED_MARKER=!SFC_UNREPAIRED!.
>>"%OUT%" echo INSTRUCTION=Reply pass. RescueMeAI remains online; next step is targeted boot/storage recovery and a boot test.
exit /b 0

:DISM_FAILED
>"%OUT%" echo STATUS=WARNING
>>"%OUT%" echo MESSAGE=DISM could not complete the component-store repair. SFC repair was intentionally skipped to avoid another long low-value pass.
>>"%OUT%" echo EVIDENCE=DISM_RESTORE_RC=!DISMRC!; log=%DISMLOG%. No reset or reinstall was attempted.
>>"%OUT%" echo INSTRUCTION=Reply warning. RescueMeAI remains online; review the DISM failure and choose a compatible repair source or move to targeted boot/storage recovery.
exit /b 0

:SFC_WARNING
>"%OUT%" echo STATUS=WARNING
>>"%OUT%" echo MESSAGE=DISM repaired the component store, but SFC still reported a condition requiring review.
>>"%OUT%" echo EVIDENCE=DISM_RESTORE_RC=!DISMRC!; SFC_SCANNOW_RC=!SFCRC!; SFC_UNREPAIRED_MARKER=!SFC_UNREPAIRED!; log=%SFCLOG%.
>>"%OUT%" echo INSTRUCTION=Reply warning. RescueMeAI remains online; do not repeat generic scans automatically.
exit /b 0

:TARGET_FAIL
>"%OUT%" echo STATUS=FAIL
>>"%OUT%" echo MESSAGE=The offline Windows installation could not be validated before repair.
>>"%OUT%" echo EVIDENCE=Expected SYSTEM hive at C:\Windows\System32\config\SYSTEM. No repair was attempted.
>>"%OUT%" echo INSTRUCTION=Reply fail. RescueMeAI remains online.
exit /b 90
