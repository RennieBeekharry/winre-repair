@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Classify the stalled Windows boot using BCD, boot evidence, servicing state, and offline System event log evidence without changing Windows.
rem WR_ACTION=CLASSIFY_STALLED_BOOT
rem WR_TARGET=Offline Windows C:\Windows boot configuration, boot evidence, servicing metadata, and System event log only.
rem WR_CONSEQUENCE=Reads recovery evidence and writes diagnostic text only under C:\WinRERepair. No Windows repair, BCD change, registry change, package install, reboot, partition operation, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.2"
set "STEP=33"
set "WORK=C:\WinRERepair"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"
set "WEVT=C:\Windows\System32\wevtutil.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - BOOT HANG CLASSIFICATION
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows still stalls at the HP loading screen after
echo                       successful offline SFC repair and clean verification.
echo CURRENT TASK        : Classifying whether the remaining failure is boot config,
echo                       servicing, a driver/service startup failure, or a crash.
echo SAFETY              : READ-ONLY - no Windows repair is running in this step.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO - wait for the final status below.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI BOOT HANG CLASSIFICATION
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo.
echo [1/6] Verifying Windows and the permanent quick reconnect...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/6] Capturing the active boot-manager and Windows-loader configuration...
"%BCDEDIT%" /enum {bootmgr} >"%WORK%\diag33-bcd-bootmgr.txt" 2>&1
set "BCD_BOOTMGR_RC=!errorlevel!"
"%BCDEDIT%" /enum {default} >"%WORK%\diag33-bcd-default.txt" 2>&1
set "BCD_DEFAULT_RC=!errorlevel!"
set "BCD_WINLOAD=NO"
set "BCD_SYSTEMROOT=NO"
set "BCD_PARTITION_C=NO"
if exist "%WORK%\diag33-bcd-default.txt" (
  findstr /i /c:"winload.efi" "%WORK%\diag33-bcd-default.txt" >nul 2>&1 && set "BCD_WINLOAD=YES"
  findstr /i /c:"\Windows" "%WORK%\diag33-bcd-default.txt" >nul 2>&1 && set "BCD_SYSTEMROOT=YES"
  findstr /i /c:"partition=C:" "%WORK%\diag33-bcd-default.txt" >nul 2>&1 && set "BCD_PARTITION_C=YES"
)
>>"%DETAILS%" echo bcd_bootmgr_exit=!BCD_BOOTMGR_RC!
>>"%DETAILS%" echo bcd_default_exit=!BCD_DEFAULT_RC!
>>"%DETAILS%" echo bcd_winload_efi=!BCD_WINLOAD!
>>"%DETAILS%" echo bcd_systemroot_windows=!BCD_SYSTEMROOT!
>>"%DETAILS%" echo bcd_partition_c=!BCD_PARTITION_C!

echo [3/6] Checking boot-status and crash evidence files...
set "BOOTSTAT=NO"
set "NTBTLOG=NO"
set "MEMDMP=NO"
set "MINIDUMPS=0"
if exist "C:\Windows\bootstat.dat" set "BOOTSTAT=YES"
if exist "C:\Windows\ntbtlog.txt" set "NTBTLOG=YES"
if exist "C:\Windows\MEMORY.DMP" set "MEMDMP=YES"
if exist "C:\Windows\Minidump\*.dmp" for %%F in ("C:\Windows\Minidump\*.dmp") do set /a MINIDUMPS+=1
>>"%DETAILS%" echo bootstat_present=!BOOTSTAT!
>>"%DETAILS%" echo ntbtlog_present=!NTBTLOG!
>>"%DETAILS%" echo memory_dmp_present=!MEMDMP!
>>"%DETAILS%" echo minidump_count=!MINIDUMPS!

echo [4/6] Reconfirming offline servicing state...
"%DISM%" /Image:C:\ /Get-Packages /Format:Table /English >"%WORK%\diag33-packages.txt" 2>&1
set "DISMRC=!errorlevel!"
findstr /i /c:"Pending" "%WORK%\diag33-packages.txt" >"%WORK%\diag33-pending.txt" 2>nul
set "PENDING_ROWS=0"
if exist "%WORK%\diag33-pending.txt" for /f %%N in ('find /c /v "" ^< "%WORK%\diag33-pending.txt"') do set "PENDING_ROWS=%%N"
set "PENDING_XML=NO"
if exist "C:\Windows\WinSxS\pending.xml" set "PENDING_XML=YES"
>>"%DETAILS%" echo dism_get_packages_exit=!DISMRC!
>>"%DETAILS%" echo pending_package_rows=!PENDING_ROWS!
>>"%DETAILS%" echo pending_xml_present=!PENDING_XML!

echo [5/6] Reading recent offline Windows System event evidence...
set "EVENT_QUERY=NOT_AVAILABLE"
set "EVENT_LINES=0"
if exist "%WEVT%" if exist "C:\Windows\System32\winevt\Logs\System.evtx" (
  "%WEVT%" qe "C:\Windows\System32\winevt\Logs\System.evtx" /lf:true /c:40 /rd:true /f:text >"%WORK%\diag33-system-events.txt" 2>&1
  if not errorlevel 1 set "EVENT_QUERY=PASS"
)
if exist "%WORK%\diag33-system-events.txt" (
  findstr /i /c:"Kernel-Boot" /c:"Kernel-Power" /c:"Service Control Manager" /c:"volmgr" /c:"disk" /c:"Ntfs" /c:"BugCheck" "%WORK%\diag33-system-events.txt" >"%WORK%\diag33-event-focus.txt" 2>nul
  if exist "%WORK%\diag33-event-focus.txt" for /f %%N in ('find /c /v "" ^< "%WORK%\diag33-event-focus.txt"') do set "EVENT_LINES=%%N"
)
>>"%DETAILS%" echo system_event_query=!EVENT_QUERY!
>>"%DETAILS%" echo focused_event_lines=!EVENT_LINES!

echo [6/6] Recording the reviewed classification evidence...
set "SERVICING_PENDING=NO"
if not "!PENDING_ROWS!"=="0" set "SERVICING_PENDING=YES"
if /i "!PENDING_XML!"=="YES" set "SERVICING_PENDING=YES"
>>"%DETAILS%" echo servicing_pending_detected=!SERVICING_PENDING!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
if exist "%WORK%\diag33-event-focus.txt" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- RECENT SYSTEM EVENT FOCUS ---
  for /f "usebackq delims=" %%L in ("%WORK%\diag33-event-focus.txt") do >>"%DETAILS%" echo %%L
)

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Boot-hang classification diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; reconnect=!RECONNECT!; BCD winload=!BCD_WINLOAD! partition C=!BCD_PARTITION_C!; servicing pending=!SERVICING_PENDING!; memory dump=!MEMDMP!; minidumps=!MINIDUMPS!; event query=!EVENT_QUERY!; focused event lines=!EVENT_LINES!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the classification evidence before any write operation or reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - RESULT SENT FOR REVIEW
echo QUICK RECONNECT     : !RECONNECT!  ^(future command: C:\r.cmd^)
echo BCD WINLOAD.EFI     : !BCD_WINLOAD!
echo BCD PARTITION C     : !BCD_PARTITION_C!
echo SERVICING PENDING   : !SERVICING_PENDING!
echo MEMORY.DMP          : !MEMDMP!
echo MINIDUMPS           : !MINIDUMPS!
echo SYSTEM EVENT QUERY  : !EVENT_QUERY!
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : No reply needed unless an unexpected error appears.
echo                       If that happens, reply FAILED and attach a photo.
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Boot-hang classification stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes were made.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of THIS screen.
echo ================================================================================
exit /b 90
