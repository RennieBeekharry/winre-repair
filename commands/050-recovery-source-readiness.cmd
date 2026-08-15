@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inventory the existing RescueMeAI recovery USB and Windows recovery-source workspace after targeted storage, storahci, and BCD boot tests did not resolve 0x7B.
rem WR_ACTION=RECOVERY_SOURCE_READINESS
rem WR_TARGET=Offline Windows version metadata, mounted volume labels, existing RescueMeAI media workspace, and recovery-source files only.
rem WR_CONSEQUENCE=Read-only inventory. No registry values, drivers, boot files, partitions, Windows files, or personal files are changed.
rem WR_ROLLBACK=No rollback required; read-only.

set "R=C:\WinRERepair"
set "O=%R%\COMMAND_RESULT.env"
set "A=%R%\runtime\github-auth.cmd"
set "UI=%R%\runtime\ui.cmd"
set "REG=C:\Windows\System32\reg.exe"
set "FS=C:\Windows\System32\findstr.exe"
set "SOFT=C:\Windows\System32\config\SOFTWARE"
set "Q=%R%\diag50-recovery-source-readiness.txt"
set "DATA="
set "MEDIA="
set "SRC="
set "SRC_PRESENT=NO"
set "SRC_FILES=0"
set "SRC_ESD=0"
set "SRC_CAB=0"
set "BOOTWIM=NO"
set "INSTALLWIM=NO"
set "INSTALLESD=NO"
set "SETUPEXE=NO"
set "BOOTX64=NO"
set "META=NO"
set "STATE=NO"
if not exist "%REG%" set "REG=reg.exe"
if not exist "%FS%" set "FS=findstr.exe"

call :SHOW "1 of 5 - Reviewing completed 0x7B evidence and identifying the existing recovery volumes."
>"%Q%" echo RESCUEMEAI COMMAND 50 - RECOVERY SOURCE READINESS
>>"%Q%" echo windows_changes=NONE
>>"%Q%" echo prior_state=Targeted Intel iaStorAC test failed; Microsoft storahci test failed and was rolled back; fresh BCD verified but boot still returned 0x7B.

for %%D in (D E F G H I J K L M N O P Q R S T U V W Y Z) do (
  vol %%D: 2>nul | "%FS%" /i /c:"REPAIRDATA" >nul 2>&1
  if not errorlevel 1 if not defined DATA set "DATA=%%D:"
  vol %%D: 2>nul | "%FS%" /i /c:"WIN11MEDIA" >nul 2>&1
  if not errorlevel 1 if not defined MEDIA set "MEDIA=%%D:"
)
>>"%Q%" echo repairdata_drive=!DATA!
>>"%Q%" echo win11media_drive=!MEDIA!

call :SHOW "2 of 5 - Reading the offline Windows servicing level so the repair source can be matched correctly."
if exist "%SOFT%" (
  "%REG%" unload HKLM\RMAISOFT50 >nul 2>&1
  "%REG%" load HKLM\RMAISOFT50 "%SOFT%" >nul 2>&1
  if not errorlevel 1 (
    >>"%Q%" echo [OFFLINE_WINDOWS]
    for %%V in (ProductName EditionID DisplayVersion CurrentBuild CurrentBuildNumber UBR BuildLabEx) do "%REG%" query "HKLM\RMAISOFT50\Microsoft\Windows NT\CurrentVersion" /v %%V >>"%Q%" 2>&1
    "%REG%" unload HKLM\RMAISOFT50 >nul 2>&1
  ) else (
    >>"%Q%" echo offline_software_hive=LOAD_FAILED
  )
) else (
  >>"%Q%" echo offline_software_hive=MISSING
)

call :SHOW "3 of 5 - Checking whether the previous Microsoft-derived UUP recovery source is already present or resumable."
if defined DATA set "SRC=!DATA!\RescueMeAI\Media\UUP\26100.8894-amd64-core-en-us"
if defined SRC if exist "!SRC!\" (
  set "SRC_PRESENT=YES"
  for /r "!SRC!" %%F in (*) do (
    set /a SRC_FILES+=1
    if /i "%%~xF"==".esd" set /a SRC_ESD+=1
    if /i "%%~xF"==".cab" set /a SRC_CAB+=1
  )
)
if exist "%R%\media\uup-26100.8894-core-en-us.json" set "META=YES"
if exist "%R%\media\uup-download-state.txt" set "STATE=YES"
>>"%Q%" echo [UUP_WORKSPACE]
>>"%Q%" echo expected_source=!SRC!
>>"%Q%" echo source_present=!SRC_PRESENT!
>>"%Q%" echo source_file_count=!SRC_FILES!
>>"%Q%" echo source_esd_count=!SRC_ESD!
>>"%Q%" echo source_cab_count=!SRC_CAB!
>>"%Q%" echo metadata_present=!META!
>>"%Q%" echo resumable_state_present=!STATE!

call :SHOW "4 of 5 - Checking the existing WIN11MEDIA partition for boot and Windows image components."
if defined MEDIA (
  if exist "!MEDIA!\sources\boot.wim" set "BOOTWIM=YES"
  if exist "!MEDIA!\sources\install.wim" set "INSTALLWIM=YES"
  if exist "!MEDIA!\sources\install.esd" set "INSTALLESD=YES"
  if exist "!MEDIA!\setup.exe" set "SETUPEXE=YES"
  if exist "!MEDIA!\EFI\Boot\bootx64.efi" set "BOOTX64=YES"
)
>>"%Q%" echo [WIN11MEDIA]
>>"%Q%" echo boot_wim=!BOOTWIM!
>>"%Q%" echo install_wim=!INSTALLWIM!
>>"%Q%" echo install_esd=!INSTALLESD!
>>"%Q%" echo setup_exe=!SETUPEXE!
>>"%Q%" echo bootx64_efi=!BOOTX64!

call :SHOW "5 of 5 - Uploading the compact source-readiness report so the next recovery step can be selected without manual commands."
>"%R%\LAST_RUN_REPORT.txt" echo status=PASS
>>"%R%\LAST_RUN_REPORT.txt" echo message=Recovery-source readiness was inventoried after the targeted boot-storage paths remained unsuccessful.
>"%R%\RUN_DETAILS.txt" echo diagnostic=RECOVERY_SOURCE_READINESS
>>"%R%\RUN_DETAILS.txt" echo windows_changes=NONE
type "%Q%" >>"%R%\RUN_DETAILS.txt"
if exist "%A%" call "%A%" upload >nul 2>&1
if errorlevel 1 goto :UPLOADFAIL

>"%O%" echo STATUS=PASS
>>"%O%" echo MESSAGE=RescueMeAI inventoried the existing recovery USB and Microsoft-derived repair-source workspace after the targeted 0x7B boot repairs were exhausted.
>>"%O%" echo EVIDENCE=Private report contains offline Windows build, REPAIRDATA/WIN11MEDIA detection, UUP source/resume state, and boot/install-media readiness.
>>"%O%" echo INSTRUCTION=No user action is required. Leave RescueMeAI online; do not reboot yet.
exit /b 0

:SHOW
if exist "%UI%" (
  call "%UI%" screen "RMAI-CMD50-2026.08.15" "CONNECTED" "ANALYZING / COMMAND 50" "NO WINDOWS CHANGES" "AI-ASSISTED WINDOWS RECOVERY" "INFO"
  call "%UI%" working "%~1"
) else (
  cls
  echo RESCUEMEAI - COMMAND 50
  echo.
  echo ACTIVITY: %~1
  echo.
  echo No action is required.
)
exit /b 0

:UPLOADFAIL
>"%O%" echo STATUS=WARNING
>>"%O%" echo MESSAGE=Recovery-source readiness was collected locally but its private upload failed.
>>"%O%" echo EVIDENCE=No Windows changes were made; local evidence is C:\WinRERepair\RUN_DETAILS.txt.
>>"%O%" echo INSTRUCTION=Leave RescueMeAI online; do not reboot.
exit /b 20
