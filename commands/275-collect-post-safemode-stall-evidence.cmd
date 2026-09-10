@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=READ_ONLY
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Collect post-Safe-Mode-stall boot evidence and verify the one-time diagnostic boot state without changing Windows or rebooting.
rem WR_ACTION=COLLECT_POST_SAFEMODE_STALL_EVIDENCE
rem WR_TARGET=C:\Windows\ntbtlog.txt, EFI BCD read-only state, and RescueMeAI diagnostic markers/output only.
rem WR_CONSEQUENCE=Reads the Safe Mode boot log and BCD state. No Windows setting, driver, registry, package, partition, personal file, or reboot is changed.
rem WR_ROLLBACK=Not applicable; this command is read-only.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=78"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "LOG=C:\Windows\ntbtlog.txt"
set "NUMBERED=%WORK%\step78-ntbt-numbered.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"

cls
echo ================================================================================
echo RescueMeAI - POST SAFE MODE STALL EVIDENCE
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Normal boot AND the one-time Safe Mode Minimal boot both
echo                       stall at the HP loading screen.
echo CURRENT TASK        : Capture the Safe Mode boot-log tail and verify one-time BCD
echo                       state before deciding on any further repair.
echo SAFETY              : READ-ONLY - NO REBOOT.
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
>"%DETAILS%" echo RESCUEMEAI POST SAFE MODE STALL EVIDENCE
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/4] Verifying the Safe Mode test marker and Windows target...
set "TESTMARK=NO"
set "REBOOTGUARD=NO"
if exist "%STATE%\safemode-test-77.started" set "TESTMARK=YES"
if exist "%STATE%\reboot-command-77.issued" set "REBOOTGUARD=YES"
>>"%DETAILS%" echo safemode_test_77_marker=!TESTMARK!
>>"%DETAILS%" echo reboot_command_77_guard=!REBOOTGUARD!
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

echo [2/4] Capturing the final raw portion of the current Windows boot log...
set "PRESENT=NO"
set "SIZE=0"
set "LINES=0"
set "CAPTURED=0"
if exist "%LOG%" (
  set "PRESENT=YES"
  for %%Z in ("%LOG%") do set "SIZE=%%~zZ"
  for /f %%N in ('find /c /v "" ^< "%LOG%"') do set "LINES=%%N"
  findstr /n "^" "%LOG%" >"%NUMBERED%" 2>nul
  set /a START=LINES-44
  if !START! LSS 1 set "START=1"
  >>"%DETAILS%" echo ntbtlog_present=YES
  >>"%DETAILS%" echo ntbtlog_size=!SIZE!
  >>"%DETAILS%" echo ntbtlog_lines=!LINES!
  >>"%DETAILS%" echo.
  >>"%DETAILS%" echo --- FINAL RAW BOOTLOG PORTION ---
  for /f "usebackq tokens=1,* delims=:" %%A in ("%NUMBERED%") do (
    set /a N=%%A+0 >nul 2>&1
    if !N! GEQ !START! if !CAPTURED! LSS 45 (
      >>"%DETAILS%" echo [%%A]%%B
      set /a CAPTURED+=1
    )
  )
) else (
  >>"%DETAILS%" echo ntbtlog_present=NO
)
>>"%DETAILS%" echo captured_final_lines=!CAPTURED!

echo [3/4] Reading one-time boot-manager state from the EFI BCD...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if exist T:\nul if "!SYS!"=="T:" set "SYS=U:"
set "BOOTSEQ_STATE=UNKNOWN"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step78-mount.txt" 2>&1
if not errorlevel 1 (
  set "MOUNTED=YES"
  set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
  if exist "!BCD!" (
    "%BCDEDIT%" /store "!BCD!" /enum {bootmgr} >"%WORK%\step78-bootmgr.txt" 2>&1
    if not errorlevel 1 (
      findstr /i /c:"bootsequence" "%WORK%\step78-bootmgr.txt" >nul 2>&1
      if errorlevel 1 (set "BOOTSEQ_STATE=NOT_PRESENT") else set "BOOTSEQ_STATE=PRESENT"
    )
  )
  "%MOUNTVOL%" !SYS! /D >nul 2>&1
  set "MOUNTED=NO"
)
>>"%DETAILS%" echo bootsequence_state_after_attempt=!BOOTSEQ_STATE!

echo [4/4] Recording result...
>>"%DETAILS%" echo windows_changes_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
>>"%DETAILS%" echo reboot_performed=NO

>"%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Post-Safe-Mode-stall evidence captured successfully.
>>"%RESULT%" echo EVIDENCE=Safe Mode marker=!TESTMARK!; reboot guard=!REBOOTGUARD!; ntbtlog=!PRESENT! size=!SIZE! lines=!LINES! final-lines=!CAPTURED!; bootsequence=!BOOTSEQ_STATE!.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=RescueMeAI will review the Safe Mode boot evidence before any additional reboot or repair.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : COMPLETE - SAFE MODE STALL EVIDENCE SENT
echo WINDOWS CHANGES     : NONE
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Leave this window open.
echo SCREENSHOT REQUIRED : NO
echo ================================================================================
exit /b 0

:FAIL
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
>"%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Post-Safe-Mode-stall evidence collection could not verify the offline Windows target.
>>"%RESULT%" echo EVIDENCE=No Windows setting, personal file, or reboot was performed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - EVIDENCE COLLECTION FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
