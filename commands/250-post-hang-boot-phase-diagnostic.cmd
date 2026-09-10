@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect bounded post-hang boot evidence after the controlled Windows boot test stalled at the HP spinner.
rem WR_ACTION=POST_HANG_BOOT_PHASE_DIAGNOSTIC
rem WR_TARGET=Offline Windows boot logs, Startup Repair log, System event log, boot status files, and RescueMeAI markers only.
rem WR_CONSEQUENCE=Reads boot evidence and writes only bounded diagnostic text under C:\WinRERepair. No Windows repair, BCD change, registry change, package change, reboot, or personal-file operation is performed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=53"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "EVT=%WORK%\step53-system-events.txt"
set "EVTFOCUS=%WORK%\step53-event-focus.txt"
set "SRT=%WORK%\step53-srt-focus.txt"
set "NTBT=%WORK%\step53-ntbt-tail.txt"
set "WEVT=X:\Windows\System32\wevtutil.exe"
if not exist "%WEVT%" set "WEVT=C:\Windows\System32\wevtutil.exe"
set "FSUTIL=X:\Windows\System32\fsutil.exe"
if not exist "%FSUTIL%" set "FSUTIL=C:\Windows\System32\fsutil.exe"
if not exist "%WORK%" md "%WORK%" >nul 2>&1

cls
echo ================================================================================
echo RescueMeAI - POST-HANG BOOT DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Windows still stalls at the HP spinner after the verified
echo                       EFI boot-manager refresh.
echo CURRENT TASK        : Locating the boot phase or driver/service evidence associated
echo                       with the stalled startup before another repair or reboot.
echo SAFETY              : READ-ONLY - no Windows repair is running.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open and keep the laptop on power.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

>"%DETAILS%" echo RESCUEMEAI POST HANG BOOT DIAGNOSTIC
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/6] Verifying the offline Windows target and reconnect helper...
set "TARGET=NO"
set "RECONNECT=NO"
if exist "C:\Windows\System32\config\SYSTEM" set "TARGET=YES"
if exist "C:\r.cmd" if exist "C:\RescueMeAI\reconnect.cmd" set "RECONNECT=YES"
>>"%DETAILS%" echo target_verified=!TARGET!
>>"%DETAILS%" echo quick_reconnect_installed=!RECONNECT!
if /i not "!TARGET!"=="YES" goto :FAIL

echo [2/6] Recording boot-test marker and boot-status evidence...
set "MARKER=NO"
if exist "C:\RescueMeAI\state\boot-test-52.pending" set "MARKER=YES"
if exist "C:\RescueMeAI\state\boot-test-52.started" set "MARKER=YES"
set "BOOTSTAT=NO"
if exist "C:\Windows\bootstat.dat" set "BOOTSTAT=YES"
>>"%DETAILS%" echo boot_test_52_marker_present=!MARKER!
>>"%DETAILS%" echo bootstat_dat_present=!BOOTSTAT!
if exist "C:\Windows\bootstat.dat" for %%Z in ("C:\Windows\bootstat.dat") do >>"%DETAILS%" echo bootstat_dat_size=%%~zZ

echo [3/6] Reading bounded Startup Repair evidence...
if exist "%SRT%" del /f /q "%SRT%" >nul 2>&1
set "SRTLOG=C:\Windows\System32\LogFiles\Srt\SrtTrail.txt"
set "SRTL=0"
if exist "%SRTLOG%" (
  findstr /i /c:"Root cause" /c:"Boot critical" /c:"corrupt" /c:"error" /c:"failed" /c:"0x" "%SRTLOG%" >"%SRT%" 2>nul
  for /f %%N in ('find /c /v "" ^< "%SRT%"') do set "SRTL=%%N"
)
>>"%DETAILS%" echo srttrail_present=NO
if exist "%SRTLOG%" >>"%DETAILS%" echo srttrail_present=YES
>>"%DETAILS%" echo srt_focus_lines=!SRTL!
if exist "%SRT%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- STARTUP REPAIR FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%SRT%") do if !N! LSS 30 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)

echo [4/6] Checking Windows boot logging evidence...
set "NTBTLOG=C:\Windows\ntbtlog.txt"
set "NTBTPRESENT=NO"
set "NTBTLINES=0"
if exist "%NTBTLOG%" (
  set "NTBTPRESENT=YES"
  findstr /i /c:"Did not load driver" /c:"Loaded driver" "%NTBTLOG%" >"%NTBT%" 2>nul
  for /f %%N in ('find /c /v "" ^< "%NTBT%"') do set "NTBTLINES=%%N"
)
>>"%DETAILS%" echo ntbtlog_present=!NTBTPRESENT!
>>"%DETAILS%" echo ntbtlog_focus_lines=!NTBTLINES!
if exist "%NTBT%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- BOOT LOG FOCUS - LAST BOUNDED LINES ---
  for /f "skip=0 delims=" %%L in ('type "%NTBT%"') do (
    if !NTBTLINES! LEQ 80 >>"%DETAILS%" echo %%L
  )
)

echo [5/6] Querying focused offline System event evidence...
if exist "%EVT%" del /f /q "%EVT%" >nul 2>&1
if exist "%EVTFOCUS%" del /f /q "%EVTFOCUS%" >nul 2>&1
set "EVTRC=NOT_RUN"
set "EVTLINES=0"
if exist "%WEVT%" if exist "C:\Windows\System32\winevt\Logs\System.evtx" (
  "%WEVT%" qe "C:\Windows\System32\winevt\Logs\System.evtx" /lf:true /rd:true /c:120 /f:text >"%EVT%" 2>&1
  set "EVTRC=!errorlevel!"
  findstr /i /c:"Event ID: 41" /c:"Event ID: 129" /c:"Event ID: 153" /c:"Event ID: 219" /c:"Event ID: 6008" /c:"Event ID: 7000" /c:"Event ID: 7001" /c:"Event ID: 7009" /c:"Event ID: 7011" /c:"Event ID: 7026" /c:"disk" /c:"stor" /c:"driver" /c:"boot" /c:"failed" /c:"error" "%EVT%" >"%EVTFOCUS%" 2>nul
  if exist "%EVTFOCUS%" for /f %%N in ('find /c /v "" ^< "%EVTFOCUS%"') do set "EVTLINES=%%N"
)
>>"%DETAILS%" echo system_event_query_exit=!EVTRC!
>>"%DETAILS%" echo system_event_focus_lines=!EVTLINES!
if exist "%EVTFOCUS%" (
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- SYSTEM EVENT FOCUS ---
  set /a N=0
  for /f "usebackq delims=" %%L in ("%EVTFOCUS%") do if !N! LSS 60 (
    >>"%DETAILS%" echo %%L
    set /a N+=1
  )
)

echo [6/6] Checking filesystem dirty state and recording result...
set "DIRTYRC=NOT_RUN"
set "DIRTYSTATE=UNKNOWN"
if exist "%FSUTIL%" (
  "%FSUTIL%" dirty query C: >"%WORK%\step53-dirty.txt" 2>&1
  set "DIRTYRC=!errorlevel!"
  findstr /i /c:"is NOT Dirty" "%WORK%\step53-dirty.txt" >nul 2>&1 && set "DIRTYSTATE=NOT_DIRTY"
  findstr /i /c:"is Dirty" "%WORK%\step53-dirty.txt" >nul 2>&1 && set "DIRTYSTATE=DIRTY"
)
>>"%DETAILS%" echo filesystem_dirty_query_exit=!DIRTYRC!
>>"%DETAILS%" echo filesystem_state=!DIRTYSTATE!
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Post-hang boot-phase diagnostic completed successfully.
>>"%RESULT%" echo EVIDENCE=Fix %FIX_VERSION%; Srt lines=!SRTL!; ntbtlog=!NTBTPRESENT!/!NTBTLINES! lines; System event focus=!EVTLINES! lines; filesystem=!DIRTYSTATE!; reconnect=!RECONNECT!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the post-hang evidence before choosing a one-time Safe Mode or boot-logging test, component-store repair, or another targeted action.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - POST-HANG EVIDENCE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : No reply needed unless an unexpected error appears.
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Post-hang diagnostic stopped because C:\Windows could not be verified.
>>"%RESULT%" echo EVIDENCE=No Windows changes or personal-file operations were performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - WINDOWS TARGET NOT VERIFIED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo of this screen.
echo ================================================================================
exit /b 90
