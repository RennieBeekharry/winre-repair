@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Prepare a separate temporary Safe Mode diagnostic boot entry without changing the normal default loader or rebooting.
rem WR_ACTION=PREPARE_SEPARATE_SAFE_MODE_DIAGNOSTIC_ENTRY
rem WR_TARGET=EFI BCD temporary copied loader entry plus RescueMeAI rollback/state files only.
rem WR_CONSEQUENCE=Backs up the EFI BCD, copies the verified default Windows loader to a separate diagnostic entry, and sets safeboot=minimal and bootlog=Yes on that copied entry only. The normal default loader is not changed, no one-time boot sequence is armed, and no reboot occurs.
rem WR_ROLLBACK=The original EFI BCD is saved at C:\RescueMeAI\backups\pre-safemode-step74\BCD and is automatically restored if preparation fails before verification.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=74"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "BACKUP=C:\RescueMeAI\backups\pre-safemode-step74"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "GUIDFILE=%STATE%\safemode-step74-guid.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"

cls
echo ================================================================================
echo RescueMeAI - PREPARE SEPARATE SAFE MODE DIAGNOSTIC
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Normal boot reaches late device initialization and then
echo                       stalls. Storage is loading; BasicDisplay and AMD amdkmdag
echo                       both appear in the real boot log.
echo CURRENT TASK        : Preparing a separate Safe Mode loader entry so the next
echo                       approved test can isolate nonessential drivers/services.
echo SAFETY              : REPAIR-WRITE - reversible BCD diagnostic entry only.
echo NORMAL DEFAULT BOOT : NOT CHANGED
echo ONE-TIME BOOT ARMED : NO
echo PERSONAL FILES      : NOT TOUCHED
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not reboot manually.
echo SCREENSHOT REQUIRED : NO unless this step stops with an error.
echo ================================================================================

if not exist "%WORK%" md "%WORK%" >nul 2>&1
if not exist "%STATE%" md "%STATE%" >nul 2>&1
if not exist "%BACKUP%" md "%BACKUP%" >nul 2>&1
if not exist "%MOUNTVOL%" goto :FAIL
if not exist "%BCDEDIT%" goto :FAIL
if not exist "C:\Windows\System32\config\SYSTEM" goto :FAIL

> "%DETAILS%" echo RESCUEMEAI PREPARE SAFE MODE DIAGNOSTIC ENTRY
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/6] Mounting the EFI system partition temporarily...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if exist T:\nul if "!SYS!"=="T:" set "SYS=U:"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step74-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "MOUNTED=YES"
set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :MOUNTFAIL

echo [2/6] Saving a rollback copy of the EFI BCD...
copy /y "!BCD!" "%BACKUP%\BCD" >nul
if errorlevel 1 goto :MOUNTFAIL
>>"%DETAILS%" echo bcd_backup=%BACKUP%\BCD

echo [3/6] Checking for an already-prepared Step 74 diagnostic entry...
set "SAFEGUID="
if exist "%GUIDFILE%" set /p "SAFEGUID="<"%GUIDFILE%"
if defined SAFEGUID (
  "%BCDEDIT%" /store "!BCD!" /enum !SAFEGUID! >"%WORK%\step74-existing.txt" 2>&1
  if not errorlevel 1 goto :ALREADY_PREPARED
  set "SAFEGUID="
)

echo [4/6] Copying the normal loader to a separate diagnostic entry...
"%BCDEDIT%" /store "!BCD!" /copy {default} /d "RescueMeAI Safe Mode Diagnostic" >"%WORK%\step74-copy.txt" 2>&1
if errorlevel 1 goto :ROLLBACK
for /f "tokens=6" %%G in ('type "%WORK%\step74-copy.txt"') do set "SAFEGUID=%%G"
set "SAFEGUID=!SAFEGUID:.=!"
if not defined SAFEGUID goto :ROLLBACK
if not "!SAFEGUID:~0,1!"=="{" goto :ROLLBACK
if not "!SAFEGUID:~-1!"=="}" goto :ROLLBACK
>>"%DETAILS%" echo safe_mode_entry=!SAFEGUID!

echo [5/6] Applying Safe Mode and boot logging to the copied entry only...
"%BCDEDIT%" /store "!BCD!" /set !SAFEGUID! safeboot minimal >"%WORK%\step74-safeboot.txt" 2>&1
if errorlevel 1 goto :ROLLBACK
"%BCDEDIT%" /store "!BCD!" /set !SAFEGUID! bootlog Yes >"%WORK%\step74-bootlog.txt" 2>&1
if errorlevel 1 goto :ROLLBACK
> "%GUIDFILE%" echo !SAFEGUID!
>>"%DETAILS%" echo safeboot_set_exit=0
>>"%DETAILS%" echo bootlog_set_exit=0

echo [6/6] Capturing the prepared entry for review and unmounting EFI...
"%BCDEDIT%" /store "!BCD!" /enum !SAFEGUID! >"%WORK%\step74-entry.txt" 2>&1
if errorlevel 1 goto :ROLLBACK
type "%WORK%\step74-entry.txt" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo normal_default_loader_changed=NO
>>"%DETAILS%" echo bootsequence_armed=NO
>>"%DETAILS%" echo reboot_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"
goto :SUCCESS

:ALREADY_PREPARED
>>"%DETAILS%" echo safe_mode_entry=!SAFEGUID!
>>"%DETAILS%" echo prepared_entry_reused=YES
type "%WORK%\step74-existing.txt" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo normal_default_loader_changed=NO
>>"%DETAILS%" echo bootsequence_armed=NO
>>"%DETAILS%" echo reboot_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"

:SUCCESS
> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Separate Safe Mode diagnostic entry prepared; normal boot was not changed and no reboot occurred.
>>"%RESULT%" echo EVIDENCE=Temporary diagnostic loader=!SAFEGUID!; rollback BCD saved; bootsequence not armed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Wait for ChatGPT review and explicit approval before arming this entry for one reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - SAFE MODE DIAGNOSTIC ENTRY PREPARED
echo NORMAL DEFAULT BOOT : UNCHANGED
echo ONE-TIME BOOT ARMED : NO
echo BCD BACKUP          : SAVED LOCALLY
echo REBOOT              : NO
echo WHAT YOU SHOULD DO  : WAIT. Do not reboot manually.
echo SCREENSHOT REQUIRED : NO
echo HOW TO REPLY        : Reply CONTINUE when ChatGPT asks to start the Safe Mode test.
echo ================================================================================
exit /b 0

:ROLLBACK
copy /y "%BACKUP%\BCD" "!BCD!" >nul 2>&1
if exist "%GUIDFILE%" del /f /q "%GUIDFILE%" >nul 2>&1
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Safe Mode diagnostic preparation failed and the original EFI BCD was restored.
>>"%RESULT%" echo EVIDENCE=Automatic rollback attempted; no reboot occurred and personal files were not targeted.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - SAFE MODE PREPARATION ROLLED BACK
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90

:MOUNTFAIL
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"
:FAIL
if /i "!MOUNTED!"=="YES" "%MOUNTVOL%" !SYS! /D >nul 2>&1
> "%RESULT%" echo STATUS=FAIL
>>"%RESULT%" echo MESSAGE=Safe Mode diagnostic preparation stopped before a verified change completed.
>>"%RESULT%" echo EVIDENCE=No reboot occurred and personal files were not targeted.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=YES
echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : STOPPED - SAFE MODE PREPARATION FAILED
echo REBOOT              : NO
echo SCREENSHOT REQUIRED : YES
echo WHAT YOU SHOULD DO  : Reply FAILED and send ChatGPT a photo. Do not reboot.
echo ================================================================================
exit /b 90
