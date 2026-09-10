@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem WR_RISK=REPAIR_WRITE
rem WR_LOCAL_AUTH=NOT_REQUIRED
rem WR_SUMMARY=Prepare a separate temporary Safe Mode diagnostic loader after correcting the Step 74 GUID parser; do not arm it or reboot.
rem WR_ACTION=PREPARE_SEPARATE_SAFE_MODE_DIAGNOSTIC_ENTRY_V2
rem WR_TARGET=EFI BCD temporary copied loader entry plus RescueMeAI rollback/state files only.
rem WR_CONSEQUENCE=Backs up the EFI BCD, copies the verified default Windows loader to a separate diagnostic entry, and sets safeboot=minimal and bootlog=Yes on that copied entry only. The normal default loader is not changed, no one-time boot sequence is armed, and no reboot occurs.
rem WR_ROLLBACK=The original EFI BCD is saved at C:\RescueMeAI\backups\pre-safemode-step76\BCD and is automatically restored if preparation fails.

set "FIX_VERSION=RMAI-FIX-2026.09.10.3"
set "STEP=76"
set "WORK=C:\WinRERepair"
set "STATE=C:\RescueMeAI\state"
set "BACKUP=C:\RescueMeAI\backups\pre-safemode-step76"
set "RESULT=%WORK%\COMMAND_RESULT.env"
set "DETAILS=%WORK%\RUN_DETAILS.txt"
set "GUIDFILE=%STATE%\safemode-step76-guid.txt"
set "MOUNTVOL=X:\Windows\System32\mountvol.exe"
if not exist "%MOUNTVOL%" set "MOUNTVOL=C:\Windows\System32\mountvol.exe"
set "BCDEDIT=X:\Windows\System32\bcdedit.exe"
if not exist "%BCDEDIT%" set "BCDEDIT=C:\Windows\System32\bcdedit.exe"

cls
echo ================================================================================
echo RescueMeAI - PREPARE SEPARATE SAFE MODE DIAGNOSTIC V2
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : RUNNING
echo CURRENT DIAGNOSIS   : Normal boot reaches late device initialization then hangs.
echo                       The raw boot log confirms BasicDisplay and AMD amdkmdag load.
echo CURRENT TASK        : Preparing a separate Safe Mode loader to isolate optional
echo                       drivers/services without altering the normal default loader.
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

> "%DETAILS%" echo RESCUEMEAI PREPARE SAFE MODE DIAGNOSTIC ENTRY V2
>>"%DETAILS%" echo fix_version=%FIX_VERSION%
>>"%DETAILS%" echo step=%STEP%

echo [1/6] Mounting the EFI system partition temporarily...
set "SYS=S:"
if exist S:\nul set "SYS=T:"
if exist T:\nul if "!SYS!"=="T:" set "SYS=U:"
"%MOUNTVOL%" !SYS! /S >"%WORK%\step76-mount.txt" 2>&1
if errorlevel 1 goto :FAIL
set "MOUNTED=YES"
set "BCD=!SYS!\EFI\Microsoft\Boot\BCD"
if not exist "!BCD!" goto :MOUNTFAIL

echo [2/6] Saving a rollback copy of the EFI BCD...
copy /y "!BCD!" "%BACKUP%\BCD" >nul
if errorlevel 1 goto :MOUNTFAIL
>>"%DETAILS%" echo bcd_backup=%BACKUP%\BCD

echo [3/6] Copying the normal loader to a separate diagnostic entry...
"%BCDEDIT%" /store "!BCD!" /copy {default} /d "RescueMeAI Safe Mode Diagnostic" >"%WORK%\step76-copy.txt" 2>&1
if errorlevel 1 goto :ROLLBACK
set "SAFEGUID="
for /f "tokens=7" %%G in ('type "%WORK%\step76-copy.txt"') do set "SAFEGUID=%%G"
set "SAFEGUID=!SAFEGUID:.=!"
if not defined SAFEGUID goto :ROLLBACK
if not "!SAFEGUID:~0,1!"=="{" goto :ROLLBACK
if not "!SAFEGUID:~-1!"=="}" goto :ROLLBACK
>>"%DETAILS%" echo safe_mode_entry=!SAFEGUID!

echo [4/6] Applying Safe Mode Minimal to the copied entry only...
"%BCDEDIT%" /store "!BCD!" /set !SAFEGUID! safeboot minimal >"%WORK%\step76-safeboot.txt" 2>&1
set "SAFERC=!errorlevel!"
>>"%DETAILS%" echo safeboot_set_exit=!SAFERC!
if not "!SAFERC!"=="0" goto :ROLLBACK

echo [5/6] Enabling boot logging on the copied diagnostic entry...
"%BCDEDIT%" /store "!BCD!" /set !SAFEGUID! bootlog Yes >"%WORK%\step76-bootlog.txt" 2>&1
set "BOOTRC=!errorlevel!"
>>"%DETAILS%" echo bootlog_set_exit=!BOOTRC!
if not "!BOOTRC!"=="0" goto :ROLLBACK

echo [6/6] Saving the entry identifier and capturing the prepared entry...
> "%GUIDFILE%" echo !SAFEGUID!
"%BCDEDIT%" /store "!BCD!" /enum !SAFEGUID! >"%WORK%\step76-entry.txt" 2>&1
set "ENUMRC=!errorlevel!"
>>"%DETAILS%" echo enum_prepared_entry_exit=!ENUMRC!
if not "!ENUMRC!"=="0" goto :ROLLBACK
type "%WORK%\step76-entry.txt" >>"%DETAILS%" 2>nul
>>"%DETAILS%" echo normal_default_loader_changed=NO
>>"%DETAILS%" echo bootsequence_armed=NO
>>"%DETAILS%" echo reboot_performed=NO
>>"%DETAILS%" echo personal_files_targeted=NO
"%MOUNTVOL%" !SYS! /D >nul 2>&1
set "MOUNTED=NO"

> "%RESULT%" echo STATUS=PASS
>>"%RESULT%" echo MESSAGE=Separate Safe Mode diagnostic entry prepared successfully; normal default boot is unchanged and no reboot occurred.
>>"%RESULT%" echo EVIDENCE=Temporary diagnostic loader=!SAFEGUID!; rollback BCD saved; safeboot and bootlog set operations succeeded; bootsequence not armed.
>>"%RESULT%" echo SCREENSHOT_REQUIRED=NO
>>"%RESULT%" echo NEXT_STEP=Wait for ChatGPT review and explicit approval before arming this entry for one controlled reboot.

echo.
echo ================================================================================
echo RECOVERY FIX        : %FIX_VERSION%
echo STEP                : %STEP%
echo STATUS              : READY - SAFE MODE DIAGNOSTIC PREPARED
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
