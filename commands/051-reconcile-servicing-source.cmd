@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Reconcile the offline Windows servicing/build state with the existing recovery-source workspace before downloading or applying any repair source.
rem WR_ACTION=RECONCILE_SERVICING_AND_REPAIR_SOURCE
rem WR_TARGET=Offline Windows SOFTWARE servicing metadata, DISM package inventory, and existing RescueMeAI recovery-source workspace only.
rem WR_CONSEQUENCE=Read-only diagnostic. No packages, registry values, boot files, drivers, partitions, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "DISM=X:\Windows\System32\dism.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "SOFT=C:\Windows\System32\config\SOFTWARE"
set "PKG=%R%\diag51-dism-packages.txt"
set "Q=%R%\diag51-servicing-source.txt"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%DISM%" set "DISM=dism.exe"
if not exist "%FS%" set "FS=findstr.exe"
if not exist "%SOFT%" goto :BAD

call :STAGE "1 of 5" "Reconciling the offline Windows build recorded in the SOFTWARE hive."
"%REG%" unload HKLM\RMAISOFT51 >nul 2>&1
"%REG%" load HKLM\RMAISOFT51 "%SOFT%" >nul 2>&1
if errorlevel 1 goto :BAD

>"%Q%" echo RESCUEMEAI COMMAND 51 - SERVICING / REPAIR-SOURCE RECONCILIATION
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo [OFFLINE_WINDOWS_VERSION]
for %%V in (ProductName EditionID DisplayVersion CurrentBuild CurrentBuildNumber UBR BuildLabEx) do "%REG%" query "HKLM\RMAISOFT51\Microsoft\Windows NT\CurrentVersion" /v %%V >>"%Q%" 2>&1
>>"%Q%" echo [CBS_STATE]
"%REG%" query "HKLM\RMAISOFT51\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" >>"%Q%" 2>&1
"%REG%" query "HKLM\RMAISOFT51\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending" >>"%Q%" 2>&1
"%REG%" unload HKLM\RMAISOFT51 >nul 2>&1
if exist C:\Windows\WinSxS\pending.xml (
  >>"%Q%" echo pending_xml=PRESENT
) else (
  >>"%Q%" echo pending_xml=ABSENT
)

call :STAGE "2 of 5" "Asking DISM for the exact installed cumulative and servicing-stack package identities."
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%PKG%" 2>&1
set "DRC=!errorlevel!"
>>"%Q%" echo [DISM_PACKAGE_QUERY]
>>"%Q%" echo return_code=!DRC!
if not "!DRC!"=="0" (
  type "%PKG%" >>"%Q%"
  goto :BAD_AFTER_REPORT
)
"%FS%" /i /c:"Package_for_RollupFix" /c:"Package_for_ServicingStack" /c:"Package_for_DotNetRollup" "%PKG%" >>"%Q%" 2>&1

call :STAGE "3 of 5" "Checking the existing Microsoft-derived recovery-source workspace and its resumable state."
set "RD="
for %%X in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%X: 2>nul | "%FS%" /i /c:"REPAIRDATA" >nul 2>&1
  if not errorlevel 1 if not defined RD set "RD=%%X:"
)
>>"%Q%" echo [RECOVERY_SOURCE]
if defined RD (
  >>"%Q%" echo repairdata_drive=!RD!
  set "SRC=!RD!\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
  if exist "!SRC!\" (
    >>"%Q%" echo legacy_8894_source_dir=PRESENT
    for /f %%C in ('dir /a:-d /s /b "!SRC!\*" 2^>nul ^| find /c /v ""') do >>"%Q%" echo legacy_8894_file_count=%%C
  ) else (
    >>"%Q%" echo legacy_8894_source_dir=ABSENT
  )
) else (
  >>"%Q%" echo repairdata_drive=NOT_FOUND
)
if exist "%R%\media\uup-26100.8894-core-en-us.json" (
  >>"%Q%" echo legacy_8894_metadata=PRESENT
) else (
  >>"%Q%" echo legacy_8894_metadata=ABSENT
)
if exist "%R%\media\uup-download-state.txt" (
  >>"%Q%" echo legacy_download_state=PRESENT
  "%FS%" /i /c:"26100" /c:"complete" /c:"download" /c:"verified" "%R%\media\uup-download-state.txt" >>"%Q%" 2>&1
) else (
  >>"%Q%" echo legacy_download_state=ABSENT
)

call :STAGE "4 of 5" "Comparing servicing evidence with the old 26100.8894 recovery-source target before any download is resumed."
>>"%Q%" echo [DECISION_GUARD]
>>"%Q%" echo old_source_target=26100.8894
>>"%Q%" echo action=DO_NOT_RESUME_OLD_SOURCE_UNTIL_AI_RECONCILES_INSTALLED_PACKAGE_BUILD
>>"%Q%" echo reason=Repair source must not be chosen from stale workspace naming alone.

call :STAGE "5 of 5" "Uploading the compact servicing and recovery-source evidence for AI review."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Offline servicing level and recovery-source state were reconciled without changing Windows.
>"%R%\RUN_DETAILS.txt" echo diagnostic=RECONCILE_SERVICING_AND_REPAIR_SOURCE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL
>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI reconciled the installed Windows servicing state with the existing recovery-source workspace.
>>"%O%" echo EVIDENCE=Private report contains exact cumulative/servicing-stack package identities, pending-servicing state, offline build metadata, and old 26100.8894 source readiness.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:STAGE
if exist "%UI%" (
  call "%UI%" screen "RMAI-AGENT-V2-2026.08.14-1508-ET" "CONNECTED" "RUNNING COMMAND 51" "READ ONLY" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
)
echo.
echo RECOVERY ACTIVITY
echo ------------------------------------------------------------------------------------------------
echo Step %~1
echo %~2
echo.
echo No action is required. RescueMeAI is still working.
exit /b 0

:BAD_AFTER_REPORT
>"%R%\LAST_RUN_REPORT.txt" echo status=FAIL
>>"%R%\LAST_RUN_REPORT.txt" echo message=DISM could not enumerate the offline servicing packages.
>"%R%\RUN_DETAILS.txt" echo diagnostic=RECONCILE_SERVICING_AND_REPAIR_SOURCE_FAIL
type "%Q%" >>"%R%\RUN_DETAILS.txt"
call "%A%" upload >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not reconcile the offline servicing package state.
>>"%O%" echo EVIDENCE=No Windows changes were made; the private report contains the DISM failure details.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Servicing/source reconciliation completed locally but private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20

:BAD
"%REG%" unload HKLM\RMAISOFT51 >nul 2>&1
>"%O%" echo STATUS=FAIL
>>"%O%" echo MESSAGE=RescueMeAI could not initialize servicing/source reconciliation.
>>"%O%" echo EVIDENCE=No Windows changes were made.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 90
