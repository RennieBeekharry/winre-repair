@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Inventory offline storage and boot-critical driver evidence after the repeated HP-spinner hang.
rem WR_ACTION=INVENTORY_BOOT_STORAGE_DRIVERS
rem WR_TARGET=Offline Windows driver metadata, INF files, boot-critical driver files, and BCD text only.
rem WR_CONSEQUENCE=Reads driver and BCD evidence and writes bounded diagnostics under C:\WinRERepair. No driver, registry, BCD, EFI, package, partition, reboot, or personal-file change.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=56"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "DRIVERS=%WORK%\step56-drivers.txt"
set "FOCUS=%WORK%\step56-storage-focus.txt"
set "INFFOCUS=%WORK%\step56-inf-focus.txt"
set "BCD=%WORK%\step56-bcd.txt"
set "DISM=C:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=X:\Windows\System32\dism.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - BOOT/STORAGE DRIVER DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows reaches the HP spinner but does not complete kernel
echo                       startup after SFC and EFI boot-manager repair.
echo CURRENT TASK        : Inventorying storage and boot-critical driver evidence before
echo                       deciding whether to run a one-time boot-logging test.
echo SAFETY              : READ-ONLY - no Windows repair is running.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI BOOT STORAGE DRIVER DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/5] Verifying the offline Windows target and reconnect v4...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/5] Capturing installed offline driver metadata...
"%DISM%" /Image:C:\ /Get-Drivers /All /Format:Table /English >"%DRIVERS%" 2>&1
set "DRIVERRC=!errorlevel!"
if exist "%FOCUS%" del /f /q "%FOCUS%" >nul 2>&1
if exist "%DRIVERS%" findstr /i /c:"storage" /c:"stor" /c:"nvme" /c:"raid" /c:"scsi" /c:"iastor" /c:"vmd" /c:"intel" /c:"sata" "%DRIVERS%" >"%FOCUS%" 2>nul
set "FOCUSLINES=0"
if exist "%FOCUS%" for /f %%N in ('find /c /v "" ^< "%FOCUS%"') do set "FOCUSLINES=%%N"
>>"%DETAILS%" echo dism_get_drivers_exit=!DRIVERRC!
>>"%DETAILS%" echo storage_driver_focus_lines=!FOCUSLINES!

echo [3/5] Locating Intel RST/VMD-related OEM INF files...
if exist "%INFFOCUS%" del /f /q "%INFFOCUS%" >nul 2>&1
findstr /s /i /m /c:"iaStor" /c:"Volume Management Device" /c:"Rapid Storage" /c:"VMD" "C:\Windows\INF\oem*.inf" >"%INFFOCUS%" 2>nul
set "INFLINES=0"
if exist "%INFFOCUS%" for /f %%N in ('find /c /v "" ^< "%INFFOCUS%"') do set "INFLINES=%%N"
>>"%DETAILS%" echo rst_vmd_inf_matches=!INFLINES!

echo [4/5] Checking boot-critical storage driver files and current BCD boot-log state...
for %%F in (storahci.sys stornvme.sys disk.sys partmgr.sys volmgr.sys volmgrx.sys fvevol.sys iaStorVD.sys iaStorAC.sys iaStorAfs.sys) do (
  if exist "C:\Windows\System32\drivers\%%F" (
    for %%Z in ("C:\Windows\System32\drivers\%%F") do >>"%DETAILS%" echo driver_file=%%F;present=YES;size=%%~zZ
  ) else (
    >>"%DETAILS%" echo driver_file=%%F;present=NO
  )
)
"%BCDEDIT%" /enum {default} >"%BCD%" 2>&1
set "BCDRC=!errorlevel!"
set "BOOTLOG=NO"
if exist "%BCD%" findstr /i /c:"bootlog                 Yes" "%BCD%" >nul 2>&1 && set "BOOTLOG=YES"
>>"%DETAILS%" echo bcd_query_exit=!BCDRC!
>>"%DETAILS%" echo bcd_bootlog_enabled=!BOOTLOG!

echo [5/5] Recording bounded evidence...
if exist "%FOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STORAGE DRIVER METADATA FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%FOCUS%") do if !N! LSS 80 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
if exist "%INFFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- RST/VMD OEM INF MATCHES ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%INFFOCUS%") do if !N! LSS 40 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Boot/storage driver diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; DISM rc=!DRIVERRC!; storage focus=!FOCUSLINES! lines; RST/VMD INF matches=!INFLINES!; bootlog currently=!BOOTLOG!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review storage-driver evidence before deciding on a reversible one-time boot-log or Safe Mode test.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - DRIVER EVIDENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot/storage driver diagnostic stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows or personal-file changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo SCREENSHOT REQUIRED : YES
exit /b 90
