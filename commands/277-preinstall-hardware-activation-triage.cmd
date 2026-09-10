@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Perform pre-reinstall hardware triage and Windows activation-readiness checks without exposing any product key.
rem WR_ACTION=PREINSTALL_HARDWARE_AND_ACTIVATION_TRIAGE
rem WR_TARGET=Offline Windows edition, firmware-OEM-key presence only, filesystem health, storage SMART/status, and bounded hardware event metadata.
rem WR_CONSEQUENCE=Reads diagnostic state only. The actual Windows product key, if present, is never written to the report or GitHub. No Windows setting, registry, BCD, EFI file, package, partition, personal file, or reboot is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=80"
set "WORK=C:\WinRERepair"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "CHKDSK=X:\Windows\System32\chkdsk.exe"
if not exist "%CHKDSK%" set "CHKDSK=C:\Windows\System32\chkdsk.exe"
set "FSUTIL=X:\Windows\System32\fsutil.exe"
if not exist "%FSUTIL%" set "FSUTIL=C:\Windows\System32\fsutil.exe"
set "WMIC=X:\Windows\System32\wbem\wmic.exe"
if not exist "%WMIC%" set "WMIC=C:\Windows\System32\wbem\wmic.exe"
set "WEVT=X:\Windows\System32\wevtutil.exe"
if not exist "%WEVT%" set "WEVT=C:\Windows\System32\wevtutil.exe"
set "DISM=X:\Windows\System32\dism.exe"
if not exist "%DISM%" set "DISM=C:\Windows\System32\dism.exe"
set "FINDSTR=X:\Windows\System32\findstr.exe"
if not exist "%FINDSTR%" set "FINDSTR=C:\Windows\System32\findstr.exe"

cls
echo ================================================================================
echo RescueMeAI - PRE-INSTALL HARDWARE AND ACTIVATION TRIAGE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Prior Windows Reset artifacts are present; normal boot and
echo                       Safe Mode both stall. We are checking hardware and activation
echo                       readiness before deciding on a clean reinstall.
echo CURRENT TASK        : Read-only storage/filesystem/event triage plus Windows edition
echo                       and firmware OEM-key PRESENCE check only.
echo SAFETY              : READ-ONLY - NO REBOOT.
echo PRIVACY             : PRODUCT KEY VALUE WILL NOT BE UPLOADED OR DISPLAYED.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

>"%DETAILS%" echo RESCUEMEAI PRE-INSTALL HARDWARE AND ACTIVATION TRIAGE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/5] Checking installed Windows edition and activation readiness...
set "EDITION_RC=NA"
if exist "%DISM%" (
  "%DISM%" /English /Image:C:\ /Get-CurrentEdition >"%WORK%\step80-edition.txt" 2>&1
  set "EDITION_RC=!errorlevel!"
  >>"%DETAILS%" echo dism_current_edition_exit=!EDITION_RC!
  "%FINDSTR%" /i /c:"Current Edition" "%WORK%\step80-edition.txt" >>"%DETAILS%" 2>nul
) else (
  >>"%DETAILS%" echo dism_current_edition=TOOL_UNAVAILABLE
)

set "OEMKEY_STATE=UNKNOWN"
if exist "%WMIC%" (
  set "OEMKEY_STATE=NOT_DETECTED_OR_UNAVAILABLE"
  for /f "tokens=1,* delims==" %%A in ('"%WMIC%" path SoftwareLicensingService get OA3xOriginalProductKey /value 2^>nul') do (
    if /i "%%A"=="OA3xOriginalProductKey" if not "%%B"=="" set "OEMKEY_STATE=PRESENT_REDACTED"
  )
) else (
  set "OEMKEY_STATE=WMIC_UNAVAILABLE"
)
>>"%DETAILS%" echo firmware_oem_key_presence=!OEMKEY_STATE!
>>"%DETAILS%" echo firmware_oem_key_value_uploaded=NO

echo [2/5] Running read-only filesystem and dirty-bit checks...
if not exist "%CHKDSK%" goto :FAIL
"%CHKDSK%" C: >"%WORK%\step80-chkdsk.txt" 2>&1
set "CHKRC=!errorlevel!"
>>"%DETAILS%" echo chkdsk_readonly_exit=!CHKRC!
"%FINDSTR%" /i /c:"found no problems" /c:"found problems" /c:"bad sectors" /c:"KB in bad sectors" /c:"failed" /c:"corruption" "%WORK%\step80-chkdsk.txt" >>"%DETAILS%" 2>nul

if exist "%FSUTIL%" (
  "%FSUTIL%" dirty query C: >"%WORK%\step80-dirty.txt" 2>&1
  set "DIRTYRC=!errorlevel!"
  >>"%DETAILS%" echo fsutil_dirty_exit=!DIRTYRC!
  type "%WORK%\step80-dirty.txt" >>"%DETAILS%"
) else (
  >>"%DETAILS%" echo fsutil_dirty=TOOL_UNAVAILABLE
)

echo [3/5] Checking storage SMART/status signals available in WinRE...
if exist "%WMIC%" (
  "%WMIC%" diskdrive get Model,Status /format:list >"%WORK%\step80-diskstatus.txt" 2>&1
  set "DISKRC=!errorlevel!"
  >>"%DETAILS%" echo wmic_disk_status_exit=!DISKRC!
  "%FINDSTR%" /i /b /c:"Model=" /c:"Status=" "%WORK%\step80-diskstatus.txt" >>"%DETAILS%" 2>nul

  "%WMIC%" /namespace:\\root\wmi path MSStorageDriver_FailurePredictStatus get PredictFailure /value >"%WORK%\step80-smartpredict.txt" 2>&1
  set "SMARTRC=!errorlevel!"
  >>"%DETAILS%" echo smart_failure_predict_exit=!SMARTRC!
  "%FINDSTR%" /i /c:"PredictFailure=" "%WORK%\step80-smartpredict.txt" >>"%DETAILS%" 2>nul
) else (
  >>"%DETAILS%" echo storage_smart_status=WMIC_UNAVAILABLE
)

echo [4/5] Checking bounded disk/storage/WHEA event metadata...
set "SYSLOG=C:\Windows\System32\winevt\Logs\System.evtx"
if exist "%WEVT%" if exist "%SYSLOG%" (
  "%WEVT%" qe "%SYSLOG%" /lf:true /q:"*[System[(Provider[@Name='disk'] or Provider[@Name='stornvme'] or Provider[@Name='storahci'] or Provider[@Name='storport'] or Provider[@Name='Microsoft-Windows-WHEA-Logger'])]]" /c:12 /rd:true /f:text >"%WORK%\step80-hw-events.txt" 2>&1
  set "EVRC=!errorlevel!"
  >>"%DETAILS%" echo hardware_event_query_exit=!EVRC!
  "%FINDSTR%" /i /c:"Provider Name:" /c:"Event ID:" /c:"Level:" "%WORK%\step80-hw-events.txt" >"%WORK%\step80-hw-events-summary.txt" 2>nul
  set /a EVLINES=0
  for /f "usebackq delims=" %%L in ("%WORK%\step80-hw-events-summary.txt") do if !EVLINES! LSS 42 (
    >>"%DETAILS%" echo %%L
    set /a EVLINES+=1
  )
  >>"%DETAILS%" echo bounded_hardware_event_summary_lines=!EVLINES!

  "%WEVT%" qe "%SYSLOG%" /lf:true /q:"*[System[Provider[@Name='Microsoft-Windows-MemoryDiagnostics-Results']]]" /c:4 /rd:true /f:text >"%WORK%\step80-memory-events.txt" 2>&1
  set "MEMEVRC=!errorlevel!"
  >>"%DETAILS%" echo memory_diagnostics_event_query_exit=!MEMEVRC!
  "%FINDSTR%" /i /c:"Provider Name:" /c:"Event ID:" /c:"Level:" "%WORK%\step80-memory-events.txt" >>"%DETAILS%" 2>nul
) else (
  >>"%DETAILS%" echo hardware_event_query=TOOL_OR_LOG_UNAVAILABLE
)

echo [5/5] Recording pre-install decision-support result...
>>"%DETAILS%" echo windows_target=PASS
>>"%DETAILS%" echo product_key_value_exposed=NO
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Pre-install hardware and activation triage completed safely.
>>"%RESULT%" echo EVIDENCE=Windows edition, redacted OEM-key presence, read-only filesystem health, storage status/SMART availability, and bounded hardware-event metadata checked; no Windows changes or reboot.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will decide whether HP UEFI hardware diagnostics are still required before clean Windows installation.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - PRE-INSTALL TRIAGE SENT FOR REVIEW
echo WINDOWS CHANGES     : NONE
echo PRODUCT KEY VALUE   : NOT DISPLAYED / NOT UPLOADED
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Pre-install hardware and activation triage could not complete safely.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, product key, or reboot was changed or uploaded.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - PRE-INSTALL TRIAGE FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
